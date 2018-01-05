import Base.keys
import Base.values

## These are the containers that can be looped over
## The prefix SDM is for SortedDict and SortedMultiDict
## The prefix SS is for SortedSet.  The prefix SA
## is for all sorted containers.
## The following two definitions now appear in tokens2.jl

# const SDMContainer = Union{SortedDict, SortedMultiDict}
# const SAContainer = Union{SDMContainer, SortedSet}

@inline extractcontainer(s::SAContainer) = s

## This holds an object describing an exclude-last
## iteration.


abstract type AbstractExcludeLast{ContainerType <: SAContainer} end

struct SDMExcludeLast{ContainerType <: SDMContainer} <:
                              AbstractExcludeLast{ContainerType}
    m::ContainerType
    first::Int
    pastlast::Int
end

struct SSExcludeLast{ContainerType <: SortedSet} <:
                              AbstractExcludeLast{ContainerType}
    m::ContainerType
    first::Int
    pastlast::Int
end

@inline extractcontainer(s::AbstractExcludeLast) = s.m
eltype(s::AbstractExcludeLast) = eltype(s.m)

## This holds an object describing an include-last
## iteration.

abstract type AbstractIncludeLast{ContainerType <: SAContainer} end



struct SDMIncludeLast{ContainerType <: SDMContainer} <:
                               AbstractIncludeLast{ContainerType}
    m::ContainerType
    first::Int
    last::Int
end


struct SSIncludeLast{ContainerType <: SortedSet} <:
                               AbstractIncludeLast{ContainerType}
    m::ContainerType
    first::Int
    last::Int
end

@inline extractcontainer(s::AbstractIncludeLast) = s.m
eltype(s::AbstractIncludeLast) = eltype(s.m)


## The basic iterations are either over the whole sorted container, an
## exclude-last object or include-last object.

const SDMIterableTypesBase = Union{SDMContainer,
                                   SDMExcludeLast,
                                   SDMIncludeLast}

const SSIterableTypesBase = Union{SortedSet,
                                  SSExcludeLast,
                                  SSIncludeLast}


const SAIterableTypesBase = Union{SAContainer,
                                  AbstractExcludeLast,
                                  AbstractIncludeLast}


## The compound iterations are obtained by applying keys(..) or values(..)
## to the basic iterations of the SDM.. type.
## Furthermore, semitokens(..) can be applied
## to either a basic iteration or a keys/values iteration.

struct SDMKeyIteration{T <: SDMIterableTypesBase}
    base::T
end

eltype(s::SDMKeyIteration) = keytype(extractcontainer(s.base))
length(s::SDMKeyIteration) = length(extractcontainer(s.base))


struct SDMValIteration{T <: SDMIterableTypesBase}
    base::T
end

eltype(s::SDMValIteration) = valtype(extractcontainer(s.base))
length(s::SDMValIteration) = length(extractcontainer(s.base))


struct SDMSemiTokenIteration{T <: SDMIterableTypesBase}
    base::T
end

eltype(s::SDMSemiTokenIteration) = Tuple{IntSemiToken,
                                         keytype(extractcontainer(s.base)),
                                         valtype(extractcontainer(s.base))}

struct SSSemiTokenIteration{T <: SSIterableTypesBase}
    base::T
end

eltype(s::SSSemiTokenIteration) = Tuple{IntSemiToken,
                                        eltype(extractcontainer(s.base))}


struct SDMSemiTokenKeyIteration{T <: SDMIterableTypesBase}
    base::T
end

eltype(s::SDMSemiTokenKeyIteration) = Tuple{IntSemiToken,
                                            keytype(extractcontainer(s.base))}

struct SAOnlySemiTokensIteration{T <: SAIterableTypesBase}
    base::T
end

eltype(::SAOnlySemiTokensIteration) = IntSemiToken


struct SDMSemiTokenValIteration{T <: SDMIterableTypesBase}
    base::T
end

eltype(s::SDMSemiTokenValIteration) = Tuple{IntSemiToken,
                                            valtype(extractcontainer(s.base))}

const SACompoundIterable = Union{SDMKeyIteration,
                                 SDMValIteration,
                                 SDMSemiTokenIteration,
                                 SSSemiTokenIteration,
                                 SDMSemiTokenKeyIteration,
                                 SDMSemiTokenValIteration,
                                 SAOnlySemiTokensIteration}

@inline extractcontainer(s::SACompoundIterable) = extractcontainer(s.base)


const SAIterable = Union{SAIterableTypesBase, SACompoundIterable}


## All the loops maintain a state which is an object of the
## following type.

struct SAIterationState
    next::Int
    final::Int
end


## All the loops have the same method for 'done'

@inline done(::SAIterable, state::SAIterationState) = state.next == state.final


@inline exclusive(m::T, ii::(Tuple{IntSemiToken,IntSemiToken})) where {T <: SDMContainer} =
    SDMExcludeLast(m, ii[1].address, ii[2].address)

@inline exclusive(m::T, ii::(Tuple{IntSemiToken,IntSemiToken})) where {T <: SortedSet} =
    SSExcludeLast(m, ii[1].address, ii[2].address)

@inline exclusive(m::T, i1::IntSemiToken, i2::IntSemiToken) where {T <: SAContainer} =
    exclusive(m, (i1,i2))

@inline inclusive(m::T, ii::(Tuple{IntSemiToken,IntSemiToken})) where {T <: SDMContainer} =
    SDMIncludeLast(m, ii[1].address, ii[2].address)

@inline inclusive(m::T, ii::(Tuple{IntSemiToken,IntSemiToken})) where {T <: SortedSet} =
    SSIncludeLast(m, ii[1].address, ii[2].address)

@inline inclusive(m::T, i1::IntSemiToken, i2::IntSemiToken) where {T <: SAContainer} =
    inclusive(m, (i1,i2))



# Next definition needed to break ambiguity with keys(AbstractDict) from Dict.jl

@inline keys(ba::SortedDict{K,D,Ord}) where {K, D, Ord <: Ordering} = SDMKeyIteration(ba)
@inline keys(ba::T) where {T <: SDMIterableTypesBase} = SDMKeyIteration(ba)


in(k, keyit::SDMKeyIteration{SortedDict{K,D,Ord}}) where {K,D,Ord <: Ordering} =
    haskey(extractcontainer(keyit.base), k)

in(k, keyit::SDMKeyIteration{SortedMultiDict{K,D,Ord}}) where {K,D,Ord <: Ordering} =
    haskey(extractcontainer(keyit.base), k)



# Next definition needed to break ambiguity with values(AbstractDict) from Dict.jl
@inline values(ba::SortedDict{K,D,Ord}) where {K, D, Ord <: Ordering} = SDMValIteration(ba)
@inline values(ba::T) where {T <: SDMIterableTypesBase} = SDMValIteration(ba)
@inline semitokens(ba::T) where {T <: SDMIterableTypesBase} = SDMSemiTokenIteration(ba)
@inline semitokens(ba::T) where {T <: SSIterableTypesBase} = SSSemiTokenIteration(ba)
@inline semitokens(ki::SDMKeyIteration{T}) where {T <: SDMIterableTypesBase} =
                   SDMSemiTokenKeyIteration(ki.base)
@inline semitokens(vi::SDMValIteration{T}) where {T <: SDMIterableTypesBase} =
                   SDMSemiTokenValIteration(vi.base)
@inline onlysemitokens(ba::T) where {T <: SAIterableTypesBase} = SAOnlySemiTokensIteration(ba)



@inline start(m::SAContainer) = SAIterationState(nextloc0(m.bt,1), 2)
@inline start(e::SACompoundIterable) = start(e.base)

function start(e::AbstractExcludeLast)
    (!(e.first in e.m.bt.useddatacells) || e.first == 1 ||
        !(e.pastlast in e.m.bt.useddatacells)) &&
        throw(BoundsError())
    if compareInd(e.m.bt, e.first, e.pastlast) < 0
        return SAIterationState(e.first, e.pastlast)
    else
        return SAIterationState(2, 2)
    end
end

function start(e::AbstractIncludeLast)
    (!(e.first in e.m.bt.useddatacells) || e.first == 1 ||
        !(e.last in e.m.bt.useddatacells) || e.last == 2) &&
        throw(BoundsError())
    if compareInd(e.m.bt, e.first, e.last) <= 0
        return SAIterationState(e.first, nextloc0(e.m.bt, e.last))
    else
        return SAIterationState(2, 2)
    end
end


## The 'next' function returns different objects depending on whether
## it is a basic iteration, a key iteration, a values iterations,
## a semitokens/basic iteration, a semitokens/key iteration, or semitokens/values
## iteration.

@inline function next(u::SAOnlySemiTokensIteration, state::SAIterationState)
    sn = state.next
    (sn < 3 || !(sn in extractcontainer(u).bt.useddatacells)) && throw(BoundsError())
    IntSemiToken(sn),
    SAIterationState(nextloc0(extractcontainer(u).bt, sn), state.final)
end


@inline function nexthelper(u, state::SAIterationState)
    sn = state.next
    (sn < 3 || !(sn in extractcontainer(u).bt.useddatacells)) && throw(BoundsError())
    extractcontainer(u).bt.data[sn], sn,
    SAIterationState(nextloc0(extractcontainer(u).bt, sn), state.final)
end





@inline function next(u::SDMIterableTypesBase, state::SAIterationState)
    dt, t, ni = nexthelper(u, state)
    (dt.k => dt.d), ni
end


@inline function next(u::SSIterableTypesBase, state::SAIterationState)
    dt, t, ni = nexthelper(u, state)
    dt.k, ni
end


@inline function next(u::SDMKeyIteration, state::SAIterationState)
    dt, t, ni = nexthelper(u, state)
    dt.k, ni
end

@inline function next(u::SDMValIteration, state::SAIterationState)
    dt, t, ni = nexthelper(u, state)
    dt.d, ni
end


@inline function next(u::SDMSemiTokenIteration, state::SAIterationState)
    dt, t, ni = nexthelper(u, state)
    (IntSemiToken(t), dt.k, dt.d), ni
end


@inline function next(u::SSSemiTokenIteration, state::SAIterationState)
    dt, t, ni = nexthelper(u, state)
    (IntSemiToken(t), dt.k), ni
end

@inline function next(u::SDMSemiTokenKeyIteration, state::SAIterationState)
    dt, t, ni = nexthelper(u, state)
    (IntSemiToken(t), dt.k), ni
end


@inline function next(u::SDMSemiTokenValIteration, state::SAIterationState)
    dt, t, ni = nexthelper(u, state)
    (IntSemiToken(t), dt.d), ni
end


eachindex(sd::SortedDict) = keys(sd)
eachindex(sdm::SortedMultiDict) = onlysemitokens(sdm)
eachindex(ss::SortedSet) = onlysemitokens(ss)
eachindex(sd::SDMExcludeLast{SortedDict{K,D,Ord}}) where {K,D,Ord <: Ordering} = keys(sd)
eachindex(smd::SDMExcludeLast{SortedMultiDict{K,D,Ord}}) where {K,D,Ord <: Ordering} =
     onlysemitokens(smd)
eachindex(ss::SSExcludeLast) = onlysemitokens(ss)
eachindex(sd::SDMIncludeLast{SortedDict{K,D,Ord}}) where {K,D,Ord <: Ordering} = keys(sd)
eachindex(smd::SDMIncludeLast{SortedMultiDict{K,D,Ord}}) where {K,D,Ord <: Ordering} =
     onlysemitokens(smd)
eachindex(ss::SSIncludeLast) = onlysemitokens(ss)


empty!(m::SAContainer) =  empty!(m.bt)
@inline length(m::SAContainer) = length(m.bt.data) - length(m.bt.freedatainds) - 2
@inline isempty(m::SAContainer) = length(m) == 0
