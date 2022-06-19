#=
Author: Alice Roselia.
It should be made available as part of the (MIT-licensed) Datastructures.jl package.
Feel free to use or extend this code.
=#


#=
Note from the author: This has only barely touched the surface of its capability.
For example, amortizing run-time costs would allow certain operations to happen on a specially initialized segment tree.
Moreover, if the density is propagated at every step, and the underlying type has commutative property, additive would be possible.
There are also 2d variants (Segment tree whose nodes are themselves segment tree) and so on.
These are complicated.
This is the crown jewel of competitive programming solving many challenging problems. The author tries to bring it out to the wider world
to bring it to the full potential.

This code may be better optimized than code with explicit recursion found in many competitive programming codes, but it may still lacks many 
good optimizations such as unrolling small leaves into a single array and so on.

Let us bring the full potential out of this surprisingly general set of algortihm.
Knowledge of abstract algebra should be put to use.
=#

#To test this package.
#cd("Data_structure")
#(package) activate .



#=
TODO: Consider adding cases of equal as a separate case.
=#

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
    head.value = head.density = identity
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
        #If this new decision pass, compare Query_low with Current_mid+1.
        #3 cases. Exact overlap, partial overlap, and no overlap. 
        
        Current_mid = get_middle(Current_low,Current_high)
        decision_boundary = Current_mid+1
        if Query_low > decision_boundary
            #Current_low = Current_mid+1 This is equivalent.
            Current_low = decision_boundary
            X = get_right_child(X)
        elseif Query_low == decision_boundary
            #Wait a bit.
            return get_op(X)(answer,get_entire_range(get_right_child(X)))
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
        decision_boundary = Current_mid
        #We write logics about variables. Let the compiler micro-optimize the registries.
        if Query_high < decision_boundary
            Current_high = decision_boundary
            X = get_left_child(X)
        elseif Query_high == decision_boundary
            return get_op(X)(get_entire_range(get_left_child(X)), answer)
        else
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
function reconstruct_stack!(stack, empty_node, stack_begin, stack_end)
    for i in stack_end:-1:stack_begin
        node = stack[i]
        node.value = get_op(node)(get_left_child(node).value,get_right_child(node).value)
        stack[i] = empty_node
    end
end


function set_range!(X::Segment_tree_node, Query_low, Query_high, Current_low, Current_high, value, stack, empty_node)
    #Working in progress.
    stack_top = 1 #The top of the stack where you can change.
    while true
        if is_terminal(X)
            #Do something about it to set the range correctly.
            #Perhaps construct empty segment tree nodes?
            #Push the final into the stack.
            construct_children!(X, Query_low, Query_high, Current_low, Current_high, value, stack, empty_node, stack_top)
            #What to do here? Not sure.

            reconstruct_stack!(stack,empty_node,1,stack_top-1)
            #Next, we need to recompute the entire stack.
            #Please ensure that X is not in the stack. (Since this will be handled separately.)
            #Working in progress.


            return
        end
        stack[stack_top] = X
        stack_top += 1
        Current_mid = get_middle(Current_low,Current_high)
        if Query_high <= Current_mid
            Current_high = Current_mid
            X = get_left_child(X)
        elseif Query_low > Current_mid
            Current_low = Current_mid+1
            X = get_right_child(X)
        else
            #Time to set left range and set right range.
            set_left_range!(get_left_child(X), Query_low, Current_low, Current_mid, value, stack, empty_node, stack_top)
            set_right_range!(get_right_child(X), Query_high, Current_mid+1, Current_high, value, stack, empty_node, stack_top)
            reconstruct_stack!(stack,empty_node,1,stack_top-1)
            #recompute the entire stack. This time with X.
            #Working in progress.
        end

    end
end



function set_left_range!(X::Segment_tree_node, Query_low, Current_low, Current_high, value, stack, empty_node, old_stack_top)
    stack_top = old_stack_top
    while true
        if is_terminal(X) 
            construct_left_children!(X,Query_low,Current_low,Current_high,value,stack,empty_node, stack_top)
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            return
        end
        #Push the stack here?
        stack[stack_top] = X
        stack_top += 1
        Current_mid = get_middle(Current_low,Current_high)
        decision_boundary = Current_mid+1
        if Query_low > decision_boundary
            #Same logic as get_left_range
            Current_low = decision_boundary
            X = get_right_child(X)
        elseif Query_low == decision_boundary
            set_entire_range!(get_right_child(X),Current_high-Current_mid,value)
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            #reconstruct_stack
            return
        else
            #Do something here?
            #Set range using Range and value.
            set_entire_range!(get_right_child(X),Current_high-Current_mid,value)
            Current_high = Current_mid
            X = get_left_child(X)
        end
    end
end

function set_right_range!(X::Segment_tree_node, Query_high, Current_low, Current_high, value, stack, empty_node, old_stack_top)
    stack_top = old_stack_top
    while true
        if is_terminal(X) #Is the terminal node.
            #Same logic.
            construct_right_children!(X,Query_high,Current_low,Current_high,value,stack,empty_node,stack_top)
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            return
        end

        stack[stack_top] = X
        stack_top += 1
        Current_mid = get_middle(Current_low,Current_high)
        decision_boundary = Current_mid
        if Query_high < decision_boundary
            #No need for anything? (Since the rest is out of range.)
            #If Query_high == Current_mid (This means that it is EXACTLY half)
            #Maybe do something else? Maybe end it right here?

            Current_high = Current_mid
            X = get_left_child(X)
        elseif Query_high == decision_boundary
            set_entire_range!(get_left_child(X), Current_mid-Current_low+1, value)
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            #reconstruct_stack
            return
        else
            #Same logic?
            set_entire_range!(get_left_child(X), Current_mid-Current_low+1, value)
            Current_low = Current_mid+1
            X = get_right_child(X)
        end
    end
end

function set_entire_range!(X::Segment_tree_node, range, value)
    X.density = value
    X.value = get_iterated_op(X)(range, value)
    X.child_nodes = nothing
end
function construct_children!(X::T, Query_low, Query_high, Current_low, Current_high, value, stack, empty_node, old_stack_top) where {T<:Segment_tree_node}
    #=
    Supposedly start? 
    Should Implicitly be here.
    left = T(nothing, get_element_identity(X), get_element_identity(X))
    right = T(nothing, get_element_identity(X), get_element_identity(X))
    X.child_nodes = (left,right)
    =#
    stack_top = old_stack_top
    old_density = X.density
    while true
        #old_density = X.density
        stack[stack_top] = X
        stack_top += 1
        Current_mid = get_middle(Current_low,Current_high)
        if Query_high <= Current_mid
            #Construct some children.
            left_child = T()
            right_child = T()
            set_entire_range!(right_child, Current_high-Current_mid+1, old_density)
            X.child_nodes = (left_child, right_child)
            Current_high = Current_mid
            X = get_left_child(X)
        elseif Query_low > Current_mid
            #Construct some children as well.
            
            left_child = T()
            right_child = T()
            set_entire_range!(left_child, Current_mid-Current_low, old_density)
            X.child_nodes = (left_child, right_child)
            Current_low = Current_mid+1
            X = get_right_child(X)
        else
            #Construct left and right children.
            left_child = T()
            right_child = T()
            left_child.density = right_child.density = old_density
            X.child_nodes = (left_child, right_child)
            construct_left_range!(get_left_child(X), Query_low, Current_low, Current_mid, value, stack, empty_node, stack_top)
            construct_right_range!(get_right_child(X), Query_high, Current_mid+1, Current_high, value, stack, empty_node, stack_top)
            reconstruct_stack!(stack,empty_node,1,stack_top-1)
            return
            #recompute the entire stack. This time with X.
        end
    end

    
end

function construct_left_children!(X::T, Query_low, Current_low, Current_high, value, stack, empty_node, old_stack_top) where {T<:Segment_tree_node} 
    stack_top = old_stack_top
    old_density = X.density
    while true
        stack[stack_top] = X
        stack_top += 1
        Current_mid = get_middle(Current_low,Current_high)
        decision_boundary = Current_mid
        if Query_low > decision_boundary
            #Same logic as get_left_range but with new constructed children.
            Current_low = decision_boundary
            #Get new children.
            left_child = T()
            right_child = T()
            set_entire_range!(left_child, Current_mid-Current_low,old_density)
            #The left range is out of range and must be of old density
            X.child_nodes = (left_child,right_child)
            Current_low = Current_mid+1
            X = get_right_child(X)
            #Now, this is happening again.
        elseif Query_low == decision_boundary
            #set_entire_range!(get_right_child(X),Current_high-Current_mid,value)
            #This is a special condition where we can just set both left and right.
            left_child = T()
            right_child = T()
            set_entire_range!(left_child, Current_mid-Current_low,old_density)
            set_entire_range!(right_child, Current_high-Current_mid+1, value)
            X.child_nodes = (left_child,right_child)
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            #reconstruct_stack
            return
        else
            #Do something here?
            #Set range using Range and value.
            left_child = T()
            right_child = T()
            set_entire_range!(right_child, Current_high-Current_mid+1, value)
            Current_high = Current_mid
            X = get_left_child(X)
        end
    end
end
function construct_right_children!(X::T, Query_high, Current_low, Current_high, value, stack, empty_node, old_stack_top) where {T<:Segment_tree_node}
    #Something here?
    stack_top = old_stack_top
    old_density = X.density
    while true
        stack[stack_top] = X
        stack_top += 1
        Current_mid = get_middle(Current_low,Current_high)
        decision_boundary = Current_mid
        if Query_high < decision_boundary
            #If Query_high == Current_mid (This means that it is EXACTLY half)
            left_child = T()
            right_child = T()
            set_entire_range!(right_child, Current_high-Current_mid+1, old_density)
            X.child_nodes = (left_child,right_child)
            Current_high = Current_mid
            X = get_left_child(X)
        elseif Query_high == decision_boundary
            left_child = T()
            right_child = T()
            set_entire_range!(left_child, Current_mid-Current_low,value)
            set_entire_range!(right_child, Current_high-Current_mid+1, old_density)
            X.child_nodes = (left_child,right_child)
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            return
        else
            left_child = T()
            right_child = T()
            set_entire_range!(left_child, Current_high-Current_mid+1, value)
            X.child_nodes = (left_child,right_child)
            Current_low = Current_mid+1
            X = get_right_child(X)
        end
    end
end

#=
function propagate_density!(X::Segment_tree_node)
    get_left_child(X).density = get_right_child(X).density
end
=#

