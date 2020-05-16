using JL0
using Test: @testset, @test

@testset "Parser" begin
    @test JL0.parse("x") == JL0.Var(:x)

    @test JL0.parse("1") == JL0.Lit(1)

    @test JL0.parse("1+2") == JL0.Bin(:+, JL0.Lit(1), JL0.Lit(2))

    @test JL0.parse("1 < 2 ? 3 : 4") == JL0.If(JL0.Bin(:<, JL0.Lit(1), JL0.Lit(2)),
                                               JL0.Lit(3),
                                               JL0.Lit(4))

    @test JL0.parse("if 1 < 2 ; 3 ; else 4; end") == JL0.If(JL0.Bin(:<, JL0.Lit(1), JL0.Lit(2)),
                                                            JL0.Lit(3),
                                                            JL0.Lit(4))

    @test JL0.parse("while x < 10; print(x); end") ==
        JL0.While(JL0.Bin(:<, JL0.Var(:x), JL0.Lit(10)),
                  JL0.Print(JL0.Exp[JL0.Var(:x)]))

end
