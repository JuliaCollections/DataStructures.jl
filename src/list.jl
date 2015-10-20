abstract LinkedList{T}

type Nil{T} <: LinkedList{T}
end

type Cons{T} <: LinkedList{T}
    head::T
    tail::LinkedList{T}
end

cons{T}(h, t::LinkedList{T}) = Cons{T}(h, t)

nil(T) = Nil{T}()
nil() = nil(Any)

head(x::Cons) = x.head
tail(x::Cons) = x.tail

==(x::Nil, y::Nil) = true
==(x::Cons, y::Cons) = (x.head == y.head) && (x.tail == y.tail)

function show{T}(io::IO, l::LinkedList{T})
    if isa(l,Nil)
        if is(T,Any)
            print(io, "nil()")
        else
            print(io, "nil(", T, ")")
        end
    else
        print(io, "list(")
        show(io, head(l))
        for t in tail(l)
            print(io, ", ")
            show(io, t)
        end
        print(io, ")")
    end
end

list() = nil()

function list(elts...)
    l = nil()
    for i=length(elts):-1:1
        l = cons(elts[i],l)
    end
    return l
end

function list{T}(elts::T...)
    l = nil(T)
    for i=length(elts):-1:1
        l = cons(elts[i],l)
    end
    return l
end

length(l::Nil) = 0

function length(l::Cons)
    n = 0
    for i in l
        n += 1
    end
    n
end

map(f::Base.Callable, l::Nil) = l

function map(f::Base.Callable, l::Cons)
    first = f(l.head)
    l2 = cons(first, nil(typeof(first)))
    for h in l.tail
        l2 = cons(f(h), l2)
    end
    reverse(l2)
end

function filter{T}(f::Function, l::LinkedList{T})
    l2 = nil(T)
    for h in l
        if f(h)
            l2 = cons(h, l2)
        end
    end
    reverse(l2)
end

function reverse{T}(l::LinkedList{T})
    l2 = nil(T)
    for h in l
        l2 = cons(h, l2)
    end
    l2
end

copy(l::Nil) = l

function copy(l::Cons)
    l2 = reverse(reverse(l))
end

cat(lst::LinkedList) = lst

function cat(lst::LinkedList, lsts::LinkedList...)
    T = typeof(lst).parameters[1]
    n = length(lsts)
    for i = 1:n
        T2 = typeof(lsts[i]).parameters[1]
        T = typejoin(T, T2)
    end

    l2 = nil(T)
    for h in lst
        l2 = cons(h, l2)
    end

    for i = 1:n
        for h in lsts[i]
            l2 = cons(h, l2)
        end
    end

    reverse(l2)
end

start{T}(l::Nil{T}) = l
start{T}(l::Cons{T}) = l
done{T}(l::Cons{T}, state::Cons{T}) = false
done{T}(l::LinkedList, state::Nil{T}) = true
next{T}(l::Cons{T}, state::Cons{T}) = (state.head, state.tail)
