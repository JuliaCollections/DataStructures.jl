## Token interface to a container.  A token is the address
## of an item in a container.  The token has two parts: the
## container and the item's address.  The address is of type
## AbstractSemiToken.  


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


## The following two operations extract the two parts of a token.
semi(i::Token) = i.semitoken
container(i::Token) = i.container

## This operation puts a token together from its parts.
assemble(m, s::AbstractSemiToken) = Token(m,s)

## The remaining functions operate on the container
## data via the token.  They are undefined (i.e., return
## nothing) at this abstract level.  It is up to
## specific implementations to define them.

## Return a key indexed by a token.
deref_key(i::Token) = nothing

## Return a value indexed by a token.
deref_value(i::Token) = nothing

## Return a key-value pair indexed by a token.
deref(i::Token) = nothing

## Return the status of a token (is it valid)
status(i::Token) = nothing

## Delete the item addressed by a token.
delete!(i::Token) = nothing

## Advance the token (return a new token) to the
## next item in the container.
advance(i::Token) = nothing


## Regress the token (return a new token) to the
## previous item in the container.
regress(i::Token) = nothing

## Compare tokens
isless(i::Token, j::Token) = nothing
isequal(i::Token, j::Token) = nothing

## Index a range of a container using a start/end
## token pair.  The colon operator is inclusive;
## the excludelast operation excludes the end token.
colon(i::Token, j::Token) = nothing
excludelast(i::Token, j::Token) = nothing


export semi, container, assemble, deref_key, deref_value
export deref, status, delete!, advance, regress
export excludelast

end
