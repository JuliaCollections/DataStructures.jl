
using Base.Meta

export @dcompat

function rewrite_ordereddict(ex)
    length(ex.args) == 1 && return ex

    f = ex.args[1]

    args = Any[]
    for i = 2:length(ex.args)
        pair = ex.args[i]
        !isexpr(pair, :(=>)) && return ex
        push!(args, tuple(pair.args...))
    end
    newex = Expr(:call, f, tuple(args...))

    newex
end

function _compat(ex::Expr)
    if ex.head == :call
        f = ex.args[1]
        if VERSION < v"0.4.0-dev+980" && (f == :OrderedDict || (isexpr(f, :curly) && length(f.args) == 3 && f.args[1] == :OrderedDict))
            ex = rewrite_ordereddict(ex)
        end
    end
    return Expr(ex.head, map(_compat, ex.args)...)
end
_compat(ex) = ex

macro dcompat(ex)
    esc(_compat(ex))
end
