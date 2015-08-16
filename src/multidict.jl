#  multi-value dictionary (multidict)

import Base: haskey, get, get!, getkey, delete!, pop!, empty!,
             insert!, getindex, length, isempty, start,
             next, done, keys, values, copy, similar,  push!,
             count, size, eltype, ==

immutable MultiDict{K,V}
    d::Dict{K,Vector{V}}

    MultiDict() = new(Dict{K,Vector{V}}())
    MultiDict(kvs) = new(Dict{K,Vector{V}}(kvs))
    if VERSION >= v"0.4.0-dev+980"
        MultiDict(ps::Pair{K,Vector{V}}...) = new(Dict{K,Vector{V}}(ps...))
    end
end

MultiDict() = MultiDict{Any,Any}()
MultiDict(kv::@compat Tuple{}) = MultiDict()
MultiDict(kvs) = multi_dict_with_eltype(kvs, eltype(kvs))

multi_dict_with_eltype{K,V}(kvs, ::Type{@compat Tuple{K,Vector{V}}}) = MultiDict{K,V}(kvs)
function multi_dict_with_eltype{K,V}(kvs, ::Type{@compat Tuple{K,V}})
    md = MultiDict{K,V}()
    for (k,v) in kvs
        insert!(md, k, v)
    end
    return md
end
multi_dict_with_eltype(kvs, t) = MultiDict{Any,Any}(kvs)

if VERSION >= v"0.4.0-dev+980"
    MultiDict{K,V<:AbstractArray}(ps::Pair{K,V}...) = MultiDict{K, eltype(V)}(ps)
    MultiDict{K,V}(kv::AbstractArray{Pair{K,V}})  = MultiDict(kv...)
    function  MultiDict{K,V}(ps::Pair{K,V}...)
        md = MultiDict{K,V}()
        for (k,v) in ps
            insert!(md, k, v)
        end
        return md
    end
end

## Functions

## Most functions are simply delegated to the wrapped Dict

@delegate MultiDict.d [ haskey, get, get!, getkey,
                        getindex, length, isempty, eltype,
                        start, next, done, keys, values]

sizehint(d::MultiDict, sz::Integer) = (sizehint(d.d, sz); d)
copy(d::MultiDict) = MultiDict(d)
similar{K,V}(d::MultiDict{K,V}) = MultiDict{K,V}()
==(d1::MultiDict, d2::MultiDict) = d1.d == d2.d
delete!(d::MultiDict, key) = (delete!(d.d, key); d)
empty!(d::MultiDict) = (empty!(d.d); d)

function insert!{K,V}(d::MultiDict{K,V}, k, v)
    if !haskey(d.d, k)
        d.d[k] = isa(v, AbstractArray) ? eltype(v)[] : V[]
    end
    if isa(v, AbstractArray)
        append!(d.d[k], v)
    else
        push!(d.d[k], v)
    end
    return d
end

function in{K,V}(pr::(@compat Tuple{Any,Any}), d::MultiDict{K,V})
    k = convert(K, pr[1])
    v = get(d,k,Base.secret_table_token)
    !is(v, Base.secret_table_token) && (isa(pr[2], AbstractArray) ? v == pr[2] : pr[2] in v)
end

function pop!(d::MultiDict, key, default)
    vs = get(d, key, Base.secret_table_token)
    if is(vs, Base.secret_table_token)
        if !is(default, Base.secret_table_token)
            return default
        else
            throw(KeyError(key))
        end
    end
    v = pop!(vs)
    (length(vs) == 0) && delete!(d, key)
    return v
end
pop!(d::MultiDict, key) = pop!(d, key, Base.secret_table_token)

if VERSION >= v"0.4.0-dev+980"
    push!(d::MultiDict, kv::Pair) = insert!(d, kv[1], kv[2])
    #push!(d::MultiDict, kv::Pair, kv2::Pair) = (push!(d.d, kv, kv2); d)
    #push!(d::MultiDict, kv::Pair, kv2::Pair, kv3::Pair...) = (push!(d.d, kv, kv2, kv3...); d)
end

push!(d::MultiDict, kv) = insert!(d, kv[1], kv[2])
#push!(d::MultiDict, kv, kv2...) = (push!(d.d, kv, kv2...); d)

count(d::MultiDict) = length(keys(d)) == 0 ? 0 : mapreduce(k -> length(d[k]), +, keys(d))
size(d::MultiDict) = (length(keys(d)), count(d::MultiDict))

# enumerate

immutable EnumerateAll
    d::MultiDict
end
enumerateall(d::MultiDict) = EnumerateAll(d)

length(e::EnumerateAll) = count(e.d)

function start(e::EnumerateAll)
    V = eltype(eltype(values(e.d)))
    vs = V[]
    (start(e.d.d), nothing, vs, start(vs))
end

function done(e::EnumerateAll, s)
    dst, k, vs, vst = s
    done(vs, vst) && done(e.d.d, dst)
end

function next(e::EnumerateAll, s)
    dst, k, vs, vst = s
    while done(vs, vst)
        ((k, vs), dst) = next(e.d.d, dst)
        vst = start(vs)
    end
    v, vst = next(vs, vst)
    ((k, v), (dst, k, vs, vst))
end
