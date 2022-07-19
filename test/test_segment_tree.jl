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

#=
function naive_reduce_matrix_mul(x)
    identity_matrix = zeros(UInt64,(3,3))
    identity_matrix[1,1] = identity_matrix[2,2] = identity_matrix[3,3] = 1
    ans = identity_matrix
    for i in x
        ans = ans*i
    end
    return ans
end
=#
import Random.MersenneTwister


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

function test_matmul(a,b)
    ans = zeros(UInt64,(3,3))
    for i in 1:3
        for j in 1:3
            for k in 1:3
                ans[i,j] += a[i,k] * b[k,j]
            end
        end
    end
    return ans
end

@testset "segment_tree" begin
    rng = MersenneTwister(1234) #A strong rng needed.
    @testset "Add" begin
        X1 = Segment_tree(UInt64,100,Base.:+)
        a = zeros(UInt64, 100)
        set_range!(X1, 37,53, 3)
        set_range!(X1, 23,45, 9)
        set_range!(X1, 2,21, 5)
        a[37:53] .= 3
        a[23:45] .= 9
        a[2:21]  .= 5
        @test sum(a[23:99]) == get_range(X1, 23,99)
        @test sum(a[55:87]) == get_range(X1, 55,87)
        @test sum(a[2:3]) == get_range(X1, 2, 3)
        @test sum(a[5:77]) == get_range(X1, 5,77)
    end
    
    @testset "Small_randomized_trial" begin
        #Don't worry about the overflow. This is unsigned integer.
        X1 = Segment_tree(UInt64,15, Base.:+)
        X2 = zeros(UInt64, 15)
        for i in 1:1000
            a = rand(rng,1:15)
            b = rand(rng,a:15)
            c = rand(rng,UInt64)
            set_range!(X1,a,b,c)
            X2[a:b] .= c
            d = rand(rng,1:15)
            e = rand(rng,d:15)
            @test sum(X2[d:e]) == get_range(X1,d,e)
        end
    
    end
    
    @testset "XL_array" begin
        X1 = Segment_tree(UInt64,1000000, Base.:+)
        X2 = zeros(UInt64, 1000000)
        for i in 1:100
            a = rand(rng,1:1000000)
            b = rand(rng,a:1000000)
            c = rand(rng,UInt64)
            set_range!(X1,a,b,c)
            X2[a:b] .= c
            d = rand(rng,1:1000000)
            e = rand(rng,d:1000000)
            @test sum(X2[d:e]) == get_range(X1,d,e)
        end
    end
    
    @testset "Large_randomized_trial" begin

        #Don't worry about the overflow. This is unsigned integer.
        X1 = Segment_tree(UInt64,10000, Base.:+)
        X2 = zeros(UInt64, 10000)
        for i in 1:10000
            a = rand(rng,1:10000)
            b = rand(rng,a:10000)
            c = rand(rng,UInt64)
            set_range!(X1,a,b,c)
            X2[a:b] .= c
            d = rand(rng,1:10000)
            e = rand(rng,d:10000)
            @test sum(X2[d:e]) == get_range(X1,d,e)
        end
    end
    
    @testset "Xor_trial" begin
        X1 = Segment_tree(UInt64,10000, xor)
        X2 = zeros(UInt64, 10000)
        for i in 1:10000
            a = rand(rng,1:10000)
            b = rand(rng,a:10000)
            c = rand(UInt64)
            set_range!(X1,a,b,c)
            X2[a:b] .= c
            d = rand(rng,1:10000)
            e = rand(rng,d:10000)
            @test reduce(xor,X2[d:e]) == get_range(X1,d,e)
        end
    end
    @testset "Vector_add" begin
        X1 = Segment_tree(Array{UInt64,1},1000, +)
        identity_vec = zeros(UInt64,5)
        #Vector of vector may not be the most efficient, but it should work without problem.
        X2 = [identity_vec for i in 1:1000]
        #Viewing without copying should be fine, as we won't mutate the arrays.
        #Static arrays recommended for serious uses of this.
        for i in 1:10000
            a = rand(rng,1:1000)
            b = rand(rng,a:1000)
            c = rand(rng,UInt64,5)
            set_range!(X1,a,b,c)
            for j in a:b
                X2[j] = c
            end
            d = rand(rng,1:1000)
            e = rand(rng,d:1000)
            
            if (reduce(+,X2[d:e]) != identity_vec)
                #println(d," ", e)
                @test reduce(+,X2[d:e]) == get_range(X1,d,e)
            end
            
            #=
            if (naive_reduce_matrix_mul(X2[d:e]) != identity_matrix)
                println(d," ", e)
                @test naive_reduce_matrix_mul(X2[d:e]) == get_range(X1,d,e)
            end
            =#
        end
    end


    @testset "3x3_matrix_multiplication" begin
        #Float/etc should work fine as well. Just don't want to deal with precision issues.
        X1 = Segment_tree(Array{UInt64,2},1000, *)
        identity_matrix = zeros(UInt64,(3,3))
        identity_matrix[1,1] = identity_matrix[2,2] = identity_matrix[3,3] = 1
        #Vector of vector may not be the most efficient, but it should work without problem.
        X2 = [identity_matrix for i in 1:1000]
        #Viewing without copying should be fine, as we won't mutate the arrays.
        #Static arrays recommended for serious uses of this.
        for i in 1:10000
            a = rand(rng,1:1000)
            b = rand(rng,a:1000)
            c = rand(rng,UInt64,(3,3))
            set_range!(X1,a,b,copy(c))
            for j in a:b
                X2[j] = copy(c)
            end
            d = rand(rng,1:1000)
            e = rand(rng,d:1000)
            
            if (reduce(*,X2[d:e]) != identity_matrix)
                #println(d," ", e)
                @test reduce(*,X2[d:e]) == get_range(X1,d,e)
            end
            
            #=
            if (naive_reduce_matrix_mul(X2[d:e]) != identity_matrix)
                println(d," ", e)
                @test naive_reduce_matrix_mul(X2[d:e]) == get_range(X1,d,e)
            end
            =#
        end
    end
    @testset "String_concat" begin
        String_choice = ["A", "B", "C", "D", "E", "AA", "BFFG","ATL", "Moon", "Hey"]
        #The words are random. The acronym's reference are coincidental.
        X1 = Segment_tree(String, 10000, Base.:*)
        X2 = ["" for i in 1:10000]
        for i in 1:10000
            
            a = rand(rng,1:10000)
            b = rand(rng,a:10000)
            c = String_choice[rand(rng,1:10)]
            set_range!(X1, a, b, c)
            X2[a:b] .= c
            d = rand(rng,1:10000)
            e = rand(rng,d:10000)
            @test get_range(X1, d, e) == reduce(*, X2[d:e])
        end
    end
    @testset "Quarternion_test" begin
        test_type = Quarternion{UInt64}
        identity = test_type(1,0,0,0)
        X1 = Segment_tree(test_type, 10000, Base.:*; identity=identity)
        X2 = [identity for i in 1:10000]
        for i in 1:10000
            a = rand(rng,1:10000)
            b = rand(rng,a:10000)
            c = test_type(rand(rng,UInt64,4)...)
            set_range!(X1, a, b, c)
            for j in a:b
                X2[j] = c
            end
            d = rand(rng,1:10000)
            e = rand(rng,d:10000)
            @test get_range(X1, d, e) == reduce(*, X2[d:e])

        end
    end
end