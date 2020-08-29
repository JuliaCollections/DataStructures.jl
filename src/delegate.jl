# by JMW

function unquote(e::Expr)
    @assert e.head == :quote
    return e.args[1]
end

function unquote(e::QuoteNode)
    return e.value
end

macro delegate(source::Expr, targets::Expr)
    typename = esc(source.args[1])
    fieldname = unquote(source.args[2])
    funcnames = targets.args
    n = length(funcnames)
    fdefs = Vector{Any}(undef, n)
    for i in 1:n
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typename), args...) =
                       ($funcname)(a.$fieldname, args...)
                   end
    end
    return Expr(:block, fdefs...)
end

macro delegate_return_parent(source::Expr, targets::Expr)
    typename = esc(source.args[1])
    fieldname = unquote(source.args[2])
    funcnames = targets.args
    n = length(funcnames)
    fdefs = Vector{Any}(undef, n)
    for i in 1:n
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typename), args...) =
                       (($funcname)(a.$fieldname, args...); a)
                   end
    end
    return Expr(:block, fdefs...)
end
