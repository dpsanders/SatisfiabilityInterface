using SatisfiabilityInterface
using Test



@testset "SatisfiabilityInterface.jl" begin

    include("graph_colouring.jl")
    include("sudoku.jl")
    include("MOI_wrapper.jl")
    include("JuMP.jl")

end

