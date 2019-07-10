@testset "LinkedList" begin

    @testset "basic tests" begin
        l = list(2, 3)
        @test length(l) == 2
        @test eltype(l) == Int
        @test eltype(typeof(l)) == Int
    end

    @testset "l0" begin
        l0 = nil(Char)
        @test length(l0) == 0
        @test l0 == nil(Char)
        @test l0 == nil()
        @test sprint(show,l0) == "nil(Char)"
    end

    @testset "l1" begin
        l1 = nil()
        @test length(l1) == 0
        @test l1 == nil()
        @test l1 == nil(Int)
        @test sprint(show,l1) == "nil()"
        @test typeof(list()) === typeof(l1)
        @test copy(l1) == l1
        @test map((x) -> x*2,l1) == l1
    end

    @testset "l2" begin
        l1 = nil()
        l2 = cons(1, l1)
        @test length(l2) == 1
        @test head(l2) == 1
        @test l2 == cons(1, l1)
        @test l2 == list(1)
        @test sprint(show,l2) == "list(1)"
        @test cat(l2) == l2
    end

    @testset "l3" begin
        l3 = list(2, 3)
        @test isa(l3, Cons{Int})
        @test length(l3) == 2
        @test head(l3) == 2
        @test head(tail(l3)) == 3
        @test l3 == list(2,3)
        @test collect(l3) == [2; 3]
        @test collect(copy(l3)) == [2; 3]
        @test sprint(show,l3) == "list(2, 3)"
    end

    @testset "l4" begin
        l1 = nil()
        l2 = cons(1, l1)
        l3 = list(2, 3)
        l4 = cat(l1, l2, l3)
        @test length(l4) == 3
        @test l4 == list(1, 2, 3)
        @test collect(l4) == [1; 2; 3]
        @test collect(copy(l4)) == [1; 2; 3]
        @test sprint(show,l4) == "list(1, 2, 3)"
    end

    @testset "l5" begin
        l4 = list(1, 2, 3)
        l5 = map((x) -> x*2, l4)
        @test isa(l5, Cons{Int})
        @test collect(l5) == [2; 4; 6]
    end

    @testset "l5b" begin
        l5 = list(2, 4, 6)
        l5b = map((x) -> "$x", l5)
        @test isa(l5b, Cons{String})
        @test collect(l5b) == ["2"; "4"; "6"]
    end

    @testset "l5" begin
        l5 = list(2, 4, 6)
        l6 = filter((x) -> x < 6, l5)
        @test length(l6) == 2
        @test l6.head == 2
        @test l6.tail.head == 4
        @test collect(l6) == [2, 4]
    end

    @testset "l7" begin
        l6 = list(2, 4)
        l7 = reverse(l6)
        @test length(l7) == 2
        @test l7.head == 4
        @test l7.tail.head == 2
    end

    @testset "l8" begin
        l5b = list("2", "4", "6")
        l6 = list(2, 4)
        l8 = cat(l5b, l6)
        @test collect(l8) == ["2"; "4"; "6"; 2; 4]
    end

    @testset "l9" begin
        l9 = cat(list(1, 2), list(3.0, 4.0))
        @test isa(l9, Cons{Real})
        @test collect(l9) == [1; 2; 3.0; 4.0]
    end

    @testset "l10" begin
        l10 = list(2, 4, 5.6, 10.5)
        @test collect(l10) == [2; 4; 5.6; 10.5]
    end

    @testset "test identity map" begin
        ex = :(a+b+2 * 2 + foo(2))
        l11 = list(ex.args...)
        @test collect(map(x->x, l11)) == collect(l11)
    end

end # @testset LinkedList
