#  multi-value dictionary (multidict)

import Base: haskey, get, get!, getkey, delete!, push!, pop!, empty!,
             setindex!, getindex, length, isempty, start,
             next, done, keys, values, show, copy, similar,
             writemime, showdict

immutable MultiDict{K,V} <: Associative{K,V}
    d::Dict{K,Vector{V}}

    MultiDict() = new(Dict{K,Vector{V}}())
    MultiDict(kv) = new(Dict{K,Vector{V}}(kv))
    if VERSION >= v"0.4.0-dev+980"
        MultiDict(ps::Pair{K,V}...) = new(Dict{K,Vector{V}}(ps...))
    end
end

MultiDict() = MultiDict{Any,Any}()
MultiDict(kv::@compat Tuple{}) = MultiDict()
MultiDict(kvs) = multi_dict_with_eltype(kvs, eltype(kvs))

multi_dict_with_eltype{K,V}(kvs, ::Type{@compat Tuple{K,Array{V,1}}}) = MultiDict{K,V}(kvs)
function multi_dict_with_eltype{K,V}(kvs, ::Type{@compat Tuple{K,V}})
    md = MultiDict{K,V}()
    for (k,v) in kvs
        setindex!(md, v, k)
    end
    return md
end
multi_dict_with_eltype(kvs, t) = MultiDict{Any,Any}(kvs)

# if VERSION >= v"0.4.0-dev+980"
#     MultiDict{K,V}(ps::Pair{K,V}...)                               = MultiDict{K,V}(ps...)
#     MultiDict{K,V}(kv::@compat Tuple{Vararg{Pair{K,V}}})           = MultiDict{K,V}(kv)
#     MultiDict{K}  (kv::@compat Tuple{Vararg{Pair{K}}})             = MultiDict{K,Any}(kv)
#     MultiDict{V}  (kv::@compat Tuple{Vararg{Pair{TypeVar(:K),V}}}) = MultiDict{Any,V}(kv)
#     MultiDict     (kv::@compat Tuple{Vararg{Pair}})                = MultiDict{Any,Any}(kv)

#     MultiDict{K,V}(kv::AbstractArray{Pair{K,V}})                   = MultiDict{K,V}(kv)

#     multi_dict_with_eltype{K,V}(kv, ::Type{Pair{K,V}})    = MultiDict{K,V}(kv)
# end

## Iterator
function start{K,V}(d::MultiDict{K,V})
    vs = V[]
    (start(d.d), nothing, vs, start(vs))
end

function done{K,V}(d::MultiDict{K,V}, s)
    dst, k, vs, vst = s
    done(vs, vst) && done(d.d, dst)
end

function next{K,V}(d::MultiDict{K,V}, s)
    dst, k, vs, vst = s
    while done(vs, vst)
        ((k, vs), dst) = next(d.d, dst)
        vst = start(vs)
    end
    v, vst = next(vs, vst)
    ((k, v), (dst, k, vs, vst))
end

## Functions

## Most functions are simply delegated to the wrapped Dict

@delegate MultiDict.d [ haskey, get, getkey, pop!,
                        empty!, getindex, isempty, keys]

sizehint(d::MultiDict, sz::Integer) = (sizehint(d.d, sz); d)
values(d::MultiDict) = Base.ValueIterator(d)
copy(d::MultiDict) = MultiDict(d)
similar{K,V}(d::MultiDict{K,V}) = MultiDict{K,V}()
writemime(io::IO, ::MIME"text/plain", t::MultiDict) = showdict(io, t, limit=false)
length(d::MultiDict) = length(keys(d)) == 0 ? 0 : mapreduce(k -> length(d[k]), +, keys(d))
#in(p::Tuple{Any,Any}, d::MultiDict) = Base.in(v, values(d))

# function Base.in(p::Tuple{Any,Any}, d::MultiDict)
#     v = get(d,p[1],Base.secret_table_token)
#     println(v)
#     !is(v, Base.secret_table_token) && (v == p[2])
# end

#in{T<:MultiDict}(key, v::Base.KeyIterator{T}) = key in keys(v.dict.d.d)

function setindex!{K,V}(d::MultiDict{K,V}, v, k)
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

function delete!(d::MultiDict, key)
    pop!(d, key, nothing)
    d
end

if VERSION >= v"0.4.0-dev+980"
    push!(d::MultiDict, kv::Pair) = (push!(d.d, kv); d)
    #push!(d::MultiDict, kv::Pair, kv2::Pair) = (push!(d.d, kv, kv2); d)
    #push!(d::MultiDict, kv::Pair, kv2::Pair, kv3::Pair...) = (push!(d.d, kv, kv2, kv3...); d)
end

push!(d::MultiDict, kv) = setindex!(d, kv[2], kv[1])
#push!(d::MultiDict, kv, kv2...) = (push!(d.d, kv, kv2...); d)