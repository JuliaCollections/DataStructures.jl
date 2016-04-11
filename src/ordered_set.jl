# ordered sets

# This was largely copied and modified from Base

# TODO: Most of these functions should be removed once AbstractSet is introduced there
# (see https://github.com/JuliaLang/julia/issues/5533)

immutable OrderedSet{T}
    dict::OrderedDict{T,Void}

    OrderedSet() = new(OrderedDict{T,Void}())
    OrderedSet(xs) = union!(new(OrderedDict{T,Void}()), xs)
end
OrderedSet() = OrderedSet{Any}()
OrderedSet(xs) = OrderedSet{eltype(xs)}(xs)


show(io::IO, s::OrderedSet) = (show(io, typeof(s)); print(io, "("); !isempty(s) && Base.show_comma_array(io, s,'[',']'); print(io, ")"))

@delegate OrderedSet.dict [isempty, length]

sizehint!(s::OrderedSet, sz::Integer) = (sizehint!(s.dict, sz); s)
eltype{T}(s::OrderedSet{T}) = T

in(x, s::OrderedSet) = haskey(s.dict, x)

push!(s::OrderedSet, x) = (s.dict[x] = nothing; s)
pop!(s::OrderedSet, x) = (pop!(s.dict, x); x)
pop!(s::OrderedSet, x, deflt) = pop!(s.dict, x, deflt) == deflt ? deflt : x
delete!(s::OrderedSet, x) = (delete!(s.dict, x); s)

getindex(x::OrderedSet,i::Int) = x.dict.keys[i]
endof(x::OrderedSet) = endof(x.dict.keys)

union!(s::OrderedSet, xs) = (for x in xs; push!(s,x); end; s)
setdiff!(s::OrderedSet, xs) = (for x in xs; delete!(s,x); end; s)
setdiff!(s::Set, xs::OrderedSet) = (for x in xs; delete!(s,x); end; s)

similar{T}(s::OrderedSet{T}) = OrderedSet{T}()
copy(s::OrderedSet) = union!(similar(s), s)

empty!{T}(s::OrderedSet{T}) = (empty!(s.dict); s)

start(s::OrderedSet)       = start(s.dict)
done(s::OrderedSet, state) = done(s.dict, state)
# NOTE: manually optimized to take advantage of OrderedDict representation
next(s::OrderedSet, i)     = (s.dict.keys[i], i+1)

pop!(s::OrderedSet) = pop!(s.dict)[1]

union(s::OrderedSet) = copy(s)
function union(s::OrderedSet, sets...)
    u = OrderedSet{Base.join_eltype(s, sets...)}()
    union!(u,s)
    for t in sets
        union!(u,t)
    end
    return u
end

intersect(s::OrderedSet) = copy(s)
function intersect(s::OrderedSet, sets...)
    i = copy(s)
    for x in s
        for t in sets
            if !in(x,t)
                delete!(i,x)
                break
            end
        end
    end
    return i
end

function setdiff(a::OrderedSet, b)
    d = similar(a)
    for x in a
        if !(x in b)
            push!(d, x)
        end
    end
    d
end

==(l::OrderedSet, r::OrderedSet) = (length(l) == length(r)) && (l <= r)
<(l::OrderedSet, r::OrderedSet) = (length(l) < length(r)) && (l <= r)
<=(l::OrderedSet, r::OrderedSet) = issubset(l, r)

function filter!(f::Function, s::OrderedSet)
    for x in s
        if !f(x)
            delete!(s, x)
        end
    end
    return s
end
filter(f::Function, s::OrderedSet) = filter!(f, copy(s))

const orderedset_seed = UInt === UInt64 ? 0x2114638a942a91a5 : 0xd86bdbf1
function hash(s::OrderedSet, h::UInt)
    h = hash(orderedset_seed, h)
    s.dict.ndel > 0 && rehash!(s.dict)
    hash(s.dict.keys, h)
end
