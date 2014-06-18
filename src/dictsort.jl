# Sorting

module DictSort

using Base: Sort

import Base: sort!, sort, issorted
import DataStructures: OrderedDict, HashDict, _compact_order, _update_order, Ordered, Unordered

export sort, sort!, issorted

function sort!{K,V}(h::HashDict{K,V,Ordered}; byvalue::Bool=false, args...)
    _compact_order(h)
    if byvalue
        p = sortperm_byval(h; args...)
    else
        p = sortperm(h.keys[h.order]; args...)
    end
    h.order = h.order[p]
    _update_order(h, 1, length(h))
    h
end

sortperm_byval{K,V}(h::HashDict{K,V,Ordered}; alg::Algorithm=DEFAULT_STABLE, args...) =
    sortperm(h.vals[h.order]; alg=alg, args...)

function sort{K,V}(h::Union(Dict{K,V},HashDict{K,V}); byvalue::Bool=false, args...)
    d = OrderedDict{K,V}()
    sizehint(d, length(h.slots))
    keyorder = byvalue ? sortkeys_byval(h, args...) : sort(collect(keys(h)), args...)
    for k in keyorder
        d[k] = h[k]
    end
    d
end

sortkeys_byval(h::Union(Dict,HashDict); by::Function=identity, alg::Algorithm=DEFAULT_STABLE, args...) = 
    sort(collect(keys(h)), by=k->by(h[k]), alg=alg, args...)

function issorted{K,V}(h::HashDict{K,V,Ordered}; byvalue=false, args...)
    _compact_order(h)
    if byvalue
        return issorted(h.vals[h.order]; args...)
    else
        return issorted(h.keys[h.order]; args...)
    end
end

issorted(h::Union(Dict,HashDict)) = false

function issorted(h::OrderedDict; byvalue::Bool=false, by::Function=identity, args...)
    if byvalue
        by = k->by(k)
    end
    issorted(collect(keys(h)), by=by, args...)
end

end # module DictSort
