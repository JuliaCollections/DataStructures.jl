# by JMW

function unquote(e::Expr)
    @assert e.head == :quote
    return e.args[1]
end

function unquote(e::QuoteNode)
    return e.value
end

const _arities = Dict(
    :get => 3,
    :get! => 3,
)

_argsig(funcname) =
    if haskey(_arities, funcname)
        :(args::Vararg{<:Any, $(_arities[funcname] - 1)})
    else
        :(args::Vararg)
    end

macro delegate(source, targets)
    typename = esc(source.args[1])
    fieldname = unquote(source.args[2])
    funcnames = targets.args
    n = length(funcnames)
    fdefs = Vector{Any}(undef, n)
    for i in 1:n
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typename), $(_argsig(funcnames[i]))) =
                       ($funcname)(a.$fieldname, args...)
                   end
    end
    return Expr(:block, fdefs...)
end

macro delegate_return_parent(source, targets)
    typename = esc(source.args[1])
    fieldname = unquote(source.args[2])
    funcnames = targets.args
    n = length(funcnames)
    fdefs = Vector{Any}(undef, n)
    for i in 1:n
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typename), $(_argsig(funcnames[i]))) =
                       (($funcname)(a.$fieldname, args...); a)
                   end
    end
    return Expr(:block, fdefs...)
end
