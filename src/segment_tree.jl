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
repeat_op(base::Integer, ::Integer, ::typeof(&)) = base
repeat_op(base::Integer, ::Integer, ::typeof(|)) = base

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
    #The stack will be used each time it is required.
    stack::Vector{node_type}
    empty_node::node_type
end
sizeof(X::Segment_tree) = X.size
function Segment_tree(type, size, op::Function, iterated_op::Function, identity)
    size = convert(Int,size)
    head = Segment_tree_node{type, op, iterated_op, identity}()
    empty_node = Segment_tree_node{type, op, iterated_op, identity}()
    stack = Vector(undef,65)
    for i in 1:65
        stack[i] = empty_node
    end
    return Segment_tree{Segment_tree_node{type,op,iterated_op,identity}}(size,head, stack, empty_node)
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



@inline function get_range(X::Segment_tree,low,high)
    
    #The reason this is inlined is because there is only ONE line.
    #This is only a wrapping call to another function which is NOT inlined.
    return get_range(X.head,low,high,1,sizeof(X))
end

@inline function set_range!(X::Segment_tree, low, high, value)
    #Same logic. Wrap the call.
    #The utility memories are here.
    set_range!(get_head(X),low,high,1,sizeof(X), value, X.stack, X.empty_node)
end

get_left_child(X::Segment_tree_node) = X.child_nodes[1]
get_right_child(X::Segment_tree_node) = X.child_nodes[2]
is_terminal(X::Segment_tree_node) = (X.child_nodes===nothing)
function get_range(X::Segment_tree_node, Query_low, Query_high, Current_low, Current_high)
    while true
        if is_terminal(X) #Is the terminal node.
            return get_iterated_op(X)(X.density, Query_high-Query_low+1) 
        end

        Current_mid =get_middle(Current_low,Current_high)
        if Query_high <= Current_mid
            Current_high = Current_mid
            X = get_left_child(X)
        elseif Query_low > Current_mid
            Current_low = Current_mid+1
            X = get_right_child(X)
        else
            return get_op(X)(get_left_range(get_left_child(X), Query_low, Current_low,Current_mid),get_right_range(get_right_child(X),Query_high, Current_mid+1,Current_high))
            #If this branch is taken before the terminal node is reached, it means that there is a "split". 
            #This can split only once. This information avoids excessive checks and recursion.
        end
    end
end

function get_left_range(X::Segment_tree_node, Query_low, Current_low, Current_high)
    answer = get_element_identity(X)
    while true
        if is_terminal(X) #Is the terminal node.
           #Hopefully, this is correct.
           # get operation between the right (previously accumulated answer) and the left (this node)
           return get_op(X)(get_iterated_op(X)(X.density, Current_high-Query_low+1), answer)
        end

        Current_mid = get_middle(Current_low,Current_high)
        if Query_low > Current_mid
            Current_low = Current_mid+1
            X = get_right_child(X)
        else
            #answer = get_op(X)(answer,get_entire_range(get_right_child(X, Current_high-Current_mid))) (Except that the 2nd argument wasn't needed.)
            answer = get_op(X)(answer,get_entire_range(get_right_child(X)))
            Current_high = Current_mid
            X = get_left_child(X)
        end
    end
        
end

function get_right_range(X::Segment_tree_node, Query_high, Current_low,Current_high)
    answer = get_element_identity(X)
    while true
        if is_terminal(X) #Is the terminal node.
            return get_op(X)(answer,get_iterated_op(X)(X.density, Query_high-Current_low+1))
        end

        Current_mid = get_middle(Current_low,Current_high)
        if Query_high <= Current_mid
            Current_high = Current_mid
            X = get_left_child(X)
        else
            #Same logic.
            answer = get_op(X)(get_entire_range(get_left_child(X)), answer)
            Current_low = Current_mid+1
            X = get_right_child(X)
        end
    end
end

@inline function get_entire_range(X::Segment_tree_node)
    return X.value
end

#=
Plan: 

set_range!.
set_left_range!.
set_right_range!
construct_children!
construct_left_children!
construct_right_children!
=#

function set_range!(X::Segment_tree_node, Query_low, Query_high, Current_low, Current_high, value, stack, empty_node)
    #Working in progress.
    while true
        if is_terminal(X)
            #Do something about it to set the range correctly.
            #Perhaps construct empty segment tree nodes?
            construct_children!(X, Query_low, Query_high, Current_low, Current_high, value)
            #Next, we need to recompute the entire stack.
            #Working in progress.
            error("Working in progress.")


            return
        end

        Current_mid = get_middle(Current_low,Current_high)
        if Query_high <= Current_mid
            Current_high = Current_mid
            X = get_left_child(X)
        elseif Query_low > Current_mid
            Current_low = Current_mid+1
            X = get_right_child(X)
        else
            #Time to set left range and set right range.
            set_left_range!(get_left_child(X), Query_low, Current_low, Current_mid, value, stack, empty_node)
            set_right_range!(get_right_child, Query_high, Current_mid+1, Current_high, value, stack, empty_node)
            #recompute the entire stack. The same way as above.
            error("Working in progress.")
            #Working in progress.
        end

    end
end



function set_left_range!(X::Segment_tree_node, Query_low, Current_low, Current_high, value, stack, empty_node)
    
end

function set_right_range!(X::Segment_tree_node, Query_high, Current_low, Current_high, value, stack, empty_node)
    
end

function construct_children!(X::T, Query_low, Query_high, Current_low, Current_high, value, stack, empty_node) where {T<:Segment_tree_node}
    left = T(nothing, get_element_identity(X), get_element_identity(X))
    right = T(nothing, get_element_identity(X), get_element_identity(X))
    X.child_nodes = (left,right)
end

#=
function propagate_density!(X::Segment_tree_node)
    get_left_child(X).density = get_right_child(X).density
end
=#