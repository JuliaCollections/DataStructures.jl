# ordered sets

# This was largely copied and modified from Base

# TODO: Most of these functions should be removed once AbstractSet is introduced there
# (see https://github.com/JuliaLang/julia/issues/5533)

@compat immutable OrderedSet{T}
    dict::HashDict{T,Void,Ordered}

    OrderedSet() = new(HashDict{T,Void,Ordered}())
    OrderedSet(xs) = union!(new(HashDict{T,Void,Ordered}()), xs)
end
OrderedSet() = OrderedSet{Any}()
OrderedSet(xs) = OrderedSet{eltype(xs)}(xs)


show(io::IO, s::OrderedSet) = (show(io, typeof(s)); print(io, "("); !isempty(s) && Base.show_comma_array(io, s,'[',']'); print(io, ")"))

@delegate OrderedSet.dict [isempty, length]

sizehint(s::OrderedSet, sz::Integer) = (sizehint(s.dict, sz); s)
eltype{T}(s::OrderedSet{T}) = T

in(x, s::OrderedSet) = haskey(s.dict, x)

push!(s::OrderedSet, x) = (s.dict[x] = nothing; s)
pop!(s::OrderedSet, x) = (pop!(s.dict, x); x)
pop!(s::OrderedSet, x, deflt) = pop!(s.dict, x, deflt) == deflt ? deflt : x
delete!(s::OrderedSet, x) = (delete!(s.dict, x); s)

union!(s::OrderedSet, xs) = (for x in xs; push!(s,x); end; s)
setdiff!(s::OrderedSet, xs) = (for x in xs; delete!(s,x); end; s)
setdiff!(s::Set, xs::OrderedSet) = (for x in xs; delete!(s,x); end; s)

similar{T}(s::OrderedSet{T}) = OrderedSet{T}()
copy(s::OrderedSet) = union!(similar(s), s)

empty!{T}(s::OrderedSet{T}) = (empty!(s.dict); s)

start(s::OrderedSet)       = start(s.dict)
done(s::OrderedSet, state) = done(s.dict, state)
# NOTE: manually optimized to take advantage of Dict representation
next(s::OrderedSet, i)     = (s.dict.keys[s.dict.order[i]], skip_deleted(s.dict,i+1))

# TODO: simplify me?
pop!(s::OrderedSet) = (val = s.dict.keys[s.dict.order[start(s.dict)]]; delete!(s.dict, val); val)

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

isequal(l::OrderedSet, r::OrderedSet) = (length(l) == length(r)) && (l <= r)
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

hash(s::OrderedSet) = (_compact_order(s.dict); hash(s.dict.keys[s.dict.order]))
