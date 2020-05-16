abstract type Insn end

# By convention, to distinguish from the JL0 ASTs, types here are ALL CAPS.

# Function definition.
@auto_hash_equals struct FUNC
    fname::Symbol
    params::Vector{Symbol}
    body::Vector{Insn}
end

# Struct definition.
@auto_hash_equals struct STRUCT
    name::Symbol
    fields::Vector{Symbol}
end

abstract type Value end

@auto_hash_equals struct INT <: Value
    value::Int
end

@auto_hash_equals struct LOC <: Value
    value::Int
end

# Create a new empty struct, with all fields initialized to 0.
# Pushes the struct address.
@auto_hash_equals struct NEW <: Insn
    structname::Symbol
end

# Load a field. Pops the address from the stack.
@auto_hash_equals struct GET <: Insn
    field::Symbol
end

# Store a field. Pops the address and value from the stack.
@auto_hash_equals struct PUT <: Insn
    field::Symbol
end

# Call the given function.
@auto_hash_equals struct CALL <: Insn
    fname::Symbol
end

# Return to the caller, popping the return value from the stack.
# Push the return value in the caller frame.
struct RET <: Insn end

# This just stops execution. Used just in the main program since RET would try to pop
# to a nonexistent caller frame.
struct STOP <: Insn end

# Load a local variable: push its value on the stack
@auto_hash_equals struct LD <: Insn
    name::Symbol
end

# Store a local variable: pop its value from the stack and store
@auto_hash_equals struct ST <: Insn
    name::Symbol
end

# Push a constant on the stack
@auto_hash_equals struct LDC <: Insn
    value::Int
end

# Push null
struct NULL <: Insn end

# Arithmetic operators. Pop two operands and push result.
struct ADD <: Insn end
struct SUB <: Insn end
struct MUL <: Insn end
struct DIV <: Insn end

# Pushes 0 if top two operands are equal, else 1
struct CMP <: Insn end

# Pop and print the value on top of the stack
struct PRINT <: Insn end

# Pop the value on top of the stack and discard it
struct POP <: Insn end

# Duplicate the value on top of the stack (i.e., push it again)
struct DUP <: Insn end

# Jump target label. No stack changes.
@auto_hash_equals struct LABEL <: Insn
    label::Symbol
end

# Unconditional jump. Jump to the given label. No stack changes.
@auto_hash_equals struct JMP <: Insn
    label::Symbol
end

# Conditional jumps.
# Pop and jump to the given label if == 0.
@auto_hash_equals struct JEQ <: Insn
    label::Symbol
end

# Pop and jump to the given label if != 0.
@auto_hash_equals struct JNE <: Insn
    label::Symbol
end

# Pop and jump to the given label if < 0.
@auto_hash_equals struct JLT <: Insn
    label::Symbol
end

# Pop and jump to the given label if > 0.
@auto_hash_equals struct JGT <: Insn
    label::Symbol
end

# Pop and jump to the given label if <= 0.
@auto_hash_equals struct JLE <: Insn
    label::Symbol
end

# Pop and jump to the given label if >= 0.
@auto_hash_equals struct JGE <: Insn
    label::Symbol
end
