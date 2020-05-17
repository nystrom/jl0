# 64 should be enough for anybody
const INIT_HEAP_SIZE = 64

"""
    struct Frame

Call stack frame
"""
@auto_hash_equals mutable struct Frame
    # operand stack for the current function
    stack::Vector{Value} 

    # local variable store for the current function
    vars::Dict{Symbol, Value}

    return_address::Int
end

"""
    struct State

Interpreter state: program counter, operand stack, variables map, and labels map.
"""
@auto_hash_equals mutable struct State
    # program counter
    pc::Int

    # instruction array
    insns::Vector{Insn}

    # map from label names to instruction index
    labels::Dict{Symbol, Int}

    # call stack 
    frames::Vector{Frame}

    # heap (maps from LOC to Value)
    heap::Vector{Union{Nothing, Symbol, Value}}

    # global function definition store
    funcs::Dict{Symbol, FUNC}

    # global struct definition store
    structs::Dict{Symbol, STRUCT}

    function State()
        new(1,
            Insn[],
            Dict{Symbol, Int}(),
            Frame[],
            fill(nothing, INIT_HEAP_SIZE),
            Dict{Symbol, FUNC}(),
            Dict{Symbol, STRUCT}(),
       )
    end
end

function current_frame(state)
    last(state.frames)
end

function append_insns!(state, insns::Vector{Insn})
    append!(state.insns, insns)

    # Update the instruction labels.
    for (i, insn) in enumerate(state.insns)
        if insn isa LABEL
            state.labels[insn.label] = i
        end
    end
end

function append_insns!(state, func::FUNC)
    append_insns!(state, func.body)
end

