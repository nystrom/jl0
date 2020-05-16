"""
    struct Frame

Call stack frame
"""
mutable struct Frame
    # operand stack for the current function
    stack::Vector{Int} 

    # local variable store for the current function
    vars::Dict{Symbol,Int}

    return_address::Int
end

"""
    struct State

Interpreter state: program counter, operand stack, variables map, and labels map.
"""
mutable struct State
    # program counter
    pc::Int

    # instruction array
    insns::Vector{Insn}

    # map from label names to instruction index
    labels::Dict{Symbol,Int}

    # call stack 
    frames::Vector{Frame}

    # global function store
    funcs::Dict{Symbol,FUNC}

    function State(insns, labels, funcs)
        new(1,
            insns,
            labels,
            Frame[],
            funcs,
        )
    end
end

function current_frame(state)
    last(state.frames)
end

function eval(insns::Vector{Insn}, funcs::Dict{Symbol,FUNC}, vars::Dict{Symbol,Int}; debug=false)::Union{Nothing,Tuple{Int,Dict{Symbol,Int}}}
    for (label, func) in funcs
        append!(insns, func.body)
    end

    labels = Dict{Symbol,Int}()

    # Set up the jump labels.
    for (i, insn) in enumerate(insns)
        if insn isa LABEL
            labels[insn.label] = i
        end
    end

    state = State(insns, labels, funcs)

    # Push a frame for the main function. This is the frame for the top-level expression.
    push!(state.frames, Frame(Int[], copy(vars), 0))

    while 1 <= state.pc && state.pc <= length(state.insns)
        debug && println(state)

        # fetch
        insn = state.insns[state.pc]
        # execute
        eval_insn(insn, state)
    end

    debug && println("end ", state)

    # We should have popped all the frames but the start frame.
    @assert length(state.frames) == 1

    # Get the return value from the start frame stack.
    frame = current_frame(state)

    @assert !isempty(frame.stack)

    return (frame.stack[end], frame.vars)
end

function eval_insn(insn::CALL, state::State)
    caller_frame = current_frame(state)

    func = state.funcs[insn.fname]
    args = Dict{Symbol, Int}()

    # pop the arugments
    for x in func.params
        v = pop!(caller_frame.stack)
        args[x] = v
    end

    # push a new stack frame
    push!(state.frames, Frame(Int[], args, state.pc+1))

    # jump to the function entry
    state.pc = state.labels[insn.fname]
end

function eval_insn(insn::RET, state::State)
    # pop the callee frame
    callee_frame = pop!(state.frames)
    caller_frame = current_frame(state)

    # pop the return value from the callee frame and push on the caller frame
    return_value = pop!(callee_frame.stack)
    push!(caller_frame.stack, return_value)

    # jump to the return address
    state.pc = callee_frame.return_address
end

function eval_insn(insn::STOP, state::State)
    state.pc = 0
end

function eval_insn(insn::JMP, state::State)
    state.pc = state.labels[insn.label]
end

function eval_insn(insn::JEQ, state::State)
    frame = current_frame(state)
    v = pop!(frame.stack)
    if v == 0
        state.pc = state.labels[insn.label]
    else
        state.pc += 1
    end
end

function eval_insn(insn::JNE, state::State)
    frame = current_frame(state)
    v = pop!(frame.stack)
    if v != 0
        state.pc = state.labels[insn.label]
    else
        state.pc += 1
    end
end

function eval_insn(insn::JLT, state::State)
    frame = current_frame(state)
    v = pop!(frame.stack)
    if v < 0
        state.pc = state.labels[insn.label]
    else
        state.pc += 1
    end
end

function eval_insn(insn::JGT, state::State)
    frame = current_frame(state)
    v = pop!(frame.stack)
    if v > 0
        state.pc = state.labels[insn.label]
    else
        state.pc += 1
    end
end

function eval_insn(insn::JLE, state::State)
    frame = current_frame(state)
    v = pop!(frame.stack)
    if v <= 0
        state.pc = state.labels[insn.label]
    else
        state.pc += 1
    end
end

function eval_insn(insn::JGE, state::State)
    frame = current_frame(state)
    v = pop!(frame.stack)
    if v >= 0
        state.pc = state.labels[insn.label]
    else
        state.pc += 1
    end
end

# Other instructions just need the frame.
function eval_insn(insn, state::State)
    eval_insn(insn, current_frame(state))
    state.pc += 1
end

function eval_insn(insn::LD, frame::Frame)
    # variables are initialized to 0
    v = get(frame.vars, insn.name, 0)
    push!(frame.stack, v)
end

function eval_insn(insn::ST, frame::Frame)
    v = pop!(frame.stack)
    frame.vars[insn.name] = v
end

function eval_insn(insn::LDC, frame::Frame)
    push!(frame.stack, insn.value)
end

function eval_insn(insn::ADD, frame::Frame)
    y = pop!(frame.stack)
    x = pop!(frame.stack)
    push!(frame.stack, x+y)
end

function eval_insn(insn::SUB, frame::Frame)
    y = pop!(frame.stack)
    x = pop!(frame.stack)
    push!(frame.stack, x-y)
end

function eval_insn(insn::MUL, frame::Frame)
    y = pop!(frame.stack)
    x = pop!(frame.stack)
    push!(frame.stack, x*y)
end

function eval_insn(insn::DIV, frame::Frame)
    y = pop!(frame.stack)
    x = pop!(frame.stack)
    push!(frame.stack, div(x, y))
end

function eval_insn(insn::PRINT, frame::Frame)
    v = pop!(frame.stack)
    println(v)
end

function eval_insn(insn::POP, frame::Frame)
    pop!(frame.stack)
end

function eval_insn(insn::DUP, frame::Frame)
    v = frame.stack[end]
    push!(frame.stack, v)
end

function eval_insn(insn::LABEL, frame::Frame)
end

