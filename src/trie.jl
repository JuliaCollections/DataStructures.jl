type Trie{T}
    value::T
    children::Dict{Char,Trie{T}}
    is_key::Bool

    function Trie()
        self = new()
        self.children = (Char=>Trie{T})[]
        self.is_key = false
        self
    end
end

Trie() = Trie{Any}()

function setindex!{T}(t::Trie{T}, val::T, key::String)
    node = t
    for char in key
        if !haskey(node.children, char)
            node.children[char] = Trie{T}()
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

function subtrie(t::Trie, prefix::String)
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

function keys(t::Trie, prefix::String="", found=String[])
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

