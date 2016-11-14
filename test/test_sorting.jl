using DataStructures
if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

@testset "DictionarySorting" begin
    forward = OrderedDict(zip('a':'z', 26:-1:1))
    rev = OrderedDict(zip(reverse('a':'z'), 1:26))

    d = copy(rev)
    @test d == rev
    @test sort(d) == forward
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

    unordered = Dict(zip('a':'z', 26:-1:1))
    @test sort(unordered) == forward
    @test sort(unordered; rev=true) == rev
    @test sort(unordered; byvalue=true) == rev
    @test sort(unordered; byvalue=true, rev=true) == forward
end
