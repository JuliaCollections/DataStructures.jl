using DataStructures
using Compat
import Base.Ordering
import Base.Forward
import Base.Reverse
import DataStructures.eq
import Base.lt
import Base.ForwardOrdering

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
        println("j = $j k = /$k/ d = /$d/ parent = /$p/")
    end
    println("----- FREE DATA CELLS -----")
    for i = 1 : size(t.freedatainds,1)
        println(t.freedatainds[i])
    end
end


## Function checkcorrectness checks a balanced tree for correctness.

function checkcorrectness{K,D,Ord <: Ordering}(t::DataStructures.BalancedTree23{K,D,Ord})
    dsz = size(t.data, 1)
    tsz = size(t.tree, 1)
    r = t.rootloc
    bfstreenodes = Array(Int, 0)
    tdpth = t.depth
    intree = IntSet()
    levstart = Array(Int, tdpth)
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
                error("Tree contains loops 1")
            end
            push!(bfstreenodes, c1)
            push!(intree, c1)
            c2 = t.tree[anc].child2
            if in(c2, intree)
                error("Tree contains loops 2")
            end
            push!(bfstreenodes, c2)
            push!(intree, c2)
            c3 = t.tree[anc].child3
            if c3 > 0
                if in(c3, intree)
                    error("Tree contains loops 3")
                end
                push!(bfstreenodes, c3)
                push!(intree, c3)
            end
        end
    end
    bfstreesize = size(bfstreenodes, 1)
    dataused = IntSet()
    minkeys = Array(K, bfstreesize)
    maxkeys = Array(K, bfstreesize)
    for s = levstart[tdpth] : bfstreesize
        anc = bfstreenodes[s]
        c1 = t.tree[anc].child1
        if s == levstart[tdpth]
            if c1 != 1
                error("Leftmost data descendant should be node 1")
            end
        else
            minkeys[s] = t.data[c1].k
        end
        c2 = t.tree[anc].child2
        c3 = t.tree[anc].child3
        lastchild = c3 > 0? c3 : c2
        if s == bfstreesize
            if lastchild != 2
                error("Rightmost data descendant should be node 2")
            end
        else
            maxkeys[s] = t.data[lastchild].k
        end
        if s > levstart[tdpth] && !lt(t.ord, maxkeys[s - 1], minkeys[s])
            error("Data nodes out of order")
        end
        if s < bfstreesize || c3 > 0
            if !eq(t.ord, t.tree[anc].splitkey1, t.data[c2].k)
                error("Splitkey1 of leaf should match key of 2nd child")
            end
        end
        if s < bfstreesize && c3 > 0
            if !eq(t.ord, t.tree[anc].splitkey2, t.data[c3].k)
                error("Splitkey2 of leaf should match key of 1st child")
            end
        end
        if t.data[c1].parent != anc || t.data[c2].parent != anc ||
            (c3 > 0 && t.data[c3].parent != anc)
            println("c1 = $c1 c2 = $c2 c3 = $c3 anc = $anc")
            println("t.data[c1].parent = $(t.data[c1].parent) t.data[c2].parent = $(t.data[c2].parent)")
            if c3 > 0
                println("t.data[c3].parent = $(t.data[c3].parent)")
            end
            error("Incorrect parent node for data child")
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
                error("Parent/child1 links do not match")
            end
            c2 = t.tree[anc].child2
            @assert(c2 == bfstreenodes[cp])
            mk2 = minkeys[cp]
            cp += 1
            if t.tree[c2].parent != anc
                error("Parent/child2 links do not match")
            end
            c3 = t.tree[anc].child3
            @assert(s == levstart[curdepth] || lt(t.ord,mk1,mk2))
            if c3 > 0 
                if t.tree[c3].parent != anc
                    error("Parent/child3 links do not match")
                end
                mk3 = minkeys[cp]
                cp += 1
                @assert(lt(t.ord,mk2, mk3))
            end
            if s > levstart[curdepth]
                minkeys[s] = mk1
            end
            if !eq(t.ord, t.tree[anc].splitkey1, mk2)
                error("Minkey2 not equal to minimum key among descendants of child2")
            end
            if c3 > 0 && !eq(t.ord, t.tree[anc].splitkey2, mk3)
                error("Minkey3 not equal to minimum key among descendants of child3")
            end
        end
    end
    freedata = IntSet()
    for i = 1 : size(t.freedatainds,1)
        fdi = t.freedatainds[i]
        if in(fdi, freedata)
            error("t.freedatainds has repeated element $i")
        end
        if fdi < 1 || fdi > dsz
            error("t.freedatainds entry out of range")
        end
        push!(freedata, fdi)
    end
    if in(:useddatacells, names(DataStructures.BalancedTree23))
        if last(t.useddatacells) > dsz
            error("t.useddatacells has indices larger than t.data size")
        end
        for i = 1 : dsz
            if (in(i, dataused) && !in(i, t.useddatacells)) ||
                (!in(i,dataused) && in(i, t.useddatacells))
                error("Mismatch between actual data cells used and useddatacells array")
            end
            if (in(i, freedata) && in(i, dataused)) ||
                (!in(i,freedata) && !in(i, dataused))
                error("Mismatch between t.freedatainds and t.useddatacells")
            end
        end
    end
    freetree = IntSet()
    for i = 1 : size(t.freetreeinds,1)
        tfi = t.freetreeinds[i]
        if in(tfi, freetree)
            error("Free tree index repeated twice")
        end
        if tfi < 1 || tfi > tsz
            error("Free tree index out of range")
        end
        push!(freetree, tfi)
    end
    for i = 1 : tsz
        if (!in(i, intree) && !in(i, freetree)) ||
            (in(i, intree) && in(i, freetree))
            error("Mismatch between t.freetreeinds and actual cells used")
        end
    end
end



function test1()
    # a few basic tests to start
    m1 = SortedDict((@compat Dict{ASCIIString,ASCIIString}()), Forward)
    kdarray = ["hello", "jello", "alpha", "beta", "fortune", "random",
               "july", "wednesday"]
    checkcorrectness(m1.bt)
    for i = 1 : div(size(kdarray,1), 2)
        k = kdarray[i*2-1]
        d = kdarray[i*2]
        #println("- inserting: k = $k d = $d")
        m1[k] = d
        checkcorrectness(m1.bt)
        # fulldump(m1.bt)
    end
    i1 = startof(m1)
    count = 0
    while i1 != pastendtoken(m1)
        count += 1
        k,d = deref(i1)
        #println("+ reading: k = $k, d = $d")
        i1 = advance(i1)
        checkcorrectness(m1.bt)
    end
    @test count == 4
end

function test2()
    # test all the methods here except loops
    m0 = SortedDict(@compat Dict{Int, Float64}())
    m1 = SortedDict(@compat Dict(8=>32.0, 12=>33.1, 6=>18.2))
    expected = ([6,8,12], [18.2, 32.0, 33.1])
    checkcorrectness(m1.bt)
    ii = startof(m1)
    m2 = packdeepcopy(m1)
    m3 = packcopy(m1)
    p = first(m1)
    @test p[1] == 6 && p[2] == 18.2
    @test in((8,32.0),m3)
    @test !in((8,32.1),m3)
    for j = 1 : 3
        @test ii != pastendtoken(m1)
        pr = deref(ii)
        @test pr[1] == expected[1][j] && pr[2] == expected[2][j]
        checkcorrectness(m1.bt)
        oldii = ii
        ii = advance(ii)
        delete!(oldii)
    end
    checkcorrectness(m1.bt)
    checkcorrectness(m2.bt)
    @test length(m2) == 3
    ii = startof(m2)
    for j = 1 : 3
        pr = deref(ii)
        @test pr[1] == expected[1][j] && pr[2] == expected[2][j]
        ii = advance(ii)
    end

    checkcorrectness(m3.bt)
    @test length(m3) == 3
    ii = startof(m3)
    for j = 1 : 3
        pr = deref(ii)
        @test pr[1] == expected[1][j] && pr[2] == expected[2][j]
        ii = advance(ii)
    end

    @test isempty(m1)
    @test length(m1) == 0
    N = 5000
    for i = N : -1 : 2
        m1[i] = convert(Float64,i) ^ 2
        if i % 50 == 0
            checkcorrectness(m1.bt)
        end
    end
    @test !isempty(m1)
    assert(length(m1) == N - 1)
    for i = 2 : N
        d = pop!(m1, i)
        @test d == convert(Float64,i)^2
        checkcorrectness(m1.bt)
    end
    @test isempty(m1)
    @test length(m1) == 0
    for i = N : -1 : 2
        m1[i] = convert(Float64,i) ^ 2
        checkcorrectness(m1.bt)
    end
    ii = endof(m1)
    for i = 1 : N - 1
        pr = deref(ii)
        @test pr[1] == N + 1 - i && pr[2] == convert(Float64,pr[1]) ^ 2
        ii = regress(ii)
    end
    lastprime = 1
    while true
        ii = searchsortedafter(m1, lastprime)
        if ii == pastendtoken(m1)
            break
        end
        j = deref_key(ii)
        for k = j * 2 : j : N
            p = find(m1, k)
            if p != pastendtoken(m1)
                delete!(p)
                checkcorrectness(m1.bt)
            end
        end
        lastprime = j
    end
    @test ii == pastendtoken(m1)
    @test status(ii) == 3
    h = assemble(m1, semi(ii))
    @test status(h) == 3
    h2 = assemble(m1, SDSemiToken(0))
    @test status(h2) == 0
    t = 0
    u = 0.0
    for pr = m1
        t += pr[1]
        u += pr[2]
    end
    numprimes = length(m1)
    pn = primes(N)
    @test t == sum(pn)
    @test u == sum(pn.^2)
    ij = endof(m1)
    @test deref_key(ij) == last(pn) && convert(Float64, last(pn)^2) ==  deref_value(ij)
    m1[6] = 49.0
    @test length(m1) == numprimes + 1
    @test m1[6] == 49.0
    b, i6 = insert!(m1, 6, 50.0)
    @test length(m1) == numprimes + 1
    @test !b
    p = deref(i6)
    @test p[1] == 6 && p[2] == 50.0
    b2, i7 = insert!(m1, 8, 51.0)
    @test b2
    st = semi(i6)
    m1[st] = 9.0
    p = deref(i6)
    @test p[1] == 6 && p[2] == 9.0
    @test m1[st] == 9.0
    @test length(m1) == numprimes + 2
    p = deref(i7)
    @test p[1] == 8 && p[2] == 51.0
    delete!(i7)
    z = pop!(m1, 6)
    checkcorrectness(m1.bt)
    @test z == 9.0
    i8 = startof(m1)
    p = deref(i8)
    @test p[1] == 2 && p[2] == 4.0
    @test i8 != beforestarttoken(m1)
    @test status(i8) == 1
    i9 = regress(i8)
    @test i9 == beforestarttoken(m1)
    @test status(i9) == 2
    i10 = find(m1, 17)
    i11 = regress(i10)
    @test deref_key(i11) == 13
    i12 = searchsortedfirst(m1, 47)
    i13 = searchsortedfirst(m1, 48)
    @test deref_key(i12) == 47
    @test deref_key(i13) == 53
    i14 = searchsortedafter(m1, 47)
    i15 = searchsortedafter(m1, 48)
    @test deref_key(i14) == 53
    @test deref_key(i15) == 53
    i16 = searchsortedlast(m1, 47)
    i17 = searchsortedlast(m1, 48)
    @test deref_key(i16) == 47
    @test deref_key(i17) == 47
    ww = primes(N)
    cc = last(m1)
    @test cc[1] == last(ww)
    wwx = first(m1)
    @test wwx[1] == 2
    tpr = eltype(m1)
    @test tpr[1] == Int && tpr[2] == Float64
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
    @test deref_key(advance(find(m1,13))) == 19
    empty!(m1)
    checkcorrectness(m1.bt)
    @test isempty(m1)
    c1 = SortedDict(@compat Dict("Eggplants"=>3, 
                        "Figs"=>9, 
                        "Apples"=>7))
    c2 = SortedDict(@compat Dict("Eggplants"=>6, 
                        "Honeydews"=>19, 
                        "Melons"=>11))
    @test !isequal(c1,c2)
    c3 = merge(c1, c2)
    checkcorrectness(c3.bt)
    c4 = SortedDict(@compat Dict("Apples"=>7, 
                        "Figs"=>9,
                        "Eggplants"=>6,
                        "Melons"=>11,
                        "Honeydews"=>19))
    @test isequal(c3,c4)
    c5 = SortedDict(@compat Dict("Apples"=>7))
    @test !isequal(c4,c5)
    merge!(c1,c2)
    checkcorrectness(c1.bt)
    @test isequal(c3,c1)
    merge!(c3,c3)
    @test isequal(c3,c1)
    checkcorrectness(c3.bt)
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



## Test the loop constructs.
function test3{T}(z::T)
    zero1 = zero(z)
    one1 = one(z)
    two1 = one1 + one1
    m1 = SortedDict(@compat Dict{T,T}())
    N = 1000
    for l = 1 : N
        lUi = convert(T, l)
        m1[bitreverse(lUi)] = lUi
    end
    count = 0
    for (tok,(k,v)) in tokens(startof(m1) : endof(m1))
        for (tok2,(k2,v2)) in tokens(excludelast(startof(m1), pastendtoken(m1)))
            if isless(tok,tok2)
                @test deref_key(tok) < deref_key(tok2)
            elseif isequal(tok,tok2)
                @test deref_key(tok) == deref_key(tok2)
            else
                @test deref_key(tok) > deref_key(tok2)
            end
            count += 1
        end
    end
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
    @test sk2 == sk
    sv2 = zero1
    for v in values(m1)
        sv2 += v
    end
    @test sv == sv2
    count = 0
    for (t,k) in tokens(keys(m1))
        @test deref_key(t) == k
        count += 1
    end
    @test count == N
    count = 0
    for (t,v) in tokens(values(m1))
        @test deref_value(t) == v
        count += 1
    end
    @test count == N

    pos1 = searchsortedfirst(m1, div(N,2))
    sk2 = zero1
    for k in keys(excludelast(startof(m1), pos1))
        sk2 += k
    end
    @test sk2 == skhalf
    sv2 = zero1
    for v in values(excludelast(startof(m1), pos1))
        sv2 += v
    end
    @test sv2 == svhalf
    count = 0
    for (k,v) in excludelast(pastendtoken(m1), pastendtoken(m1))
        count += 1
    end
    @test count == 0
    count = 0
    for (k,v) in startof(m1) :  beforestarttoken(m1)
        count += 1
    end
    @test count == 0
end    


# test all the errors
function test4()
    m = SortedDict(@compat Dict("a" => 6, "bb" => 9))
    @test_throws KeyError println(m["b"])
    m2 = SortedDict(@compat Dict{ASCIIString, Int}())
    @test_throws BoundsError println(first(m2))
    @test_throws BoundsError println(last(m2))
    state1 = start(m2)
    @test_throws BoundsError next(m2, state1)
    @test_throws ArgumentError beforestarttoken(m) : pastendtoken(m2)
    @test_throws ArgumentError excludelast(beforestarttoken(m), pastendtoken(m2))
    @test_throws ArgumentError isless(beforestarttoken(m), pastendtoken(m2))
    @test_throws ArgumentError isequal(beforestarttoken(m), pastendtoken(m2))
    i1 = find(m,"a")
    delete!(i1)
    i2 = find(m,"bb")
    @test_throws BoundsError start(i1:i2)
    @test_throws BoundsError start(excludelast(i1,i2))
    @test_throws KeyError delete!(m,"a")
    @test_throws KeyError pop!(m,"a")
    m3 = SortedDict((@compat Dict{ASCIIString, Int}()), Reverse)
    @test_throws ErrorException isequal(m2, m3)
    i1semi = semi(i1)
    @test_throws BoundsError m[i1semi]
    @test_throws BoundsError regress(beforestarttoken(m))
    @test_throws BoundsError advance(pastendtoken(m))
end



function seekfile(fname)
    fullname = joinpath(Pkg.dir("DataStructures"), "test", fname)
end

immutable CaseInsensitive <: Ordering
end

lt(::CaseInsensitive, a, b) = isless(lowercase(a), lowercase(b))
eq(::CaseInsensitive, a, b) = isequal(lowercase(a), lowercase(b))




## Test use of alternative orderings

function test5()
    keylist = ["Apple", "aPPle", "berry", "CHerry", "Dairy", "diary"]
    vallist = [6,9,-4,2,1,8]
    m = SortedDict(@compat Dict{ASCIIString,Int}())
    for j = 1:6
        m[keylist[j]] = vallist[j]
    end
    checkcorrectness(m.bt)
    expectedord1 = [1,4,5,2,3,6]
    count = 0
    for p in m
        count += 1
        @test p[1] == keylist[expectedord1[count]] && 
                p[2] == vallist[expectedord1[count]]
    end
    @test count == 6
    m2 = SortedDict((@compat Dict{ASCIIString, Int}()), Reverse)
    for j = 1 : 6
        m2[keylist[j]] = vallist[j]
    end
    checkcorrectness(m2.bt)
    expectedord2 = [6,3,2,5,4,1]
    count = 0
    for p in m2
        count += 1
        @test p[1] == keylist[expectedord2[count]] && 
                p[2] == vallist[expectedord2[count]]
    end
    @test count == 6
    m3 = SortedDict((@compat Dict{ASCIIString, Int}()), CaseInsensitive())
    for j = 1 : 6
        m3[keylist[j]] = vallist[j]
    end
    checkcorrectness(m3.bt)
    expectedord3 = [2,3,4,5,6]
    count = 0
    for p in m3
        count += 1
        @test p[1] == keylist[expectedord3[count]] &&
                p[2] == vallist[expectedord3[count]]
    end
    @test count == 5
    m4 = SortedDict((@compat Dict{ASCIIString,Int}()), Lt((x,y) -> isless(lowercase(x),lowercase(y))))
    for j = 1 : 6
        m4[keylist[j]] = vallist[j]
    end
    checkcorrectness(m4.bt)
    count = 0
    for p in m4
        count += 1
        @test p[1] == keylist[expectedord3[count]] &&
                p[2] == vallist[expectedord3[count]]
    end
    @test count == 5
end
    

## test6, test6a and test6b are not run by package
## testing but are included for timing tests.
## They are identical except for their usage of ordering objects.

function test6(numtrial::Int, expectedk::ASCIIString, expectedd::ASCIIString)
    NSTRINGPAIR = 50000
    m1 = SortedDict(@compat Dict{ASCIIString,ASCIIString}())
    strlist = ASCIIString[]
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
            delete!(l)
        end
        spec = div(NSTRINGPAIR * 3,4)
        l = startof(m1)
        for j = 1 : spec
            l = advance(l)
        end
        k,d = deref(l)
        ekn = expectedk
        edn = expectedd
        @test k == ekn && d == edn
    end
end



function test6a(numtrial::Int, expectedk::ASCIIString, expectedd::ASCIIString)
    NSTRINGPAIR = 50000
    m1 = SortedDict((@compat Dict{ASCIIString, ASCIIString}()), Lt(isless))
    strlist = ASCIIString[]
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
            delete!(l)
        end
        spec = div(NSTRINGPAIR * 3,4)
        l = startof(m1)
        for j = 1 : spec
            l = advance(l)
        end
        k,d = deref(l)
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
        error("having both by and lt not both implemented")
    end
end

    


function test6b(numtrial::Int, expectedk::ASCIIString, expectedd::ASCIIString)
    NSTRINGPAIR = 50000
    m1 = SDConstruct((@compat Dict{ASCIIString,ASCIIString}()), lt=isless)
    strlist = ASCIIString[]
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
            delete!(l)
        end
        spec = div(NSTRINGPAIR * 3,4)
        l = startof(m1)
        for j = 1 : spec
            l = advance(l)
        end
        k,d = deref(l)
        ekn = expectedk
        edn = expectedd
        @test k == ekn && d == edn
    end
end




test1()
test2()
test3(0x00000000)
test4()
test5()
#test6(2, "soothingly", "compere")

