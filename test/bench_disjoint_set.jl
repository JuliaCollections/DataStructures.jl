# Benchmark on disjoint set forests

using DataStructures

# do 10^6 random unions over 10^6 element set

n = 10^6
T = 10^6

s = IntDisjointSets(n)
x = rand(1:n, T)
y = rand(1:n, T)

union!(s, 1, 2)  # warming (force compilation)

@time for t = 1 : T
    union!(s, x[t], y[t])
end
