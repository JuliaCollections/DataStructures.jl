mutable struct Trie{K,V}
    value::V
    children::Dict{K,Trie{K,V}}
    is_key::Bool

    function Trie{K,V}() where {K,V}
        self = new{K,V}()
        self.children = Dict{K,Trie{K,V}}()
        self.is_key = false
        return self
    end

    function Trie{K,V}(ks, vs) where {K,V}
        return Trie{K,V}(zip(ks, vs))
    end

    function Trie{K,V}(kv) where {K,V}
        t = Trie{K,V}()
        for (k,v) in kv
            t[k] = v
        end
        return t
    end
end

Trie() = Trie{Any,Any}()
Trie(ks::AbstractVector{K}, vs::AbstractVector{V}) where {K,V} = Trie{eltype(K),V}(ks, vs)
Trie(kv::AbstractVector{Tuple{K,V}}) where {K,V} = Trie{eltype(K),V}(kv)
Trie(kv::AbstractDict{K,V}) where {K,V} = Trie{eltype(K),V}(kv)
Trie(ks::AbstractVector{K}) where {K} = Trie{eltype(K),Nothing}(ks, similar(ks, Nothing))

function Base.setindex!(t::Trie{K,V}, val, key) where {K,V}
    value = convert(V, val) # we don't want to iterate before finding out it fails
    node = t
    for char in key
        node = get!(Trie{K,V}, node.children, char)
    end
    node.is_key = true
    node.value = value
end

function Base.getindex(t::Trie, key)
    node = subtrie(t, key)
    if node != nothing && node.is_key
        return node.value
    end
    throw(KeyError("key not found: $key"))
end

function subtrie(t::Trie, prefix)
    node = t
    for char in prefix
        node = get(node.children, char, nothing)
        isnothing(node) && return nothing
    end
    return node
end

function Base.haskey(t::Trie, key)
    node = subtrie(t, key)
    node != nothing && node.is_key
end

function Base.get(t::Trie, key, notfound)
    node = subtrie(t, key)
    if node != nothing && node.is_key
        return node.value
    end
    return notfound
end

_concat(prefix::String, char::Char) = string(prefix, char)
_concat(prefix::Vector{T}, char::T) where {T} = vcat(prefix, char)

_empty_prefix(::Trie{Char,V}) where {V} = ""
_empty_prefix(::Trie{K,V}) where {K,V} = K[]

function Base.keys(t::Trie{K,V},
                   prefix=_empty_prefix(t),
                   found=Vector{typeof(prefix)}()) where {K,V}
    if t.is_key
        push!(found, prefix)
    end
    for (char,child) in t.children
        keys(child, _concat(prefix, char), found)
    end
    return found
end

function keys_with_prefix(t::Trie, prefix)
    st = subtrie(t, prefix)
    st != nothing ? keys(st,prefix) : []
end

# The state of a TrieIterator is a pair (t::Trie, i::Int),
# where t is the Trie which was the output of the previous iteration
# and i is the index of the current character of the string.
# The indexing is potentially confusing;
# see the comments and implementation below for details.
struct TrieIterator
    t::Trie
    str
end

# At the start, there is no previous iteration,
# so the first element of the state is undefined.
# We use a "dummy value" of it.t to keep the type of the state stable.
# The second element is 0
# since the root of the trie corresponds to a length 0 prefix of str.
function Base.iterate(it::TrieIterator, (t, i) = (it.t, 0))
    if i == 0
        return it.t, (it.t, firstindex(it.str))
    elseif i > lastindex(it.str) || !(it.str[i] in keys(t.children))
        return nothing
    else
        t = t.children[it.str[i]]
        return (t, (t, nextind(it.str, i)))
    end
end

partial_path(t::Trie, str) = TrieIterator(t, str)
Base.IteratorSize(::Type{TrieIterator}) = Base.SizeUnknown()

"""
    find_prefixes(t::Trie, str)

Find all keys from the `Trie` that are prefix of the given string

# Examples
```julia-repl
julia> t = Trie(["A", "ABC", "ABCD", "BCE"])

julia> find_prefixes(t, "ABCDE")
3-element Vector{AbstractString}:
 "A"
 "ABC"
 "ABCD"

julia> t′ = Trie([1:1, 1:3, 1:4, 2:4]);

julia> find_prefixes(t′, 1:5)
3-element Vector{UnitRange{Int64}}:
 1:1
 1:3
 1:4

julia> find_prefixes(t′, [1,2,3,4,5])
3-element Vector{Vector{Int64}}:
 [1]
 [1, 2, 3]
 [1, 2, 3, 4]
```
"""
function find_prefixes(t::Trie, str::T) where {T}
    prefixes = T[]
    it = partial_path(t, str)
    idx = 0
    for t in it
        if t.is_key
            push!(prefixes, str[firstindex(str):idx])
        end
        idx = nextind(str, idx)
    end
    return prefixes
end
