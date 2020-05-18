function prompt()
    print("JL0> ")
end

function eval_lines(lines::AbstractString...)
    eval_lines(State(), [lines...])
end

function eval_lines(state::State, lines::AbstractString...)
    eval_lines(state, [lines...])
end

function eval_lines(lines::Vector{T}) where {T <: AbstractString}
    eval_lines(State(), lines)
end

function eval_lines(state::State, lines::Vector{T}) where {T <: AbstractString}
    result = nothing

    for line in lines
        line = strip(line)

        if line == ""
            continue
        end

        e = parse(line)

        if e == nothing
            result = nothing
        elseif e isa Func
            f = lower(e)
            state.funcs[f.fname] = f
            append_insns!(state, f.body)
            result = nothing
        elseif e isa Struct
            s = lower(e)
            state.structs[s.name] = s
            result = nothing
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
    println("Welcome to JL0. Enter expressions and watch them get evaluated! Type `:q` to quit.")
    prompt()

    state = State()

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

        if line == ":gc"
            gc(state)
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

        v = eval_lines(state, line)

        if v isa INT
            println(v.value)
        elseif v == LOC(0)
            println("nothing")
        elseif v isa LOC
            o = state.heap[v.value]
            println(o)
        end

        prompt()
    end
end
