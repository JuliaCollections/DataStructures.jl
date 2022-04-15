#=
Author: Alice Roselia.
It should be made available as part of the (MIT-licensed) Datastructures.jl package.
Feel free to use or extend this code.
=#

#cd("Data_structure)
#(package) activate .



abstract type Abstractsegmenttreenode{Dtype, Op, iterated_op} end
abstract type Abstractsegmenttree{node_type} end
Standard_Field = Union{Real, Complex}
#=
Segment trees have the following traits.
1) can_add_range: either Val{True} or Val{False}.
2) can_change_range: either Val{True} or Val{False}. 
3) is_functional: either Val{True} or Val{False}

Dispatching will have "valid". Dispatching for invalid would be error.
=#
can_add_range(::Abstractsegmenttree)= false;
can_change_range(::Abstractsegmenttree) = true;
is_functional(::Abstractsegmenttree) = false;
#Convenience so you don't have to use arguments every time.
get_dtype(::Abstractsegmenttreenode{Dtype,Op,iterated_op}) where {Dtype, Op, iterated_op} = Dtype
get_op(::Abstractsegmenttreenode{Dtype,Op,iterated_op}) where {Dtype, Op, iterated_op} = Op
get_iterated_op(::Abstractsegmenttreenode{Dtype,Op,iterated_op}) where {Dtype, Op, iterated_op} = iterated_op


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



mutable struct Segment_tree{node_type<:Abstractsegmenttreenode}<:Abstractsegmenttree{node_type}
    size::UInt64
    head::node_type
end
function Segment_tree(size::Number,Dtype::Type,op::Function, iterated_op::Function)
    newsize = convert(UInt64,size)
    node_type = Segment_tree_node{Dtype,op,iterated_op}
    return Segment_tree{node_type}(newsize, node_type())
end

sizeof(X::Abstractsegmenttree) = X.size
get_head(X::Abstractsegmenttree) = X.head
Segment_tree(size::Number, T::Type, op::Function) = Segment_tree(size, T, op, (x,y)->repeat_op(x,y,op))
Segment_tree(size::Number,::Type{T}, ::typeof(+)) where {T<:Standard_Field} = Segment_tree(size,T,+,*)
Segment_tree(size::Number,::Type{Array{T,N}}, ::typeof(+)) where {T<:Standard_Field,N} = Segment_tree(size,Array{T,N},+,*)
Segment_tree(size::Number,::Type{T}, ::typeof(*)) where {T<:Standard_Field} = Segment_tree(size,T,*,^)
Segment_tree(size::Number,::Type{Array{T,N}}, ::typeof(*)) where {T<:Standard_Field,N} = Segment_tree(size,Array{T,N},*,^)

struct functional_segment_tree{node_type<:Abstractsegmenttreenode}<:Abstractsegmenttree{node_type}
    size::UInt64
    head::node_type
end
is_functional(functional_segment_tree) = true


mutable struct Segment_tree_node{Dtype, Op, iterated_op, identity}<:Abstractsegmenttreenode{Dtype,Op,iterated_op}
    child_nodes::Union{NTuple{2,Segment_tree_node{Dtype, Op, iterated_op, identity}},Nothing}
    #Either both children are valid or none is valid. 
    value::Dtype
    density::Dtype
    #Implicitly have information about where it represents.
    function Segment_tree_node()
        return new(nothing)
    end
end

mutable struct Segment_tree_node_without_identity{Dtype,Op,iterated_op}<:Abstractsegmenttreenode{Dtype,Op,iterated_op}
    child_nodes::Union{NTuple{2,Segment_tree_node_without_identity{Dtype, Op, iterated_op}},Nothing}
    #Either both children are valid or none is valid. 
    #This variant will throw an error instead of returning an identity.
    #This is not very recommended, as complexity is required to bypass this.
    value::Union{Dtype,Nothing}
    density::Union{Dtype,Nothing}
    function Segment_tree_node_without_identity()
        return new(nothing)
    end
end



function Segment_tree_node(Dtype::Type{T}, Op::Function, iterated_op::Function, identity::T)
    return Segment_tree_node{Dtype,Op,iterated_op,identity}()
end

get_identity(X,op::Function) = get_identity(typeof(X),op)
get_identity(::Type,::Function) = nothing
get_identity(::Type{X},typeof(+)) where {X<:Standard_Field} = zero(X)
get_identity(::Type{X},typeof(*)) where {X<:Standard_Field} = one(X)
function Segment_tree_node(Dtype::Type, Op::Function, iterated_op::Function)
    if get_identity(Dtype,Op) isa Nothing
        #Consider this solution.
        #Workaround_op(x,y) = ifelse(x==nothing, y, ifelse(y==nothing,x,Op(x,y)))
        #Workaround_iterated_op(x,y) = ifelse(x==nothing, nothing, iterated_op(x,y))
        return Segment_tree_node_without_identity{Dtype,Op,iterated_op}()
    else
        return Segment_tree_node{Dtype,Op,iterated_op,get_identity(Dtype,Op)}()
    end
end
get_element_identity(::Segment_tree_node{Dtype, Op, iterated_op, identity}) where {Dtype, Op, iterated_op, identity} = identity
get_element_identity(::Segment_tree_node_without_identity) = nothing

Standard_Segment_tree_node = Union{Segment_tree_node,Segment_tree_node_without_identity} #Standard meaning not every Segment_tree_node has this.
#TODO: consider refactoring this into its abstract type instead of as union.

get_left_child(X::Standard_Segment_tree_node) = X.child_nodes[1]
get_right_child(X::Standard_Segment_tree_node) = X.child_nodes[2]



function get_range(X::Abstractsegmenttree, low, high)
    # get the reduce(Op, X[i] for all low<=i<=high)
    return get_range(get_head(X),low,high, 1, sizeof(X))
end




#Implement get_op, get_iterated_op, etc...

function get_range(X::Standard_Segment_tree_node, Query_low, Query_high, Current_low, Current_high)
    
    #while the tree is still not at splitting point
        #if on low 
            #Go down low path.
        #else
            #Go down high path.
        #end
    #end
    #Split into two functions, ones where you only care about prefix, and the other where you only care about suffix.
    while true
        if X.child_nodes == nothing
            return get_iterated_op(X)(X.density, Query_high-Query_low+1) 
        end

        Current_mid = div(Current_low+Current_high,2)
        if Query_high <= Current_mid
            Current_high = Current_mid
            X = get_left_child(X)
        else if Query_low > Current_mid
            Current_low = Current_mid+1
            X = get_right_child(X)
        else
            return get_op(X)(get_left_range(get_left_child(X), Query_low, Current_low),get_right_range(get_right_child(X,Query_high, Current_high)))
            #Working in progress.
        end

    end
end

function get_entire_range(X::Standard_Segment_tree_node, range)
    #Working in progress.
    if X.child_nodes == nothing
        return get_iterated_op(X)(X.density, range)
    else
        return X.value
    end
end

function get_left_range(X::Standard_Segment_tree_node, Query_low, Current_low, Current_high)
    answer = get_element_identity(X)
    while true
        if X.child_nodes == nothing
            return get_op(X)(get_iterated_op(X)(X.density, Current_high-Query_low+1), answer)
        end

        Current_mid = div(Current_low+Current_high,2)
        if Query_low > Current_mid
            Current_low = Current_mid+1
            X = get_right_child(X)
        else
            answer = get_op(X)(answer,get_entire_range(get_right_child(X, Current_high-Current_mid)))
            Current_high = Current_mid
            X = get_left_child(X)
        end
        #Working in progress.
    end
        
end

function get_right_range(X::Standard_Segment_tree_node, Query_high, Current_low,Current_high)
    answer = get_element_identity(X)
    while true
        if X.child_nodes == nothing
            return 
        end

        Current_mid = div(Current_low+Current_high,2)
        if #
        else

        end
        #Working in progress.
    end
end
