using DataStructures
using Base.Test

l1 = nil()
@test length(l1) == 0

l2 = cons(1, l1)
@test length(l2) == 1
@test head(l2) == 1

l3 = list(2, 3)
@test length(l3) == 2
@test head(l3) == 2
@test head(tail(l3)) == 3
@test collect(l3) == [2; 3]

l4 = cat(l1, l2, l3)
@test length(l4) == 3
@test collect(l4) == [1; 2; 3]

l5 = map((x) -> x*2, l4)
@test collect(l5) == [2; 4; 6]

l6 = filter((x) -> x < 6, l5)
@test length(l6) == 2
@test l6.head == 2
@test l6.tail.head == 4

l7 = reverse(l6)
@test length(l7) == 2
@test l7.head == 4
@test l7.tail.head == 2
