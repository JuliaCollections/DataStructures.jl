## A SortedDict is a wrapper around balancedTree with
## methods similiar to those of Julia container Dict.


type SortedDict{K, D, Ord <: Ordering} <: Associative{K,D}
    bt::BalancedTree{K,D,Ord}
end

## Constructor takes an ordering object which defaults
## to Forward

function SortedDict{K,D, Ord <: Ordering}(d::Associative{K,D}, o::Ord=Forward)
    bt1 = BalancedTree{K,D,Ord}(o)
    for pr in d
        insert!(bt1, pr[1], pr[2], false)
    end
    SortedDict(bt1)
end



## An SDToken is a small structure for iterating
## over the items in a sorted dict order.  It is
## a wrapper around an (SortedDict,Int) pair; the int is the index
## of the current item in t.data.  An iterator
## should never point to a deleted item.  An iterator
## that points to the before-start item (=1)
## or the after-end item (=2) cannot be  dereferenced.


typealias Semitoken Int

immutable SDToken{K,D, Ord <: Ordering}
    address::Semitoken
    m::SortedDict{K,D,Ord}
end

SDToken{K,D, Ord <: Ordering}(a::Semitoken, 
                              m1::SortedDict{K,D,Ord}) = SDToken{K,D,Ord}(a,m1)


validtoken(i::SDToken) = !in(i.address, i.m.bt.useddatacells)? 0 :
          (i.address == 1? 2 : (i.address == 2? 3 : 1))

token_not_beforestart(i::SDToken) =
    (!in(i.address, i.m.bt.useddatacells) || i.address == 1) && throw(BoundsError())

token_not_pastend(i::SDToken) =
    (!in(i.address, i.m.bt.useddatacells) || i.address == 2) && throw(BoundsError())

token_has_data(i::SDToken) =
    (!in(i.address, i.m.bt.useddatacells) || i.address < 3) && throw(BoundsError())




## This function implements m[k]; it returns the
## data item associated with key k.

function getindex{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    if !exactfound
        throw(KeyError(k))
    end
    return m.bt.data[i].d
end

## This function implements m[k]=d; it sets the 
## data item associated with key k equal to d.

function setindex!{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, d_, k_)
    insert!(m.bt, convert(K,k_), convert(D,d_), false)
end

## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.
        
function findtoken{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    ll, exactfound = findkey(m.bt, convert(K,k_))
    exactfound? SDToken(ll,m) :  SDToken(2,m)
end

## This function inserts an item into the tree.
## Unlike m[k]=d, it also returns a bool and a token.
## The bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The token points to the newly inserted item.

function insert!{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_, d_)
    b, i = insert!(m.bt, convert(K,k_), convert(D,d_), false)
    b, SDToken(i,m)
end


## delete! deletes an item given a token.

function delete!(ii::SDToken)
    token_has_data(ii)
    delete!(ii.m.bt, ii.address)
end
    


## Function startof returns the token that points
## to the first sorted order of the tree.  It returns
## the past-end token if the tree is empty.

startof(m::SortedDict) = SDToken(beginloc(m.bt), m)

## Function pastendtoken returns the otken past the end of the data.

pastendtoken(m::SortedDict) = SDToken(2,m)

## Function beforestarttoken returns the token before the start of the data.

beforestarttoken(m::SortedDict) = SDToken(1,m)

## Function advance takes a token and returns the
## next token in the sorted order. 

function advance(ii::SDToken)
    token_not_pastend(ii)
    SDToken(nextloc0(ii.m.bt, ii.address), ii.m)
end


## Function regress takes a token and returns the
## previous token in the sorted order. 

function regress(ii::SDToken)
    token_not_beforestart(ii)
    SDToken(prevloc0(ii.m.bt, ii.address), ii.m)
end

## Endof returns the token of the last item in the sorted order,
## or the before-start marker if the SortedDict is empty.

endof(m::SortedDict) = SDToken(endloc(m.bt),m)

## First and last return the first and last (key,data) pairs
## in the SortedDict.  It is an error to invoke them on an
## empty SortedDict.

function first(m::SortedDict)
    i = beginloc(m.bt)
    if i == 2
        throw(BoundsError())
    end
    return m.bt.data[i].k, m.bt.data[i].d
end


function last(m::SortedDict)
    i = endloc(m.bt)
    if i == 1
        throw(BoundsError())
    end
    return m.bt.data[i].k, m.bt.data[i].d
end


## Function deref(ii), where ii is a token, returns the
## (k,d) pair indexed by ii.

function deref(ii::SDToken)
    token_has_data(ii)
    return ii.m.bt.data[ii.address].k, ii.m.bt.data[address].d
end

## Function deref_key(ii), where ii is a token, returns the
## key indexed by ii.

function deref_key(ii:SDToken)
    token_has_data(ii)
    return ii.m.bt.data[ii.address].k
end

## Function deref_value(ii), where ii is a token, returns the
## value indexed by ii.

function deref_value(ii:SDToken)
    token_has_data(ii)
    return ii.m.bt.data[ii.address].d
end

## This function takes a key and returns the token
## of the first item in the tree that is >= the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

function searchsortedfirst{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    exactfound?  SDToken(i,m) : SDToken(nextloc0(m.bt, i), m)
end

## This function takes a key and returns a token
## to the first item in the tree that is > the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

function searchsortedafter{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    SDToken(nextloc0(m.bt, i), m)
end

## This function takes a key and returns a token
## to the last item in the tree that is <= the given
## key in the sorted order.  It returns the before-start marker
## if there is none.

function searchsortedlast{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    SDToken(i, m)
end

isempty(m::SortedDict) = size(m.bt.data,1) - size(m.bt.freedatainds, 1) == 2

empty!(m::SortedDict) =  empty!(m.bt)

length(m::SortedDict) = size(m.bt.data,1) - size(m.bt.freedatainds, 1) - 2


immutable SDIterationState{K, D, Ord <: Ordering}
    m::SortedDict{K,D,Ord}
    next::Int
    final::Int
end

SDIterationState{K, D, Ord <: Ordering}(m1::SortedDict{K,D,Ord},
                                        next1::Int, final1::Int) = 
                                        SDIterationState{K,D,Ord}(m1, next1, final1)

## The next three functions are for iterating over a SortedDict
## with a for-loop.  We define done and next with a first argument of
## Any because the SortedDict object itself is carried in the state, and we
## want to reuse these functions range iterations
## (below)

start(m::SortedDict) = SDIterationState(m, nextloc0(m.bt,1), 2)
done(::Any, state::SDIterationState) = state.next == state.final

function next(::Any, state:SDIterationState)
    m = state.m
    sn = state.next
    if sn < 3 || !in(sn, m.bt.useddatacells)
        throw(BoundsError())
    end
    return (m.bt.data[sn].k, m.bt.data[sn].d, SDToken(sn, m)),
           SDIterationState(m, nextloc0(m.bt, sn), state.final)
end

itertoken((k,v,t)) = t


function isless(s::SDToken, t::SDToken)
    if !(s.m === t.m)
        throw(AgumentError())
    end
    return compareInd(m.bt, s.address, t. address) < 0
end


function isequal(s::SDToken, t::SDToken)
    if !(s.m === t.m)
        throw(AgumentError())
    end
    return s.address == t.address
end


immutable ExcludeLast{K, D, Ord <: Ordering}
    m::SortedDict{K, D, Ord}
    first::Int
    pastlast::Int
end

immutable IncludeLast{K, D, Ord <: Ordering}
    m::SortedDict{K, D, Ord}
    first::Int
    last::Int
end


ExcludeLast{K, D, Ord <: Ordering}(m1::SortedDict{K, D, Ord}, 
                                   first1::Int, 
                                   pastlast1::Int) = 
                                   ExcludeLast{K,D,Ord}(m1, first1, pastlast1)


function excludelast(i1::SDToken, i2::SDToken)
    if !(i1.m === i2.m)
        throw(ArgumentError())
    end
    ExcludeLast(i1.m, i1.address, i2.address)
end

IncludeLast{K, D, Ord <: Ordering}(m1::SortedDict{K, D, Ord}, first1::Int, last1::Int) = 
            IncludeLast{K,D,Ord}(m1, first1, last1)


function colon(i1::SDToken, i2::SDToken)
    if !(i1.m === i2.m)
        throw(ArgumentError())
    end
    IncludeLast(i1.m, i1.address, i2.address)
end


function start(e::ExcludeLast) 
    if !in(e.first, e.m.bt.useddatcells) || e.first == 1 ||
        !in(e.last, e.m.bt.usdedatacells)
        throw(BoundsError())
    end
    if compareInd(e.m.bt, e.first, e.pastlast) < 0
        return SDIterationState(e.m, e.first, e.pastlast) 
    else
        return SDIterationState(e.m, 2, 2)
    end
end

function start(e::IncludeLast) 
    if !in(e.first, e.m.bt.useddatcells) || e.first == 1 ||
        !in(e.last, e.m.bt.usdedatacells) || e.last == 2
        throw(BoundsError())
    end
    if compareInd(e.m.bt, e.first, e.pastlast) <= 0
        return SDIterationState(e.m, e.first, nextloc0(e.m.bt, e.last)) 
    else
        return SDIterationState(e.m, 2, 2)
    end
end


function in{K,D,Ord <: Ordering}((k_,d_)::(Any,Any), m::SortedDict{K,D,Ord})
    i, exactfound = findkey(m.bt,convert(K,k_))
    return exactfound && isequal(m.bt.data[i].d,convert(D,d_))
end

function eltype{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    (K,D)
end

function orderobject{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    m.bt.ord
end

function haskey{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt,convert(K,k_))
    exactfound
end

function get{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_, default_)
    i, exactfound = findkey(m.bt, convert(K,k_))
   return  exactfound? m.bt.data[i].d : convert(D,default_)
end


function get!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_, default_)
    k = convert(K,k_)
    i, exactfound = findkey(m.bt, k)
    if exactfound
        return m.bt.data[i].d
    else
        default = convert(D,default_)
        insert!(m.bt,k, default, false)
        return default
    end
end


function getkey{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_, default_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    exactfound? m.bt.data[i].k : convert(K,default_)
end

## Function delete! deletes an item at a given 
## key

function delete!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt,convert(K,k_))
    if !exactfound
        throw(KeyError(k))
    end
    delete!(m.bt, i)
    m
end

function pop!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt,convert(K,k_))
    if !exactfound
        throw(KeyeError(k))
    end
    d = m.bt.data[i].d
    delete!(m.bt, i)
    d
end


## The next three functions support "for k in keys(m)" where m is
## a SortedDict.

type KeySOD{K,D,Ord <: Ordering}
    m::SortedDict{K,D,Ord}
end

keys(m::SortedDict) = KeySOD(m)

start(ksod::KeySOD) = nextloc0(ksod.m.bt, 1)

done(ksod::KeySOD, state) = state == 2

function next(ksod::KeySOD, state::Int)
    if state == 2 || !in(state, ksod.m.bt.useddatacells)
        throw(BoundsError())
    end
    return ksod.m.bt.data[state].k, nextloc0(ksod.m.bt, state)
end


# These functions support "for p in values(m)"

type ValueSOD{K,D,Ord <: Ordering}
    m::SortedDict{K,D,Ord}
end

values(m::SortedDict) = ValueSOD(m)

start(vsod::ValueSOD) = nextloc0(vsod.m.bt, 1)

done(vsod::ValueSOD, state::Int) = state == 2

function next(vsod::ValueSOD{K,D,Ord}, state::Int)
    if state == 2 || !in(state, vsod.m.bt.useddatacells)
        throw(BoundsError())
    end
    return vsod.m.bt.data[state].d, nextloc0(vsod.m.bt, state)
end


## Check if two SortedDicts are equal in the sense of containing
## the same (K,D) pairs.  This sense of equality does not mean
## that indices valid for one are also valid for the other.

function isequal{K,D,Ord <: Ordering}(m1::SortedDict{K,D,Ord},
                                      m2::SortedDict{K,D,Ord})
    p1 = ind_first(m1)
    p2 = ind_first(m2)
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2))
        error("Cannot use isequal for two SortedDicts unless their ordering objects are equal")
    end
    while true
        if p1 == past_end(m1)
            return p2 == past_end(m2)
        end
        if p2 == past_end(m2)
            return false
        end
        k1,d1 = deref_ind(m1,p1)
        k2,d2 = deref_ind(m2,p2)
        if !eq(ord,k1,k2) || !isequal(d1,d2)
            return false
        end
        p1 = advance_ind(m1,p1)
        p2 = advance_ind(m2,p2)
    end
end


function mergetwo!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                        m2::SortedDict{K,D,Ord})
    for p in m2
        @inbounds m[p[1]] = p[2]
    end
end

function packcopy{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    w = SortedDict((K=>D)[],orderobject(m))
    mergetwo!(w,m)
    w
end

function packdeepcopy{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    w = SortedDict((K=>D)[],orderobject(m))
    for p in m
        newk = deepcopy(p[1])
        newv = deepcopy(p[2])
        w[newk] = newv
    end
    w
end

    

function merge!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                     others::SortedDict{K,D,Ord}...)
    apply(others) do m2
        mergetwo!(m, m2)
    end
end

function merge{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                    others::SortedDict{K,D,Ord}...)
    result = packcopy(m)
    merge!(result, others...)
    result
end


semiextract(s::SDToken) = s.address
containerextract(s::SDToken) = s.m
assembletoken(m,s) = SDToken(s,m)
