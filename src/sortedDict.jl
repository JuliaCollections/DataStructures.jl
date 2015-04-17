## A SortedDict is a wrapper around balancedTree with
## methods similiar to those of Julia container Dict.


type SortedDict{K, D, Ord <: Ordering} <: Associative{K,D}
    bt::BalancedTree23{K,D,Ord}
end


typealias SDSemiToken IntSemiToken

typealias SDToken{K,D, Ord <: Ordering} Token{SortedDict{K,D,Ord}, SDSemiToken}

## This constructor takes an ordering object which defaults
## to Forward

function SortedDict{K,D, Ord <: Ordering}(d::Associative{K,D}, o::Ord=Forward)
    bt1 = BalancedTree23{K,D,Ord}(o)
    for pr in d
        insert!(bt1, pr[1], pr[2], false)
    end
    SortedDict(bt1)
end

## This function implements m[k]; it returns the
## data item associated with key k.

function getindex{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    !exactfound && throw(KeyError(k_))
    return m.bt.data[i].d
end


## This function implements m[k]=d; it sets the 
## data item associated with key k equal to d.

function setindex!{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, d_, k_)
    insert!(m.bt, convert(K,k_), convert(D,d_), false)
    m
end

## Functions setindex! and getindex for semitokens:

function getindex{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, i::SDSemiToken)
    addr = i.address
    has_data(SDToken{K,D,Ord}(m,i))
    return m.bt.data[addr].d
end

function setindex!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                        d_, 
                                        i::SDSemiToken)
    addr = i.address
    has_data(SDToken{K,D,Ord}(m,i))
    m.bt.data[addr] = KDRec{K,D}(m.bt.data[addr].parent,
                                 m.bt.data[addr].k, 
                                 convert(D,d_))
    m
end


sdtoken_construct{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord},int1::Int) = 
    SDToken{K,D,Ord}(m, SDSemiToken(int1))

## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.
        
function find{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    ll, exactfound = findkey(m.bt, convert(K,k_))
    sdtoken_construct(m, exactfound? ll : 2)
end

## This function inserts an item into the tree.
## Unlike m[k]=d, it also returns a bool and a token.
## The bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The token points to the newly inserted item.

function insert!{K,D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_, d_)
    b, i = insert!(m.bt, convert(K,k_), convert(D,d_), false)
    b, sdtoken_construct(m, i)
end


## delete! deletes an item given a token.

function delete!{K, D, Ord <: Ordering}(ii::SDToken{K,D,Ord})
    has_data(ii)
    delete!(ii.container.bt, ii.semitoken.address)
end
    


## Function startof returns the token that points
## to the first sorted order of the tree.  It returns
## the past-end token if the tree is empty.


startof(m::SortedDict) = sdtoken_construct(m, beginloc(m.bt))

## Function pastendtoken returns the otken past the end of the data.

pastendtoken(m::SortedDict) = sdtoken_construct(m,2)

## Function beforestarttoken returns the token before the start of the data.

beforestarttoken(m::SortedDict) = sdtoken_construct(m,1)

## Function advance takes a token and returns the
## next token in the sorted order. 

function advance{K, D, Ord <: Ordering}(ii::SDToken{K,D,Ord})
    not_pastend(ii)
    sdtoken_construct(ii.container, nextloc0(ii.container.bt, ii.semitoken.address))
end


## Function regress takes a token and returns the
## previous token in the sorted order. 

function regress{K, D, Ord <: Ordering}(ii::SDToken{K,D,Ord})
    not_beforestart(ii)
    sdtoken_construct(ii.container, prevloc0(ii.container.bt, ii.semitoken.address))
end

## Endof returns the token of the last item in the sorted order,
## or the before-start marker if the SortedDict is empty.

endof(m::SortedDict) = sdtoken_construct(m,endloc(m.bt))

## First and last return the first and last (key,data) pairs
## in the SortedDict.  It is an error to invoke them on an
## empty SortedDict.


function first(m::SortedDict)
    i = beginloc(m.bt)
    i == 2 && throw(BoundsError())
    return m.bt.data[i].k, m.bt.data[i].d
end

function last(m::SortedDict)
    i = endloc(m.bt)
    i == 1 && throw(BoundsError())
    return m.bt.data[i].k, m.bt.data[i].d
end

## Function deref(ii), where ii is a token, returns the
## (k,d) pair indexed by ii.

function deref{K, D, Ord <: Ordering}(ii::SDToken{K,D,Ord})
    has_data(ii)
    return ii.container.bt.data[ii.semitoken.address].k, 
           ii.container.bt.data[ii.semitoken.address].d
end

## Function deref_key(ii), where ii is a token, returns the
## key indexed by ii.

function deref_key{K, D, Ord <: Ordering}(ii::SDToken{K,D,Ord})
    has_data(ii)
    return ii.container.bt.data[ii.semitoken.address].k
end

## Function deref_value(ii), where ii is a token, returns the
## value indexed by ii.

function deref_value{K, D, Ord <: Ordering}(ii::SDToken{K,D,Ord})
    has_data(ii)
    return ii.container.bt.data[ii.semitoken.address].d
end

## This function takes a key and returns the token
## of the first item in the tree that is >= the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

function searchsortedfirst{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    sdtoken_construct(m, exactfound? i : nextloc0(m.bt, i))
end

## This function takes a key and returns a token
## to the first item in the tree that is > the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

function searchsortedafter{K, D, Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    sdtoken_construct(m, nextloc0(m.bt, i))
end

## This function takes a key and returns a token
## to the last item in the tree that is <= the given
## key in the sorted order.  It returns the before-start marker
## if there is none.

function searchsortedlast{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt, convert(K,k_))
    sdtoken_construct(m, i)
end


empty!(m::SortedDict) =  empty!(m.bt)
length(m::SortedDict) = length(m.bt.data) - length(m.bt.freedatainds) - 2
isempty(m::SortedDict) = length(m) == 0


## The next block of code handles iterations (for loops, i.e., start/next/done
## functions).  There are multiple ways to iterate over a loop; see the documentation.


## All the loops maintain a state which is an object of the
## following type.
immutable SDIterationState{K, D, Ord <: Ordering}
    m::SortedDict{K,D,Ord}
    next::Int
    final::Int
end


## This holds an object describing an exclude-last
## iteration.

immutable ExcludeLast{K, D, Ord <: Ordering}
    m::SortedDict{K, D, Ord}
    first::Int
    pastlast::Int
end


## This holds an object describing an include-last
## (i.e., colon operator) iteration.

immutable IncludeLast{K, D, Ord <: Ordering}
    m::SortedDict{K, D, Ord}
    first::Int
    last::Int
end


## The basic iterations are either over the whole sorted dict, an
## exclude-last object or include-last object.

typealias SDIterableTypesBase Union(SortedDict,ExcludeLast,IncludeLast)


## The compound iterations are obtained by applying keys(..) or tokens(..)
## to the basic iterations.  Furthermore, tokens(..) can be applied
## to either a basic iteration or a keys/values iteration.

immutable SDKeyIteration{T <: SDIterableTypesBase}
    base::T
end

immutable SDValIteration{T <: SDIterableTypesBase}
    base::T
end

immutable SDTokenIteration{T <: SDIterableTypesBase}
    base::T
end

immutable SDTokenKeyIteration{T <: SDIterableTypesBase}
    base::T
end

immutable SDTokenValIteration{T <: SDIterableTypesBase}
    base::T
end

typealias SDCompoundIterable Union(SDKeyIteration,
                                   SDValIteration, SDTokenIteration,
                                   SDTokenKeyIteration, SDTokenValIteration)
                                   
typealias SDAllIterable Union(SDIterableTypesBase, SDCompoundIterable)


done(::SDAllIterable, state::SDIterationState) = state.next == state.final


function nexthelper(state::SDIterationState)
    m = state.m
    sn = state.next
    (sn < 3 || !(sn in m.bt.useddatacells)) && throw(BoundsError())
    m.bt.data[sn], sdtoken_construct(m,sn), SDIterationState(m, nextloc0(m.bt, sn), state.final)
end


## The next function returns different objects depending on whether
## it is a basic iteration, a key iteration, a values iterations,
## a tokens/basic iteration, a tokens/key iteration, or tokens/values
## iteration.

function next(::SDIterableTypesBase, state::SDIterationState)
    dt, t, ni = nexthelper(state)
    (dt.k, dt.d), ni
end

function next(::SDKeyIteration, state::SDIterationState)
    dt, t, ni = nexthelper(state)
    dt.k, ni
end

function next(::SDValIteration, state::SDIterationState)
    dt, t, ni = nexthelper(state)
    dt.d, ni
end


function next(::SDTokenIteration, state::SDIterationState)
    dt, t, ni = nexthelper(state)
    (t, (dt.k, dt.d)), ni
end

function next(::SDTokenKeyIteration, state::SDIterationState)
    dt, t, ni = nexthelper(state)
    (t, dt.k), ni
end

function next(::SDTokenValIteration, state::SDIterationState)
    dt, t, ni = nexthelper(state)
    (t, dt.d), ni
end



function excludelast{K, D, Ord <: Ordering}(i1::SDToken{K,D,Ord}, i2::SDToken{K,D,Ord})
    !(i1.container === i2.container) && 
        throw(ArgumentError("SDToken range constructor requires tokens for the same container"))
    ExcludeLast(i1.container, i1.semitoken.address, i2.semitoken.address)
end



function colon{K, D, Ord <: Ordering}(i1::SDToken{K,D,Ord}, i2::SDToken{K,D,Ord})
    !(i1.container === i2.container) &&
        throw(ArgumentError("SDToken range constructor requires tokens for the same container"))
    IncludeLast(i1.container, i1.semitoken.address, i2.semitoken.address)
end


# need the next two to resolve ambiguity with keys(Associative)
keys(m::SortedDict) = SDKeyIteration(m)
values(m::SortedDict) = SDValIteration(m)
keys{T <: SDIterableTypesBase}(ba::T) = SDKeyIteration(ba)
values{T <: SDIterableTypesBase}(ba::T) = SDValIteration(ba)
tokens{T <: SDIterableTypesBase}(ba::T) = SDTokenIteration(ba)
tokens{T <: SDIterableTypesBase}(ki::SDKeyIteration{T}) = SDTokenKeyIteration(ki.base)
tokens{T <: SDIterableTypesBase}(vi::SDValIteration{T}) = SDTokenValIteration(vi.base)

start(m::SortedDict) = SDIterationState(m, nextloc0(m.bt,1), 2)

function start(e::ExcludeLast) 
    (!(e.first in e.m.bt.useddatacells) || e.first == 1 ||
        !(e.pastlast in e.m.bt.useddatacells)) &&
        throw(BoundsError())
    if compareInd(e.m.bt, e.first, e.pastlast) < 0
        return SDIterationState(e.m, e.first, e.pastlast) 
    else
        return SDIterationState(e.m, 2, 2)
    end
end

function start(e::IncludeLast) 
    (!(e.first in e.m.bt.useddatacells) || e.first == 1 ||
        !(e.last in e.m.bt.useddatacells) || e.last == 2) && 
        throw(BoundsError())
    if compareInd(e.m.bt, e.first, e.last) <= 0
        return SDIterationState(e.m, e.first, nextloc0(e.m.bt, e.last)) 
    else
        return SDIterationState(e.m, 2, 2)
    end
end

start(e::SDCompoundIterable) = start(e.base)

function isless{K, D, Ord <: Ordering}(s::SDToken{K,D,Ord}, t::SDToken{K,D,Ord})
    !(s.container === t.container) &&  
        throw(ArgumentError("SDToken isless requires tokens for the same container"))
    return compareInd(s.container.bt, 
                      s.semitoken.address, 
                      t.semitoken.address) < 0
end


function isequal{K, D, Ord <: Ordering}(s::SDToken{K,D,Ord}, t::SDToken{K,D,Ord})
    !(s.container === t.container) && 
        throw(ArgumentError("SDToken isequal requires tokens for the same container"))
    return s.semitoken.address == t.semitoken.address
end


function in{K,D,Ord <: Ordering}(pr::(@compat Tuple{Any,Any}), m::SortedDict{K,D,Ord})
    i, exactfound = findkey(m.bt,convert(K,pr[1]))
    return exactfound && isequal(m.bt.data[i].d,convert(D,pr[2]))
end

eltype{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}) = (K,D)

orderobject(m::SortedDict) = m.bt.ord

function haskey{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt,convert(K,k_))
    exactfound
end

function get{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_, default_)
    i, exactfound = findkey(m.bt, convert(K,k_))
   return exactfound? m.bt.data[i].d : convert(D,default_)
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
    !exactfound && throw(KeyError(k_))
    delete!(m.bt, i)
    m
end

function pop!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, k_)
    i, exactfound = findkey(m.bt,convert(K,k_))
    !exactfound && throw(KeyError(k_))
    d = m.bt.data[i].d
    delete!(m.bt, i)
    d
end


## Check if two SortedDicts are equal in the sense of containing
## the same (K,D) pairs.  This sense of equality does not mean
## that semitokens valid for one are also valid for the other.

function isequal(m1::SortedDict, m2::SortedDict)
    ord = orderobject(m1)
    if !isequal(ord, orderobject(m2)) || !isequal(eltype(m1), eltype(m2))
        error("Cannot use isequal for two SortedDicts unless their element types and ordering objects are equal")
    end
    p1 = startof(m1)
    p2 = startof(m2)
    while true
        if p1 == pastendtoken(m1)
            return p2 == pastendtoken(m2)
        end
        if p2 == pastendtoken(m2)
            return false
        end
        k1,d1 = deref(p1)
        k2,d2 = deref(p2)
        if !eq(ord,k1,k2) || !isequal(d1,d2)
            return false
        end
        p1 = advance(p1)
        p2 = advance(p2)
    end
end


function mergetwo!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                        m2::SortedDict{K,D,Ord})
    for (k,v) in m2
        m[k] = v
    end
end

function packcopy{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    w = SortedDict(Dict{K,D}(),orderobject(m))
    mergetwo!(w,m)
    w
end

function packdeepcopy{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord})
    w = SortedDict(Dict{K,D}(),orderobject(m))
    for (k,v) in m
        newk = deepcopy(k)
        newv = deepcopy(v)
        w[newk] = newv
    end
    w
end


function merge!{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                     others::SortedDict{K,D,Ord}...)
    for o in others
        mergetwo!(m,o)
    end
end

function merge{K,D,Ord <: Ordering}(m::SortedDict{K,D,Ord}, 
                                    others::SortedDict{K,D,Ord}...)
    result = packcopy(m)
    merge!(result, others...)
    result
end



## status of a token is 0 if the token is invalid, 1 if it points to 
## ordinary data, 2 if it points to the before-start location and 3 if
## it points to the past-end location.

status{K, D, Ord <: Ordering}(i::SDToken{K,D,Ord}) = 
       !(i.semitoken.address in i.container.bt.useddatacells)? 0 :
                        (i.semitoken.address == 1? 2 : (i.semitoken.address == 2? 3 : 1))


## The next three are non-exported correctness checking routines.

not_beforestart{K, D, Ord <: Ordering}(i::SDToken{K,D,Ord}) =
    (!(i.semitoken.address in i.container.bt.useddatacells) || 
     i.semitoken.address == 1) && throw(BoundsError())

not_pastend{K, D, Ord <: Ordering}(i::SDToken{K,D,Ord}) =
    (!(i.semitoken.address in i.container.bt.useddatacells) || 
     i.semitoken.address == 2) && 
       throw(BoundsError())

has_data{K, D, Ord <: Ordering}(i::SDToken{K,D,Ord}) =
    (!(i.semitoken.address in i.container.bt.useddatacells) || 
     i.semitoken.address < 3) && 
       throw(BoundsError())

