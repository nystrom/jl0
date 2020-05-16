abstract type Exp end

# Integer literal
@auto_hash_equals struct Lit <: Exp
    value::Int
end

struct LitNothing <: Exp end

# Binary operator. Op should be one of :+, :-, :*, :/
@auto_hash_equals struct Bin <: Exp
    op::Symbol
    e1::Exp
    e2::Exp
end

# Variable
@auto_hash_equals struct Var <: Exp
    name::Symbol
end

# Assign to a variable
@auto_hash_equals struct Assign <: Exp
    name::Symbol
    exp::Exp
end

# Eval t_part if cond is not zero, f_part if false
@auto_hash_equals struct If <: Exp
    cond::Exp
    t_part::Exp
    f_part::Exp
end

# Eval body while cond is not zero. Evaluates to the number of loop iterations
@auto_hash_equals struct While <: Exp
    cond::Exp
    body::Exp
end

# Print the values
@auto_hash_equals struct Print <: Exp
    exps::Vector{Exp}
end

# Evaluate all the expressions in the block. Result is the last expression.
@auto_hash_equals struct Block <: Exp
    exps::Vector{Exp}
end

# Function definition
@auto_hash_equals struct Func
    fname::Symbol
    params::Vector{Symbol}
    body::Exp
end

# Function call
@auto_hash_equals struct Call <: Exp
    fname::Symbol
    args::Vector{Exp}
end

# Function return
@auto_hash_equals struct Return <: Exp
    exp::Exp
end

# Struct definition
@auto_hash_equals struct Struct
    name::Symbol
    fields::Vector{Symbol}
end

# New struct
@auto_hash_equals struct New <: Exp
    name::Symbol
    fields::Vector{Exp}
end

# Field access
@auto_hash_equals struct GetField <: Exp
    target::Exp
    field::Symbol
end

# Field access
@auto_hash_equals struct SetField <: Exp
    target::Exp
    field::Symbol
    value::Exp
end
