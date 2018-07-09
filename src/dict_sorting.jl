# Sort for dicts
import Base: sort, sort!

function sort!(d::OrderedDict; byvalue::Bool=false, args...)
    if d.ndel > 0
        rehash!(d)
    end

    if byvalue
        p = sortperm(d.vals; args...)
    else
        p = sortperm(d.keys; args...)
    end
    d.keys = d.keys[p]
    d.vals = d.vals[p]
    rehash!(d)
    return d
end

sort(d::OrderedDict; args...) = sort!(copy(d); args...)
sort(d::Dict; args...) = sort!(OrderedDict(d); args...)
## Uncomment these after #224 is merged
# sort!(d::DefaultOrderedDict; args...) = (sort!(d.d.d; args...); d)
# sort(d::DefaultDict; args...) = DefaultOrderedDict(d.d.default, sort(d.d.d; args...))
# sort(d::DefaultOrderedDict; args...) = DefaultOrderedDict(d.d.default, sort!(copy(d.d.d); args...))
