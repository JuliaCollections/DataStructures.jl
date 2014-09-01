



## A SortedDict is a wrapper around balancedTree with
## methods similiar to those of Julia container Dict.
## QUESTION: better to make this type ... or immutable... ??
## I'm not sure what the tradeoffs are.

type SortedDict{K, D, Ord <: Ordering} <: Associative{K,D}
    bt::BalancedTree{K,D,Ord}
end


function SortedDict{K,D, Ord <: Ordering}(d::Associative{K,D}, o=Forward)
    bt1 = BalancedTree{K,D,Ord}(o)
    for pr in d
        insert!(bt1, pr[1], pr[2], false)
    end
    SortedDict(bt1)
end



## A SortedDictIndex is a small structure for iterating
## over the items in a tree in sorted order.  It is
## a wrapper around an Int; the int is the index
## of the current item in t.data.  An iterator
## should never point to a deleted item.  An iterator
## that points to the before-start item (=1)
## or the after-end item (=2) cannot be  dereferenced.


immutable SortedDictIndex{K,D, Ord <: Ordering}
    address::Int
end


## This function implements m[k]; it returns the
## data item associated with key k.

function getindex{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K)
    i, exactfound = findkey(m.bt, k)
    if !exactfound
        throw(KeyError(k))
    end
    return m.bt.data[i].d
end

## This function implements m[k]=d; it sets the 
## data item associated with key k equal to d.

function setindex!{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, d::D, k::K)
    insert!(m.bt, k, d, false)
end

## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.
        
function ind_find{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K)
    ll, exactfound = findkey(m.bt, k)
    exactfound?
    SortedDictIndex{K,D,Ord}(ll) :
    SortedDictIndex{K,D,Ord}(2)
end

## This function inserts an item into the tree.
## Unlike m[k]=d, it also returns a bool and a Index.
## The bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The index points to the newly inserted item.

function ind_insert!{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K, d::D)
    b, i = insert!(m.bt, k, d, false)
    b, SortedDictIndex{K,D,Ord}(i)
end


## delete_ind! deletes an item given an index.

function delete_ind!{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                           ii::SortedDictIndex{K,D,Ord})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
    end
    if ii.address < 3
        throw(BoundsError())
    end
    delete!(m.bt, ii.address)
end
    


## Function ind_first returns the index that points
## to the first sorted order of the tree.  It returns
## the past-end index (i.e., 2) if the tree is empty.

function ind_first{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord})
    SortedDictIndex{K,D,Ord}(beginloc(m.bt))
end


## Function past_end returns the index past the end of the data.

function past_end{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord})
    SortedDictIndex{K,D,Ord}(2)
end

## Function before_start returns the index past the end of the data.

function before_start{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord})
    SortedDictIndex{K,D,Ord}(1)
end



## Function advance_ind takes an index and returns the
## next index in the sorted order. 

function advance_ind{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                           ii::SortedDictIndex{K,D,Ord})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
        #error("advance_ind invoked on deleted index")
    end
    if ii.address == 2
        throw(BoundsError())
        #error("advance_ind invoked on past-end data item")
    end

    SortedDictIndex{K,D,Ord}(nextloc0(m.bt, ii.address))
end


## Function regress_ind takes an index and returns the
## previous index in the sorted order. 

function regress_ind{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                           ii::SortedDictIndex{K,D,Ord})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
        #error("regress_ind invoked on deleted index")
    end
    if ii.address == 1
        throw(BoundsError())
        #error("regress_ind invoked on before-start data item")
    end
    SortedDictIndex{K,D,Ord}(prevloc0(m.bt, ii.address))
end

## Endof returns the index of the last item in the sorted order,
## or the before-start marker if the SortedDict is empty.

function endof{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord})
    SortedDictIndex{K,D,Ord}(endloc(m.bt))
end

## First and last return the first and last (key,data) pairs
## in the SortedDict.  It is an error to invoke them on an
## empty SortedDict.

function first{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord})
    i = beginloc(m.bt)
    if i == 2
        throw(BoundsError())
    end
    return m.bt.data[i].k, m.bt.data[i].d
end


function last{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord})
    i = endloc(m.bt)
    if i == 1
        throw(BoundsError())
    end
    return m.bt.data[i].k, m.bt.data[i].d
end




## Function deref_ind(m,ii), where ii is an index, returns the
## (k,d) pair indexed by ii.

function deref_ind{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                         ii::SortedDictIndex{K,D,Ord})
    addr = ii.address
    if addr < 3
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(addr, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return m.bt.data[addr].k, m.bt.data[addr].d
end

## Function deref_key_only_ind(m,ii), where ii is an index, returns the
## key indexed by ii.

function deref_key_only_ind{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                                  ii::SortedDictIndex{K,D,Ord})
    addr = ii.address
    if addr < 3
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(addr, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry $ii")
    end
    return m.bt.data[addr].k
end

## This function takes a key and returns the index
## of the first item in the tree that is >= the given
## key in the sorted order.  It returns the end marker
## if there is none.

function ind_equal_or_greater{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K)
    i, exactfound = findkey(m.bt, k)
    exactfound?
    SortedDictIndex{K,D,Ord}(i) :
    SortedDictIndex{K,D,Ord}(nextloc0(m.bt, i))
end

## This function takes a key and returns an index
## to the first item in the tree that is > the given
## key in the sorted order.  It returns the end marker
## if there is none.

function ind_greater{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K)
    i, exactfound = findkey(m.bt, k)
    SortedDictIndex{K,D,Ord}(nextloc0(m.bt, i))
end



## The next three functions are for iterating over a SortedDict
## with a for-loop.

function start{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    nextloc0(m.bt,1)
end


function done{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, state::Int)
    state == 2
end

function next{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ((m.bt.data[state].k, m.bt.data[state].d), nextloc0(m.bt, state))
end



    
type SortedDictRangeIteration{K,D,Ord <: Ordering}
    m::SortedDict{K,D,Ord}
    startit::Int
    endit::Int
end



## The next three functions are for iterating over a range of a
## SortedDict with a for-loop; the range is specified by a start
## and end index.


function sorted_dict_range_iteration{K,D,Ord <: Ordering}(m1::SortedDict{K,D,Ord},
                                                          startit1::SortedDictIndex{K,D,Ord},
                                                          endit1::SortedDictIndex{K,D,Ord})
    SortedDictRangeIteration(m1, startit1.address, endit1.address)
end




function start{K,D,Ord <: Ordering}(sodri::SortedDictRangeIteration{K,D,Ord})
    sodri.startit
end

function done{K,D,Ord <: Ordering}(sodri::SortedDictRangeIteration{K,D,Ord}, state::Int)
    state == 2 || state == sodri.endit
end

function next{K,D,Ord <: Ordering}(sodri::SortedDictRangeIteration{K,D,Ord}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, sodri.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ((sodri.m.bt.data[state].k, sodri.m.bt.data[state].d),
     nextloc0(sodri.m.bt, state))
end



type EnumerateSOD{K, D, Ord <: Ordering}
    m::SortedDict{K, D, Ord}
end


## The next three functions support "for p in enumerate_ind(m)... end"
## where m is a SortedDict.


function enumerate_ind{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord})
    EnumerateSOD{K,D,Ord}(m)
end

function start{K,D, Ord <: Ordering}(esod::EnumerateSOD{K,D,Ord})
    nextloc0(esod.m.bt,1)
end

function done{K, D, Ord <: Ordering}(esod::EnumerateSOD{K,D,Ord}, state::Int)
    state == 2
end

function next{K, D, Ord <: Ordering}(esod::EnumerateSOD{K,D,Ord}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, esod.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ((SortedDictIndex{K,D,Ord}(state), 
      (esod.m.bt.data[state].k,esod.m.bt.data[state].d)),
      nextloc0(esod.m.bt, state))
end

## These functions support "for p in enumerate_ind(sorted_dict_range_iteration(m,i1,i2))"

type EnumerateSODRI{K,D,Ord <: Ordering}
    sodri::SortedDictRangeIteration{K,D,Ord}
end

function enumerate_ind{K,D,Ord <: Ordering}(m::SortedDictRangeIteration{K,D,Ord})
    EnumerateSODRI{K,D,Ord}(m)
end


function start{K,D,Ord <: Ordering}(esodri::EnumerateSODRI{K,D,Ord})
    esodri.sodri.startit
end

function done{K,D,Ord <: Ordering}(esodri::EnumerateSODRI{K,D,Ord}, state::Int)
    state == 2 || state == esodri.sodri.endit
end

function next{K,D,Ord <: Ordering}(esodri::EnumerateSODRI{K,D,Ord}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, esodri.sodri.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (SortedDictIndex{K,D,Ord}(state), 
     (esodri.sodri.m.bt.data[state].k, esodri.sodri.m.bt.data[state].d)),
    nextloc0(esodri.sodri.m.bt, state)
end


function isempty{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    size(m.bt.data,1) - size(m.bt.freedatainds, 1) == 2
end


## This function clears a SortedDict -- all items deleted.

function empty!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    empty!(m.bt)
end

function length{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
   size(m.bt.data,1) - size(m.bt.freedatainds, 1) - 2
end

function in{K,D,Ord <: Ordering}(p::(K,D), m::SortedDict{K,D,Ord})
    @inbounds i, exactfound = findkey(m.bt,p[1])
    @inbounds return exactfound && isequal(m.bt.data[i].d,p[2])
end

function eltype{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    (K,D)
end

function orderobject{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    m.bt.ord
end

function haskey{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K)
    i, exactfound = findkey(m.bt,k)
    exactfound
end

function get{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K, default::D)
    i, exactfound = findkey(m.bt, k)
   return  exactfound? m.bt.data[i].d : default
end


function get!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K, default::D)
    i, exactfound = findkey(m.bt, k)
    if exactfound
        return m.bt.data[i].d
    else
        insert!(m.bt, k, default, false)
        return default
    end
end


function getkey{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K, default::K)
    i, exactfound = findkey(m.bt, k)
    exactfound? k : default
end

## Function delete! deletes an item at a given 
## key

function delete!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K)
    i, exactfound = findkey(m.bt,k)
    if !exactfound
        throw(KeyError(k))
        #error("Key not in SortedDict in delete!")
    end
    delete!(m.bt, i)
    m
end

function pop!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k::K)
    i, exactfound = findkey(m.bt,k)
    if !exactfound
        throw(KeyeError(k))
        #error("Key not in SortedDict in pop!")
    end
    d = m.bt.data[i].d
    delete!(m.bt, i)
    d
end


## The next three function support "for k in keys(m)" where m is
## a SortedDict.

type KeySOD{K,D,Ord <: Ordering}
    m::SortedDict{K,D,Ord}
end

function keys{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    KeySOD(m)
end

function start{K,D,Ord <: Ordering}(ksod::KeySOD{K,D,Ord})
    nextloc0(ksod.m.bt, 1)
end

function done{K,D,Ord <: Ordering}(ksod::KeySOD{K,D,Ord}, state::Int)
    state == 2
end

function next{K,D,Ord <: Ordering}(ksod::KeySOD{K,D,Ord}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, ksod.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ksod.m.bt.data[state].k, nextloc0(ksod.m.bt, state)
end


# The functions support "for p in enumerate_ind(keys(m))"


type EKeySOD{K,D,Ord <: Ordering}
    m::SortedDict{K,D,Ord}
end

function enumerate_ind{K,D,Ord <: Ordering}(ksod::KeySOD{K,D,Ord})
    EKeySOD(ksod.m)
end

function start{K,D,Ord <: Ordering}(eksod::EKeySOD{K,D,Ord})
    nextloc0(eksod.m.bt, 1)
end

function done{K,D,Ord <: Ordering}(eksod::EKeySOD{K,D,Ord}, state::Int)
    state == 2
end

function next{K,D,Ord <: Ordering}(eksod::EKeySOD{K,D,Ord}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, eksod.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (SortedDictIndex{K,D,Ord}(state),eksod.m.bt.data[state].k), 
    nextloc0(eksod.m.bt, state)
end


# These functions support "for p in values(m)"


type ValueSOD{K,D,Ord <: Ordering}
    m::SortedDict{K,D,Ord}
end

function values{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    ValueSOD(m)
end

function start{K,D,Ord <: Ordering}(vsod::ValueSOD{K,D,Ord})
    nextloc0(vsod.m.bt, 1)
end

function done{K,D,Ord <: Ordering}(vsod::ValueSOD{K,D,Ord}, state::Int)
    state == 2
end

function next{K,D,Ord <: Ordering}(vsod::ValueSOD{K,D,Ord}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, vsod.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return vsod.m.bt.data[state].d, nextloc0(vsod.m.bt, state)
end


# These functions support "for p in enumerate_ind(values(m))"


type EValueSOD{K,D,Ord <: Ordering}
    m::SortedDict{K,D,Ord}
end

function enumerate_ind{K,D,Ord <: Ordering}(vsod::ValueSOD{K,D,Ord})
    EValueSOD(vsod.m)
end

function start{K,D,Ord <: Ordering}(evsod::EValueSOD{K,D,Ord})
    nextloc0(evsod.m.bt, 1)
end

function done{K,D,Ord <: Ordering}(evsod::EValueSOD{K,D,Ord}, state::Int)
    state == 2
end

function next{K,D,Ord <: Ordering}(evsod::EValueSOD{K,D,Ord}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, evsod.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (SortedDictIndex{K,D,Ord}(state), evsod.m.bt.data[state].d), 
    nextloc0(evsod.m.bt, state)
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
        if is_ind_past_end(m1,p1)
            return is_ind_past_end(m2,p2)
        end
        if is_ind_past_end(m2,p2)
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


