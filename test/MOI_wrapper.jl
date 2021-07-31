import MathOptInterface
const MOI = MathOptInterface

@testset "MOI wrapper" begin
    model = SatisfiabilityInterface.Optimizer{Bool}()

    x, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
    y, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
    z, _ = MOI.add_constrained_variable(model, MOI.ZeroOne())
    
    MOI.add_constraint(model, MOI.VectorOfVariables([x, y, z]), SatisfiabilityInterface.CNF([true, true, true]))
    MOI.add_constraint(model, MOI.VectorOfVariables([x, y, z]), SatisfiabilityInterface.CNF([false, true, true]))
    MOI.add_constraint(model, MOI.VectorOfVariables([x, y]),    SatisfiabilityInterface.CNF([false, false]))
    MOI.add_constraint(model, MOI.VectorOfVariables([y, z]),    SatisfiabilityInterface.CNF([false, false]))
    MOI.add_constraint(model, MOI.VectorOfVariables([x, z]),    SatisfiabilityInterface.CNF([true, false]))
    
    MOI.optimize!(model)
    
    @test MOI.get(model, MOI.RawStatusString()) == "sat"
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
    @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT
    @test !MOI.get(model, MOI.VariablePrimal(), x)
    @test MOI.get(model, MOI.VariablePrimal(), y)
    @test !MOI.get(model, MOI.VariablePrimal(), z)
end
