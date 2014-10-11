module Tokens

abstract AbstractSemiToken
import Base.getindex
import Base.setindex!
import Base.isless
import Base.isequal
import Base.colon

immutable IntSemiToken <: AbstractSemiToken
    address::Int
end

immutable Token{T, S <: AbstractSemiToken}
    container::T
    semitoken::S
end


semi(i::Token) = i.semitoken
container(i::Token) = i.container
assemble(m, s::AbstractSemiToken) = Token(m,s)
deref_key(i::Token) = error("undefined operation")
deref_value(i::Token) = error("undefined operation")
deref(i::Token) = error("undefined operation")
status(i::Token) = error("undefined operation")
getindex(m, i::AbstractSemiToken) = error("undefined operation")
settindex!(m, i::AbstractSemiToken) = error("undefined operation")
delete!(i::Token) = error("undefined operation")
advance(i::Token) = error("undefined operation")
regress(i::Token) = error("undefined operation")
isless(i::Token, j::Token) = error("undefined operation")
isequal(i::Token, j::Token) = error("undefined operation")
colon(i::Token, j::Token) = error("undefined operation")


export semi, container, assemble, deref_key, deref_value
export deref, status, delete!, advance, regress

end
