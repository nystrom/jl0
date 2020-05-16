"""
    lower(e::Func)

Lower a function definition. This mainly just lowers the function body.
"""
function lower(func::Func)::FUNC
    insns = Insn[]
    push!(insns, LABEL(func.fname))
    append!(insns, lower(func.body))
    push!(insns, RET())
    FUNC(func.fname, func.params, insns)
end

function lower(s::Struct)::STRUCT
    STRUCT(s.name, s.fields)
end

"""
    lower(e::Exp)

Return a list of stack instructions to evaluate the expression `e`.
For all expressions, the list of instructions should consume values
on the stack and leave a result expression on the stack.

All stack values are integers.
"""
function lower(e)
    @error("lower undefined for $e")
end

function lower(e::LitNothing)::Vector{Insn}
    Insn[NULL()]
end

function lower(e::Lit)::Vector{Insn}
    # Push the constant on the stack. Convert to an integer first.
    Insn[LDC(Int(e.value))]
end

function lower(e::Call)::Vector{Insn}
    # Push the arguments.
    insns = Insn[]
    for s in e.args
        append!(insns, lower(s))
    end
    # Then call.
    push!(insns, CALL(e.fname))
    insns
end

function lower(e::Return)::Vector{Insn}
    insns = Insn[]
    append!(insns, lower(e.exp))
    push!(insns, RET())
    insns
end

function lower(e::New)::Vector{Insn}
    insns = Insn[]
    for x in e.fields
        append!(insns, lower(x))
    end
    push!(insns, NEW(e.name))
    insns
end

function lower(e::GetField)::Vector{Insn}
    insns = Insn[]
    append!(insns, lower(e.target))
    push!(insns, GET(e.field))
    insns
end

function lower(e::SetField)::Vector{Insn}
    insns = Insn[]
    append!(insns, lower(e.target))
    append!(insns, lower(e.value))
    push!(insns, PUT(e.field))
    insns
end

function lower(e::Block)::Vector{Insn}
    # Empty blocks evaluate to 0.
    if isempty(e.exps)
        return Insn[LDC(0)]
    end

    # Non-empty blocks evaluate to the last expression.
    insns = Insn[]
    for (i, s) in enumerate(e.exps)
        append!(insns, lower(s))

        # Pop all but the last result
        if i < length(e.exps)
            push!(insns, POP())
        end
    end
    insns
end

function lower(e::Bin)::Vector{Insn}
    # Evaluate the left operand, then the right, then perform the operation.
    if e.op == :+
        vcat(lower(e.e1), lower(e.e2), Insn[ADD()])
    elseif e.op == :-
        vcat(lower(e.e1), lower(e.e2), Insn[SUB()])
    elseif e.op == :*
        vcat(lower(e.e1), lower(e.e2), Insn[MUL()])
    elseif e.op == :/
        vcat(lower(e.e1), lower(e.e2), Insn[DIV()])

    # For boolean operators, translate to an `if` and lower.
    elseif e.op in [:(==), :(!=), :<, :<=, :>, :>=]
        lower(If(e, Lit(1), Lit(0)))
    elseif e.op == :&
        lower(If(e.e1, e.e2, Lit(0)))
    elseif e.op == :|
        lower(If(e.e1, Lit(1), e.e2))
    else
        @error("unexpected binary expression")
    end
end

function lower(e::Var)::Vector{Insn}
    # Load the variable
    Insn[LD(e.name)]
end

function lower(e::Assign)::Vector{Insn}
    # Dup to leave the RHS on the stack after storing.
    vcat(lower(e.exp), Insn[DUP(), ST(e.name)])
end

function lower(e::Print)::Vector{Insn}
    # Like a block, but print each expression.
    # Leave the last expression on the stack.
    insns = Insn[]
    for (i, s) in enumerate(e.exps)
        append!(insns, lower(s))
        # Dup the last argument so it remains on the stack.
        if i == length(e.exps)
            push!(insns, DUP())
        end
        push!(insns, PRINT())
    end
    insns
end

function lower(e::If)::Vector{Insn}
    t = lower(e.t_part)
    f = lower(e.f_part)

    f_label = gensym("Lfalse")
    j_label = gensym("Ljoin")

    if e.cond isa Bin && (e.cond.op in [:(==), :(!=), :(<), :(>), :(<=), :(>=)])
        # If the condition is a binary comparison, generate a conditional jump.
        # Subtract and compare the result with 0; that is, (l < r) iff (l - r) < 0.
        # The jump instruction is inverted to jump to the false branch.

        l = lower(e.cond.e1)
        r = lower(e.cond.e2)

        sub = SUB()

        if e.cond.op == :(==)
            jump = JNE(f_label)
            sub = CMP()
        elseif e.cond.op == :(!=)
            jump = JEQ(f_label)
            sub = CMP()
        elseif e.cond.op == :(<)
            jump = JGE(f_label)
        elseif e.cond.op == :(>)
            jump = JLE(f_label)
        elseif e.cond.op == :(<=)
            jump = JGT(f_label)
        elseif e.cond.op == :(>=)
            jump = JLT(f_label)
        else
            @error("invalid comparison")
        end

        vcat(l,
             r,
             Insn[sub, jump],
             t,
             Insn[JMP(j_label), LABEL(f_label)],
             f,
             Insn[LABEL(j_label)],
            )
    elseif e.cond isa Lit && !(e.cond.value == 0 || e.cond.value == false)
        # If the condition is true, just evaluate the true branch.
        t
    elseif e.cond isa Lit && (e.cond.value == 0 || e.cond.value == false)
        # If the condition is false, just evaluate the true branch.
        f
    else
        # For all other conditions, evaluate it and jump to the false branch if 0.
        c = lower(e.cond)
        vcat(c,
             Insn[JNE(f_label)],
             t,
             Insn[JMP(j_label), LABEL(f_label)],
             f,
             Insn[LABEL(j_label)],
            )
    end
end

function lower(e::While)::Vector{Insn}
    bot_label = gensym("Lbot")
    top_label = gensym("Ltop")

    # Before the loop body, push 0, then at the beginning of each iteration,
    # increment by 1. The iteration count should be on top of the stack at loop exit.

    if e.cond isa Bin && (e.cond.op in [:(==), :(!=), :(<), :(>), :(<=), :(>=)])
        # If the condition is a binary comparison, generate a conditional jump.
        # Subtract and compare the result with 0; that is, (l < r) iff (l - r) < 0.

        l = lower(e.cond.e1)
        r = lower(e.cond.e2)

        sub = SUB()

        if e.cond.op == :(==)
            jump = JEQ(top_label)
            sub = CMP()
        elseif e.cond.op == :(!=)
            jump = JNE(top_label)
            sub = CMP()
        elseif e.cond.op == :(<)
            jump = JLT(top_label)
        elseif e.cond.op == :(>)
            jump = JGT(top_label)
        elseif e.cond.op == :(<=)
            jump = JLE(top_label)
        elseif e.cond.op == :(>=)
            jump = JGE(top_label)
        else
            @error("invalid comparison")
        end

        vcat(Insn[LDC(0), JMP(bot_label), LABEL(top_label), LDC(1), ADD()],
             lower(e.body),
             Insn[POP(), LABEL(bot_label)],
             l,
             r,
             Insn[sub, jump],
            )
    elseif e.cond isa Lit && !(e.cond.value == false || e.cond.value == 0)
        # while true. There's no need to track the iteration count.
        vcat(Insn[LABEL(top_label)],
             lower(e.body),
             Insn[POP(), JMP(top_label)],
            )
    elseif e.cond isa Lit && (e.cond.value == false || e.cond.value == 0)
        # whlie false. The iteration count is 0.
        Insn[LDC(0)]
    else
        vcat(Insn[LDC(0), JMP(bot_label), LABEL(top_label), LDC(1), ADD()],
             lower(e.body),
             Insn[POP(), LABEL(bot_label)],
             lower(e.cond),
             Insn[JEQ(top_label)],
            )
    end
end
