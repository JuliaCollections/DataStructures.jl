# Sort for dicts
import Base: sort, sort!

function sort!(od::OrderedDict; byvalue::Bool=false, args...)
    keylist = collect(keys(od))
    vallist = [od[k] for k in keylist]
    if byvalue
        p = sortperm(vallist; args...)
    else
        p = sortperm(keylist; args...)
    end
    newa1 = Vector{Tuple{keytype(od),Bool}}()
    for (i, k) in enumerate(keylist[p])
        od.d1[k] = (vallist[p[i]], i)
        push!(newa1, (k, true))
    end
    od.a1 = newa1
    return od
end

sort(d::OrderedDict; args...) = sort!(copy(d); args...)
sort(d::Dict; args...) = sort!(OrderedDict(d); args...)
## Uncomment these after #224 is merged
# sort!(d::DefaultOrderedDict; args...) = (sort!(d.d.d; args...); d)
# sort(d::DefaultDict; args...) = DefaultOrderedDict(d.d.default, sort(d.d.d; args...))
# sort(d::DefaultOrderedDict; args...) = DefaultOrderedDict(d.d.default, sort!(copy(d.d.d); args...))
