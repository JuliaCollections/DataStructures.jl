# Benchmark on disjoint set forests

using DataStructures

# do 10^6 random unions over 10^6 element set

const n =  2 * (10^6)
const T0 = 10
const T = 10^6

function batch_union!(s::IntDisjointSets, x::Vector{Int}, y::Vector{Int})
    for i = 1 : length(x)
        @inbounds union!(s, x[i], y[i])
    end
end

s = IntDisjointSets(n)

# warming

x0 = rand(1:n, T0)
y0 = rand(1:n, T0)

batch_union!(s, x0, y0)

# measure

x = rand(1:n, T)
y = rand(1:n, T)

@time batch_union!(s, x, y)
