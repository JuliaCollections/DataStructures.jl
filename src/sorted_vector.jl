immutable SortedVector{T, F<:Function}
    data::Vector{T}
    by::F

    function SortedVector(data::Vector{T}, by::F)
        new(sort(data), by)
    end
end


SortedVector{T,F}(data::Vector{T}, by::F) = SortedVector{T,F}(data, by)
SortedVector{T}(data::Vector{T}) = SortedVector{T,typeof(identity)}(data, identity)

function show(io::IO, v::SortedVector)
    print(io, "SortedVector($(v.data))")
end



getindex(v::SortedVector, i::Int) = v.data[i]
length(v::SortedVector) = length(v.data)


function insert!{T}(v::SortedVector{T}, i::Int, x::T)
    push!(v.data, i, x)
    return v
end

function push!{T}(v::SortedVector{T}, x::T)
    i = searchsortedfirst(v.data, x, by=v.by)
    insert!(v.data, i, x)
    return v
end

isempty(v::SortedVector) = isempty(v.data)

pop!(v::SortedVector) = pop!(v.data)

shift!(v::SortedVector) = shift!(v.data)

function deleteat!(v::SortedVector, i::Int)
    deleteat!(v.data, i)
    return v
end

function resize!(v::SortedVector, n::Int)
    resize!(v.data, n)
    return v
end


## Use searchsortedfirst instead
"""
Do binary search for item `x` in *sorted* vector `v`.
Returns the lower bound for the position of `x` in `v`.
"""
function binary_search(v::SortedVector, x)

    by = v.by

    a, b = 1, length(v)

    if by(x) < by(v[a])
        return 1

    elseif by(x) > by(v[b])
        return b + 1
    end

    m = (a + b) ÷ 2  # mid-point

    while abs(a - b) > 1

        # @show a, b, v[a], v[b]

        if by(v[m]) == by(x)
            return m
        end

        if by(x) < by(v[m])
            b = m
        else
            a = m
        end

        m = (a + b) ÷ 2  # mid-point

    end

    # @show a, b, v[a], v[b]

    if by(v[a]) == by(x)
        return a
    end

    if by(v[b]) == by(x)
        return b
    end

    return b  # a is a lower_bound; insert in position b
end
