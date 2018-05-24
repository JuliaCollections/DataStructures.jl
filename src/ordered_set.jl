# ordered sets

# This was largely copied and modified from Base

# TODO: Most of these functions should be removed once AbstractSet is introduced there
# (see https://github.com/JuliaLang/julia/issues/5533)

struct OrderedSet{T}
    dict::OrderedDict{T,Nothing}

    OrderedSet{T}() where {T} = new{T}(OrderedDict{T,Nothing}())
    OrderedSet{T}(xs) where {T} = union!(new{T}(OrderedDict{T,Nothing}()), xs)
end
OrderedSet() = OrderedSet{Any}()
OrderedSet(xs) = OrderedSet{eltype(xs)}(xs)


show(io::IO, s::OrderedSet) = (show(io, typeof(s)); print(io, "("); !isempty(s) && Base.show_comma_array(io, s,'[',']'); print(io, ")"))

@delegate OrderedSet.dict [isempty, length]

sizehint!(s::OrderedSet, sz::Integer) = (sizehint!(s.dict, sz); s)
eltype(s::OrderedSet{T}) where {T} = T
eltype(::Type{OrderedSet{T}}) where {T} = T

in(x, s::OrderedSet) = haskey(s.dict, x)

push!(s::OrderedSet, x) = (s.dict[x] = nothing; s)
pop!(s::OrderedSet, x) = (pop!(s.dict, x); x)
pop!(s::OrderedSet, x, deflt) = pop!(s.dict, x, deflt) == deflt ? deflt : x
delete!(s::OrderedSet, x) = (delete!(s.dict, x); s)

#getindex(x::OrderedSet,i::Int) = x.dict.keys[i]
#lastindex(x::OrderedSet) = lastindex(x.dict.keys)
#Base.nextind(::OrderedSet, i::Int) = i + 1  # Needed on 0.7 to mimic array indexing.
#Base.keys(s::OrderedSet) = 1:length(s)

union!(s::OrderedSet, xs) = (for x in xs; push!(s,x); end; s)
setdiff!(s::OrderedSet, xs) = (for x in xs; delete!(s,x); end; s)
setdiff!(s::Set, xs::OrderedSet) = (for x in xs; delete!(s,x); end; s)

similar(s::OrderedSet{T}) where {T} = OrderedSet{T}()
copy(s::OrderedSet) = union!(similar(s), s)

empty!(s::OrderedSet{T}) where {T} = (empty!(s.dict); s)



if VERSION >= v"0.7.0-DEV.5126"
    IteratorEltype(::Type{OrderedSet{K}} where {K}) = HasEltype()
    IteratorSize(::Type{OrderedSet{K}} where {K}) = HasLength()

    function iterate(os::OrderedSet, pos = 1)
        t = iterate(os.dict, pos)
        if t == nothing
            return nothing
        else
            return (t[1][1], t[2])
        end
    end
    
else
    start(os::OrderedSet) = start(os.dict)
    function next(os::OrderedSet, state)
        (dt, state) = next(os.dict, state)
        return (dt[1], state)
    end
    done(os::OrderedSet, state) = done(os.dict, state)
end


function pop!(s::OrderedSet)
    l = length(s.dict.a1)
    while l > 0
        if s.dict.a1[l][2]
            key = s.dict.a1[l][1]
            pop!(s.dict, key)
            return key
        end
        l -= 1
    end
    throw(ArgumentError("OrderedSet must be nonempty"))
end


union(s::OrderedSet) = copy(s)
function union(s::OrderedSet, sets...)
    u = OrderedSet{Base.promote_eltype(s, sets...)}()
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

