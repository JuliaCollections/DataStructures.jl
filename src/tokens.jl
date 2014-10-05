module Tokens

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
status(i::Token) = 0

export semi, container, assemble, status

end
