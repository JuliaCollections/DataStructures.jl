module Tokens

import Base.isless
import Base.isequal
import Base.colon

abstract AbstractSemiToken

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
deref_key(i::Token) = nothing
deref_value(i::Token) = nothing
deref(i::Token) = nothing
status(i::Token) = nothing
delete!(i::Token) = nothing
advance(i::Token) = nothing
regress(i::Token) = nothing
isless(i::Token, j::Token) = nothing
isequal(i::Token, j::Token) = nothing
colon(i::Token, j::Token) = nothing


export semi, container, assemble, deref_key, deref_value
export deref, status, delete!, advance, regress

end
