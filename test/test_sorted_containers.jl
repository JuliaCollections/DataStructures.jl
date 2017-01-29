if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

if VERSION >= v"0.6.0-dev.1765"
    using Primes
end

using DataStructures
import Base.Ordering
import Base.Forward
import Base.Reverse
import DataStructures.eq
import Base.lt
import Base.ForwardOrdering
import Base.ReverseOrdering
import DataStructures.IntSemiToken

immutable CaseInsensitive <: Ordering
end

lt(::CaseInsensitive, a, b) = isless(lowercase(a), lowercase(b))
eq(::CaseInsensitive, a, b) = isequal(lowercase(a), lowercase(b))


@testset "SortedContainers" begin

## Function fulldump dumps the entire tree; helpful for debugging.

function fulldump(t::DataStructures.BalancedTree23)
    thislevstack = Int[]
    rl = t.rootloc
    dpth = t.depth
    push!(thislevstack, rl)
    println("  rootloc = $rl depth = $dpth")
    nextlevstack = Int[]
    levcount = 0
    for mydepth = 1 : dpth
        isleaf = (dpth == mydepth)
        sz = size(thislevstack,1)
        if sz == 0
            break
        end
        levcount += 1
        println("-------------\n------LEVEL $levcount")
        for i = 1 : sz
            ii = thislevstack[i]
            p = t.tree[ii].parent
            sk1 = t.tree[ii].splitkey1
            sk2 = t.tree[ii].splitkey2
            c1 = t.tree[ii].child1
            c2 = t.tree[ii].child2
            c3 = t.tree[ii].child3
            dt = (mydepth == dpth)? "child(data)" : "child(tree)"
            if c3 == 0
                println("ii = $ii splitkey1 = /$sk1/ $dt.1 = $c1 $dt.2 = $c2 parent = $p")
                if !isleaf
                    push!(nextlevstack,c1)
                    push!(nextlevstack,c2)
                end
            else
                println("ii = $ii splitkey1 = /$sk1/ splitkey2 = /$sk2/ $dt.1 = $c1 $dt.2 = $c2 $dt.3 =$c3 parent = $p")
                if !isleaf
                    push!(nextlevstack,c1)
                    push!(nextlevstack,c2)
                    push!(nextlevstack,c3)
                end
            end
        end
        thislevstack = nextlevstack
        nextlevstack = Int[]
    end
    println("----- FREE TREE CELLS -----")
    for i = 1 : size(t.freetreeinds,1)
        println(t.freetreeinds[i])
    end

    println("----- DATA ARRAY ---")
    for j = 1 : size(t.data,1)
        k = t.data[j].k
        d = t.data[j].d
        p = t.data[j].parent
        if j > 2
            println("j = $j k = /$k/ d = /$d/ parent = /$p/")
        else
            println("j = $j (  k = /$k/ d = /$d/ ) parent = /$p/")
        end
    end
    println("----- FREE DATA CELLS -----")
    for i = 1 : size(t.freedatainds,1)
        println(t.freedatainds[i])
    end
end



push_test!(m, k, v) = push!(m, k=>v)



## Function checkcorrectness checks a balanced tree for correctness.

function checkcorrectness{K,D,Ord <: Ordering}(t::DataStructures.BalancedTree23{K,D,Ord},
                                               allowdups=false)
    dsz = size(t.data, 1)
    tsz = size(t.tree, 1)
    r = t.rootloc
    bfstreenodes = Vector{Int}(0)
    tdpth = t.depth
    intree = IntSet()
    levstart = Vector{Int}(tdpth)
    push!(bfstreenodes, r)
    levstart[1] = 1
    push!(intree, r)
    for curdepth = 2 : tdpth
        levstart[curdepth] = size(bfstreenodes, 1) + 1
        for l = levstart[curdepth - 1] : levstart[curdepth] - 1
            anc = bfstreenodes[l]
            c1 = t.tree[anc].child1
            if in(c1, intree)
                println("anc = $anc c1 = $c1")
                throw(ErrorException("Tree contains loops 1"))
            end
            push!(bfstreenodes, c1)
            push!(intree, c1)
            c2 = t.tree[anc].child2
            if in(c2, intree)
                throw(ErrorException("Tree contains loops 2"))
            end
            push!(bfstreenodes, c2)
            push!(intree, c2)
            c3 = t.tree[anc].child3
            if c3 > 0
                if in(c3, intree)
                    throw(ErrorException("Tree contains loops 3"))
                end
                push!(bfstreenodes, c3)
                push!(intree, c3)
            end
        end
    end
    bfstreesize = size(bfstreenodes, 1)
    dataused = IntSet()
    minkeys = Vector{K}(bfstreesize)
    maxkeys = Vector{K}(bfstreesize)
    for s = levstart[tdpth] : bfstreesize
        anc = bfstreenodes[s]
        c1 = t.tree[anc].child1
        if s == levstart[tdpth]
            if c1 != 1
                throw(ErrorException("Leftmost data descendant should be node 1"))
            end
        else
            minkeys[s] = t.data[c1].k
        end
        c2 = t.tree[anc].child2
        c3 = t.tree[anc].child3
        lastchild = c3 > 0? c3 : c2
        if s == bfstreesize
            if lastchild != 2
                throw(ErrorException("Rightmost data descendant should be node 2"))
            end
        else
            maxkeys[s] = t.data[lastchild].k
        end
        if s > levstart[tdpth] &&
            (lt(t.ord, minkeys[s], maxkeys[s - 1]) ||
             (!lt(t.ord, maxkeys[s-1],minkeys[s]) && !allowdups))
            println("tdpth = ", tdpth, " s = ", s,
                    " maxkeys[s-1] = ", maxkeys[s-1],
                    " minkeys[s] = ", minkeys[s])
            throw(ErrorException("Data nodes out of order"))
        end
        if s < bfstreesize || c3 > 0
            if !eq(t.ord, t.tree[anc].splitkey1, t.data[c2].k)
                throw(ErrorException("Splitkey1 of leaf should match key of 2nd child"))
            end
        end
        if s < bfstreesize && c3 > 0
            if !eq(t.ord, t.tree[anc].splitkey2, t.data[c3].k)
                throw(ErrorException("Splitkey2 of leaf should match key of 1st child"))
            end
        end
        if t.data[c1].parent != anc || t.data[c2].parent != anc ||
            (c3 > 0 && t.data[c3].parent != anc)
            println("c1 = $c1 c2 = $c2 c3 = $c3 anc = $anc")
            println("t.data[c1].parent = $(t.data[c1].parent) t.data[c2].parent = $(t.data[c2].parent)")
            if c3 > 0
                println("t.data[c3].parent = $(t.data[c3].parent)")
            end
            throw(ErrorException("Incorrect parent node for data child"))
        end
        push!(dataused, c1)
        push!(dataused, c2)
        if c3 > 0
            push!(dataused, c3)
        end
    end
    for curdepth = tdpth - 1 : -1 : 1
        cp = levstart[curdepth + 1]
        for s = levstart[curdepth] : levstart[curdepth + 1] - 1
            anc = bfstreenodes[s]
            c1 = t.tree[anc].child1
            @assert(c1 == bfstreenodes[cp])
            if s > levstart[curdepth]
                mk1 = minkeys[cp]
            end
            cp += 1
            if t.tree[c1].parent != anc
                throw(ErrorException("Parent/child1 links do not match"))
            end
            c2 = t.tree[anc].child2
            @assert(c2 == bfstreenodes[cp])
            mk2 = minkeys[cp]
            cp += 1
            if t.tree[c2].parent != anc
                throw(ErrorException("Parent/child2 links do not match"))
            end
            c3 = t.tree[anc].child3
            @assert(s == levstart[curdepth] ||
                    lt(t.ord,mk1,mk2) || (!lt(t.ord,mk2,mk1) && allowdups))
            if c3 > 0
                if t.tree[c3].parent != anc
                    throw(ErrorException("Parent/child3 links do not match"))
                end
                mk3 = minkeys[cp]
                cp += 1
                @assert(lt(t.ord,mk2, mk3) ||
                        !lt(t.ord,mk3,mk2) && allowdups)
            end
            if s > levstart[curdepth]
                minkeys[s] = mk1
            end
            if !eq(t.ord, t.tree[anc].splitkey1, mk2)
                throw(ErrorException("Minkey2 not equal to minimum key among descendants of child2"))
            end
            if c3 > 0 && !eq(t.ord, t.tree[anc].splitkey2, mk3)
                throw(ErrorException("Minkey3 not equal to minimum key among descendants of child3"))
            end
        end
    end
    freedata = IntSet()
    for i = 1 : size(t.freedatainds,1)
        fdi = t.freedatainds[i]
        if in(fdi, freedata)
            throw(ErrorException("t.freedatainds has repeated element $i"))
        end
        if fdi < 1 || fdi > dsz
            throw(ErrorException("t.freedatainds entry out of range"))
        end
        push!(freedata, fdi)
    end
    if last(t.useddatacells) > dsz
        throw(ErrorException("t.useddatacells has indices larger than t.data size"))
    end
    for i = 1 : dsz
        if (in(i, dataused) && !in(i, t.useddatacells)) ||
            (!in(i,dataused) && in(i, t.useddatacells))
            throw(ErrorException("Mismatch between actual data cells used and useddatacells array"))
        end
        if (in(i, freedata) && in(i, dataused)) ||
            (!in(i,freedata) && !in(i, dataused))
            throw(ErrorException("Mismatch between t.freedatainds and t.useddatacells"))
        end
    end
    freetree = IntSet()
    for i = 1 : size(t.freetreeinds,1)
        tfi = t.freetreeinds[i]
        if in(tfi, freetree)
            throw(ErrorException("Free tree index repeated twice"))
        end
        if tfi < 1 || tfi > tsz
            throw(ErrorException("Free tree index out of range"))
        end
        push!(freetree, tfi)
    end
    for i = 1 : tsz
        if (!in(i, intree) && !in(i, freetree)) ||
            (in(i, intree) && in(i, freetree))
            throw(ErrorException("Mismatch between t.freetreeinds and actual cells used"))
        end
    end
end


@testset "SortedDictBasic" begin
    # a few basic tests of SortedDict to start
    m1 = SortedDict((Dict{Compat.ASCIIString,Compat.ASCIIString}()), Forward)
    kdarray = ["hello", "jello", "alpha", "beta", "fortune", "random",
               "july", "wednesday"]
    checkcorrectness(m1.bt, false)
    for i = 1 : div(size(kdarray,1), 2)
        k = kdarray[i*2-1]
        d = kdarray[i*2]
        #println("- inserting: k = $k d = $d")
        m1[k] = d
        checkcorrectness(m1.bt, false)
        # fulldump(m1.bt)
    end
    i1 = startof(m1)
    count = 0
    while i1 != pastendsemitoken(m1)
        count += 1
        k,d = deref((m1,i1))
        #println("+ reading: k = $k, d = $d")
        i1 = advance((m1,i1))
        checkcorrectness(m1.bt, false)
    end
    @test count == 4
end

@testset "SortedDictMethods" begin
    # test all methods of SortedDict here except loops
    m0 = SortedDict(Dict{Int, Float64}())
    @test typeof(m0) == SortedDict{Int,Float64,ForwardOrdering}
    m1 = SortedDict(Dict(8=>32.0, 12=>33.1, 6=>18.2))
    @test typeof(m1) == SortedDict{Int,Float64,ForwardOrdering}
    m01 = SortedDict(8=>32.0, 12=>33.1, 6=>18.2)
    @test typeof(m01) == SortedDict{Int,Float64,ForwardOrdering}
    m11 = SortedDict((8=>32.0, 12=>33.1, 6=>18.2))
    @test typeof(m11) == SortedDict{Int,Float64,ForwardOrdering}
    m02 = SortedDict{Int,Float64}()
    @test typeof(m02) == SortedDict{Int,Float64,ForwardOrdering}
    m03 = SortedDict([(1,2.0), (3,4.0), (5,6.0)])
    @test typeof(m03) == SortedDict{Int,Float64,ForwardOrdering}
    m04 = SortedDict{Int,Float64}(Pair[1=>1, 2=>2.0])
    @test typeof(m04) == SortedDict{Int,Float64,ForwardOrdering}
    m05 = SortedDict{Int,Float64}(Reverse, Pair[1=>1, 2=>2.0])
    @test typeof(m05) == SortedDict{Int,Float64,ReverseOrdering{ForwardOrdering}}
    m06a = SortedDict(Pair[1=>2.0, 3=>'a'])
    @test typeof(m06a) == SortedDict{Any,Any,ForwardOrdering}
    m06b = SortedDict([(1,2.0), (3,'a')])
    @test typeof(m06b) == SortedDict{Int,Any,ForwardOrdering}
    m07a = SortedDict(Pair[1.0=>2, 2=>3])
    @test typeof(m07a) == SortedDict{Any,Any,ForwardOrdering}
    m07b = SortedDict([(1.0,2), (2,3)])
    @test typeof(m07b) == SortedDict{Real,Int,ForwardOrdering}
    m08a = SortedDict(Pair[1.0=>2, 2=>'a'])
    @test typeof(m08a) == SortedDict{Any,Any,ForwardOrdering}
    m08b = SortedDict([(1.0,2), (2,'a')])
    @test typeof(m08b) == SortedDict{Real,Any,ForwardOrdering}
    m09a = SortedDict(Pair{Int}[1=>2, 3=>'a'])
    @test typeof(m09a) == SortedDict{Int,Any,ForwardOrdering}
    m09b = SortedDict([(1,2), (3,'a')])
    @test typeof(m09a) == SortedDict{Int,Any,ForwardOrdering}

    @test m0 == m02
    @test isequal(m0, m02)
    @test m1 == m01
    @test isequal(m1, m01)
    @test m1 == m11
    @test isequal(m1, m11)

    # Test Exceptions
    @test_throws ArgumentError SortedDict([1,2,3,4])
    @test_throws ArgumentError SortedDict{Int,Int}([1,2,3,4])


    expected = ([6,8,12], [18.2, 32.0, 33.1])
    checkcorrectness(m1.bt, false)
    ii = startof(m1)
    m2 = packdeepcopy(m1)
    m3 = packcopy(m1)
    p = first(m1)
    @test p[1] == 6 && p[2] == 18.2
    @test in(Pair(8,32.0),m3)
    @test !in(Pair(8,32.1),m3)
    push_test!(m1, 12, 33.2)
    checkcorrectness(m1.bt, false)
    @test length(m1) == 3
    @test m1[12] == 33.2
    push_test!(m1, 12, 33.1)
    @test length(m1) == 3
    @test m1[12] == 33.1
    for j = 1 : 3
        @test ii != pastendsemitoken(m1)
        pr = deref((m1,ii))
        @test pr[1] == expected[1][j] && pr[2] == expected[2][j]
        checkcorrectness(m1.bt, false)
        oldii = ii
        ii = advance((m1,ii))
        delete!((m1,oldii))
    end
    checkcorrectness(m1.bt, false)
    checkcorrectness(m2.bt, false)
    @test length(m2) == 3
    ii = startof(m2)
    for j = 1 : 3
        pr = deref((m2,ii))
        @test pr[1] == expected[1][j] && pr[2] == expected[2][j]
        ii = advance((m2,ii))
    end

    checkcorrectness(m3.bt, false)
    @test length(m3) == 3
    ii = startof(m3)
    for j = 1 : 3
        pr = deref((m3,ii))
        @test pr[1] == expected[1][j] && pr[2] == expected[2][j]
        ii = advance((m3,ii))
    end

    @test isempty(m1)
    @test length(m1) == 0
    N = 5000
    for i = N : -1 : 2
        m1[i] = convert(Float64,i) ^ 2
        if i % 50 == 0
            checkcorrectness(m1.bt, false)
        end
    end
    @test !isempty(m1)
    assert(length(m1) == N - 1)
    for i = 2 : N
        d = pop!(m1, i)
        @test d == convert(Float64,i)^2
        if i % 50 == 0
            checkcorrectness(m1.bt, false)
        end
    end
    @test isempty(m1)
    @test length(m1) == 0
    for i = N : -1 : 2
        m1[i] = convert(Float64,i) ^ 2
        if i % 50 == 0
            checkcorrectness(m1.bt, false)
        end
    end
    ii = endof(m1)
    for i = 1 : N - 1
        pr = deref((m1,ii))
        @test pr[1] == N + 1 - i && pr[2] == convert(Float64,pr[1]) ^ 2
        ii = regress((m1,ii))
    end
    lastprime = 1
    while true
        ii = searchsortedafter(m1, lastprime)
        if ii == pastendsemitoken(m1)
            break
        end
        j = deref_key((m1,ii))
        for k = j * 2 : j : N
            p = find(m1, k)
            if p != pastendsemitoken(m1)
                delete!((m1,p))
            end
        end
        lastprime = j
    end
    checkcorrectness(m1.bt, false)
    @test ii == pastendsemitoken(m1)
    @test status((m1,ii)) == 3
    @test status((m1,SDSemiToken(-1))) == 0
    t = 0
    u = 0.0
    for pr in m1
        t += pr[1]
        u += pr[2]
    end
    numprimes = length(m1)
    pn = primes(N)
    @test t == sum(pn)
    @test u == sum(pn.^2)
    ij = endof(m1)
    @test deref_key((m1,ij)) == last(pn) &&
       convert(Float64, last(pn)^2) ==  deref_value((m1,ij))
    m1[6] = 49.0
    @test length(m1) == numprimes + 1
    @test m1[6] == 49.0
    b, i6 = insert!(m1, 6, 50.0)
    @test length(m1) == numprimes + 1
    @test !b
    p = deref((m1,i6))
    @test p[1] == 6 && p[2] == 50.0
    m1[i6] = 9.0
    p = deref((m1,i6))
    @test p[1] == 6 && p[2] == 9.0
    @test m1[i6] == 9.0
    b2, i7 = insert!(m1, 8, 51.0)
    @test b2
    @test length(m1) == numprimes + 2
    p = deref((m1,i7))
    @test p[1] == 8 && p[2] == 51.0
    delete!((m1,i7))
    z = pop!(m1, 6)
    checkcorrectness(m1.bt, false)
    @test z == 9.0
    i8 = startof(m1)
    p = deref((m1,i8))
    @test p[1] == 2 && p[2] == 4.0
    @test i8 != beforestartsemitoken(m1)
    @test status((m1,i8)) == 1
    i9 = regress((m1,i8))
    @test i9 == beforestartsemitoken(m1)
    @test status((m1,i9)) == 2
    i10 = find(m1, 17)
    i11 = regress((m1,i10))
    @test deref_key((m1,i11)) == 13
    i12 = searchsortedfirst(m1, 47)
    i13 = searchsortedfirst(m1, 48)
    @test deref_key((m1,i12)) == 47
    @test deref_key((m1,i13)) == 53
    i14 = searchsortedafter(m1, 47)
    i15 = searchsortedafter(m1, 48)
    @test deref_key((m1,i14)) == 53
    @test deref_key((m1,i15)) == 53
    i16 = searchsortedlast(m1, 47)
    i17 = searchsortedlast(m1, 48)
    @test deref_key((m1,i16)) == 47
    @test deref_key((m1,i17)) == 47
    ww = primes(N)
    cc = last(m1)
    @test cc[1] == last(ww)
    wwx = first(m1)
    @test wwx[1] == 2
    tpr = eltype(m1)
    @test tpr == Pair{Int,Float64}
    tpr2 = eltype(typeof(m1))
    @test tpr2 == Pair{Int,Float64}
    kt = keytype(m1)
    @test kt == Int
    kt2 = keytype(typeof(m1))
    @test kt2 == Int
    vt = valtype(m1)
    @test vt == Float64
    vt2 = valtype(typeof(m1))
    @test vt2 == Float64
    @test ordtype(m1) == ForwardOrdering
    @test ordtype(typeof(m1)) == ForwardOrdering

    co = orderobject(m1)
    @test co == Forward
    @test haskey(m1, 71)
    @test !haskey(m1, 77)
    @test get(m1, 70, -45.2) == -45.2
    @test get(m1, 83, -45.2) == convert(Float64,83)^2
    h = get!(m1, 5, 27.0)
    @test h == 25.0
    h = get!(m1, 6, 27.0)
    @test h == 27.0
    @test m1[6] == 27.0
    @test length(m1) == length(ww) + 1
    pop!(m1, 6)
    @test getkey(m1,7, 9) == 7
    @test getkey(m1,7.0, 9) == 7
    @test getkey(m1,12, 9) == 9
    delete!(m1, 17)
    @test length(m1) == length(ww) - 1
    @test deref_key((m1,advance((m1,find(m1,13))))) == 19
    empty!(m1)
    checkcorrectness(m1.bt, false)
    @test isempty(m1)
    c1 = SortedDict(Dict("Eggplants"=>3,
                        "Figs"=>9,
                        "Apples"=>7))
    c2 = SortedDict(Dict("Eggplants"=>6,
                        "Honeydews"=>19,
                        "Melons"=>11))
    @test !isequal(c1,c2)
    c3 = merge(c1, c2)
    checkcorrectness(c3.bt, false)
    c4 = SortedDict(Dict("Apples"=>7,
                        "Figs"=>9,
                        "Eggplants"=>6,
                        "Melons"=>11,
                        "Honeydews"=>19))
    @test isequal(c3,c4)
    c5 = SortedDict(Dict("Apples"=>7))
    @test !isequal(c4,c5)
    merge!(c1,c2)
    checkcorrectness(c1.bt, false)
    @test isequal(c3,c1)
    merge!(c3,c3)
    @test isequal(c3,c1)
    checkcorrectness(c3.bt, false)

    # issue #216
    @test DataStructures.isordered(SortedDict{Int, String})
end


function bitreverse(i)
    zeroi = zero(i)
    onei = one(i)
    twoi = onei + onei
    r = zeroi
    for j = 1 : 32
        r *= twoi
        r += (i & onei)
        i = div(i,twoi)
    end
    r
end



@testset "SortedDictLoops" begin
    z = 0x00000000
    T = typeof(z)
    ## Test the loops
    zero1 = zero(z)
    one1 = one(z)
    two1 = one1 + one1
    m1 = SortedDict{T,T}()
    N = 1000
    for l = 1 : N
        lUi = convert(T, l)
        m1[bitreverse(lUi)] = lUi
    end
    count = 0
    for (stok,k,v) in semitokens(inclusive(m1, startof(m1), endof(m1)))
        for (stok2,k2,v2) in semitokens(exclusive(m1, startof(m1), pastendsemitoken(m1)))
            c = compare(m1,stok,stok2)
            if c < 0
                @test deref_key((m1,stok)) < deref_key((m1,stok2))
            elseif c == 0
                @test deref_key((m1,stok)) == deref_key((m1,stok2))
            else
                @test deref_key((m1,stok)) > deref_key((m1,stok2))
            end
            count += 1
        end
    end
    @test eltype(semitokens(exclusive(m1, startof(m1), pastendsemitoken(m1)))) ==
    Tuple{IntSemiToken, T, T}
    @test count == N^2
    N = 10000
    sk = zero1
    sv = zero1
    skhalf = zero1
    svhalf = zero1
    for l = 1 : N
        lUi = convert(T, l)
        brl = bitreverse(lUi)
        sk += brl
        m1[brl] = lUi
        sv += lUi
        if brl < div(N, 2)
            skhalf += brl
            svhalf += lUi
        end
    end
    count = 0
    sk2 = zero1
    sv2 = zero1
    for (k,v) in m1
        sk2 += k
        sv2 += v
        count += 1
    end
    @test count == N
    @test sk2 == sk
    @test sv == sv2
    sk2 = zero1
    for k in keys(m1)
        sk2 += k
    end
    @test eltype(keys(m1)) == T
    @test sk2 == sk

    sk2a = zero1


    for k in eachindex(m1)
        sk2a += k
    end
    @test eltype(eachindex(m1)) == T
    @test sk2a == sk



    sk2b = zero1
    for st in onlysemitokens(m1)
        sk2b += deref_key((m1,st))
    end
    @test sk2b == sk

    sv2 = zero1
    for v in values(m1)
        sv2 += v
    end
    @test eltype(values(m1)) == T

    @test sv == sv2
    count = 0
    for (st,k) in semitokens(keys(m1))
        @test deref_key((m1,st)) == k
        count += 1
    end
    @test eltype(semitokens(keys(m1))) == Tuple{IntSemiToken, T}

    @test count == N
    count = 0
    for (st,v) in semitokens(values(m1))
        @test deref_value((m1,st)) == v
        count += 1
    end
    @test count == N
    @test eltype(semitokens(values(m1))) == Tuple{IntSemiToken, T}

    pos1 = searchsortedfirst(m1, div(N,2))
    sk2 = zero1
    for k in keys(exclusive(m1, startof(m1), pos1))
        sk2 += k
    end
    @test sk2 == skhalf
    @test eltype(keys(exclusive(m1, startof(m1), pos1))) == T



    sk2a = zero1
    for k in eachindex(exclusive(m1, startof(m1), pos1))
        sk2a += k
    end
    @test sk2a == skhalf
    @test eltype(eachindex(exclusive(m1, startof(m1), pos1))) == T



    sv2 = zero1
    for v in values(exclusive(m1, startof(m1), pos1))
        sv2 += v
    end
    @test sv2 == svhalf
    count = 0
    for (k,v) in exclusive(m1, pastendsemitoken(m1), pastendsemitoken(m1))
        count += 1
    end
    @test eltype(keys(exclusive(m1, startof(m1), pos1))) == T
    @test count == 0


    count = 0
    for (k,v) in inclusive(m1, startof(m1), beforestartsemitoken(m1))
        count += 1
    end
    @test count == 0
    @test eltype(keys(inclusive(m1, startof(m1), beforestartsemitoken(m1)))) ==
       T


    count = 0
    sk5 = zero1
    for k in eachindex(inclusive(m1, startof(m1), startof(m1)))
        sk5 += k
        count += 1
    end
    @test count == 1 && sk5 == deref_key((m1,startof(m1)))
    @test eltype(eachindex(inclusive(m1, startof(m1), startof(m1)))) == T

    factors = SortedMultiDict(Int[], Int[])
    N = 1000
    len = 0
    sum1 = 0
    sum2 = 0
    for factor = 1 : N
        for multiple = factor : factor : N
            insert!(factors, multiple, factor)
            sum1 += multiple
            sum2 += factor
            len += 1
        end
    end

    sum1a = 0
    sum2a = 0

    for (k,v) in factors
        sum1a += k
        sum2a += v
    end
    @test sum1a == sum1 && sum2a == sum2





    sum1a = 0
    sum2a = 0
    for st in eachindex(factors)
        (k,v) = deref((factors,st))
        sum1a += k
        sum2a += v
    end
    @test sum1a == sum1 && sum2a == sum2

    sum1a = 0
    sum2a = 0
    for st in onlysemitokens(factors)
        (k,v) = deref((factors,st))
        sum1a += k
        sum2a += v
    end
    @test sum1a == sum1 && sum2a == sum2
    @test eltype(onlysemitokens(factors)) == IntSemiToken

    sum2 = 0
    for (k,v) in inclusive(factors,
                           searchsortedfirst(factors,70),
                           searchsortedlast(factors,70))
        sum2 += v
    end

    @test sum2 == 1 + 2 + 5 + 7 + 10 + 14 + 35 + 70
    @test eltype(inclusive(factors,
                           searchsortedfirst(factors,70),
                           searchsortedlast(factors,70))) == Pair{Int,Int}


    sum2 = 0
    for st in eachindex(inclusive(factors,
                                  searchsortedfirst(factors,70),
                                  searchsortedlast(factors,70)))
        v = deref_value((factors,st))
        sum2 += v
    end

    @test sum2 == 1 + 2 + 5 + 7 + 10 + 14 + 35 + 70
    @test eltype(eachindex(inclusive(factors,
                                     searchsortedfirst(factors,70),
                                     searchsortedlast(factors,70)))) == IntSemiToken



    sum3 = 0
    for (k,v) in exclusive(factors,
                           searchsortedfirst(factors,60),
                           searchsortedfirst(factors,61))
        sum3 += v
    end
    @test sum3 == 1 + 2 + 3 + 4 + 5 + 6 + 10 + 12 + 15 + 20 + 30 + 60
    @test eltype(exclusive(factors,
                           searchsortedfirst(factors,70),
                           searchsortedlast(factors,70))) == Pair{Int,Int}


    sum3 = 0
    for st in eachindex(exclusive(factors,
                                  searchsortedfirst(factors,60),
                                  searchsortedfirst(factors,61)))
        v = deref_value((factors,st))
        sum3 += v
    end
    @test sum3 == 1 + 2 + 3 + 4 + 5 + 6 + 10 + 12 + 15 + 20 + 30 + 60
    @test eltype(eachindex(exclusive(factors,
                                     searchsortedfirst(factors,70),
                                     searchsortedlast(factors,70)))) == IntSemiToken


    sum4 = 0
    for k in keys(factors)
        sum4 += k
    end
    @test sum4 == sum1
    @test eltype(keys(factors)) == Int




    sum5 = 0
    for v in values(factors)
        sum5 += v
    end

    @test sum5 == sum2a
    @test eltype(values(factors)) == Int

    sum2 = 0
    for k in keys(inclusive(factors,
                            searchsortedfirst(factors,70),
                            searchsortedlast(factors,70)))
        sum2 += k
    end
    @test sum2 == 70 * 8
    @test eltype(keys(inclusive(factors,
                                searchsortedfirst(factors,70),
                                searchsortedlast(factors,70)))) ==  Int


    sum3 = 0
    for k in keys(exclusive(factors,
                            searchsortedfirst(factors,60),
                            searchsortedfirst(factors,61)))
        sum3 += k
    end
    @test sum3 == 60 * 12
    @test eltype(keys(exclusive(factors,
                                searchsortedfirst(factors,60),
                                searchsortedfirst(factors,61)))) == Int



    sum2 = 0
    for v in values(inclusive(factors,
                              searchsortedfirst(factors,70),
                              searchsortedlast(factors,70)))
        sum2 += v
    end
    @test sum2 == 1 + 2 + 5 + 7 + 10 + 14 + 35 + 70
    @test eltype(values(inclusive(factors,
                                  searchsortedfirst(factors,60),
                                  searchsortedfirst(factors,61)))) == Int

    sum3 = 0
    for v in values(exclusive(factors,
                              searchsortedfirst(factors,60),
                              searchsortedfirst(factors,61)))
        sum3 += v
    end
    @test sum3 == 1 + 2 + 3 + 4 + 5 + 6 + 10 + 12 + 15 + 20 + 30 + 60
    @test eltype(values(exclusive(factors,
                                  searchsortedfirst(factors,60),
                                  searchsortedfirst(factors,61)))) == Int

    sum1b = 0
    sum2b = 0
    for (st,k,v) in semitokens(factors)
        @test deref_value((factors,st)) == v
        sum1b += k
        sum2b += v
    end
    @test sum1b == sum1a && sum2b == sum2a
    @test eltype(semitokens(factors)) == Tuple{IntSemiToken, Int, Int}

    sum2 = 0
    for (st,k,v) in semitokens(inclusive(factors,
                                         searchsortedfirst(factors,70),
                                         searchsortedlast(factors,70)))
        @test deref_value((factors,st)) == v
        sum2 += v
    end
    @test sum2 == 1 + 2 + 5 + 7 + 10 + 14 + 35 + 70
    @test eltype(semitokens(inclusive(factors,
                                         searchsortedfirst(factors,70),
                                         searchsortedlast(factors,70)))) ==
        Tuple{IntSemiToken, Int, Int}

    sum3 = 0
    for (st,k,v) in semitokens(exclusive(factors,
                                         searchsortedfirst(factors,60),
                                         searchsortedfirst(factors,61)))
        @test deref_value((factors,st)) == v
        sum3 += v
    end
    @test sum3 == 1 + 2 + 3 + 4 + 5 + 6 + 10 + 12 + 15 + 20 + 30 + 60
    @test eltype(semitokens(exclusive(factors,
                                      searchsortedfirst(factors,60),
                                      searchsortedfirst(factors,61)))) ==
         Tuple{IntSemiToken, Int, Int}

    sum4 = 0
    for (st,k) in semitokens(keys(factors))
        @test deref_key((factors,st)) == k && mod(k,deref_value((factors,st))) == 0
        sum4 += k
    end
    @test sum4 == sum1
    @test eltype(semitokens(keys(factors))) == Tuple{IntSemiToken,Int}

    sum5 = 0
    for (st,v) in semitokens(values(factors))
        @test deref_value((factors,st)) == v
        sum5 += v
    end
    @test sum5 == sum2a
    @test eltype(semitokens(values(factors))) == Tuple{IntSemiToken,Int}

    sum2 = 0
    for (st,k) in semitokens(keys(inclusive(factors,
                                           searchsortedfirst(factors,70),
                                           searchsortedlast(factors,70))))
        @test deref_key((factors,st)) == k && mod(k,deref_value((factors,st))) == 0
        sum2 += k
    end
    @test sum2 == 70 * 8
    @test eltype(semitokens(keys(inclusive(factors,
                                           searchsortedfirst(factors,70),
                                           searchsortedlast(factors,70))))) ==
        Tuple{IntSemiToken, Int}

    sum3 = 0
    for (st,k) in semitokens(keys(inclusive(factors,
                                            searchsortedfirst(factors,60),
                                            searchsortedlast(factors,60))))
        @test deref_key((factors,st)) == k && mod(k,deref_value((factors,st))) == 0
        sum3 += k
    end
    @test sum3 == 60 * 12
    @test eltype(semitokens(keys(inclusive(factors,
                                            searchsortedfirst(factors,60),
                                            searchsortedlast(factors,60))))) ==
        Tuple{IntSemiToken, Int}

    sum2 = 0
    for (st,v) in semitokens(values(inclusive(factors,
                                              searchsortedfirst(factors,70),
                                              searchsortedlast(factors,70))))
        @test deref_value((factors,st)) == v
        sum2 += v
    end
    @test sum2 == 1 + 2 + 5 + 7 + 10 + 14 + 35 + 70
    @test eltype(semitokens(values(inclusive(factors,
                                              searchsortedfirst(factors,70),
                                              searchsortedlast(factors,70))))) ==
      Tuple{IntSemiToken, Int}

    sum3 = 0
    for (st,v) in semitokens(values(exclusive(factors,
                                              searchsortedfirst(factors,60),
                                              searchsortedfirst(factors,61))))
        @test deref_value((factors,st)) == v
        sum3 += v
    end
    @test sum3 == 1 + 2 + 3 + 4 + 5 + 6 + 10 + 12 + 15 + 20 + 30 + 60
    @test eltype(semitokens(values(exclusive(factors,
                                              searchsortedfirst(factors,60),
                                              searchsortedfirst(factors,61))))) ==
       Tuple{IntSemiToken, Int}

    s = SortedSet([39, 24, 2, 14, 45, 107, 66])
    sum1 = 0
    for k in s
        sum1 += k
    end
    @test sum1 == sum([39, 24, 2, 14, 45, 107, 66])

    sum1 = 0
    for (st,k) in semitokens(s)
        @test deref((s,st)) == k
        sum1 += k
    end
    @test sum1 == sum([39, 24, 2, 14, 45, 107, 66])
    @test eltype(semitokens(s)) == Tuple{IntSemiToken, Int}


    sum1 = 0
    for st in onlysemitokens(s)
        k = deref((s,st))
        sum1 += k
    end
    @test sum1 == sum([39, 24, 2, 14, 45, 107, 66])
    @test eltype(onlysemitokens(s)) == IntSemiToken


    sum1 = 0
    for st in eachindex(s)
        k = deref((s,st))
        sum1 += k
    end
    @test sum1 == sum([39, 24, 2, 14, 45, 107, 66])
    @test eltype(eachindex(s)) == IntSemiToken


    sum2 = 0
    for k in inclusive(s,
                       searchsortedfirst(s, 24),
                       searchsortedfirst(s, 66))
        sum2 += k
    end
    @test sum2 == 24 + 39 + 45 + 66
    @test eltype(inclusive(s,
                       searchsortedfirst(s, 24),
                       searchsortedfirst(s, 66))) == Int


    sum2 = 0
    for st in eachindex(inclusive(s,
                                  searchsortedfirst(s, 24),
                                  searchsortedfirst(s, 66)))
        sum2 += deref((s,st))
    end
    @test sum2 == 24 + 39 + 45 + 66
    @test eltype(eachindex(inclusive(s,
                                     searchsortedfirst(s, 24),
                                     searchsortedfirst(s, 66)))) == IntSemiToken




    sum2 = 0
    for (st,k) in semitokens(inclusive(s,
                                       searchsortedfirst(s, 24),
                                       searchsortedfirst(s, 66)))
        @test deref((s,st)) == k
        sum2 += k
    end
    @test sum2 == 24 + 39 + 45 + 66
    @test eltype(semitokens(inclusive(s,
                                       searchsortedfirst(s, 24),
                                       searchsortedfirst(s, 66)))) ==
      Tuple{IntSemiToken, Int}


    sum2 = 0
    for st in onlysemitokens(inclusive(s,
                                       searchsortedfirst(s, 24),
                                       searchsortedfirst(s, 66)))
        sum2 += deref((s,st))
    end
    @test sum2 == 24 + 39 + 45 + 66
    @test eltype(onlysemitokens(inclusive(s,
                                          searchsortedfirst(s, 24),
                                          searchsortedfirst(s, 66)))) == IntSemiToken




    sum3 = 0
    for k in exclusive(s,
                       searchsortedfirst(s, 24),
                       searchsortedfirst(s, 66))
        sum3 += k
    end
    @test sum3 == 24 + 39 + 45
    @test eltype(exclusive(s,
                       searchsortedfirst(s, 24),
                       searchsortedfirst(s, 66))) == Int


    sum3 = 0
    for (st,k) in semitokens(exclusive(s,
                                       searchsortedfirst(s, 24),
                                       searchsortedfirst(s, 66)))
        @test deref((s,st)) == k
        sum3 += k
    end
    @test sum3 == 24 + 39 + 45
    @test eltype(semitokens(exclusive(s,
                                       searchsortedfirst(s, 24),
                                       searchsortedfirst(s, 66)))) ==
     Tuple{IntSemiToken, Int}


    sum3 = 0
    for st in eachindex(exclusive(s,
                                  searchsortedfirst(s, 24),
                                  searchsortedfirst(s, 66)))
        sum3 += deref((s,st))
    end
    @test sum3 == 24 + 39 + 45
    @test eltype(eachindex(exclusive(s,
                                     searchsortedfirst(s, 24),
                                     searchsortedfirst(s, 66)))) == IntSemiToken
end




@testset "SortedDictErrors" begin
    # test all the errors of sorted containers
    m = SortedDict(Dict("a" => 6, "bb" => 9))
    @test_throws KeyError println(m["b"])
    m2 = SortedDict{Compat.ASCIIString,Int}()
    @test_throws BoundsError println(first(m2))
    @test_throws BoundsError println(last(m2))
    state1 = start(m2)
    @test_throws BoundsError next(m2, state1)
    i1 = find(m,"a")
    delete!((m,i1))
    i2 = find(m,"bb")
    @test_throws BoundsError start(inclusive(m,i1,i2))
    @test_throws BoundsError start(exclusive(m,i1,i2))
    @test_throws KeyError delete!(m,"a")
    @test_throws KeyError pop!(m,"a")
    m3 = SortedDict((Dict{Compat.ASCIIString, Int}()), Reverse)
    @test_throws ArgumentError isequal(m2, m3)``
    @test_throws BoundsError m[i1]
    @test_throws BoundsError regress((m,beforestartsemitoken(m)))
    @test_throws BoundsError advance((m,pastendsemitoken(m)))
    m1 = SortedMultiDict(Int[], Int[])
    @test_throws ArgumentError m3 = SortedMultiDict(["a", "b"], [1,2,3])
    @test_throws ArgumentError isequal(SortedMultiDict(["a"],[1]), SortedMultiDict(["b"], [1.0]))
    @test_throws ArgumentError isequal(SortedMultiDict(["a"],[1],Reverse), SortedMultiDict(["b"], [1]))
    @test_throws BoundsError first(m1)
    @test_throws BoundsError last(m1)
    s = SortedSet([3,5])
    @test_throws KeyError delete!(s,7)
    @test_throws KeyError pop!(s, 7)
    pop!(s)
    pop!(s)
    @test_throws BoundsError pop!(s)
    @test_throws BoundsError first(s)
    @test_throws BoundsError last(s)
    @test_throws ArgumentError isequal(SortedSet(["a"]), SortedSet([1]))
    @test_throws ArgumentError isequal(SortedSet(["a"]), SortedSet(["b"],Reverse))
    @test_throws ArgumentError (("a",6) in m)
    @test_throws ArgumentError ((2,5) in m1)
end



function seekfile(fname)
    #fullname = joinpath(Pkg.dir("DataStructures"), "test", fname)
    fname
end


@testset "SortedDictOrderings" begin
    ## Test use of alternative orderings in test5
    keylist = ["Apple", "aPPle", "berry", "CHerry", "Dairy", "diary"]
    vallist = [6,9,-4,2,1,8]
    m = SortedDict{Compat.ASCIIString,Int}()
    for j = 1:6
        m[keylist[j]] = vallist[j]
    end
    checkcorrectness(m.bt, false)
    expectedord1 = [1,4,5,2,3,6]
    count = 0
    for p in m
        count += 1
        @test p[1] == keylist[expectedord1[count]] &&
                p[2] == vallist[expectedord1[count]]
    end
    @test count == 6
    m2 = SortedDict((Dict{Compat.ASCIIString, Int}()), Reverse)
    for j = 1 : 6
        m2[keylist[j]] = vallist[j]
    end
    checkcorrectness(m2.bt, false)
    expectedord2 = [6,3,2,5,4,1]
    count = 0
    for p in m2
        count += 1
        @test p[1] == keylist[expectedord2[count]] &&
                p[2] == vallist[expectedord2[count]]
    end
    @test count == 6
    m3 = SortedDict((Dict{Compat.ASCIIString, Int}()), CaseInsensitive())
    for j = 1 : 6
        m3[keylist[j]] = vallist[j]
    end
    @test "BERRY" in keys(m3)
    @test !("BERRY" in collect(keys(m3)))
    checkcorrectness(m3.bt, false)
    expectedord3 = [2,3,4,5,6]
    count = 0
    for p in m3
        count += 1
        @test p[1] == keylist[expectedord3[count]] &&
                p[2] == vallist[expectedord3[count]]
    end
    @test count == 5
    m3empty = similar(m3)
    @test eltype(m3empty) == Pair{Compat.ASCIIString, Int} &&
       orderobject(m3empty) == CaseInsensitive() &&
       length(m3empty) == 0 && ordtype(m3empty) == CaseInsensitive &&
       ordtype(typeof(m3empty)) == CaseInsensitive
    m4 = SortedDict((Dict{Compat.ASCIIString,Int}()), Lt((x,y) -> isless(lowercase(x),lowercase(y))))
    for j = 1 : 6
        m4[keylist[j]] = vallist[j]
    end
    checkcorrectness(m4.bt, false)
    count = 0
    for p in m4
        count += 1
        @test p[1] == keylist[expectedord3[count]] &&
                p[2] == vallist[expectedord3[count]]
    end
    @test count == 5
end

@testset "SortedMultiDict" begin
    # Test all methods of SortedMultiDict except loops
    factors = SortedMultiDict(Int[], Int[])
    @test typeof(factors) == SortedMultiDict{Int,Int,ForwardOrdering}
    factors2 = SortedMultiDict{Int,Int}()
    @test typeof(factors2) == SortedMultiDict{Int,Int,ForwardOrdering}

    #@test factors == factors2   # Broken!  TODO: fix me...
    @test isequal(factors, factors2)

    N = 1000
    checkcorrectness(factors.bt, true)
    len = 0
    for factor = 1 : N
        for multiple = factor : factor : N
            insert!(factors, multiple, factor)
            len += 1
        end
    end
    @test length(factors) == len
    @test Pair(70,2) in factors
    @test Pair(70,14) in factors
    @test !(Pair(70,15) in factors)
    @test !(Pair(N+1,15) in factors)
    @test eltype(factors) == Pair{Int,Int}
    @test eltype(typeof(factors)) == Pair{Int,Int}

    @test keytype(factors) == Int
    @test keytype(typeof(factors)) == Int
    @test valtype(factors) == Int
    @test valtype(typeof(factors)) == Int
    @test ordtype(factors) == ForwardOrdering
    @test ordtype(typeof(factors)) == ForwardOrdering

    push_test!(factors, 70,3)
    @test length(factors) == len+1
    @test Pair(70,3) in factors
    i = searchsortedfirst(factors, 70)
    dcount = 0
    for (s,k,v) in semitokens(inclusive(factors, i, endof(factors)))
        @test k == 70
        if v == 3
            delete!((factors,s))
            dcount += 1
            break
        end
    end
    @test dcount == 1

    @test orderobject(factors) == Forward
    @test haskey(factors, 60)
    @test !haskey(factors, -1)
    @test 60 in keys(factors)
    @test !(-1 in keys(factors))
    checkcorrectness(factors.bt, true)
    i = startof(factors)
    i = advance((factors,i))
    @test deref((factors,i)) == Pair(2,1)
    @test deref_key((factors,i)) == 2
    @test deref_value((factors,i)) == 1
    @test factors[i] == 1
    factors[i] = 7
    @test deref((factors,i)) == Pair(2,7)
    factors[i] = 1
    i = regress((factors,i))
    i = regress((factors,i))
    @test i == beforestartsemitoken(factors)
    pr = first(factors)
    @test pr == Pair(1,1)
    pr2 = last(factors)
    @test pr2 == Pair(N,N)
    i = searchsortedfirst(factors,77)
    @test deref((factors,i)) == Pair(77,1)
    i = searchsortedlast(factors,77)
    @test deref((factors,i)) == Pair(77,77)
    i = searchsortedafter(factors,77)
    @test deref((factors,i)) == Pair(78,1)
    expected = [1,2,4,5,8,10,16,20,40,80]
    i1,i2 = searchequalrange(factors, 80)
    i = i1
    for e in expected
        @test deref_value((factors,i)) == e
        i = advance((factors,i))
    end
    @test compare(factors,i,i2) != 0
    @test compare(factors,regress((factors,i)),i2) == 0
    @test compare(factors,i,i1) != 0
    insert!(factors, 80, 6)
    @test length(factors) == len + 1
    checkcorrectness(factors.bt, true)
    expected1 = deepcopy(expected)
    push!(expected1, 6)
    i1,i2 = searchequalrange(factors, 80)
    i = i1
    for e in expected1
        @test deref_value((factors,i)) == e
        i = advance((factors,i))
    end
    @test compare(factors,i2,regress((factors,i))) == 0
    @test compare(factors,i,i1) != 0
    delete!((factors,i2))
    @test length(factors) == len
    checkcorrectness(factors.bt, true)
    i1,i2 = searchequalrange(factors, 80)
    i = i1
    for e in expected
        @test deref_value((factors,i)) == e
        i = advance((factors,i))
    end
    @test compare(factors,regress((factors,i)),i2) == 0
    @test !isempty(factors)
    empty!(factors)
    checkcorrectness(factors.bt, true)
    @test length(factors) == 0
    @test isempty(factors)
    i = startof(factors)
    @test i == pastendsemitoken(factors)
    i = endof(factors)
    @test i == beforestartsemitoken(factors)
    i1,i2 = searchequalrange(factors, N + 2)
    @test i1 == pastendsemitoken(factors)
    @test i2 == beforestartsemitoken(factors)
    m1 = SortedMultiDict(["apples", "apples", "bananas"], [2.0, 1.0,1.5])
    checkcorrectness(m1.bt, true)
    m2 = SortedMultiDict(["bananas","apples", "apples"], [1.5, 2.0, 1.0])
    checkcorrectness(m2.bt, true)
    m3 = SortedMultiDict(["apples", "apples", "bananas"], [1.0, 2.0, 1.5])
    checkcorrectness(m3.bt, true)
    @test isequal(m1,m2)
    @test !isequal(m1,m3)
    @test !isequal(m1, SortedMultiDict(["apples"], [2.0]))
    stok = insert!(m2, "cherries", 6.1)
    checkcorrectness(m2.bt, true)
    @test !isequal(m1,m2)
    delete!((m2,stok))
    checkcorrectness(m2.bt, true)
    @test isequal(m1,m2)
    m4 = deepcopy(m2)
    checkcorrectness(m4.bt, true)
    @test isequal(m1,m4)
    m5 = packcopy(m2)
    checkcorrectness(m5.bt, true)
    @test isequal(m1,m5)
    m6 = packdeepcopy(m2)
    checkcorrectness(m6.bt, true)
    @test isequal(m1,m6)

    m1 = SortedMultiDict(["bananas", "apples", "cherries", "cherries", "oranges"],
                         [1.0, 2.0, 3.0, 4.0, 5.0])
    m2 = SortedMultiDict(["apples", "cherries", "cherries", "bananas", "plums"],
                         [6.0, 7.0, 8.0, 9.0, 10.0])
    m3 = SortedMultiDict(["apples", "apples", "bananas", "bananas",
                          "cherries", "cherries", "cherries", "cherries",
                          "oranges", "plums"],
                         [2.0, 6.0, 1.0, 9.0, 3.0, 4.0, 7.0, 8.0, 5.0, 10.0])
    m3empty = similar(m3)
    @test (eltype(m3empty) == Pair{Compat.ASCIIString, Float64}) &&
        orderobject(m3empty) == Forward &&
        length(m3empty) == 0
    m4 = merge(m1, m2)
    @test isequal(m3, m4)
    m5 = merge(m2, m1)
    @test !isequal(m3, m5)
    merge!(m1, m2)
    @test isequal(m1, m3)
    m7 = SortedMultiDict(Int[], Int[])
    n1 = 10000
    for k = 1 : n1
        insert!(m7, k, k+1)
    end
    for k = 1 : n1
        insert!(m7, k, k+2)
    end
    for k = 1 : n1
        i1, i2 = searchequalrange(m7, k)
        count = 0
        for (key,v) in inclusive(m7, i1, i2)
            count += 1
            @test key == k
            @test v == k + count
        end
        @test count == 2
        count = 0
        for (key,v) in inclusive(m7, searchequalrange(m7,k))
            count += 1
            @test key == k
            @test v == k + count
        end
        @test count == 2
    end
    # issue #216
    @test DataStructures.isordered(SortedMultiDict{Int, String})
end


@testset "SortedSet" begin
    # Test SortedSet
    N = 1000
    sm = 0.0

    m = SortedSet(Float64[])
    @test typeof(m) == SortedSet{Float64, ForwardOrdering}
    mm = SortedSet{Float64}()
    @test typeof(mm) == SortedSet{Float64, ForwardOrdering}
    @test m == mm
    @test isequal(m, mm)

    @test typeof(SortedSet()) == SortedSet{Any, ForwardOrdering}
    @test typeof(SortedSet{Float64}()) == SortedSet{Float64, ForwardOrdering}
    @test typeof(SortedSet(Reverse)) == SortedSet{Any, ReverseOrdering{ForwardOrdering}}
    @test typeof(SortedSet{Float64}(Reverse)) == SortedSet{Float64, ReverseOrdering{ForwardOrdering}}

    @test SortedSet([1,2]) < SortedSet([1,2,3])
    @test SortedSet([1,2]) <= SortedSet([1,2,3])
    @test SortedSet([1,2,3]) <= SortedSet([1,2,3])

    @test SortedSet([1,2]) ⊊ SortedSet([1,2,3])
    @test SortedSet([1,2]) ⊆ SortedSet([1,2,3])
    @test SortedSet([1,2,3]) ⊆ SortedSet([1,2,3])
    @test SortedSet([1,4]) ⊈ SortedSet([1,2,3])

    smallest = 10.0
    largest = -10.0
    for j = 1 : N
        u = j * exp(1)
        ui = u - floor(u)
        push!(m, ui)
        sm += ui
        smallest = min(smallest,ui)
        largest = max(largest,ui)
    end
    isnew,st = insert!(m, 72.5)
    @test isnew
    @test deref((m,st)) == 72.5
    delete!((m,st))
    isnew,st = insert!(m, 73.5)
    @test isnew
    @test deref((m,st)) == 73.5
    delete!(m, 73.5)
    checkcorrectness(m.bt, false)
    count = 0
    sm2 = 0.0
    prev = -1.0
    for k in m
        sm2 += k
        count += 1
        @test k >= prev
    end
    @test abs(sm2 - sm) <= 1e-10
    @test count == N
    @test length(m) == N
    ii2 = searchsortedfirst(m, 0.5)
    i3 = startof(m)
    v = first(m)
    @test v == smallest
    @test deref((m,i3)) == v
    i4 = endof(m)
    w = last(m)
    @test w == largest
    @test deref((m,i4)) == w
    i5 = beforestartsemitoken(m)
    @test advance((m,i5)) == i3
    i6 = pastendsemitoken(m)
    @test regress((m,i6)) == i4
    @test advance((m,i5)) != i4
    @test regress((m,i6)) != i3
    j1 = searchsortedfirst(m,0.5)
    j2 = searchsortedlast(m,0.5)
    j3 = searchsortedafter(m,0.5)
    @test deref((m,j1)) > 0.5
    @test deref((m,j2)) < 0.5
    @test advance((m,j2)) == j1
    @test j1 == j3
    k1 = searchsortedfirst(m,smallest)
    k2 = searchsortedlast(m,smallest)
    k3 = searchsortedafter(m,smallest)
    @test deref((m,k1)) == smallest
    @test deref((m,k2)) == smallest
    @test deref((m,regress((m,k3)))) == smallest
    secondsmallest = deref((m,k3))
    sk = searchsortedfirst(m,0.4)
    ek = searchsortedfirst(m,0.6)
    dcount = 0
    for (st,k) in semitokens(exclusive(m,sk,ek))
        delete!((m,st))
        dcount += 1
        if dcount % 20 == 0
            checkcorrectness(m.bt, false)
        end
    end
    newcount = 0
    for k in m
        newcount += 1
        @test k < 0.4 || k > 0.6
    end
    @test newcount == N - dcount
    @test smallest in m
    @test haskey(m,smallest)
    @test !(0.5 in m)
    @test !haskey(m,0.5)
    @test eltype(m) == Float64
    @test eltype(typeof(m)) == Float64
    @test keytype(m) == Float64
    @test keytype(typeof(m)) == Float64
    @test orderobject(m) == Forward
    @test ordtype(m) == ForwardOrdering
    @test ordtype(typeof(m)) == ForwardOrdering
    pop!(m, smallest)
    checkcorrectness(m.bt, false)
    @test length(m) == N - dcount - 1
    key1 = pop!(m)
    @test key1 == secondsmallest
    @test length(m) == N - dcount - 2
    checkcorrectness(m.bt, false)
    @test !isempty(m)
    empty!(m)
    @test isempty(m)
    m1 = SortedSet(["blue", "orange", "red"])
    m2 = SortedSet(["orange", "blue", "red"])
    m3 = SortedSet(["orange", "yellow", "red"])
    m3empty = similar(m3)
    @test eltype(m3empty) == Compat.ASCIIString &&
       length(m3empty) == 0
    @test isequal(m1,m2)
    @test !isequal(m1,m3)
    @test !isequal(m1, SortedSet(["blue"]))
    m4 = packcopy(m3)
    @test isequal(m3,m4)
    m5 = packdeepcopy(m4)
    @test isequal(m3,m4)
    m6 = deepcopy(m5)
    @test isequal(m3,m5)
    checkcorrectness(m1.bt, false)
    checkcorrectness(m2.bt, false)
    checkcorrectness(m3.bt, false)
    checkcorrectness(m4.bt, false)
    checkcorrectness(m5.bt, false)
    checkcorrectness(m5.bt, false)
    m7 = union(m1, ["yellow"])
    m8 = union(m3, SortedSet(["blue"]))
    @test isequal(m7,m8)
    @test !isequal(m1,m8)
    union!(m1, ["yellow"])
    @test isequal(m1,m8)
    m8a = intersect(m8)
    @test isequal(m8a,m8)
    m9 = intersect(m8, SortedSet(["yellow", "red", "white"]))
    @test isequal(m9, SortedSet(["red", "yellow"]))
    m9a = intersect(m8, SortedSet(["yellow", "red", "white"]), m8)
    @test isequal(m9a, SortedSet(["red", "yellow"]))
    m10 = symdiff(m8,  SortedSet(["yellow", "red", "white"]))
    @test isequal(m10, SortedSet(["white", "blue", "orange"]))
    m11 = symdiff(m8, SortedSet(["yellow", "red", "blue", "orange",
                                 "zinc"]))
    @test isequal(m11, SortedSet(["zinc"]))
    m12 = symdiff(SortedSet(["yellow", "red", "blue", "orange",
                                 "zinc"]), m8)
    @test isequal(m12, SortedSet(["zinc"]))
    m13 = setdiff(m8, SortedSet(["yellow", "red", "white"]))
    @test isequal(m13, SortedSet(["blue", "orange"]))
    m14 = setdiff(m8, SortedSet(["blue"]))
    @test isequal(m14, SortedSet(["orange", "yellow", "red"]))
    @test issubset(["yellow", "blue"], m8)
    @test !issubset(["blue", "green"], m8)
    setdiff!(m8, SortedSet(["yellow", "red", "white"]))
    @test isequal(m8, SortedSet(["blue", "orange"]))
end


# test the constructors of SortedDict and SortedMultiDict

@testset "SortedDictConstructors" begin
    sd1 = SortedDict("w" => 64, "p" => 12)
    @test length(sd1) == 2 && first(sd1) == ("p"=>12) &&
        last(sd1) == ("w"=>64)
    sd2 = SortedDict(Reverse, "w" => 64, "p" => 12)
    @test length(sd2) == 2 && last(sd2) == ("p"=>12) &&
        first(sd2) == ("w"=>64)
    sd3 = SortedDict(("w"=>64, "p"=>12))
    @test length(sd3) == 2 && first(sd3) == ("p"=>12) &&
        last(sd3) == ("w"=>64)
    sd4 = SortedDict(("w"=>64, "p"=>12), Reverse)
    @test length(sd4) == 2 && last(sd4) == ("p"=>12) &&
        first(sd4) == ("w"=>64)

    @test typeof(SortedDict()) == SortedDict{Any,Any,ForwardOrdering}
    @test typeof(SortedDict(CaseInsensitive())) == SortedDict{Any,Any,CaseInsensitive}
    @test typeof(SortedDict{Int,Int}(Reverse)) == SortedDict{Int,Int,ReverseOrdering{ForwardOrdering}}
    @test typeof(SortedDict{Int,Int}(Reverse, 1=>2)) == SortedDict{Int,Int,ReverseOrdering{ForwardOrdering}}
    @test typeof(SortedDict{Int,Int}(1=>2)) == SortedDict{Int,Int,ForwardOrdering}
end

@testset "SortedMultiDictConstructors" begin
    sm1 = SortedMultiDict("w" => 64, "p" => 12, "p" => 9)
    @test length(sm1) == 3 && first(sm1) == ("p"=>12) &&
        last(sm1) == ("w"=>64)
    sm2 = SortedMultiDict(Reverse, "w" => 64, "p" => 12, "p" => 9)
    @test length(sm2) == 3 && last(sm2) == ("p"=>9) &&
        first(sm2) == ("w"=>64)
    sm3 = SortedMultiDict(("w"=>64, "p"=>12, "p"=> 9))
    @test length(sm3) == 3 && first(sm3) == ("p"=>12) &&
        last(sm3) == ("w"=>64)
    sm4 = SortedMultiDict(("w"=> 64, "p"=>12, "p"=>9), Reverse)
    @test length(sm4) == 3 && last(sm4) == ("p"=>9) &&
        first(sm4) == ("w"=>64)

    @test typeof(SortedMultiDict()) == SortedMultiDict{Any,Any,ForwardOrdering}
    @test typeof(SortedMultiDict(CaseInsensitive())) == SortedMultiDict{Any,Any,CaseInsensitive}
    @test typeof(SortedMultiDict{Int,Int}(Reverse)) == SortedMultiDict{Int,Int,ReverseOrdering{ForwardOrdering}}
    # @test typeof(SortedMultiDict{Int,Int}(Reverse, 1=>2)) == SortedMultiDict{Int,Int,ReverseOrdering{ForwardOrdering}}
    # @test typeof(SortedMultiDict{Int,Int}(1=>2)) == SortedMultiDict{Int,Int,ForwardOrdering}
end

end # Testset


## sorted_dict_timing{123} are not run by package testing
## but are included for timing tests.
## They are identical except for their usage of ordering objects.

function sorted_dict_timing1(numtrial::Int, expectedk::String, expectedd::String)
    NSTRINGPAIR = 50000
    m1 = SortedDict{Compat.ASCIIString,Compat.ASCIIString}()
    strlist = Compat.ASCIIString[]
    open(seekfile("wordsScram.txt"), "r") do inio
        for j = 1 : NSTRINGPAIR * 2
            push!(strlist, chomp(readline(inio)))
        end
    end
    for trial = 1 : numtrial
        empty!(m1)
        count = 1
        for j = 1 : NSTRINGPAIR
            k = strlist[count]
            d = strlist[count + 1]
            m1[k] = d
            count += 2
        end
        delct = div(NSTRINGPAIR, 6)
        for j = 1 : delct
            l = find(m1, strlist[j * 2 + 1])
            delete!((m1,l))
        end
        spec = div(NSTRINGPAIR * 3,4)
        l = startof(m1)
        for j = 1 : spec
            l = advance((m1,l))
        end
        k,d = deref((m1,l))
        ekn = expectedk
        edn = expectedd
        @test k == ekn && d == edn
    end
end



function sorted_dict_timing2(numtrial::Int, expectedk::String, expectedd::String)
    NSTRINGPAIR = 50000
    m1 = SortedDict((Dict{Compat.ASCIIString, Compat.ASCIIString}()), Lt(isless))
    strlist = Compat.ASCIIString[]
    open(seekfile("wordsScram.txt"), "r") do inio
        for j = 1 : NSTRINGPAIR * 2
            push!(strlist, chomp(readline(inio)))
        end
    end
    for trial = 1 : numtrial
        empty!(m1)
        count = 1
        for j = 1 : NSTRINGPAIR
            k = strlist[count]
            d = strlist[count + 1]
            m1[k] = d
            count += 2
        end
        delct = div(NSTRINGPAIR, 6)
        for j = 1 : delct
            l = find(m1, strlist[j * 2 + 1])
            delete!((m1,l))
        end
        spec = div(NSTRINGPAIR * 3,4)
        l = startof(m1)
        for j = 1 : spec
            l = advance((m1,l))
        end
        k,d = deref((m1,l))
        ekn = expectedk
        edn = expectedd
        @test k == ekn && d == edn
    end
end

function SDConstruct(a::Associative; lt::Function=isless, by::Function=identity)
    if by == identity
        return SortedDict(a, Lt(lt))
    elseif lt == isless
        return SortedDict(a, By(by))
    else
        throw(ErrorException("having both by and lt not both implemented"))
    end
end


function sorted_dict_timing3(numtrial::Int, expectedk::String, expectedd::String)
    NSTRINGPAIR = 50000
    m1 = SDConstruct((Dict{Compat.ASCIIString,Compat.ASCIIString}()), lt=isless)
    strlist = Compat.ASCIIString[]
    open(seekfile("wordsScram.txt"), "r") do inio
        for j = 1 : NSTRINGPAIR * 2
            push!(strlist, chomp(readline(inio)))
        end
    end
    for trial = 1 : numtrial
        empty!(m1)
        count = 1
        for j = 1 : NSTRINGPAIR
            k = strlist[count]
            d = strlist[count + 1]
            m1[k] = d
            count += 2
        end
        delct = div(NSTRINGPAIR, 6)
        for j = 1 : delct
            l = find(m1, strlist[j * 2 + 1])
            delete!((m1,l))
        end
        spec = div(NSTRINGPAIR * 3,4)
        l = startof(m1)
        for j = 1 : spec
            l = advance((m1,l))
        end
        k,d = deref((m1,l))
        ekn = expectedk
        edn = expectedd
        @test k == ekn && d == edn
    end
end
