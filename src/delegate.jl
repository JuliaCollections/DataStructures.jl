# by JMW
macro delegate(source, fieldname, targets)
    typename = esc(source)
    funcnames = targets.args
    n = length(funcnames)
    fdefs = Vector{Any}(n)
    for i in 1:n
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typename), args...) =
                       ($funcname)(a.$fieldname, args...)
                   end
    end
    return Expr(:block, fdefs...)
end

macro delegate_return_parent(source, fieldname, targets)
    typename = esc(source)
    funcnames = targets.args
    n = length(funcnames)
    fdefs = Vector{Any}(n)
    for i in 1:n
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typename), args...) =
                       (($funcname)(a.$fieldname, args...); a)
                   end
    end
    return Expr(:block, fdefs...)
end
