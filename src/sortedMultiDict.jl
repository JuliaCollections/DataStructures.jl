# A SortedMultiDict is a wrapper around balancedTree.
## Unlike SortedDict, a key in SortedMultiDict can
## refer to multiple data entries.

type SortedMultiDict{K, D, Ord <: Ordering}
    bt::BalancedTree23{K,D,Ord}
end


typealias SMDSemiToken IntSemiToken

typealias SMDToken @compat Tuple{SortedMultiDict, IntSemiToken}

## This constructor takes an ordering object which defaults
## to Forward

function SortedMultiDict{K,D, Ord <: Ordering}(kk::AbstractArray{K,1},
                                               dd::AbstractArray{D,1}, 
                                               o::Ord=Forward)
    bt1 = BalancedTree23{K,D,Ord}(o)
    if length(kk) != length(dd)
        throw(ArgumentError("SortedMultiDict K and D constructor array arguments must be the same length"))
    end
    for i = 1 : length(kk)
        insert!(bt1, kk[i], dd[i], true)
    end
    SortedMultiDict(bt1)
end



## This function inserts an item into the tree.
## It returns a token that
## points to the newly inserted item.

@inline function insert!{K, D, Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, k_, d_)
    b, i = insert!(m.bt, convert(K,k_), convert(D,d_), true)
    IntSemiToken(i)
end


## First and last return the first and last (key,data) pairs
## in the SortedMultiDict.  It is an error to invoke them on an
## empty SortedMultiDict.


@inline function first(m::SortedMultiDict)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    return m.bt.data[i].k, m.bt.data[i].d
end

@inline function last(m::SortedMultiDict)
    i = endloc(m.bt)
    i == 1 && throw(BoundsError())
    return m.bt.data[i].k, m.bt.data[i].d
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


## (k,d) in m checks whether a key-data pair is in 
## a sorted multidict.  This requires a loop over
## all data items whose key is equal to k. 

function in(pr::(@compat Tuple{Any,Any}), m::SortedMultiDict)
    k = convert(keytype(m), pr[1])
    i1 = findkeyless(m.bt, k)
    i2,exactfound = findkey(m.bt,k)
    !exactfound && return false
    ord = m.bt.ord
    while true
        i1 = nextloc0(m.bt, i1)
        i1 == i2 && return false
        @assert(eq(ord, m.bt.data[i1].k, k))
        m.bt.data[i1].d == pr[2] && return true
    end
end
 

@inline eltype{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}) = @compat Tuple{K,D}
@inline keytype{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}) = K
@inline datatype{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}) = D
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

typealias SDorAssociative Union(Associative, SortedMultiDict)

function mergetwo!{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord}, 
                                        m2::SDorAssociative)
    for (k,v) in m2
        insert!(m.bt, convert(K,k), convert(D,v), true)
    end
end

function packcopy{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord})
    w = SortedMultiDict((K)[], (D)[], orderobject(m))
    mergetwo!(w,m)
    w
end

function packdeepcopy{K,D,Ord <: Ordering}(m::SortedMultiDict{K,D,Ord})
    w = SortedMultiDict((K)[], (D)[], orderobject(m))
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
    keys = K[]
    vals = D[]
    for (k,v) in m
        push!(keys, k)
        push!(vals, v)
    end
    print(io, keys)
    println(io, ",")
    print(io, vals)
    println(io, ",")
    print(io, orderobject(m))
    print(io, ")")
end
