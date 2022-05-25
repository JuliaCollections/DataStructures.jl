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

function repeat_op(base,time::Integer, op::Function)
    #Hopefully segment tree not larger than 64. Otherwise, big number segment tree may be needed.
    Iterations = convert(UInt,time)
    #Find trailing zeros.
    baseline = base
    for i in 1:trailing_zeros(Iterations)
        baseline = op(baseline,baseline)
    end
    Iterations = Iterations>>trailing_zeros(Iterations)
    
    #Operate to get to the baseline.
    #baseline = #Working in progress.
    
    #Then, you can iterate.
    final_value = baseline
    while (Iterations!=0)
        Iterations>>=1
        baseline = op(baseline,baseline)
        if isodd(Iterations)
            final_value = op(final_value,baseline)
        end
    end
    #Something

    
    return final_value
end

#Specialized cases for repeat_op.

repeat_op(base::Number, time::Integer, ::typeof(+)) = base*time
repeat_op(base::Number, time::Integer, ::typeof(*)) = base^time
repeat_op(base::T, time::Integer, ::typeof(xor)) where {T<:Integer} = iseven(time) ? zero(T) : base
repeat_op(base::T, ::Integer, ::typeof(&)) = base
repeat_op(base::T, ::Integer, ::typeof(|)) = base

#I luv multiple dispatch!

#Identity is required.
struct artificial_identity end


get_identity(x,y) = artificial_identity()
get_identity(::Type{T}, ::typeof(+)) where {T<:Number} = zero(T)
get_identity(::Type{T}, ::typeof(*)) where {T<:Number} = one(T)
operation_with_identity(f) = (x,y)-> (x===artificial_identity()) ? y : (y===artificial_identity() ? x : f(x,y))
repeat_op_with_identity(f) = (base,time) -> (base===artificial_identity()) ? artificial_identity() : f(base,time)


mutable struct Segment_tree_node{Dtype, Op, iterated_op, identity}<:Abstractsegmenttreenode{Dtype,Op,iterated_op}
    child_nodes::Union{NTuple{2,Segment_tree_node{Dtype, Op, iterated_op, identity}},Nothing}
    #Either both children are valid or none is valid. 
    value::Dtype
    density::Dtype
    #Implicitly have information about where it represents.
    function Segment_tree_node{Dtype,Op,iterated_op,identity}() where {Dtype,Op,iterated_op,identity}
        return new{Dtype,Op,iterated_op,identity}(nothing)
    end
end
get_element_identity(::Segment_tree_node{Dtype, Op, iterated_op, identity}) where {Dtype, Op, iterated_op, identity} = identity

struct Segment_tree{node_type<:Abstractsegmenttreenode} <: Abstractsegmenttree{node_type}
    size::Int
    head::node_type
end
function Segment_tree(type, size, op::Function, iterated_op::Function, identity)
    size = convert(Int,size)
    head = Segment_tree_node{type, op, iterated_op, identity}()
    return Segment_tree{Segment_tree_node{type,op,iterated_op,identity}}(size,head)
end

function Segment_tree(type::Type, size, op; iterated_op=nothing, identity=nothing)
    #A bit annoying but local scope must take place.
    new_op = op
    if iterated_op===nothing
        new_iterated_op = (x,y)->repeat_op(x,y,op)
    else
        new_iterated_op = iterated_op
    end
    if identity === nothing
        new_identity = get_identity(type,op)
        if new_identity === artificial_identity()
            type = Union{type,artificial_identity}
            new_op = operation_with_identity(op)
            new_iterated_op = repeat_op_with_identity(new_iterated_op)
        end
    else
        new_identity = identity
    end
    return Segment_tree(type,size,new_op,new_iterated_op,new_identity)
end