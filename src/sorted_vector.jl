"""
A `SortedVector` behaves like a standard Julia `Vector`, except that its elements are stored in sorted order, with an optional function `by` that determines the sorting order in the same way as `Base.searchsorted`.
"""
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
