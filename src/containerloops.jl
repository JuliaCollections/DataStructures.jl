import Base.keys
import Base.values

## These are the containers that can be looped over
## The prefix SDM is for SortedDict and SortedMultiDict
## The prefix SS is for SortedSet.  The prefix SA
## is for all sorted containers.
## The following two definitions now appear in tokens2.jl

#typealias SDMContainer Union{SortedDict, SortedMultiDict}
#typealias SAContainer Union{SDMContainer, SortedSet}

@inline extractcontainer(s::SAContainer) = s

## This holds an object describing an exclude-last
## iteration.

abstract AbstractExcludeLast{ContainerType <: SAContainer}

immutable SDMExcludeLast{ContainerType <: SDMContainer} <:
                              AbstractExcludeLast{ContainerType}
    m::ContainerType
    first::Int
    pastlast::Int
end



immutable SSExcludeLast{ContainerType <: SortedSet} <:
                              AbstractExcludeLast{ContainerType}
    m::ContainerType
    first::Int
    pastlast::Int
end

@inline extractcontainer(s::AbstractExcludeLast) = s.m
eltype(s::AbstractExcludeLast) = eltype(s.m)

## This holds an object describing an include-last
## iteration.

abstract AbstractIncludeLast{ContainerType <: SAContainer}



immutable SDMIncludeLast{ContainerType <: SDMContainer} <: 
                               AbstractIncludeLast{ContainerType}
    m::ContainerType
    first::Int
    last::Int
end


immutable SSIncludeLast{ContainerType <: SortedSet} <: 
                               AbstractIncludeLast{ContainerType}
    m::ContainerType
    first::Int
    last::Int
end

@inline extractcontainer(s::AbstractIncludeLast) = s.m
eltype(s::AbstractIncludeLast) = eltype(s.m)


## The basic iterations are either over the whole sorted container, an
## exclude-last object or include-last object.

@compat typealias SDMIterableTypesBase Union{SDMContainer,
                                     SDMExcludeLast,
                                     SDMIncludeLast}

@compat typealias SSIterableTypesBase Union{SortedSet,
                                    SSExcludeLast,
                                    SSIncludeLast}


@compat typealias SAIterableTypesBase Union{SAContainer,
                                    AbstractExcludeLast,
                                    AbstractIncludeLast}


## The compound iterations are obtained by applying keys(..) or values(..)
## to the basic iterations of the SDM.. type.
## Furthermore, semitokens(..) can be applied
## to either a basic iteration or a keys/values iteration.

immutable SDMKeyIteration{T <: SDMIterableTypesBase}
    base::T
end

eltype(s::SDMKeyIteration) = keytype(extractcontainer(s.base))


immutable SDMValIteration{T <: SDMIterableTypesBase}
    base::T
end

eltype(s::SDMValIteration) = datatype(extractcontainer(s.base))



immutable SDMSemiTokenIteration{T <: SDMIterableTypesBase}
    base::T
end

eltype(s::SDMSemiTokenIteration) = @compat Tuple{IntSemiToken, 
                                         keytype(extractcontainer(s.base)),
                                         datatype(extractcontainer(s.base))}

immutable SSSemiTokenIteration{T <: SSIterableTypesBase}
    base::T
end

eltype(s::SSSemiTokenIteration) = @compat Tuple{IntSemiToken,
                                        eltype(extractcontainer(s.base))}


immutable SDMSemiTokenKeyIteration{T <: SDMIterableTypesBase}
    base::T
end

eltype(s::SDMSemiTokenKeyIteration) = @compat Tuple{IntSemiToken,
                                            keytype(extractcontainer(s.base))}



immutable SDMSemiTokenValIteration{T <: SDMIterableTypesBase}
    base::T
end

eltype(s::SDMSemiTokenValIteration) = @compat Tuple{IntSemiToken,
                                            datatype(extractcontainer(s.base))}

@compat typealias SACompoundIterable Union{SDMKeyIteration,
                                   SDMValIteration,
                                   SDMSemiTokenIteration,
                                   SSSemiTokenIteration,
                                   SDMSemiTokenKeyIteration,
                                   SDMSemiTokenValIteration}

@inline extractcontainer(s::SACompoundIterable) = extractcontainer(s.base)


@compat typealias SAIterable Union{SAIterableTypesBase, SACompoundIterable}


## All the loops maintain a state which is an object of the
## following type.

immutable SAIterationState
    next::Int
    final::Int
end


## All the loops have the same method for 'done'

@inline done(::SAIterable, state::SAIterationState) = state.next == state.final


@inline exclusive{T <: SDMContainer}(m::T, ii::(@compat Tuple{IntSemiToken,IntSemiToken})) =
    SDMExcludeLast(m, ii[1].address, ii[2].address)

@inline exclusive{T <: SortedSet}(m::T, ii::(@compat Tuple{IntSemiToken,IntSemiToken})) =
    SSExcludeLast(m, ii[1].address, ii[2].address)

@inline exclusive{T <: SAContainer}(m::T, i1::IntSemiToken, i2::IntSemiToken) =
    exclusive(m, (i1,i2))

@inline inclusive{T <: SDMContainer}(m::T, ii::(@compat Tuple{IntSemiToken,IntSemiToken})) =
    SDMIncludeLast(m, ii[1].address, ii[2].address)

@inline inclusive{T <: SortedSet}(m::T, ii::(@compat Tuple{IntSemiToken,IntSemiToken})) =
    SSIncludeLast(m, ii[1].address, ii[2].address)

@inline inclusive{T <: SAContainer}(m::T, i1::IntSemiToken, i2::IntSemiToken) =
    inclusive(m, (i1,i2))



# Next definition needed to break ambiguity with keys(Associative) from Dict.jl

@inline keys{K, D, Ord <: Ordering}(ba::SortedDict{K,D,Ord}) = SDMKeyIteration(ba)
@inline keys{T <: SDMIterableTypesBase}(ba::T) = SDMKeyIteration(ba)


in{K,D,Ord <: Ordering}(k, keyit::SDMKeyIteration{SortedDict{K,D,Ord}}) =
    haskey(extractcontainer(keyit.base), k)

in{K,D,Ord <: Ordering}(k, keyit::SDMKeyIteration{SortedMultiDict{K,D,Ord}}) = 
    haskey(extractcontainer(keyit.base), k)

    

# Next definition needed to break ambiguity with values(Associative) from Dict.jl
@inline values{K, D, Ord <: Ordering}(ba::SortedDict{K,D,Ord}) = SDMValIteration(ba)
@inline values{T <: SDMIterableTypesBase}(ba::T) = SDMValIteration(ba)
@inline semitokens{T <: SDMIterableTypesBase}(ba::T) = SDMSemiTokenIteration(ba)
@inline semitokens{T <: SSIterableTypesBase}(ba::T) = SSSemiTokenIteration(ba)
@inline semitokens{T <: SDMIterableTypesBase}(ki::SDMKeyIteration{T}) = 
                   SDMSemiTokenKeyIteration(ki.base)
@inline semitokens{T <: SDMIterableTypesBase}(vi::SDMValIteration{T}) = 
                   SDMSemiTokenValIteration(vi.base)

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

@inline function nexthelper(u, state::SAIterationState)
    sn = state.next
    (sn < 3 || !(sn in extractcontainer(u).bt.useddatacells)) && throw(BoundsError())
    extractcontainer(u).bt.data[sn], sn, 
    SAIterationState(nextloc0(extractcontainer(u).bt, sn), state.final)
end


@inline function next(u::SDMIterableTypesBase, state::SAIterationState)
    dt, t, ni = nexthelper(u, state)
    (dt.k, dt.d), ni
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

empty!(m::SAContainer) =  empty!(m.bt)
@inline length(m::SAContainer) = length(m.bt.data) - length(m.bt.freedatainds) - 2
@inline isempty(m::SAContainer) = length(m) == 0
