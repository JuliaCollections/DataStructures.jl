# A counter type

type Indexer
    fmap::Dict{Any, Int32}
    rmap::Dict{Int32, Any}
    inc::Int32
end

## constructors

Indexer() = Indexer(Dict(), Dict(), 1)
Indexer(start::Int32) = Indexer(Dict(), Dict(), start)
function Indexer(collection)
    idx = Indexer()
    for x in collection
        get_index(idx, x)
    end
    return idx
end

## Usage

function get_index(idx::Indexer, t::Any)
    if haskey(idx.fmap, t)
        return get(idx.fmap, t, null)
    else
        result = idx.inc
        idx.fmap[t] = idx.inc
        idx.rmap[idx.inc] = t
        idx.inc = idx.inc + 1
        return result
    end
end

reverse_index(idx::Indexer, i::Int32) = idx.rmap[i]
