@testset "DictionarySorting" begin
    @testset "Core Functionality" begin
        forward = OrderedDict(zip('a':'z', 26:-1:1))
        rev = OrderedDict(zip(reverse('a':'z'), 1:26))

        @testset "sort" begin
            d = copy(rev)
            @test d == rev
            @test sort(d) == forward
        end

        @testset "sort!" begin
            d = copy(rev)
            sort!(d)
            @test d == forward
            @test sort(d; rev=true) == rev

            sort!(d; rev=true)
            @test d == rev
            @test sort(d; byvalue=true) == rev
            @test sort(d; byvalue=true, rev=true) == forward

            sort!(d; byvalue=true, rev=true)
            @test d == forward
            @test sort(d; byvalue=true) == rev
            @test sort(d; byvalue=true, rev=true) == forward

            sort!(d; byvalue=true)
            @test d == rev
        end

    end

    @testset "Bug DataStructures.jl/#394" begin
        @test sort(OrderedDict(k=>string(k) for k in 1:3))[1] == "1"
    end
end
