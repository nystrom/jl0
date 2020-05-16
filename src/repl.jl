function prompt()
    print("JL0> ")
end

function repl()
    println("Welcome to JL0. Enter expressionx and watch them get evaluated! Type `:q` to quit.")
    prompt()

    vars = Dict{Symbol,Int}()
    funcs = Dict{Symbol,FUNC}()

    while !eof(stdin)
        line = readline()

        if line == ":q" || line == ":quit"
            println("Bye!")
            break
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
            funcs[f.fname] = f
        elseif e isa Exp
            insns = lower(e)
            push!(insns, STOP())
            println("lowered $insns")

            result = eval(insns, funcs, vars)

            if result != nothing
                (v, vars) = result
                println(v)
            end
        end

        prompt()
    end
end
