import MathOptInterface
const MOI = MathOptInterface

mutable struct Optimizer{T} <: MOI.AbstractOptimizer
    problem::SATProblem
    status::Symbol
    results::Vector{Int}
end
const NOT_CALLED = :notcalled
function Optimizer{T}() where {T}
    return Optimizer{T}(SATProblem(0, Vector{Int}[]), NOT_CALLED, Int[])
end
# JuMP will expects `VariablePrimal` to return `Float64`
Optimizer() = Optimizer{Float64}()
function MOI.empty!(model::Optimizer)
    model.problem.num_variables = 0
    empty!(model.problem.clauses)
    model.status = NOT_CALLED
    empty!(model.results)
end
function MOI.is_empty(model::Optimizer)
    return iszero(model.problem.num_variables) && isempty(model.problem.clauses)
end
MOI.supports_add_constrained_variable(::Optimizer, ::Type{MOI.ZeroOne}) = true
function MOI.add_constrained_variable(model::Optimizer, ::MOI.ZeroOne)
    model.problem.num_variables += 1
    id = model.problem.num_variables
    return MOI.VariableIndex(id), MOI.ConstraintIndex{MOI.SingleVariable,MOI.ZeroOne}(id)
end
struct CNF <: MOI.AbstractVectorSet
    not::Vector{Bool}
end
MOI.dimension(set::CNF) = length(set.not)
Base.copy(set::CNF) = CNF(Base.copy(set.not))
_not(id::Int, not::Bool) = not ? -id : id
MOI.supports_constraint(::Optimizer, ::Type{MOI.VectorOfVariables}, ::Type{CNF}) = true
function MOI.add_constraint(model::Optimizer, func::MOI.VectorOfVariables, set::CNF)
    clause = Int[_not(func.variables[i].value, set.not[i]) for i in eachindex(set.not)]
    push!(model.problem, clause)
    return MOI.ConstraintIndex{typeof(func),typeof(set)}(length(model.problem.clauses))
end
function MOI.optimize!(model::Optimizer)
    model.status, model.results = solve(model.problem)
end
const TERM = Dict(NOT_CALLED => MOI.OPTIMIZE_NOT_CALLED, :sat => MOI.OPTIMAL, :unsat => MOI.INFEASIBLE, :unknown => MOI.TIME_LIMIT)
MOI.get(model::Optimizer, ::MOI.RawStatusString) = string(model.status)
MOI.get(model::Optimizer, ::MOI.TerminationStatus) = TERM[model.status]
MOI.get(model::Optimizer, ::MOI.ResultCount) = model.status == :sat ? 1 : 0
function MOI.get(model::Optimizer, attr::MOI.PrimalStatus)
    if 1 <= attr.N <= MOI.get(model, MOI.ResultCount())
        return MOI.FEASIBLE_POINT
    else
        return MOI.NO_SOLUTION
    end
end
MOI.get(model::Optimizer, ::MOI.DualStatus) = MOI.NO_SOLUTION
MOI.get(model::Optimizer, ::MOI.VariablePrimal, vi::MOI.VariableIndex) = model.results[vi.value] > 0
