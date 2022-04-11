#=
Author: Alice Roselia.
It should be made available as part of the (MIT-licensed) Datastructures.jl package.
Feel free to use or extend this code.
=#







#=
Putting my Quarternion to test.

Quarternion also has associative property, so it should work.

This is NOT a complete Quarternion implementation. It is only used here for testing purpose.
This code belongs to me (it's my early julia codes) but you could've written this code too. 
Just a literal implementation of Quarternion based on its definition, no optimization or other methods. 
=#



struct Quarternion{T<:Real}
    real::T
    i::T
    j::T
    k::T
end

#Base.:+(a::Quarternion, b::Quarternion) = Quarternion(a.real+b.real, a.i+b.i, a.j+b.j, a.k+b.k) Not used in the test.
Base.:*(a::Quarternion, b::Quarternion) =
Quarternion(a.real*b.real - a.i*b.i - a.j*b.j - a.k*b.k,
            a.real*b.i + b.real*a.i + a.j*b.k - a.k*b.j,
            a.real*b.j + b.real*a.j + a.k*b.i - a.i*b.k,
            a.real*b.k + b.real*a.k + a.i*b.j - a.j*b.i,
)

@testset "segment_tree" begin
    @testset "Add" begin
        X1 = segment_tree(100,UInt64,Base.:+)
        a = zeros(UInt64, 100)
        change_range!(X1, 3,37,53)
        change_range!(X1, 9,23,45)
        change_range!(X1, 5,2,21)
        a[37:53] .= 3
        a[23:45] .= 9
        a[2:21]  .= 5
        @test sum(a[23:99]) == get_range(X1, 23,99)
        @test sum(a[55:87]) == get_range(X1, 55,87)
        @test sum(a[2:3]) == get_range(X1, 2, 3)
        @test sum(a[5:77]) == get_range(X1, 5,77)
    end

    @testset "Large_randomized_trial" begin

        #Don't worry about the overflow. This is unsigned integer.
        X1 = segment_tree(10000,UInt64, Base.:+)
        X2 = zeros(UInt64, 10000)
        for i in 1:10000
            a = rand(1:10000)
            b = rand(a:10000)
            c = rand(UInt64)
            change_range!(X1,c,a,b)
            X2[a:b] = c
            d = rand(1:10000)
            e = rand(d:10000)
            @test sum(X2[d:e]) == get_range(X1,d,e)
        end
    end

    @testset "Xor_trial" begin
        X1 = segment_tree(10000,UInt64, xor)
        X2 = zeros(UInt64, 10000)
        for i in 1:10000
            a = rand(1:10000)
            b = rand(a:10000)
            c = rand(UInt64)
            change_range!(X1,c,a,b)
            X2[a:b] = c
            d = rand(1:10000)
            e = rand(d:10000)
            @test reduce(xor,X2[d:e]) == get_range(X1,d,e)
        end
    end
    
    @testset "3x3_matrix_multiplication" begin
        #Float/etc should work fine as well. Just don't want to deal with precision issues.
        X1 = segment_tree(1000,Array{UInt64,2},*)
        identity_matrix = zeros(UInt64,(3,3))
        identity_matrix[1,1] = identity_matrix[2,2] = identity_matrix[3,3] = 1
        #Vector of vector may not be the most efficient, but it should work without problem.
        X2 = [identity_matrix for i in 1:1000]
        #Viewing without copying should be fine, as we won't mutate the arrays.
        #Static arrays recommended for serious uses of this.
        for i in 1:1000
            a = rand(1:1000)
            b = rand(a:1000)
            c = rand(UInt64,(3,3))
            change_range!(X1,c,a,b)
            X2[a:b] = c
            d = rand(1:1000)
            e = rand(d:1000)
            @test reduce(*,X2[d:e]) == get_range(X1,d,e)
        end
    end
end