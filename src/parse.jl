function parse(x::AbstractString)::Union{Exp, Func, Struct, Nothing}
    try
        expr = Base.parse_input_line(x)
        if expr isa Expr || expr isa Symbol
            return parse(expr)
        else
            return nothing
        end
    catch ex
        @error("parse error")
        return nothing
    end
end

function parse(x::Symbol)::Union{Exp, Nothing}
    if x == :true
        return Lit(1)
    elseif x == :false
        return Lit(0)
    elseif x == :nothing
        return LitNothing()
    else
        return Var(x)
    end
end

function parse(x::Int)::Union{Exp, Nothing}
    return Lit(x)
end

function parse(x::Bool)::Union{Exp, Nothing}
    return Lit(x)
end

function parse(e)
    @error("syntax error: unexpected expression $e")
    return nothing
end

function parse(e::Expr)::Union{Exp, Func, Struct, Nothing}
    if e.head == :toplevel
        args = filter(x -> !(x isa LineNumberNode), e.args)
        if length(args) == 1
            return parse(args[1])
        else
            return Block(map(parse, args))
        end
    elseif e.head == :struct
        dict = MacroTools.splitstructdef(e)
        fieldnames = map(x -> x[1], dict[:fields])
        return Struct(dict[:name], fieldnames)
    elseif e.head == :function
        dict = MacroTools.splitdef(e)
        argnames = map(x -> x[1], map(MacroTools.splitarg, dict[:args]))
        return Func(dict[:name], argnames, parse(dict[:body]))
    elseif e.head == :call
        if length(e.args) > 2 && e.args[1] in [:+, :-, :*, :/, :<, :<=, :>, :>=, :(==), :(!=), :&, :|]
            return foldl((x, y) -> Bin(e.args[1], x, y), map(parse, e.args[3:end]); init=parse(e.args[2]))
        elseif length(e.args) >= 1 && e.args[1] == :print
            return Print(map(parse, e.args[2:end]))
        elseif length(e.args) == 2 && e.args[1] == :!
            return If(parse(e.args[2]), Lit(false), Lit(true))
        elseif length(e.args) == 2 && e.args[1] == :-
            return Bin(:-, Lit(0), e.args[2])
        elseif e.args[1] isa Symbol && isuppercase(string(e.args[1])[1])
            return New(e.args[1], map(parse, e.args[2:end]))
        elseif e.args[1] isa Symbol
            return Call(e.args[1], map(parse, e.args[2:end]))
        else
            @error("syntax error: unexpected expression $e")
        end
    elseif e.head == :&& && length(e.args) >= 1
        return foldl((x, y) -> If(x, y, Lit(false)), map(parse, e.args[2:end]); init=parse(e.args[1]))
    elseif e.head == :|| && length(e.args) >= 1
        return foldl((x, y) -> If(x, Lit(true), y), map(parse, e.args[2:end]); init=parse(e.args[1]))
    elseif e.head == :if
        if length(e.args) == 3
            return If(parse(e.args[1]), parse(e.args[2]), parse(e.args[3]))
        elseif length(e.args) == 2
            return If(parse(e.args[1]), parse(e.args[2]), Block(Exp[]))
        end
    elseif e.head == :while
        return While(parse(e.args[1]), parse(e.args[2]))
    elseif e.head == :block
        args = filter(x -> !(x isa LineNumberNode), e.args)
        if length(args) == 1
            return parse(args[1])
        else
            return Block(map(parse, args))
        end
    elseif e.head == :(=)
        left = parse(e.args[1])
        right = parse(e.args[2])
        if left isa Var
            return Assign(left.name, right)
        elseif left isa GetField
            return SetField(left.target, left.field, right)
        else
            @error("syntax: unexpected expression $e")
        end
    elseif e.head == :. && e.args[2] isa QuoteNode && e.args[2].value isa Symbol
        return GetField(parse(e.args[1]), e.args[2].value)
    elseif e.head == :return && length(e.args) == 1
        return Return(parse(e.args[1]))
    else
        @error("syntax: unexpected expression $e")
    end
end
