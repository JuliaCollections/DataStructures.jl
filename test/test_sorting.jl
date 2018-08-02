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

        @testset "sort unordered" begin
            unordered = Dict(zip('a':'z', 26:-1:1))
            @test sort(unordered) == forward
            @test sort(unordered; rev=true) == rev
            @test sort(unordered; byvalue=true) == rev
            @test sort(unordered; byvalue=true, rev=true) == forward
        end
    end

    @testset "Bug DataStructures.jl/#394" begin
        @test sort(Dict(k=>string(k) for k in 1:3))[1] == "1"
    end
end
