## A SortedSet is a wrapper around balancedTree with
## methods similiar to those of the julia Set.


@compat type SortedSet{K, Ord <: Ordering}
    bt::BalancedTree23{K,Void,Ord}

    ## Zero-argument constructor, or possibly one argument to specify order.

    function SortedSet(o::Ord=Forward)
        bt1 = BalancedTree23{K,Void,Ord}(o)
        new(bt1)
    end
end


typealias SetSemiToken IntSemiToken

# The following definition was moved to tokens2.jl
#typealias SetToken Tuple{SortedSet, IntSemiToken}

## This constructor takes an iterable; order defaults
## to Forward

## This one takes an iterable; ordering type is optional.

SortedSet{Ord <: Ordering}(iter, o::Ord=Forward) =
    sortedset_with_eltype(iter, eltype(iter), o)

function sortedset_with_eltype{K,Ord}(iter, ::Type{K}, o::Ord)
    h = SortedSet{K,Ord}(o)
    for k in iter
        insert!(h, k)
    end
    h
end



## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.

@inline function find(m::SortedSet, k_)
    ll, exactfound = findkey(m.bt, convert(keytype(m),k_))
    IntSemiToken(exactfound? ll : 2)
end


## This function inserts an item into the tree.
## It returns a bool and a token.
## The bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The token points to the newly inserted item.

@inline function insert!(m::SortedSet, k_)
    b, i = insert!(m.bt, convert(keytype(m),k_), nothing, false)
    b, IntSemiToken(i)
end

## push! is similar to insert but returns the set

@inline function push!(m::SortedSet, k_)
    b, i = insert!(m.bt, convert(keytype(m),k_), nothing, false)
    m
end


## First and last return the first and last (key,data) pairs
## in the SortedDict.  It is an error to invoke them on an
## empty SortedDict.


@inline function first(m::SortedSet)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    return m.bt.data[i].k
end

@inline function last(m::SortedSet)
    i = endloc(m.bt)
    i == 1 && throw(BoundsError())
    return m.bt.data[i].k
end


@inline function in(k_, m::SortedSet)
    i, exactfound = findkey(m.bt, convert(keytype(m),k_))
    return exactfound
end

@inline eltype{K,Ord <: Ordering}(m::SortedSet{K,Ord}) = K
@inline eltype{K,Ord <: Ordering}(::Type{SortedSet{K,Ord}}) = K
@inline keytype{K,Ord <: Ordering}(m::SortedSet{K,Ord}) = K
@inline orderobject(m::SortedSet) = m.bt.ord

haskey(m::SortedSet, k_) = in(k_, m)

@inline function delete!(m::SortedSet, k_)
    i, exactfound = findkey(m.bt,convert(keytype(m),k_))
    !exactfound && throw(KeyError(k_))
    delete!(m.bt, i)
    m
end


@inline function pop!(m::SortedSet, k_)
    k = convert(keytype(m),k_)
    i, exactfound = findkey(m.bt, k)
    !exactfound && throw(KeyError(k_))
    d = m.bt.data[i].d
    delete!(m.bt, i)
    k
end

@inline function pop!(m::SortedSet)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    k = m.bt.data[i].k
    delete!(m.bt, i)
    k
end



## Check if two SortedSets are equal in the sense of containing
## the same K entries.  This sense of equality does not mean
## that semitokens valid for one are also valid for the other.

function isequal(m1::SortedSet, m2::SortedSet)
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2)) || !isequal(eltype(m1), eltype(m2))
        throw(ArgumentError("Cannot use isequal for two SortedSets unless their element types and ordering objects are equal"))
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
        k1 = deref((m1,p1))
        k2 = deref((m2,p2))
        if !eq(ord,k1,k2)
            return false
        end
        p1 = advance((m1,p1))
        p2 = advance((m2,p2))
    end
end


function union!{K, Ord <: Ordering}(m1::SortedSet{K,Ord}, iterable_item)
    for k in iterable_item
        push!(m1,convert(K,k))
    end
    m1
end

function union(m1::SortedSet, others...)
    mr = packcopy(m1)
    for m2 in others
        union!(mr, m2)
    end
    mr
end

function intersect2{K, Ord <: Ordering}(m1::SortedSet{K, Ord}, m2::SortedSet{K, Ord})
    ord = orderobject(m1)
    mi = SortedSet(K[], ord)
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        if p1 == pastendsemitoken(m1) || p2 == pastendsemitoken(m2)
            return mi
        end
        k1 = deref((m1,p1))
        k2 = deref((m2,p2))
        if lt(ord,k1,k2)
            p1 = advance((m1,p1))
        elseif lt(ord,k2,k1)
            p2 = advance((m2,p2))
        else
            push!(mi,k1)
            p1 = advance((m1,p1))
            p2 = advance((m2,p2))
        end
    end
end

            
function intersect{K, Ord <: Ordering}(m1::SortedSet{K,Ord}, others::SortedSet{K,Ord}...)
    ord = orderobject(m1)
    for s2 in others
        if !isequal(ord, orderobject(s2))
            throw(ArgumentError("Cannot intersect two SortedSets unless their ordering objects are equal"))
        end
    end
    if length(others) == 0
        return m1
    else
        mi = intersect2(m1, others[1])
        for s2 = others[2:end]
            mi = intersect2(mi, s2)
        end
        return mi
    end
end
    

function symdiff{K, Ord <: Ordering}(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord})
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2))
        throw(ArgumentError("Cannot apply symdiff to two SortedSets unless their ordering objects are equal"))
    end
    mi = SortedSet(K[], ord)
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        m1end = p1 == pastendsemitoken(m1)
        m2end = p2 == pastendsemitoken(m2)
        if m1end && m2end
            return mi
        elseif m1end
            push!(mi, deref((m2,p2)))
            p2 = advance((m2,p2))
        elseif m2end
            push!(mi, deref((m1,p1)))
            p1 = advance((m1,p1))
        else
            k1 = deref((m1,p1))
            k2 = deref((m2,p2))
            if lt(ord,k1,k2)
                push!(mi, k1)
                p1 = advance((m1,p1))
            elseif lt(ord,k2,k1)
                push!(mi, k2)
                p2 = advance((m2,p2))
            else
                p1 = advance((m1,p1))
                p2 = advance((m2,p2))
            end
        end
    end
end
    
function setdiff{K, Ord <: Ordering}(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord})
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2))
        throw(ArgumentError("Cannot apply setdiff to two SortedSets unless their ordering objects are equal"))
    end
    mi = SortedSet(K[], ord)
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        if p1 == pastendsemitoken(m1)
            return mi
        elseif p2 == pastendsemitoken(m2)
            push!(mi, deref((m1,p1)))
            p1 = advance((m1,p1))
        else
            k1 = deref((m1,p1))
            k2 = deref((m2,p2))
            if lt(ord,k1,k2)
                push!(mi, deref((m1,p1)))
                p1 = advance((m1,p1))
            elseif lt(ord,k2,k1)
                p2 = advance((m2,p2))
            else
                p1 = advance((m1,p1))
                p2 = advance((m2,p2))
            end
        end
    end
end

function setdiff!(m1::SortedSet, iterable)
    for p in iterable
        i = find(m1, p)
        if i != pastendsemitoken(m1)
            delete!((m1,i))
        end
    end
end


    
function issubset(iterable, m2::SortedSet)
    for k in iterable
        if !in(k, m2)
            return false
        end
    end
    return true
end


function packcopy{K,Ord <: Ordering}(m::SortedSet{K,Ord})
    w = SortedSet(K[], orderobject(m))
    for k in m
        push!(w, k)
    end
    w
end

function packdeepcopy{K, Ord <: Ordering}(m::SortedSet{K,Ord})
    w = SortedSet(K[], orderobject(m))
    for k in m
        newk = deepcopy(k)
        push!(w, newk)
    end
    w
end



function Base.show{K,Ord <: Ordering}(io::IO, m::SortedSet{K,Ord})
    print(io, "SortedSet(")
    keys = K[]
    for k in m
        push!(keys, k)
    end
    print(io, keys)
    println(io, ",")
    print(io, orderobject(m))
    print(io, ")")
end

similar{K,Ord<:Ordering}(m::SortedSet{K,Ord}) = 
SortedSet{K,Ord}(orderobject(m))
