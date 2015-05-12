import Base.haskey

type Trie{K,T}
    value::T
    children::Dict{K,Trie{K,T}}
    is_key::Bool

    function Trie()
        self = new()
        self.children = Dict{K,Trie{K,T}}()
        self.is_key = false
        self
    end

    function Trie(ks, vs)
        t = Trie{T}()
        for (k, v) in zip(ks, vs)
            setindex!(t, v, k)
        end
        return t
    end

    function Trie(kv)
        t = Trie{K,T}()
        for (k,v) in kv
            setindex!(t, v, k)
        end
        return t
    end
end

Trie() = Trie{Any,Any}()
Trie{K<:String,V}(ks::AbstractVector{K}, vs::AbstractVector{V}) = Trie{K,V}(ks, vs)
Trie{K<:String,V}(kv::AbstractVector{(K,V)}) = Trie{K,V}(kv)
Trie{K<:String,V}(kv::Associative{K,V}) = Trie{K,V}(kv)
Trie{K<:String}(ks::AbstractVector{K}) = Trie{K,Nothing}(ks, similar(ks, Nothing))

function setindex!{T}(t::Trie{Char,T}, val::T, key::String)
    node = t
    for char in key
        if !haskey(node.children, char)
            node.children[char] = Trie{Char,T}()
        end
        node = node.children[char]
    end
    node.is_key = true
    node.value = val
end

function getindex(t::Trie, key::String)
    node = subtrie(t, key)
    if node != nothing && node.is_key
        return node.value
    end
    throw(KeyError("key not found: $key"))
end

function subtrie{T}(t::Trie{Char,T}, prefix::String)
    node = t
    for char in prefix
        if !haskey(node.children, char)
            return nothing
        else
            node = node.children[char]
        end
    end
    node
end

function haskey(t::Trie, key::String)
    node = subtrie(t, key)
    node != nothing && node.is_key
end

function get(t::Trie, key::String, notfound)
    node = subtrie(t, key)
    if node != nothing && node.is_key
        return node.value
    end
    notfound
end

function keys{T}(t::Trie{Char, T}, prefix::String="", found=String[])
    if t.is_key
        push!(found, prefix)
    end
    for (char,child) in t.children
        keys(child, string(prefix,char), found)
    end
    found
end

function keys_with_prefix(t::Trie, prefix::String)
    st = subtrie(t, prefix)
    st != nothing ? keys(st,prefix) : []
end

# The state of a TrieIterator is a pair (t::Trie, i::Int),
# where t is the Trie which was the output of the previous iteration
# and i is the index of the current character of the string.
# The indexing is potentially confusing;
# see the comments and implementation below for details.
immutable TrieIterator
    t::Trie
    str::String
end

# At the start, there is no previous iteration,
# so the first element of the state is undefined.
# We use a "dummy value" of it.t to keep the type of the state stable.
# The second element is 0
# since the root of the trie corresponds to a length 0 prefix of str.
start(it::TrieIterator) = (it.t, 0)

function next(it::TrieIterator, state)
    t, i = state
    i == 0 && return it.t, (it.t, 1)

    t = t.children[it.str[i]]
    return (t, (t, i + 1))
end

function done(it::TrieIterator, state)
    t, i = state
    i == 0 && return false
    i == length(it.str) + 1 && return true
    return !(it.str[i] in keys(t.children))
end

path(t::Trie, str::String) = TrieIterator(t, str)
