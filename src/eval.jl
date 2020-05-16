function eval(label::Symbol, state::State; debug=false)::Value
    state.pc = state.labels[label]

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

    return frame.stack[end]
end

function eval_insn(insn::CALL, state::State)
    caller_frame = current_frame(state)

    func = state.funcs[insn.fname]
    args = Dict{Symbol, Value}()

    # pop the arugments
    for x in func.params
        v = pop!(caller_frame.stack)
        args[x] = v
    end

    # push a new stack frame
    push!(state.frames, Frame(Value[], args, state.pc+1))

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

function eval_insn(insn::NEW, state::State)
    frame = current_frame(state)
    s = state.structs[insn.structname]

    # allocate a new object and add it to the heap
    h = length(state.heap) + 1
    o = Object(Dict{Symbol, Value}())
    push!(state.heap, o)

    # pop and store the fields in the struct
    for x in reverse(s.fields)
        v = pop!(frame.stack)
        o[x] = v
    end

    # push the new object's address
    push!(frame.stack, LOC(h))
    state.pc += 1
end

function eval_insn(insn::GET, state::State)
    frame = current_frame(state)
    h = pop!(frame.stack)
    o = state.heap[h.value]
    push!(frame.stack, o.fields[insn.field])
    state.pc += 1
end

function eval_insn(insn::PUT, state::State)
    frame = current_frame(state)
    v = pop!(frame.stack)
    h = pop!(frame.stack)
    o = state.heap[h.value]
    o.fields[insn.field] = v
    push!(frame.stack, v)
    state.pc += 1
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
    push!(frame.stack, INT(insn.value))
end

function eval_insn(insn::ADD, frame::Frame)
    y = pop!(frame.stack)
    x = pop!(frame.stack)
    push!(frame.stack, INT(x.value+y.value))
end

function eval_insn(insn::SUB, frame::Frame)
    y = pop!(frame.stack)
    x = pop!(frame.stack)
    push!(frame.stack, INT(x.value-y.value))
end

function eval_insn(insn::MUL, frame::Frame)
    y = pop!(frame.stack)
    x = pop!(frame.stack)
    push!(frame.stack, INT(x.value*y.value))
end

function eval_insn(insn::DIV, frame::Frame)
    y = pop!(frame.stack)
    x = pop!(frame.stack)
    push!(frame.stack, INT(div(x.value, y.value)))
end

function eval_insn(insn::PRINT, frame::Frame)
    v = pop!(frame.stack)
    if v isa INT
        println(v.value)
    elseif v isa LOC
        o = state.heap[v.value]
        println(o)
    end
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

