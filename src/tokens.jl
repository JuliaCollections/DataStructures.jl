## Token interface to a container.  A token is the address
## of an item in a container.  The token has two parts: the
## container and the item's address.  The address is of type
## AbstractSemiToken.


module Tokens

using Compat

@compat abstract type AbstractSemiToken end

immutable IntSemiToken <: AbstractSemiToken
    address::Int
end

end
