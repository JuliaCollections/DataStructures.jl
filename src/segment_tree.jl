#=
Author: Alice Roselia.
It should be made available as part of the (MIT-licensed) Datastructures.jl package.
Feel free to use or extend this code.
=#

#cd("Data_structure)
#(package) activate .
abstract type Abstractsegmenttreenode{Dtype, Op, iterated_op} end
abstract type Abstractsegmenttree{node_type} end
get_dtype(::Abstractsegmenttreenode{Dtype,Op,iterated_op}) where {Dtype, Op, iterated_op} = Dtype
get_op(::Abstractsegmenttreenode{Dtype,Op,iterated_op}) where {Dtype, Op, iterated_op} = Op
get_iterated_op(::Abstractsegmenttreenode{Dtype,Op,iterated_op}) where {Dtype, Op, iterated_op} = iterated_op


get_middle(low, high) = div(low+high,2)


