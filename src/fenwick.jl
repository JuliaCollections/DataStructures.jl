mutable struct fenwick{T}
    BIT::Vector{T}
    n::Integer
end

fenwick{T}() where T = fenwick{T}(0)
fenwick{T}(n::Integer) where T = fenwick{T}(fill(zero(T), n), n)

bit(F::fenwick{T}) where T = F.BIT
size(F::fenwick{T}) where T = F.BIT

function update(F::fenwick{T}, ind::Int, val::T) where T
    i = ind
    N = F.n
    (i in 1:N) || throw(DomainError(i, "$i should be in between 1 and $N"))
    while i <= N
        F.BIT[i] += val
        i += i&(-i)
    end
end

function update(F::fenwick{T}, left::Int, right::Int, val::T) where T
    update(F, left, +val)
    update(F, right, -val)
end

function getsum(F::fenwick{T}, ind::Int) where T
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

