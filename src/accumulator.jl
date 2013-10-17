# A counter type 

type Accumulator{T, V<:Number}
	map::Dict{T,V}
end

## constructors

Accumulator{T,V<:Number}(::Type{T}, ::Type{V}) = Accumulator{T,V}((T=>V)[])
counter(T::Type) = Accumulator(T,Int)

Accumulator{T,V<:Number}(dct::Dict{T,V}) = Accumulator{T,V}(copy(dct))
counter{T}(dct::Dict{T,Int}) = Accumulator{T,Int}(copy(dct))

function counter{T}(seq::AbstractArray{T})
	ct = counter(T)
	for x in seq
		add!(ct, x)
	end
	return ct
end

copy{T,V<:Number}(ct::Accumulator{T,V}) = Accumulator{T,V}(copy(ct.map))

length(a::Accumulator) = length(a.map)

## retrieval

getindex{T,V}(ct::Accumulator{T,V}, x::T) = get(ct.map, x, zero(V))

haskey{T,V}(ct::Accumulator{T,V}, x::T) = haskey(ct.map, x)

keys(ct::Accumulator) = keys(ct.map)


## iteration

start(ct::Accumulator) = start(ct.map)
next(ct::Accumulator, state) = next(ct.map, state) 
done(ct::Accumulator, state) = done(ct.map, state)


# manipulation

add!{T,V<:Number}(ct::Accumulator{T,V}, x::T, a::V) = (ct.map[x] = ct[x] + a)
add!{T,V<:Number,V2<:Number}(ct::Accumulator{T,V}, x::T, a::V2) = add!(ct, x, convert(V,a))
add!{T,V<:Number}(ct::Accumulator{T,V}, x::T) = add!(ct, x, one(V))
push!{T,V<:Number}(ct::Accumulator{T,V}, x::T) = add!(ct, x)

function add!{T,V<:Number,V2<:Number}(ct::Accumulator{T,V}, r::Accumulator{T,V2})
	for (x::T, v::V2) in r
		add!(ct, x, v)
	end
	ct
end

pop!{T,V<:Number}(ct::Accumulator{T,V}, x::T) = pop!(ct.map, x)

merge{T,V<:Number}(ct1::Accumulator{T,V}, ct2::Accumulator{T,V}) = add!(copy(ct1), ct2)

