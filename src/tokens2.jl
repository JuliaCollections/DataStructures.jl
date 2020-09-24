const SDMContainer = Union{SortedDict, SortedMultiDict}
const SAContainer = Union{SDMContainer, SortedSet}

const Token = Tuple{SAContainer, IntSemiToken}
const SDMToken = Tuple{SDMContainer, IntSemiToken}
const SetToken = Tuple{SortedSet, IntSemiToken}


## Function startof returns the semitoken that points
## to the first sorted order of the tree.  It returns
## the past-end token if the tree is empty.

@inline startof(m::SAContainer) = IntSemiToken(beginloc(m.bt))

## Function lastindex returns the semitoken that points
## to the last item in the sorted order,
## or the before-start marker if the tree is empty.

@inline Base.lastindex(m::SAContainer) = IntSemiToken(endloc(m.bt))

## Function pastendsemitoken returns the token past the end of the data.

@inline pastendsemitoken(::SAContainer) = IntSemiToken(2)

## Function beforestarttoken returns the token before the start of the data.

@inline beforestartsemitoken(::SAContainer) = IntSemiToken(1)

## delete! deletes an item given a token.

@inline function Base.delete!(ii::Token)
    has_data(ii)
    delete!(ii[1].bt, ii[2].address)
end

## Function advances takes a token and returns the
## next token in the sorted order.

@inline function advance(ii::Token)
    not_pastend(ii)
    IntSemiToken(nextloc0(ii[1].bt, ii[2].address))
end


## Function regresss takes a token and returns the
## previous token in the sorted order.

@inline function regress(ii::Token)
    not_beforestart(ii)
    IntSemiToken(prevloc0(ii[1].bt, ii[2].address))
end


## status of a token is 0 if the token is invalid, 1 if it points to
## ordinary data, 2 if it points to the before-start location and 3 if
## it points to the past-end location.


@inline status(ii::Token) =
       !(ii[2].address in ii[1].bt.useddatacells) ? 0 :
         ii[2].address == 1 ?                       2 :
         ii[2].address == 2 ?                       3 : 1

"""
    compare(m::SAContainer, s::IntSemiToken, t::IntSemiToken)

Determines the  relative positions of the  data items indexed
by `(m,s)` and  `(m,t)` in the sorted order. The  return value is `-1`
if `(m,s)` precedes `(m,t)`, `0` if they are equal, and `1` if `(m,s)`
succeeds `(m,t)`. `s`  and `t`  are semitokens  for the  same container `m`.
"""
@inline compare(m::SAContainer, s::IntSemiToken, t::IntSemiToken) =
      compareInd(m.bt, s.address, t.address)


@inline function deref(ii::SDMToken)
    has_data(ii)
    return Pair(ii[1].bt.data[ii[2].address].k, ii[1].bt.data[ii[2].address].d)
end

@inline function deref(ii::SetToken)
    has_data(ii)
    return ii[1].bt.data[ii[2].address].k
end

@inline function deref_key(ii::SDMToken)
    has_data(ii)
    return ii[1].bt.data[ii[2].address].k
end

@inline function deref_value(ii::SDMToken)
    has_data(ii)
    return ii[1].bt.data[ii[2].address].d
end


## Functions setindex! and getindex for semitokens.
## Note that we can't use SDMContainer here; we have
## to spell it out otherwise there is an ambiguity.

@inline function Base.getindex(m::SortedDict,
                          i::IntSemiToken)
    has_data((m,i))
    return m.bt.data[i.address].d
end

@inline function Base.getindex(m::SortedMultiDict,
                          i::IntSemiToken)
    has_data((m,i))
    return m.bt.data[i.address].d
end

@inline function Base.setindex!(m::SortedDict,
                           d_,
                           i::IntSemiToken)
    has_data((m,i))
    m.bt.data[i.address] = KDRec{keytype(m),valtype(m)}(m.bt.data[i.address].parent,
                                                         m.bt.data[i.address].k,
                                                         convert(valtype(m),d_))
    return m
end

@inline function Base.setindex!(m::SortedMultiDict,
                           d_,
                           i::IntSemiToken)
    has_data((m,i))
    m.bt.data[i.address] = KDRec{keytype(m),valtype(m)}(m.bt.data[i.address].parent,
                                                         m.bt.data[i.address].k,
                                                         convert(valtype(m),d_))
    return m
end


## This function takes a key and returns the token
## of the first item in the tree that is >= the given
## key in the sorted order.  It returns the past-end marker
## if there is none.

@inline function Base.searchsortedfirst(m::SAContainer, k_)
    i = findkeyless(m.bt, convert(keytype(m), k_))
    IntSemiToken(nextloc0(m.bt, i))
end

## This function takes a key and returns a token
## to the first item in the tree that is > the given
## key in the sorted order.  It returns the past-end marker
## if there is none.


@inline function searchsortedafter(m::SAContainer, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m), k_))
    IntSemiToken(nextloc0(m.bt, i))
end

## This function takes a key and returns a token
## to the last item in the tree that is <= the given
## key in the sorted order.  It returns the before-start marker
## if there is none.

@inline function Base.searchsortedlast(m::SAContainer, k_)
    i, exactfound = findkey(m.bt, convert(keytype(m),k_))
    IntSemiToken(i)
end


## The next four are correctness-checking routines.  They are
## not exported.


@inline not_beforestart(i::Token) =
    (!(i[2].address in i[1].bt.useddatacells) ||
     i[2].address == 1) && throw(BoundsError())

@inline not_pastend(i::Token) =
    (!(i[2].address in i[1].bt.useddatacells) ||
     i[2].address == 2) && throw(BoundsError())


@inline has_data(i::Token) =
    (!(i[2].address in i[1].bt.useddatacells) ||
     i[2].address < 3) && throw(BoundsError())
