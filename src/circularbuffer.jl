
# this represents a circular buffer, where new items are pushed to the back of the list, 
# overwriting values in a circular fashion
# iterating occurs from the "start" until the "end", and will return "length(buffer)" nodes

type CircularBuffer{T} <: AbstractVector{T}
  capacity::Int
  startIdx::Int
  buffer::Vector{T}

  CircularBuffer{T}(::Type{T}, capacity::Int) = new(capacity, 1, T[])
end

CircularBuffer{T}(::Type{T}, capacity::Int) = CircularBuffer{T}(T, capacity)

function CircularBuffer{T}(::Type{T}, capacity::Int, fillval::T)
  cb = CircularBuffer(T, capacity)
  for i in 1:capacity
    push!(cb, copy(fillval))
  end
  cb
end

function CircularBuffer{T}(::Type{T}, capacity::Int, v::Vector{T})
  cb = CircularBuffer(T, capacity)
  for x in v
    push!(cb, copy(x))
  end
  cb
end



function Base.print{T}(io::IO, cb::CircularBuffer{T})
  print(io, "{")
  print(io, join(collect(cb), ", "))
  print(io, "}")
end

function Base.show{T}(io::IO, cb::CircularBuffer{T})
  print(io, "CircularBuffer(cap=$(cb.capacity) start=$(cb.startIdx) n=$(length(cb)))")
  print(io, cb)
end


# cap = 8
# n = 6
# start = 6

# i = 1
# x = 6

# i = 4
# x = 1

# 4 5 6 _ _ 1 2 3




function bufferIndex(cb::CircularBuffer, i::Int)
  if i < 1 || i > length(cb)
    error("CircularBuffer out of range. cb=$cb i=$i")
  end
  (i + cb.startIdx - 2) % cb.capacity + 1
end

Base.getindex(cb::CircularBuffer, i::Int) = cb.buffer[bufferIndex(cb, i)]
function Base.setindex!{T}(cb::CircularBuffer, data::T, i::Int)
  cb.buffer[bufferIndex(cb, i)] = data
  nothing
end



function Base.push!{T}(cb::CircularBuffer{T}, data::T)

  if length(cb) == cb.capacity
    # if the buffer is full, increment the startIdx, and add to the end
    cb.startIdx = (cb.startIdx == cb.capacity ? 1 : cb.startIdx + 1)
    cb[length(cb)] = data

  else

    # add to the end
    push!(cb.buffer, data)

  end
end

function Base.append!{T}(cb::CircularBuffer{T}, datavec::AbstractVector{T})
  for d in datavec
    push!(cb, d)
  end
end

Base.length(cb::CircularBuffer) = length(cb.buffer)
Base.size(cb::CircularBuffer) = (length(cb),)
Base.convert{T}(::Type{Array}, cb::CircularBuffer{T}) = T[copy(x) for x in cb]

capacity(cb::CircularBuffer) = cb.capacity
isfull(cb::CircularBuffer) = length(cb) == cb.capacity


