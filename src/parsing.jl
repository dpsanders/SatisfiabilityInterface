


function parse_expression(varmap, ex) 
    op = operation(ex)
    args = arguments(ex)

    new_args = parse_expression.(Ref(varmap), args)

    return op, new_args
end

function parse_expression(varmap, ex::Term) 
    if ex.f == getindex 
        return varmap[ex]
    else
        op = operation(ex)
        args = arguments(ex)
    
        new_args = parse_expression.(Ref(varmap), args)
    
        return op, new_args
    end
end
parse_expression(varmap, ex::Sym) = varmap[ex]
parse_expression(varmap, ex::Num) = parse_expression(varmap, value(ex))
parse_expression(varmap, ex::Real) = ex


"Parse a symbolic expression into a relation"
function parse_relation(varmap, ex)
    op = operation(ex)
    args = arguments(ex)

    lhs = args[1]
    rhs = args[2]

   
    return BinaryRelation{op}(parse_expression(varmap, lhs), parse_expression(varmap, rhs))

end


# function parse_relation!(varmap, ex::Equation)
    
#     varmap[ex.lhs] = parse_expression(varmap, ex.rhs)   

# end

is_variable(ex) = !istree(ex) || (operation(ex) == getindex)

function process(constraint)

    # println("\nprocess")
    # @show constraint

    new_constraints = []

    constraint2 = value(constraint)

    op = operation(constraint2)
    args = arguments(constraint2)

    lhs = args[1]
    rhs = args[2]

    # @show op
    # @show lhs 
    # @show rhs

    intermediates_generated = false

    if !is_variable(lhs)
        lhs = flatten_expression(lhs)

        append!(new_constraints, lhs[1])
        lhs = lhs[2]

    end

    if !is_variable(rhs)
        rhs = flatten_expression(rhs)

        append!(new_constraints, rhs[1])
        rhs = rhs[2]

    end

    if op ∈ (==, <=, <, >=, >, !=)   # an actual constraint
        push!(new_constraints, op(lhs, rhs))
    
    else
        val = make_variable()        # defines a new variable
        push!(new_constraints, val ~ op(lhs, rhs))
    end

    @show new_constraints
    return new_constraints

end


process(constraints::Vector) = reduce(vcat, process(constraint) for constraint in constraints)
    




function parse_constraint!(domains, ex::Equation)   # ~ produces an Equation
   lhs = Num(ex.lhs)
   rhs = Num(ex.rhs)
   
#    @show lhs
#    @show rhs 
#    @show typeof(rhs)

   new_constraints = process(rhs)

@show new_constraints

    last = pop!(new_constraints)   # remove last constraint to rename its lhs variable 

    push!(new_constraints, lhs ~ last.rhs)



   return domains, new_constraints

   


end

function parse_constraint!(domains, ex)

    expr = value(ex)
    op = operation(expr)

    new_constraints = []

    if op == ∈   # assumes right-hand side is an explicit set specifying the doomain

        args = arguments(expr)

        var = args[1]
        domain = args[2]

        domains[var] = domain

    else
        new_constraints = process(expr)
     
    end

    return domains, new_constraints

end


function parse_constraints(constraints)
    # domains = Dict(var => -Inf..Inf for var in vars)

    additional_vars = []
    domains = Dict()
    all_new_constraints = []  # excluding domain constraints

    for constraint in constraints

        # binarize constraints: 
        domains, new_constraints = parse_constraint!(domains, constraint)

        for statement in new_constraints 
            if statement isa Equation 
                push!(additional_vars, statement.lhs)
            end
        end

        append!(all_new_constraints, new_constraints)
    end

    # append!(additional_vars, keys(domains))

    return domains, all_new_constraints, additional_vars
end

