function prompt()
    print("JL0> ")
end

function eval_lines(lines::String...)
    eval_lines([lines...])
end

function eval_lines(lines::Vector{String})
    result = nothing

    state = State()
 
    # Push a frame for the main function. This is the frame for the top-level expression.
    # We need this frame to keep track of the variables.
    push!(state.frames, Frame(Value[], Dict{Symbol, Value}(), 0))

    for line in lines
        line = strip(line)

        if line == ""
            continue
        end

        e = parse(line)

        if e == nothing
            return nothing
        elseif e isa Func
            f = lower(e)
            state.funcs[f.fname] = f
            append_insns!(state, f.body)
        elseif e isa Struct
            s = lower(e)
            state.structs[s.name] = s
        elseif e isa Exp
            label = gensym()

            insns = Insn[]
            push!(insns, LABEL(label))
            append!(insns, lower(e))
            push!(insns, STOP())

            append_insns!(state, insns)

            # println("lowered $(state.insns)")

            # Clear the stack for the next run.
            current_frame(state).stack = Value[]

            result = eval(label, state)
        end
    end

    return result
end

function repl()
    println("Welcome to JL0. Enter expressionx and watch them get evaluated! Type `:q` to quit.")
    prompt()

    state = State()

    # Push a frame for the main function. This is the frame for the top-level expression.
    # We need this frame to keep track of the variables.
    push!(state.frames, Frame(Value[], Dict{Symbol, Value}(), 0))

    while !eof(stdin)
        line = readline()
        line = strip(line)

        if line == ":q" || line == ":quit"
            println("Bye!")
            break
        end

        if line == ":heap"
            for (i, v) in enumerate(state.heap)
                println("$i -> $v")
            end
            prompt()
            continue
        end

        if line == ":vars"
            for (x, v) in current_frame(state).vars
                println("$x = $v")
            end
            prompt()
            continue
        end

        if line == ":insns"
            for insn in state.insns
                println(insn)
            end
            prompt()
            continue
        end

        if line == ""
            prompt()
            continue
        end

        println("read $line")

        e = parse(line)
        println("parsed $e")

        if e == nothing
            println("syntax error")
        elseif e isa Func
            f = lower(e)
            state.funcs[f.fname] = f
            append_insns!(state, f.body)
        elseif e isa Struct
            s = lower(e)
            state.structs[s.name] = s
        elseif e isa Exp
            label = gensym()

            insns = Insn[]
            push!(insns, LABEL(label))
            append!(insns, lower(e))
            push!(insns, STOP())

            append_insns!(state, insns)

            println("lowered $(state.insns)")

            # Clear the stack for the next run.
            current_frame(state).stack = Value[]

            result = eval(label, state)

            println(result)
        end

        prompt()
    end
end
