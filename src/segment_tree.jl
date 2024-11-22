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

abstract type AbstractSegmentTreeNode{Dtype, Op, iterated_op} end
abstract type Abstractsegmenttree{node_type} end
get_dtype(::AbstractSegmentTreeNode{Dtype,Op,iterated_op}) where {Dtype, Op, iterated_op} = Dtype
get_op(::AbstractSegmentTreeNode{Dtype,Op,iterated_op}) where {Dtype, Op, iterated_op} = Op
get_iterated_op(::AbstractSegmentTreeNode{Dtype,Op,iterated_op}) where {Dtype, Op, iterated_op} = iterated_op


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
repeat_op(base::String, time::Integer, ::typeof(*)) = repeat(base, time)

#I luv multiple dispatch!

#Identity is required.
struct artificial_identity end


get_identity(x,y) = artificial_identity()
get_identity(::Type{T}, ::typeof(+)) where {T<:Number} = zero(T)
get_identity(::Type{T}, ::typeof(*)) where {T<:Number} = one(T)
get_identity(::Type{T}, ::typeof(xor)) where {T<:Integer} = zero(T)
get_identity(::Type{T}, ::typeof(*)) where {T<:String} = ()->""
operation_with_identity(f) = (x,y)-> (x===artificial_identity()) ? y : (y===artificial_identity() ? x : f(x,y))
repeat_op_with_identity(f) = (base,time) -> (base===artificial_identity()) ? artificial_identity() : f(base,time)


mutable struct SegmentTreeNode{Dtype, Op, iterated_op, identity}<:AbstractSegmentTreeNode{Dtype,Op,iterated_op}
    child_nodes::Union{NTuple{2,SegmentTreeNode{Dtype, Op, iterated_op, identity}},Nothing}
    #Either both children are valid or none is valid. 
    value::Dtype
    density::Dtype
    #Implicitly have information about where it represents.
    function SegmentTreeNode{Dtype,Op,iterated_op,identity}() where {Dtype,Op,iterated_op,identity}
        return new{Dtype,Op,iterated_op,identity}(nothing)
    end
end

process_identity(x) = x
process_identity(x::Function) = x()
get_element_identity(::SegmentTreeNode{Dtype, Op, iterated_op, identity}) where {Dtype, Op, iterated_op, identity} = process_identity(identity)


struct SegmentTree{node_type<:AbstractSegmentTreeNode} <: Abstractsegmenttree{node_type}
    size::Int
    head::node_type
    #The stack will be used each time it is required.
    stack::Vector{node_type}
    empty_node::node_type
end
get_head(X::SegmentTree) = X.head
sizeof(X::SegmentTree) = X.size
function SegmentTree(type, size, op::Function, iterated_op::Function, identity)
    #println(type)
    size = convert(Int,size)
    head = SegmentTreeNode{type, op, iterated_op, identity}()
    head.value = head.density = process_identity(identity)
    empty_node = SegmentTreeNode{type, op, iterated_op, identity}()
    stack = Vector(undef,65)
    for i in 1:65
        @inbounds stack[i] = empty_node
    end
    return SegmentTree{SegmentTreeNode{type,op,iterated_op,identity}}(size,head, stack, empty_node)
end

function SegmentTree(type::Type, size, op; iterated_op=nothing, identity=nothing)
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
    return SegmentTree(type,size,new_op,new_iterated_op,new_identity)
end



@inline function get_range(X::SegmentTree,low,high)
    #println("get range called from head from ", low, " to ", high)
    #The reason this is inlined is because there is only ONE line.
    #This is only a wrapping call to another function which is NOT inlined.
    return get_range(X.head,low,high,1,sizeof(X))
end

@inline function set_range!(X::SegmentTree, low, high, value)
    #Same logic. Wrap the call.
    #The utility memories are here.
    #println("Set range called from head from ", low, " to ", high, " setting value to ", value)
    set_range!(get_head(X),low,high,1,sizeof(X), value, X.stack, X.empty_node)
    #println("ending set range query")
end

get_left_child(X::SegmentTreeNode) = X.child_nodes[1]
get_right_child(X::SegmentTreeNode) = X.child_nodes[2]
is_terminal(X::SegmentTreeNode) = (X.child_nodes===nothing)
function get_range(X::SegmentTreeNode, Query_low, Query_high, Current_low, Current_high)
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

function get_left_range(X::SegmentTreeNode, Query_low, Current_low, Current_high)
    #println("get_left_range called from ", Current_low, " to ", Current_high)
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
            #println("Skipping ", Current_low, " to ", Current_mid)
            Current_low = decision_boundary
            
            X = get_right_child(X)
        elseif Query_low == decision_boundary
            #Wait a bit.
            #println("returning")
            return get_op(X)(get_entire_range(get_right_child(X)), answer)
        else
            #answer = get_op(X)(answer,get_entire_range(get_right_child(X, Current_high-Current_mid))) (Except that the 2nd argument wasn't needed.)
            #println("Taking ", Current_mid+1, " to ", Current_high)
            answer = get_op(X)(get_entire_range(get_right_child(X)), answer)
            Current_high = Current_mid
            X = get_left_child(X)
        end
    end
        
end

function get_right_range(X::SegmentTreeNode, Query_high, Current_low,Current_high)
    #println("get_right_range called from ", Current_low, " to ", Current_high)
    answer = get_element_identity(X)
    while true
        if is_terminal(X) #Is the terminal node.
            return get_op(X)(answer,get_iterated_op(X)(X.density, Query_high-Current_low+1))
        end

        Current_mid = get_middle(Current_low,Current_high)
        decision_boundary = Current_mid
        #We write logics about variables. Let the compiler micro-optimize the registries.
        if Query_high < decision_boundary
            #println("Skipping ", Current_mid+1, " to ", Current_high)
            Current_high = decision_boundary
            X = get_left_child(X)
        elseif Query_high == decision_boundary
            #println("returning.")
            return get_op(X)(answer, get_entire_range(get_left_child(X)))
        else
            #println("Taking ", Current_low, " to ", Current_mid)
            answer = get_op(X)(answer, get_entire_range(get_left_child(X)))
            Current_low = Current_mid+1
            X = get_right_child(X)
        end
    end
end

@inline function get_entire_range(X::SegmentTreeNode)
    return X.value
end

function reconstruct_stack!(stack, empty_node, stack_begin, stack_end)
    #println("Debugging: reconstructing stack from ",stack_begin," to ", stack_end)
    for i in stack_end:-1:stack_begin
        @inbounds node = stack[i]
        node.value = get_op(node)(get_left_child(node).value,get_right_child(node).value)
        @inbounds stack[i] = empty_node
    end
end


function set_range!(X::SegmentTreeNode, Query_low, Query_high, Current_low, Current_high, value, stack, empty_node)
    #Working in progress.
    stack_top = 1 #The top of the stack where you can change.
    while true
        if is_terminal(X)
            #Do something about it to set the range correctly.
            #Perhaps construct empty segment tree nodes?
            #Push the final into the stack.
            if(Current_low == Current_high)
                X.density=X.value=value
            else
                construct_children!(X, Query_low, Query_high, Current_low, Current_high, value, stack, empty_node, stack_top)
            end

            
            #What to do here? Not sure.

            reconstruct_stack!(stack,empty_node,1,stack_top-1)
            #Next, we need to recompute the entire stack.
            #Please ensure that X is not in the stack. (Since this will be handled separately.)
            #Working in progress.


            return
        end
        @inbounds stack[stack_top] = X
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
            #Does it work now? IDK.
            return
        end

    end
end



function set_left_range!(X::SegmentTreeNode, Query_low, Current_low, Current_high, value, stack, empty_node, old_stack_top)
    #println("set left range called from ", Current_low, " to ", Current_high)
    stack_top = old_stack_top
    while true



        
        if is_terminal(X) 
            if(Current_low == Current_high)
                X.density=X.value=value
            else
                construct_left_children!(X,Query_low,Current_low,Current_high,value,stack,empty_node, stack_top)
            end
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            return
        end
        #Push the stack here?
        @inbounds stack[stack_top] = X
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

function set_right_range!(X::SegmentTreeNode, Query_high, Current_low, Current_high, value, stack, empty_node, old_stack_top)
    #println("set right range called from ", Current_low, " to ", Current_high)
    stack_top = old_stack_top
    while true
        if is_terminal(X) #Is the terminal node.
            #Same logic.
            if(Current_low == Current_high)
                X.density=X.value=value
            else
                construct_right_children!(X,Query_high,Current_low,Current_high,value,stack,empty_node,stack_top)
            end
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            return
        end

        @inbounds stack[stack_top] = X
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

function set_entire_range!(X::SegmentTreeNode, range, value)
    X.density = value
    X.value = get_iterated_op(X)(value, range)
    X.child_nodes = nothing
end
function construct_children!(X::T, Query_low, Query_high, Current_low, Current_high, value, stack, empty_node, old_stack_top) where {T<:SegmentTreeNode}
    #println("Construct children called from ", Current_low, " to ", Current_high)
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
        @inbounds stack[stack_top] = X
        stack_top += 1
        Current_mid = get_middle(Current_low,Current_high)
        if Query_high <= Current_mid
            #Construct some children.
            left_child = T()
            right_child = T()
            set_entire_range!(right_child, Current_high-Current_mid, old_density)
            X.child_nodes = (left_child, right_child)
            Current_high = Current_mid
            if (Current_low == Current_mid)
                left_child.density = left_child.value = value
                reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
                return
            end
            X = get_left_child(X)
        elseif Query_low > Current_mid
            #Construct some children as well.
            
            left_child = T()
            right_child = T()
            set_entire_range!(left_child, Current_mid-Current_low+1, old_density)
            X.child_nodes = (left_child, right_child)
            Current_low = Current_mid+1
            if (Current_low == Current_high)
                #There is only ONE case now.
                right_child.density = right_child.value = value
                reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
                return
            end

            X = get_right_child(X)

        #elseif Query_low == Current_mid
        #Something is wrong in this line.

        else
            #Construct left and right children.
            left_child = T()
            right_child = T()
            X.child_nodes = (left_child, right_child)
            if (Current_low == Current_mid)
                left_child.density = right_child.density = value
                left_child.value = right_child.value = value
                reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
                return
                
            elseif (Current_mid+1 == Current_high)
                left_child.density = old_density
                construct_left_children!(get_left_child(X), Query_low, Current_low, Current_mid, value, stack, empty_node, stack_top)
                right_child.density = right_child.value = value
                reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
                return
                
            end

            left_child.density = right_child.density = old_density
            
            construct_left_children!(get_left_child(X), Query_low, Current_low, Current_mid, value, stack, empty_node, stack_top)
            construct_right_children!(get_right_child(X), Query_high, Current_mid+1, Current_high, value, stack, empty_node, stack_top)
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            return
            #recompute the entire stack. This time with X.
        end
    end

    
end

function construct_left_children!(X::T, Query_low, Current_low, Current_high, value, stack, empty_node, old_stack_top) where {T<:SegmentTreeNode}
    #println("Construct left children called from ", Current_low, " to ", Current_high)
    stack_top = old_stack_top
    old_density = X.density
    while true
        @inbounds stack[stack_top] = X
        stack_top += 1
        Current_mid = get_middle(Current_low,Current_high)
        decision_boundary = Current_mid+1

        #Case: if Current_low == Current_high
        if Query_low > decision_boundary
            #Same logic as get_left_range but with new constructed children.
            
            #Get new children.
            left_child = T()
            right_child = T()
            set_entire_range!(left_child, Current_mid-Current_low+1,old_density)
            Current_low = decision_boundary
            #The left range is out of range and must be of old density
            X.child_nodes = (left_child,right_child)
            #Current_low = Current_mid+1
            X = get_right_child(X)
            #Now, this is happening again.
        elseif Query_low == decision_boundary
            #set_entire_range!(get_right_child(X),Current_high-Current_mid,value)
            #This is a special condition where we can just set both left and right.
            left_child = T()
            right_child = T()
            set_entire_range!(left_child, Current_mid-Current_low+1,old_density)
            set_entire_range!(right_child, Current_high-Current_mid, value)
            X.child_nodes = (left_child,right_child)
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            #reconstruct_stack
            return
        else
            #Do something here?
            #Set range using Range and value.
            left_child = T()
            right_child = T()
            set_entire_range!(right_child, Current_high-Current_mid, value)
            X.child_nodes = (left_child,right_child)
            Current_high = Current_mid
            if(Current_low == Current_mid)
                #=
                if (Current_low == Current_high)
                    X.child_nodes = nothing
                    X.density = X.value = value
                    stack[stack_top-1] = empty_node
                    reconstruct_stack!(stack, empty_node, old_stack_top, stack_top-2)
                    return
                end
                =#
                left_child.density = left_child.value = value
                reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
                return
            end


            X = get_left_child(X)
        end
    end
end
function construct_right_children!(X::T, Query_high, Current_low, Current_high, value, stack, empty_node, old_stack_top) where {T<:SegmentTreeNode}
    #println("Construct right children called from ", Current_low, " to ", Current_high)
    #Something here?
    stack_top = old_stack_top
    old_density = X.density
    while true
        @inbounds stack[stack_top] = X
        stack_top += 1
        Current_mid = get_middle(Current_low,Current_high)
        decision_boundary = Current_mid
        if Query_high < decision_boundary
            #If Query_high == Current_mid (This means that it is EXACTLY half)
            left_child = T()
            right_child = T()
            set_entire_range!(right_child, Current_high-Current_mid, old_density)
            X.child_nodes = (left_child,right_child)
            Current_high = Current_mid
            X = get_left_child(X)
        elseif Query_high == decision_boundary

            if (Current_low == Current_high)
                @inbounds stack[stack_top] = empty_node
                stack_top -= 1
                X.value = X.density = value
                reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
                return
            end


            left_child = T()
            right_child = T()
            set_entire_range!(left_child, Current_mid-Current_low+1,value)
            set_entire_range!(right_child, Current_high-Current_mid, old_density)
            X.child_nodes = (left_child,right_child)
            reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
            return
        else
            left_child = T()
            right_child = T()
            set_entire_range!(left_child, Current_mid-Current_low+1, value)
            X.child_nodes = (left_child,right_child)
            
            if (Current_low == Current_mid)
                #=
                if (Current_low == Current_high)
                    X.child_nodes = nothing
                    X.density = X.value = value
                    stack[stack_top-1] = empty_node
                    reconstruct_stack!(stack, empty_node, old_stack_top, stack_top-2)
                    return
                end
                =#
                right_child.density = right_child.value = value
                reconstruct_stack!(stack,empty_node,old_stack_top,stack_top-1)
                return
            end
            Current_low = Current_mid+1
            X = get_right_child(X)
        end
    end
end

#=
function propagate_density!(X::SegmentTreeNode)
    get_left_child(X).density = get_right_child(X).density
end
=#


function debug_print(X::SegmentTree)
    println("Debug printing: ",1,"-",sizeof(X))
    debug_print(X.head, 1, 1, sizeof(X))
    println("end debug print")
end

function debug_print(X::SegmentTreeNode, indent, low, high)
    println(repeat("  ", indent),"value: ", X.value)
    if is_terminal(X)
        println(repeat("  ", indent),"density: ", X.density)
    else
        middle = get_middle(low,high)
        println(repeat("  ", indent),"left: ",low,"-",middle)
        debug_print(get_left_child(X), indent+1, low, middle)
        println(repeat("  ", indent),"right: ",middle+1,"-",high)
        debug_print(get_right_child(X), indent+1, middle+1, high)
        println(repeat("  ", indent),"end")
    end
end

function check_consistency(X::SegmentTree)
    consistency = check_consistency(X.head, 1, sizeof(X))
    if (!consistency)
        println("This segment tree is currently not consistent with the invariant:.")
        #debug_print(X)
    end
    return consistency
end

function check_consistency(X::SegmentTreeNode, low, high)
    if is_terminal(X)
        return low <= high && get_iterated_op(X)(X.density,high-low+1) == X.value
    else
        middle = get_middle(low,high)
        return (check_consistency(get_left_child(X),low,middle) 
        && check_consistency(get_right_child(X), middle+1, high) && 
        X.value == get_op(X)(get_left_child(X).value, get_right_child(X).value)
        )
    end
end