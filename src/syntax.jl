abstract type Exp end

# Integer literal
struct Lit <: Exp
    value::Int
end

# Binary operator. Op should be one of :+, :-, :*, :/
struct Bin <: Exp
    op::Symbol
    e1::Exp
    e2::Exp
end

# Variable
struct Var <: Exp
    name::Symbol
end

# Assign to a variable
struct Assign <: Exp
    name::Symbol
    exp::Exp
end

# Eval t_part if cond is not zero, f_part if false
struct If <: Exp
    cond::Exp
    t_part::Exp
    f_part::Exp
end

# Eval body while cond is not zero. Evaluates to the number of loop iterations
struct While <: Exp
    cond::Exp
    body::Exp
end

# Print the values
struct Print <: Exp
    exps::Vector{Exp}
end

# Evaluate all the expressions in the block. Result is the last expression.
struct Block <: Exp
    exps::Vector{Exp}
end

# Function definition
struct Func <: Exp
    fname::Symbol
    params::Vector{Symbol}
    body::Exp
end

# Function call
struct Call <: Exp
    fname::Symbol
    args::Vector{Exp}
end

# Function return
struct Return <: Exp
    exp::Exp
end
