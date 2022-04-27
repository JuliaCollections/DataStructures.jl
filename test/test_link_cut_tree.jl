@testset "LinkCutTree" begin

    function attach_left!(v::LinkCutTreeNode, w::LinkCutTreeNode)
        w.left = v
        v.parent = w
    end

    function attach_right!(v::LinkCutTreeNode, w::LinkCutTreeNode)
        w.right = v
        v.parent = w
    end

    @testset "splay!" begin
        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)

            attach_left!(n3, n2)
            attach_right!(n4, n2)
            n2.path_parent = n1

            splay!(n2)

            @test n2.path_parent === n1
            @test n2.left == n3
            @test n2.right == n4
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)

            attach_left!(n3, n2)
            attach_right!(n4, n2)
            n2.path_parent = n1
            attach_left!(n5, n3)
            attach_right!(n6, n3)

            splay!(n3)

            @test  n3.path_parent === n1
            @test  n3.left === n5
            @test  n3.right === n2
            @test  n2.left === n6
            @test  n2.right === n4
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)

            attach_left!(n3, n2)
            attach_right!(n4, n2)
            n2.path_parent = n1
            attach_left!(n5, n4)
            attach_right!(n6, n4)

            splay!(n4)

            @test  n4.path_parent === n1
            @test  n4.left === n2
            @test  n4.right === n6
            @test  n2.left === n3
            @test  n2.right === n5
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)
            n7 = LinkCutTreeNode{Int}(7)
            n8 = LinkCutTreeNode{Int}(8)

            attach_left!(n3, n2)
            attach_right!(n4, n2)
            n2.path_parent = n1
            attach_left!(n5, n3)
            attach_right!(n6, n3)
            attach_left!(n7, n5)
            attach_right!(n8, n5)

            splay!(n5)

            @test  n5.path_parent === n1
            @test  n5.left === n7
            @test  n5.right === n3
            @test  n3.left === n8
            @test  n3.right === n2
            @test  n2.left === n6
            @test  n2.right === n4
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)
            n7 = LinkCutTreeNode{Int}(7)
            n8 = LinkCutTreeNode{Int}(8)

            attach_left!(n3, n2)
            attach_right!(n4, n2)
            n2.path_parent = n1
            attach_left!(n5, n4)
            attach_right!(n6, n4)
            attach_left!(n7, n5)
            attach_right!(n8, n5)

            splay!(n5)

            @test  n5.path_parent === n1
            @test  n5.left === n2
            @test  n5.right === n4
            @test  n2.left === n3
            @test  n2.right === n7
            @test  n4.left === n8
            @test  n4.right === n6
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)
            n7 = LinkCutTreeNode{Int}(7)
            n8 = LinkCutTreeNode{Int}(8)

            attach_left!(n3, n2)
            attach_right!(n4, n2)
            n2.path_parent = n1
            attach_left!(n5, n3)
            attach_right!(n6, n3)
            attach_left!(n7, n6)
            attach_right!(n8, n6)

            splay!(n6)

            @test  n6.path_parent === n1
            @test  n6.left === n3
            @test  n6.right === n2
            @test  n3.left === n5
            @test  n3.right === n7
            @test  n2.left === n8
            @test  n2.right === n4
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)
            n7 = LinkCutTreeNode{Int}(7)
            n8 = LinkCutTreeNode{Int}(8)

            attach_left!(n3, n2)
            attach_right!(n4, n2)
            n2.path_parent = n1
            attach_left!(n5, n4)
            attach_right!(n6, n4)
            attach_left!(n7, n6)
            attach_right!(n8, n6)

            splay!(n6)

            @test  n6.path_parent === n1
            @test  n6.left === n4
            @test  n6.right === n8
            @test  n4.left === n2
            @test  n4.right === n7
            @test  n2.left === n3
            @test  n2.right === n5
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)
            n7 = LinkCutTreeNode{Int}(7)
            n8 = LinkCutTreeNode{Int}(8)
            n9 = LinkCutTreeNode{Int}(9)
            n10 = LinkCutTreeNode{Int}(10)

            attach_left!(n3, n2)
            attach_right!(n4, n2)
            n2.path_parent = n1
            attach_left!(n5, n3)
            attach_right!(n6, n3)
            attach_left!(n7, n5)
            attach_right!(n8, n5)
            attach_left!(n9, n7)
            attach_right!(n10, n7)

            splay!(n7)

            @test  n7.path_parent === n1
            @test  n7.left === n9
            @test  n7.right === n2
            @test  n2.left === n5
            @test  n2.right === n4
            @test  n5.left === n10
            @test  n5.right === n3
            @test  n3.left === n8
            @test  n3.right === n6
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)
            n7 = LinkCutTreeNode{Int}(7)
            n8 = LinkCutTreeNode{Int}(8)
            n9 = LinkCutTreeNode{Int}(9)
            n10 = LinkCutTreeNode{Int}(10)

            attach_left!(n3, n2)
            attach_right!(n4, n2)
            n2.path_parent = n1
            attach_left!(n5, n4)
            attach_right!(n6, n4)
            attach_left!(n7, n6)
            attach_right!(n8, n6)
            attach_left!(n9, n8)
            attach_right!(n10, n8)

            splay!(n8)

            @test  n8.path_parent === n1
            @test  n8.left === n2
            @test  n8.right === n10
            @test  n2.left === n3
            @test  n2.right === n6
            @test  n6.left === n4
            @test  n6.right === n9
            @test  n4.left === n5
            @test  n4.right === n7
        end
    end

    @testset "access!" begin
        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)

            n2.path_parent = n1
            n3.path_parent = n1
            n4.path_parent = n1
            n5.path_parent = n2
            n6.path_parent = n3

            access!(n5)

            @test n5.parent === nothing
            @test n5.path_parent === nothing
            @test n5.right === nothing
            @test n5.left === n2
            @test n2.parent === n5
            @test n2.left === n1
            @test n1.parent === n2
            @test n3.path_parent === n1
            @test n4.path_parent === n1
            @test n6.path_parent === n3
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)

            n2.path_parent = n1
            n3.path_parent = n1
            n4.path_parent = n1
            n5.path_parent = n2
            n6.path_parent = n3

            access!(n2)

            @test n2.parent === nothing
            @test n2.path_parent === nothing
            @test n2.right === nothing
            @test n2.left === n1
            @test n1.parent === n2
            @test n5.path_parent === n2
            @test n3.path_parent === n1
            @test n4.path_parent === n1
            @test n6.path_parent === n3
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)
            n4 = LinkCutTreeNode{Int}(4)
            n5 = LinkCutTreeNode{Int}(5)
            n6 = LinkCutTreeNode{Int}(6)
            n7 = LinkCutTreeNode{Int}(7)

            n2.path_parent = n1
            attach_left!(n1, n3)
            attach_right!(n6, n3)
            n5.path_parent = n2
            n7.path_parent = n1
            attach_left!(n4, n7)

            access!(n5)

            @test n5.parent === nothing
            @test n5.path_parent === nothing
            @test n5.left === n2
            @test n5.right === nothing
            @test n2.left === n1
            @test n3.path_parent === n1
            @test n3.right === n6
            @test n7.path_parent === n1
            @test n7.left === n4
        end
    end

    @testset "link!" begin
        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)

            link!(n2, n1)

            @test n2.left === n1
            @test n1.parent === n2
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)

            n2.path_parent = n1

            @test_throws ArgumentError link!(n2, n1)
        end
    end

    @testset "cut!" begin
        begin
            n1 = LinkCutTreeNode{Int}(1)

            cut!(n1)

            @test  n1.path_parent === nothing
            @test  n1.parent === nothing
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)

            attach_left!(n1, n2)

            cut!(n2)

            @test  n2.path_parent === nothing
            @test  n2.parent === nothing
        end
    end

    @testset "find_root!" begin
        begin
            n1 = LinkCutTreeNode{Int}(1)

            r = find_root!(n1)

            @test r === n1
        end

        begin
            n1 = LinkCutTreeNode{Int}(1)
            n2 = LinkCutTreeNode{Int}(2)
            n3 = LinkCutTreeNode{Int}(3)

            attach_left!(n2, n1)
            attach_left!(n3, n2)

            r = find_root!(n1)

            @test r === n3
        end
    end
end
