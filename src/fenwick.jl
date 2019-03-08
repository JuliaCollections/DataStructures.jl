mutable struct FenwickTree{T}
    BIT::Vector{T}
    n::Integer
end

FenwickTree{T}() where T = FenwickTree{T}(0)
FenwickTree{T}(n::Integer) where T = FenwickTree{T}(fill(zero(T), n), n)

bit(F::FenwickTree{T}) where T = F.BIT
size(F::FenwickTree{T}) where T = F.n

function update(F::FenwickTree{T}, ind::Int, val::T) where T
    i = ind
    N = F.n
    (i in 1:N) || throw(DomainError(i, "$i should be in between 1 and $N"))
    while i <= N
        F.BIT[i] += val
        i += i&(-i)
    end
end

function update(F::FenwickTree{T}, left::Int, right::Int, val::T) where T
    update(F, left, +val)
    update(F, right, -val)
end

function getsum(F::FenwickTree{T}, ind::Int) where T
    sum = zero(T)
    i = ind
    N = F.n
    (i in 1:N) || throw(DomainError(i, "$i should be in between 1 and $N"))
    while i > 0 
        sum += F.BIT[i]
        i -= i&(-i)
    end
    sum
end
