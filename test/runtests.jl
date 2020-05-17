using JL0
using Test: @testset, @test, @test_broken

@testset "Parser" begin
    @test JL0.parse("x") == JL0.Var(:x)

    @test JL0.parse("1") == JL0.Lit(1)

    @test JL0.parse("nothing") == JL0.LitNothing()

    @test JL0.parse("1+2") == JL0.Bin(:+, JL0.Lit(1), JL0.Lit(2))

    @test JL0.parse("1+2*3") ==
        JL0.Bin(:+, JL0.Lit(1), JL0.Bin(:*, JL0.Lit(2), JL0.Lit(3)))

    @test JL0.parse("1*2+3") ==
        JL0.Bin(:+, JL0.Bin(:*, JL0.Lit(1), JL0.Lit(2)), JL0.Lit(3))

    @test JL0.parse("1+2+3") ==
        JL0.Bin(:+,
                JL0.Bin(:+, JL0.Lit(1), JL0.Lit(2)),
                JL0.Lit(3))

    @test JL0.parse("true") == JL0.Lit(1)
    @test JL0.parse("false") == JL0.Lit(0)

    @test JL0.parse("false && false") == JL0.If(JL0.Lit(0), JL0.Lit(0), JL0.Lit(0))
    @test JL0.parse("false && true") == JL0.If(JL0.Lit(0), JL0.Lit(1), JL0.Lit(0))
    @test JL0.parse("true && false") == JL0.If(JL0.Lit(1), JL0.Lit(0), JL0.Lit(0))
    @test JL0.parse("true && true") == JL0.If(JL0.Lit(1), JL0.Lit(1), JL0.Lit(0))

    @test JL0.parse("false || false") == JL0.If(JL0.Lit(0), JL0.Lit(1), JL0.Lit(0))
    @test JL0.parse("false || true") == JL0.If(JL0.Lit(0), JL0.Lit(1), JL0.Lit(1))
    @test JL0.parse("true || false") == JL0.If(JL0.Lit(1), JL0.Lit(1), JL0.Lit(0))
    @test JL0.parse("true || true") == JL0.If(JL0.Lit(1), JL0.Lit(1), JL0.Lit(1))

    @test JL0.parse("1 < 2 ? 3 : 4") == JL0.If(JL0.Bin(:<, JL0.Lit(1), JL0.Lit(2)),
                                               JL0.Lit(3),
                                               JL0.Lit(4))

    @test JL0.parse("if 1 < 2 ; 3 ; else 4; end") == JL0.If(JL0.Bin(:<, JL0.Lit(1), JL0.Lit(2)),
                                                            JL0.Lit(3),
                                                            JL0.Lit(4))

    @test JL0.parse("while x < 10; print(x); end") ==
        JL0.While(JL0.Bin(:<, JL0.Var(:x), JL0.Lit(10)),
                  JL0.Print(JL0.Exp[JL0.Var(:x)]))

    @test JL0.parse("x.f = y") == JL0.SetField(JL0.Var(:x), :f, JL0.Var(:y))

    @test JL0.parse("x.f") == JL0.GetField(JL0.Var(:x), :f)

    @test JL0.parse("x.f") == JL0.GetField(JL0.Var(:x), :f)

    @test JL0.parse("f(1)") == JL0.Call(:f, JL0.Exp[JL0.Lit(1)])
    @test JL0.parse("F(1,x)") == JL0.New(:F, JL0.Exp[JL0.Lit(1), JL0.Var(:x)])

    @test JL0.parse("function f(x) x+1 end") == JL0.Func(:f, [:x], JL0.Bin(:+, JL0.Var(:x), JL0.Lit(1)))
    @test JL0.parse("function f(x,y) x+y end") == JL0.Func(:f, [:x, :y], JL0.Bin(:+, JL0.Var(:x), JL0.Var(:y)))

    @test JL0.parse("struct F end") == JL0.Struct(:F, [])
    @test JL0.parse("struct F x end") == JL0.Struct(:F, [:x])
    @test JL0.parse("struct F x ; y end") == JL0.Struct(:F, [:x, :y])
end

@testset "Lowering" begin
    begin
        local e = JL0.parse("1")
        @test JL0.lower(e) == JL0.Insn[JL0.LDC(1)]
    end

    begin
        local e = JL0.parse("1+2")
        @test JL0.lower(e) == JL0.Insn[JL0.LDC(1), JL0.LDC(2), JL0.ADD()]
    end

    begin
        local e = JL0.parse("x")
        @test JL0.lower(e) == JL0.Insn[JL0.LD(:x)]
    end

    begin
        local e = JL0.parse("x = 2")
        @test JL0.lower(e) == JL0.Insn[JL0.LDC(2), JL0.DUP(), JL0.ST(:x)]
    end

    begin
        local e = JL0.parse("f(1)")
        @test JL0.lower(e) == JL0.Insn[JL0.LDC(1), JL0.CALL(:f)]
    end

    begin
        local e = JL0.parse("F(x)")
        @test JL0.lower(e) == JL0.Insn[JL0.LD(:x), JL0.NEW(:F)]
    end

    begin
        local e = JL0.parse("return x")
        @test JL0.lower(e) == JL0.Insn[JL0.LD(:x), JL0.RET()]
    end

    begin
        local e = JL0.parse("x < y ? x : y")
        @test JL0.lower(e) == JL0.Insn[JL0.LD(:x), JL0.LD(:y), JL0.SUB(),
                                       JL0.JGE(Symbol("##Lfalse#253")),
                                       JL0.LD(:x),
                                       JL0.JMP(Symbol("##Ljoin#254")),
                                       JL0.LABEL(Symbol("##Lfalse#253")),
                                       JL0.LD(:y),
                                       JL0.LABEL(Symbol("##Ljoin#254"))]
    end

    begin
        local e = JL0.parse("while x < y ; x = x + 1; end")
        @test JL0.lower(e) == JL0.Insn[JL0.LDC(0),
                                       JL0.JMP(Symbol("##Lbot#255")),
                                       JL0.LABEL(Symbol("##Ltop#256")),
                                       JL0.LDC(1), JL0.ADD(),
                                       JL0.LD(:x), JL0.LDC(1), JL0.ADD(), JL0.DUP(), JL0.ST(:x),
                                       JL0.POP(),
                                       JL0.LABEL(Symbol("##Lbot#255")),
                                       JL0.LD(:x), JL0.LD(:y), JL0.SUB(),
                                       JL0.JLT(Symbol("##Ltop#256"))]
    end
end

@testset "Eval" begin
    # For technical reasons (i.e., I need to update the REPL code),
    # function and struct definitions have to be added
    # in a separate line than expressions that use them.
    @test JL0.eval_lines("1") == JL0.INT(1)
    @test JL0.eval_lines("1", "2") == JL0.INT(2)
    @test JL0.eval_lines("1+2") == JL0.INT(3)
    @test JL0.eval_lines("x=1", "x+2") == JL0.INT(3)
    @test JL0.eval_lines("""
                         x = 1
                         x + 2
                         """) == JL0.INT(3)
    @test JL0.eval_lines("""
                         x = 0
                         while x < 10
                             x = x + 1
                         end
                         x
                         """) == JL0.INT(10)
    @test JL0.eval_lines("function f(x) x+1 end", "f(9)") == JL0.INT(10)
    @test JL0.eval_lines("function fib(n) n <= 1 ? 1 : fib(n-1) + fib(n-2) end", "fib(10)") == JL0.INT(89)
    @test JL0.eval_lines("struct Foo x end", "Foo(9).x") == JL0.INT(9)
    @test JL0.eval_lines("struct Foo x; y; z; end", "Foo(1,2,3).x") == JL0.INT(1)
    @test JL0.eval_lines("struct Foo x; y; z; end", "Foo(1,2,3).y") == JL0.INT(2)
    @test JL0.eval_lines("struct Foo x; y; z; end", "Foo(1,2,3).z") == JL0.INT(3)
    @test JL0.eval_lines("struct Cons head; tail end",
                         """
                         function sum(xs)
                             if xs == nothing
                                 return 0
                             else
                                 return xs.head + sum(xs.tail)
                             end
                         end
                         """,
                         """
                         xs = Cons(1, Cons(2, Cons(3, nothing)))
                         sum(xs)
                         """) == JL0.INT(6)
end

@testset "GC" begin
    begin
        state = JL0.State()
        @test JL0.count_allocated_objects(state) == 0

        JL0.eval_lines(state, "struct Foo x end")

        @test JL0.count_allocated_objects(state) == 0

        JL0.eval_lines(state, "x = Foo(1)")
        @test JL0.count_allocated_objects(state) == 1

        JL0.eval_lines(state, "y = Foo(2)")
        @test JL0.count_allocated_objects(state) == 2

        JL0.gc(state)
        @test JL0.count_allocated_objects(state) == 2

        JL0.eval_lines(state, "y = nothing")

        JL0.gc(state)
        @test JL0.count_allocated_objects(state) == 1

        JL0.eval_lines(state, "x = nothing")

        JL0.gc(state)
        @test JL0.count_allocated_objects(state) == 0
    end
end
