# stacks

type Stack{T}
    q::Dequeue{T}
    
    Stack() = new(Dequeue{T}())
    Stack(blksize::Int) = new(Dequeue{T}(blksize))
end

isempty(s::Stack) = isempty(s.q)
length(s::Stack) = length(s.q)

top(s::Stack) = back(s.q)

push!{T}(s::Stack{T}, x::T) = push_back!(s.q, x)
pop!{T}(s::Stack{T}) = pop_back!(s.q)
