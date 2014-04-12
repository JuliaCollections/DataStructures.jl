abstract List{T}

type Nil{T} <: List{T}
end

type Cons{T} <: List{T}
    head::T
    tail::List{T}
end

cons{T}(h, t::List{T}) = Cons{T}(h, t)

nil(T) = Nil{T}()
nil() = nil(Any)

head(x::Cons) = x.head
tail(x::Cons) = x.tail

function show{T}(io::IO, l::List{T})
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
function list{T}(elts::List{T}...)
    l = nil(List{T})
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
map(f::Base.Callable, l::Cons) = cons(f(head(l)), map(f, tail(l)))

copy(l::Nil) = l
copy(l::Cons) = cons(head(l), copy(tail(l)))

function append2(a, b)
    if isa(a,Nil)
        b
    else
        cons(head(a), append2(tail(a), b))
    end
end

cat(lst::List) = lst

function cat(lst::List, lsts...)
    n = length(lsts)
    l = lsts[n]
    for i = (n-1):-1:1
        l = append2(lsts[i], l)
    end
    return append2(lst, l)
end

start{T}(l::Nil{T}) = l
start{T}(l::Cons{T}) = l
done{T}(l::Cons{T}, state::Cons{T}) = false
done{T}(l::List, state::Nil{T}) = true
next{T}(l::Cons{T}, state::Cons{T}) = (state.head, state.tail)
