# A SortedMultiDict is a wrapper around balancedTree.
## Unlike SortedDict, a key in SortedMultiDict can
## refer to multiple data entries.

type SortedMultiDict{K, D, Ord <: Ordering}
    bt::BalancedTree23{K,D,Ord}

    ## Base constructors

    (::Type{SortedMultiDict{K,D,Ord}}){K,D,Ord}(o::Ord) = new{K,D,Ord}(BalancedTree23{K,D,Ord}(o))

    function (::Type{SortedMultiDict{K,D,Ord}}){K,D,Ord}(o::Ord, kv)
        smd = new{K,D,Ord}(BalancedTree23{K,D,Ord}(o))

        if eltype(kv) <: Pair
            # It's (possibly?) more efficient to access the first and second
            # elements of Pairs directly, rather than destructure
            for p in kv
                insert!(smd, p.first, p.second)
            end
        else
            for (k,v) in kv
                insert!(smd, k, v)
            end
        end
        return smd

    end
end

SortedMultiDict() = SortedMultiDict{Any,Any,ForwardOrdering}(Forward)
SortedMultiDict{O<:Ordering}(o::O) = SortedMultiDict{Any,Any,O}(o)

# Construction from Pairs
SortedMultiDict(ps::Pair...) = SortedMultiDict(Forward, ps)
SortedMultiDict(o::Ordering, ps::Pair...) = SortedMultiDict(o, ps)
(::Type{SortedMultiDict{K,D}}){K,D}(ps::Pair...) = SortedMultiDict{K,D,ForwardOrdering}(Forward, ps)
(::Type{SortedMultiDict{K,D}}){K,D,Ord<:Ordering}(o::Ord, ps::Pair...) = SortedMultiDict{K,D,Ord}(o, ps)

# Construction from Associatives
SortedMultiDict{K,D,Ord<:Ordering}(o::Ord, d::Associative{K,D}) = SortedMultiDict{K,D,Ord}(o, d)

## Construction from iteratables of Pairs/Tuples

# Construction specifying Key/Value types
# e.g., SortedMultiDict{Int,Float64}([1=>1, 2=>2.0])
(::Type{SortedMultiDict{K,D}}){K,D}(kv) = SortedMultiDict{K,D}(Forward, kv)
function (::Type{SortedMultiDict{K,D}}){K,D,Ord<:Ordering}(o::Ord, kv)
    try
        SortedMultiDict{K,D,Ord}(o, kv)
    catch e
        if not_iterator_of_pairs(kv)
            throw(ArgumentError("SortedMultiDict(kv): kv needs to be an iterator of tuples or pairs"))
        else
            rethrow(e)
        end
    end
end

# Construction inferring Key/Value types from input
# e.g. SortedMultiDict{}

SortedMultiDict(o1::Ordering, o2::Ordering) = throw(ArgumentError("SortedMultiDict with two parameters must be called with an Ordering and an interable of pairs"))
SortedMultiDict(kv, o::Ordering=Forward) = SortedMultiDict(o, kv)
function SortedMultiDict(o::Ordering, kv)
    try
        _sorted_multidict_with_eltype(o, kv, eltype(kv))
    catch e
        if not_iterator_of_pairs(kv)
            throw(ArgumentError("SortedMultiDict(kv): kv needs to be an iterator of tuples or pairs"))
        else
            rethrow(e)
        end
    end
end

_sorted_multidict_with_eltype{K,D,Ord}(o::Ord, ps, ::Type{Pair{K,D}}) = SortedMultiDict{  K,  D,Ord}(o, ps)
_sorted_multidict_with_eltype{K,D,Ord}(o::Ord, kv, ::Type{Tuple{K,D}}) = SortedMultiDict{  K,  D,Ord}(o, kv)
_sorted_multidict_with_eltype{K,  Ord}(o::Ord, ps, ::Type{Pair{K}}  ) = SortedMultiDict{  K,Any,Ord}(o, ps)
_sorted_multidict_with_eltype{    Ord}(o::Ord, kv, ::Type            ) = SortedMultiDict{Any,Any,Ord}(o, kv)

## TODO: It seems impossible (or at least very challenging) to create the eltype below.
##       If deemed possible, please create a test and uncomment this definition.
# if VERSION < v"0.6.0-dev.2123"
#     _sorted_multi_dict_with_eltype{  D,Ord}(o::Ord, ps, ::Type{Pair{TypeVar(:K),D}}) = SortedMultiDict{Any,  D,Ord}(o, ps)
# else
#     _include_string("_sorted_multi_dict_with_eltype{  D,Ord}(o::Ord, ps, ::Type{Pair{K,D} where K}) = SortedMultiDict{Any,  D,Ord}(o, ps)")
# end

const SMDSemiToken = IntSemiToken

const SMDToken = Tuple{SortedMultiDict, IntSemiToken}


## This function inserts an item into the tree.
## It returns a token that
## points to the newly inserted item.

@inline function insert!{K, D, Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, k_, d_)
    b, i = insert!(m.bt, convert(K,k_), convert(D,d_), true)
    IntSemiToken(i)
end

## push! is an alternative to insert!; it returns the container.


@inline function push!{K,D}(m::SortedMultiDict{K,D}, pr::Pair)
    insert!(m.bt, convert(K,pr[1]), convert(D,pr[2]), true)
    m
end



## First and last return the first and last (key,data) pairs
## in the SortedMultiDict.  It is an error to invoke them on an
## empty SortedMultiDict.


@inline function first(m::SortedMultiDict)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    return Pair(m.bt.data[i].k, m.bt.data[i].d)
end

@inline function last(m::SortedMultiDict)
    i = endloc(m.bt)
    i == 1 && throw(BoundsError())
    return Pair(m.bt.data[i].k, m.bt.data[i].d)
end


function searchequalrange(m::SortedMultiDict, k_)
    k = convert(keytype(m),k_)
    i1 = findkeyless(m.bt, k)
    i2, exactfound = findkey(m.bt, k)
    if exactfound
        i1a = nextloc0(m.bt, i1)
        return IntSemiToken(i1a), IntSemiToken(i2)
    else
        return IntSemiToken(2), IntSemiToken(1)
    end
end



## '(k,d) in m' checks whether a key-data pair is in
## a sorted multidict.  This requires a loop over
## all data items whose key is equal to k.


function in_(k_, d_, m::SortedMultiDict)
    k = convert(keytype(m), k_)
    d = convert(valtype(m), d_)
    i1 = findkeyless(m.bt, k)
    i2,exactfound = findkey(m.bt,k)
    !exactfound && return false
    ord = m.bt.ord
    while true
        i1 = nextloc0(m.bt, i1)
        @assert(eq(ord, m.bt.data[i1].k, k))
        m.bt.data[i1].d == d && return true
        i1 == i2 && return false
    end
end




@inline eltype{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}) =  Pair{K,D}
@inline eltype{K,D,Ord <: Ordering}(::Type{SortedMultiDict{K,D,Ord}}) =  Pair{K,D}
@inline in(pr::Pair, m::SortedMultiDict) =
    in_(pr[1], pr[2], m)
@inline in(::Tuple{Any,Any}, ::SortedMultiDict) =
    throw(ArgumentError("'(k,v) in sortedmultidict' not supported in Julia 0.4 or 0.5.  See documentation"))



@inline keytype{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}) = K
@inline keytype{K,D,Ord <: Ordering}(::Type{SortedMultiDict{K,D,Ord}}) = K
@inline valtype{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}) = D
@inline valtype{K,D,Ord <: Ordering}(::Type{SortedMultiDict{K,D,Ord}}) = D
@inline ordtype{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}) = Ord
@inline ordtype{K,D,Ord <: Ordering}(::Type{SortedMultiDict{K,D,Ord}}) = Ord
@inline orderobject(m::SortedMultiDict) = m.bt.ord

@inline function haskey(m::SortedMultiDict, k_)
    i, exactfound = findkey(m.bt,convert(keytype(m),k_))
    exactfound
end



## Check if two SortedMultiDicts are equal in the sense of containing
## the same (K,D) pairs in the same order.  This sense of equality does not mean
## that semitokens valid for one are also valid for the other.

function isequal(m1::SortedMultiDict, m2::SortedMultiDict)
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2)) || !isequal(eltype(m1), eltype(m2))
        throw(ArgumentError("Cannot use isequal for two SortedMultiDicts unless their element types and ordering objects are equal"))
    end
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        if p1 == pastendsemitoken(m1)
            return p2 == pastendsemitoken(m2)
        end
        if p2 == pastendsemitoken(m2)
            return false
        end
        k1,d1 = deref((m1,p1))
        k2,d2 = deref((m2,p2))
        if !eq(ord,k1,k2) || !isequal(d1,d2)
            return false
        end
        p1 = advance((m1,p1))
        p2 = advance((m2,p2))
    end
end

const SDorAssociative = Union{Associative,SortedMultiDict}

function mergetwo!{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord},
                                        m2::SDorAssociative)
    for (k,v) in m2
        insert!(m.bt, convert(K,k), convert(D,v), true)
    end
end

function packcopy{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord})
    w = SortedMultiDict{K,D}(orderobject(m))
    mergetwo!(w,m)
    w
end

function packdeepcopy{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord})
    w = SortedMultiDict{K,D}(orderobject(m))
    for (k,v) in m
        insert!(w.bt, deepcopy(k), deepcopy(v), true)
    end
    w
end


function merge!{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord},
                                     others::SDorAssociative...)
    for o in others
        mergetwo!(m,o)
    end
end

function merge{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord},
                                    others::SDorAssociative...)
    result = packcopy(m)
    merge!(result, others...)
    result
end

function Base.show{K,D,Ord <: Ordering}(io::IO, m::SortedMultiDict{K,D,Ord})
    print(io, "SortedMultiDict(")
    print(io, orderobject(m), ",")
    l = length(m)
    for (count,(k,v)) in enumerate(m)
        print(io, k, " => ", v)
        if count < l
            print(io, ", ")
        end
    end
    print(io, ")")
end

similar{K,D,Ord<:Ordering}(m::SortedMultiDict{K,D,Ord}) =
   SortedMultiDict{K,D}(orderobject(m))

isordered{T<:SortedMultiDict}(::Type{T}) = true
