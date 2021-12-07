import Base.Ordering
import Base.Forward
import Base.Reverse
import DataStructures.eq
import Base.lt
import Base.ForwardOrdering
import Base.ReverseOrdering
import DataStructures.IntSemiToken

struct CaseInsensitive <: Ordering
end

lt(::CaseInsensitive, a, b) = isless(lowercase(a), lowercase(b))
eq(::CaseInsensitive, a, b) = isequal(lowercase(a), lowercase(b))

@noinline my_assert(stmt) = stmt ? nothing : throw(AssertionError("assertion failed"))

function my_primes(N)
    w = Vector{Bool}(undef, N)
    fill!(w,true)
    for k = 2 : N
        if w[k]
            w[2 * k : k : N] .= false
        end
    end
    p = Int[]
    for k = 2 : N
        if w[k]
            push!(p,k)
        end
    end
    p
end






## Function checkcorrectness checks a balanced tree for correctness.

function checkcorrectness(t::DataStructures.BalancedTree23{K,D,Ord},
                          allowdups=false)  where {K,D,Ord <: Ordering}
    dsz = size(t.data, 1)
    tsz = size(t.tree, 1)
    r = t.rootloc
    bfstreenodes = Vector{Int}()
    tdpth = t.depth
    intree = BitSet()
    levstart = Vector{Int}(undef, tdpth)
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
    dataused = BitSet()
    minkeys = Vector{K}(undef, bfstreesize)
    maxkeys = Vector{K}(undef, bfstreesize)
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
        lastchild = c3 > 0 ? c3 : c2
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
            my_assert(c1 == bfstreenodes[cp])
            if s > levstart[curdepth]
                mk1 = minkeys[cp]
            end
            cp += 1
            if t.tree[c1].parent != anc
                throw(ErrorException("Parent/child1 links do not match"))
            end
            c2 = t.tree[anc].child2
            my_assert(c2 == bfstreenodes[cp])
            mk2 = minkeys[cp]
            cp += 1
            if t.tree[c2].parent != anc
                throw(ErrorException("Parent/child2 links do not match"))
            end
            c3 = t.tree[anc].child3
            my_assert(s == levstart[curdepth] ||
                    lt(t.ord,mk1,mk2) || (!lt(t.ord,mk2,mk1) && allowdups))
            if c3 > 0
                if t.tree[c3].parent != anc
                    throw(ErrorException("Parent/child3 links do not match"))
                end
                mk3 = minkeys[cp]
                cp += 1
                my_assert(lt(t.ord,mk2, mk3) ||
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
    freedata = BitSet()
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
    freetree = BitSet()
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


function testSortedDictBasic()
    # a few basic tests of SortedDict to start
    m1 = SortedDict((Dict{String,String}()), Forward)
    my_assert(typeof(m1) == SortedDict{String, String, ForwardOrdering})
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
    my_assert(count == 4)
    true
end

function testSortedDictMethods()
    # test all methods of SortedDict here except loops
    m0 = SortedDict(Dict{Int, Float64}())
    my_assert(typeof(m0) == SortedDict{Int,Float64,ForwardOrdering})
    m1 = SortedDict(Dict(8=>32.0, 12=>33.1, 6=>18.2))
    my_assert(typeof(m1) == SortedDict{Int,Float64,ForwardOrdering})
    m01 = SortedDict(8=>32.0, 12=>33.1, 6=>18.2)
    my_assert(typeof(m01) == SortedDict{Int,Float64,ForwardOrdering})
    m11 = SortedDict((8=>32.0, 12=>33.1, 6=>18.2))
    my_assert(typeof(m11) == SortedDict{Int,Float64,ForwardOrdering})
    m02 = SortedDict{Int,Float64}()
    my_assert(typeof(m02) == SortedDict{Int,Float64,ForwardOrdering})
    m03 = SortedDict([(1,2.0), (3,4.0), (5,6.0)])
    my_assert(typeof(m03) == SortedDict{Int,Float64,ForwardOrdering})
    m04 = SortedDict{Int,Float64}(Pair[1=>1, 2=>2.0])
    my_assert(typeof(m04) == SortedDict{Int,Float64,ForwardOrdering})
    m05 = SortedDict{Int,Float64}(Reverse, Pair[1=>1, 2=>2.0])
    my_assert(typeof(m05) == SortedDict{Int,Float64,ReverseOrdering{ForwardOrdering}})
    m06a = SortedDict(Pair[1=>2.0, 3=>'a'])
    my_assert(typeof(m06a) == SortedDict{Any,Any,ForwardOrdering})
    m06b = SortedDict([(1,2.0), (3,'a')])
    my_assert(typeof(m06b) == SortedDict{Int,Any,ForwardOrdering})
    m07a = SortedDict(Pair[1.0=>2, 2=>3])
    my_assert(typeof(m07a) == SortedDict{Any,Any,ForwardOrdering})
    m07b = SortedDict([(1.0,2), (2,3)])
    my_assert(typeof(m07b) == SortedDict{Real,Int,ForwardOrdering})
    m08a = SortedDict(Pair[1.0=>2, 2=>'a'])
    my_assert(typeof(m08a) == SortedDict{Any,Any,ForwardOrdering})
    m08b = SortedDict([(1.0,2), (2,'a')])
    my_assert(typeof(m08b) == SortedDict{Real,Any,ForwardOrdering})
    m09a = SortedDict(Pair{Int}[1=>2, 3=>'a'])
    my_assert(typeof(m09a) == SortedDict{Int,Any,ForwardOrdering})
    m09b = SortedDict([(1,2), (3,'a')])
    my_assert(typeof(m09a) == SortedDict{Int,Any,ForwardOrdering})

    my_assert(m0 == m02)
    my_assert(isequal(m0, m02))
    my_assert(m1 == m01)
    my_assert(isequal(m1, m01))
    my_assert(m1 == m11)
    my_assert(isequal(m1, m11))

    # Test Exceptions
    @test_throws ArgumentError SortedDict([1,2,3,4])
    @test_throws ArgumentError SortedDict{Int,Int}([1,2,3,4])


    expected = ([6,8,12], [18.2, 32.0, 33.1])
    checkcorrectness(m1.bt, false)
    ii = startof(m1)
    m2 = packdeepcopy(m1)
    m3 = packcopy(m1)
    p = first(m1)
    my_assert(p[1] == 6 && p[2] == 18.2)
    my_assert(in(Pair(8,32.0),m3))
    my_assert(!in(Pair(8,32.1),m3))
    push!(m1, 12 => 33.2)
    checkcorrectness(m1.bt, false)
    my_assert(length(m1) == 3)
    my_assert(m1[12] == 33.2)
    push!(m1, 12 => 33.1)
    my_assert(length(m1) == 3)
    my_assert(m1[12] == 33.1)
    for j = 1 : 3
        my_assert(ii != pastendsemitoken(m1))
        pr = deref((m1,ii))
        my_assert(pr[1] == expected[1][j] && pr[2] == expected[2][j])
        checkcorrectness(m1.bt, false)
        oldii = ii
        ii = advance((m1,ii))
        delete!((m1,oldii))
    end
    checkcorrectness(m1.bt, false)
    checkcorrectness(m2.bt, false)
    my_assert(length(m2) == 3)
    ii = startof(m2)
    for j = 1 : 3
        pr = deref((m2,ii))
        my_assert(pr[1] == expected[1][j] && pr[2] == expected[2][j])
        ii = advance((m2,ii))
    end

    checkcorrectness(m3.bt, false)
    my_assert(length(m3) == 3)
    ii = startof(m3)
    for j = 1 : 3
        pr = deref((m3,ii))
        my_assert(pr[1] == expected[1][j] && pr[2] == expected[2][j])
        ii = advance((m3,ii))
    end

    my_assert(isempty(m1))
    my_assert(length(m1) == 0)
    N = 1000
    for i = N : -1 : 2
        m1[i] = convert(Float64,i) ^ 2
        if i % 200 == 0
            checkcorrectness(m1.bt, false)
        end
    end
    my_assert(!isempty(m1))
    my_assert(length(m1) == N - 1)
    for i = 2 : N
        d = pop!(m1, i)
        my_assert(d == convert(Float64,i)^2)
        if i % 200 == 0
            checkcorrectness(m1.bt, false)
        end
    end
    my_assert(isempty(m1))
    my_assert(length(m1) == 0)
    N = 1000
    for i = 2:N
        m1[i] = convert(Float64,i) ^ 2
    end
    my_assert(!isempty(m1))
    my_assert(length(m1) == N - 1)
    for i = 2 : N
        d = pop!(m1, i, -1.0)
        my_assert(d == convert(Float64,i)^2)
        d2 = pop!(m1, i, -1.0)
        my_assert(d2 == -1.0)
        d3 = pop!(m1, i, nothing)
        my_assert(d3 == nothing)

        if i % 200 == 0
            checkcorrectness(m1.bt, false)
        end
    end
    my_assert(isempty(m1))
    my_assert(length(m1) == 0)
    for i = N : -1 : 2
        m1[i] = convert(Float64,i) ^ 2
        if i % 200 == 0
            checkcorrectness(m1.bt, false)
        end
    end
    ii = lastindex(m1)
    for i = 1 : N - 1
        pr = deref((m1,ii))
        my_assert(pr[1] == N + 1 - i && pr[2] == convert(Float64,pr[1]) ^ 2)
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
            p = findkey(m1, k)
            if p != pastendsemitoken(m1)
                delete!((m1,p))
            end
        end
        lastprime = j
    end
    checkcorrectness(m1.bt, false)
    my_assert(ii == pastendsemitoken(m1))
    my_assert(status((m1,ii)) == 3)
    my_assert(status((m1,SDSemiToken(-1))) == 0)
    t = 0
    u = 0.0
    for pr in m1
        t += pr[1]
        u += pr[2]
    end
    numprimes = length(m1)
    pn = convert(Array{Int64}, my_primes(N))
    my_assert(t == sum(pn))
    my_assert(u == sum(pn.^2))
    ij = lastindex(m1)
    my_assert(deref_key((m1,ij)) == last(pn) &&
       convert(Float64, last(pn)^2) ==  deref_value((m1,ij)))
    m1[6] = 49.0
    my_assert(length(m1) == numprimes + 1)
    my_assert(m1[6] == 49.0)
    b, i6 = insert!(m1, 6, 50.0)
    my_assert(length(m1) == numprimes + 1)
    my_assert(!b)
    p = deref((m1,i6))
    my_assert(p[1] == 6 && p[2] == 50.0)
    m1[i6] = 9.0
    p = deref((m1,i6))
    my_assert(p[1] == 6 && p[2] == 9.0)
    my_assert(m1[i6] == 9.0)
    b2, i7 = insert!(m1, 8, 51.0)
    my_assert(b2)
    my_assert(length(m1) == numprimes + 2)
    p = deref((m1,i7))
    my_assert(p[1] == 8 && p[2] == 51.0)
    delete!((m1,i7))
    z = pop!(m1, 6)
    checkcorrectness(m1.bt, false)
    my_assert(z == 9.0)
    i8 = startof(m1)
    p = deref((m1,i8))
    my_assert(p[1] == 2 && p[2] == 4.0)
    my_assert(i8 != beforestartsemitoken(m1))
    my_assert(status((m1,i8)) == 1)
    i9 = regress((m1,i8))
    my_assert(i9 == beforestartsemitoken(m1))
    my_assert(status((m1,i9)) == 2)
    i10 = findkey(m1, 17)
    i11 = regress((m1,i10))
    my_assert(deref_key((m1,i11)) == 13)
    i12 = searchsortedfirst(m1, 47)
    i13 = searchsortedfirst(m1, 48)
    my_assert(deref_key((m1,i12)) == 47)
    my_assert(deref_key((m1,i13)) == 53)
    i14 = searchsortedafter(m1, 47)
    i15 = searchsortedafter(m1, 48)
    my_assert(deref_key((m1,i14)) == 53)
    my_assert(deref_key((m1,i15)) == 53)
    i16 = searchsortedlast(m1, 47)
    i17 = searchsortedlast(m1, 48)
    my_assert(deref_key((m1,i16)) == 47)
    my_assert(deref_key((m1,i17)) == 47)
    ww = my_primes(N)
    cc = last(m1)
    my_assert(cc[1] == last(ww))
    wwx = first(m1)
    my_assert(wwx[1] == 2)
    tpr = eltype(m1)
    my_assert(tpr == Pair{Int,Float64})
    tpr2 = eltype(typeof(m1))
    my_assert(tpr2 == Pair{Int,Float64})
    kt = keytype(m1)
    my_assert(kt == Int)
    kt2 = keytype(typeof(m1))
    my_assert(kt2 == Int)
    vt = valtype(m1)
    my_assert(vt == Float64)
    vt2 = valtype(typeof(m1))
    my_assert(vt2 == Float64)
    my_assert(ordtype(m1) == ForwardOrdering)
    my_assert(ordtype(typeof(m1)) == ForwardOrdering)

    co = orderobject(m1)
    my_assert(co == Forward)
    my_assert(haskey(m1, 71))
    my_assert(!haskey(m1, 77))
    my_assert(get(m1, 70, nothing) == nothing)
    my_assert(get(m1, 70, -45.2) == -45.2)
    my_assert(get(m1, 83, -45.2) == convert(Float64,83)^2)
    h = get!(m1, 5, 27.0)
    my_assert(h == 25.0)
    h = get!(m1, 6, 27.0)
    my_assert(h == 27.0)
    my_assert(m1[6] == 27.0)
    my_assert(length(m1) == length(ww) + 1)
    pop!(m1, 6)
    my_assert(getkey(m1,7, 9) == 7)
    my_assert(getkey(m1,7.0, 9) == 7)
    my_assert(getkey(m1,12, 9) == 9)
    my_assert(getkey(m1,12, nothing) == nothing)
    delete!(m1, 17)
    my_assert(length(m1) == length(ww) - 1)
    my_assert(deref_key((m1,advance((m1,findkey(m1,13))))) == 19)
    empty!(m1)
    checkcorrectness(m1.bt, false)
    my_assert(isempty(m1))
    c1 = SortedDict(Dict("Eggplants"=>3,
                        "Figs"=>9,
                        "Apples"=>7))
    my_assert(typeof(c1) == SortedDict{String, Int, ForwardOrdering})
    c2 = SortedDict(Dict("Eggplants"=>6,
                        "Honeydews"=>19,
                        "Melons"=>11))
    my_assert(!isequal(c1,c2))
    c3 = merge(c1, c2)
    checkcorrectness(c3.bt, false)
    c4 = SortedDict(Dict("Apples"=>7,
                        "Figs"=>9,
                        "Eggplants"=>6,
                        "Melons"=>11,
                        "Honeydews"=>19))
    my_assert(isequal(c3,c4))
    c5 = SortedDict(Dict("Apples"=>7))
    my_assert(!isequal(c4,c5))
    merge!(c1,c2)
    checkcorrectness(c1.bt, false)
    my_assert(isequal(c3,c1))
    merge!(c3,c3)
    my_assert(isequal(c3,c1))
    checkcorrectness(c3.bt, false)

    # issue #216
    my_assert(DataStructures.isordered(SortedDict{Int, String}))


    # check for get! and get
    dfc =  SortedDict{Int, Vector{Int}}()
    x1 = get!(dfc,1,[1])
    my_assert(x1 == [1])
    my_assert(x1 === dfc[1])
    my_assert(x1 === get!(dfc, 1, [1000]))
    my_assert(x1 === get(dfc, 1, [1000]))

    x2 = get!(()->[2], dfc, 2)
    my_assert(x2 == [2])
    my_assert(x2 === dfc[2])
    my_assert(x2 === get!(()->[1000], dfc, 2))
    my_assert(x2 === get(()->[1000], dfc, 2))

    my_assert([42] == get(()->[42], dfc, 3))
    my_assert(!haskey(dfc, 3))
    my_assert([43] == get(dfc, 4, [43]))
    my_assert(!haskey(dfc, 4))
    true
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



function testSortedDictLoops()
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
    for (stok,k,v) in semitokens(inclusive(m1, startof(m1), lastindex(m1)))
        for (stok2,k2,v2) in semitokens(exclusive(m1, startof(m1), pastendsemitoken(m1)))
            c = compare(m1,stok,stok2)
            if c < 0
                my_assert(deref_key((m1,stok)) < deref_key((m1,stok2)))
            elseif c == 0
                my_assert(deref_key((m1,stok)) == deref_key((m1,stok2)))
            else
                my_assert(deref_key((m1,stok)) > deref_key((m1,stok2)))
            end
            count += 1
        end
    end
    my_assert(eltype(semitokens(exclusive(m1, startof(m1), pastendsemitoken(m1)))) ==
           Tuple{IntSemiToken, T, T})
    my_assert(count == N^2)
    N = 1000
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
    my_assert(count == N)
    my_assert(sk2 == sk)
    my_assert(sv == sv2)
    sk2 = zero1
    for k in keys(m1)
        sk2 += k
    end
    my_assert(eltype(keys(m1)) == T)
    my_assert(sk2 == sk)

    sk2a = zero1


    for k in eachindex(m1)
        sk2a += k
    end
    my_assert(eltype(eachindex(m1)) == T)
    my_assert(sk2a == sk)



    sk2b = zero1
    for st in onlysemitokens(m1)
        sk2b += deref_key((m1,st))
    end
    my_assert(sk2b == sk)

    sv2 = zero1
    for v in values(m1)
        sv2 += v
    end
    my_assert(eltype(values(m1)) == T)

    my_assert(sv == sv2)
    count = 0
    for (st,k) in semitokens(keys(m1))
        my_assert(deref_key((m1,st)) == k)
        count += 1
    end
    my_assert(eltype(semitokens(keys(m1))) == Tuple{IntSemiToken, T})

    my_assert(count == N)
    count = 0
    for (st,v) in semitokens(values(m1))
        my_assert(deref_value((m1,st)) == v)
        count += 1
    end
    my_assert(count == N)
    my_assert(eltype(semitokens(values(m1))) == Tuple{IntSemiToken, T})

    pos1 = searchsortedfirst(m1, div(N,2))
    sk2 = zero1
    for k in keys(exclusive(m1, startof(m1), pos1))
        sk2 += k
    end
    my_assert(sk2 == skhalf)
    my_assert(eltype(keys(exclusive(m1, startof(m1), pos1))) == T)



    sk2a = zero1
    for k in eachindex(exclusive(m1, startof(m1), pos1))
        sk2a += k
    end
    my_assert(sk2a == skhalf)
    my_assert(eltype(eachindex(exclusive(m1, startof(m1), pos1))) == T)



    sv2 = zero1
    for v in values(exclusive(m1, startof(m1), pos1))
        sv2 += v
    end
    my_assert(sv2 == svhalf)
    count = 0
    for (k,v) in exclusive(m1, pastendsemitoken(m1), pastendsemitoken(m1))
        count += 1
    end
    my_assert(eltype(keys(exclusive(m1, startof(m1), pos1))) == T)
    my_assert(count == 0)


    count = 0
    for (k,v) in inclusive(m1, startof(m1), beforestartsemitoken(m1))
        count += 1
    end
    my_assert(count == 0)
    my_assert(eltype(keys(inclusive(m1, startof(m1), beforestartsemitoken(m1)))) == T)


    count = 0
    sk5 = zero1
    for k in eachindex(inclusive(m1, startof(m1), startof(m1)))
        sk5 += k
        count += 1
    end
    my_assert(count == 1 && sk5 == deref_key((m1,startof(m1))))
    my_assert(eltype(eachindex(inclusive(m1, startof(m1), startof(m1)))) == T)

    factors = SortedMultiDict{Int,Int}()
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
    my_assert(sum1a == sum1 && sum2a == sum2)





    sum1a = 0
    sum2a = 0
    for st in eachindex(factors)
        (k,v) = deref((factors,st))
        sum1a += k
        sum2a += v
    end
    my_assert(sum1a == sum1 && sum2a == sum2)

    sum1a = 0
    sum2a = 0
    for st in onlysemitokens(factors)
        (k,v) = deref((factors,st))
        sum1a += k
        sum2a += v
    end
    my_assert(sum1a == sum1 && sum2a == sum2)
    my_assert(eltype(onlysemitokens(factors)) == IntSemiToken)

    sum2 = 0
    for (k,v) in inclusive(factors,
                           searchsortedfirst(factors,70),
                           searchsortedlast(factors,70))
        sum2 += v
    end

    my_assert(sum2 == 1 + 2 + 5 + 7 + 10 + 14 + 35 + 70)
    my_assert(eltype(inclusive(factors,
                           searchsortedfirst(factors,70),
                           searchsortedlast(factors,70))) == Pair{Int,Int})


    sum2 = 0
    for st in eachindex(inclusive(factors,
                                  searchsortedfirst(factors,70),
                                  searchsortedlast(factors,70)))
        v = deref_value((factors,st))
        sum2 += v
    end

    my_assert(sum2 == 1 + 2 + 5 + 7 + 10 + 14 + 35 + 70)
    my_assert(eltype(eachindex(inclusive(factors,
                                     searchsortedfirst(factors,70),
                                     searchsortedlast(factors,70)))) == IntSemiToken)



    sum3 = 0
    for (k,v) in exclusive(factors,
                           searchsortedfirst(factors,60),
                           searchsortedfirst(factors,61))
        sum3 += v
    end
    my_assert(sum3 == 1 + 2 + 3 + 4 + 5 + 6 + 10 + 12 + 15 + 20 + 30 + 60)
    my_assert(eltype(exclusive(factors,
                           searchsortedfirst(factors,70),
                           searchsortedlast(factors,70))) == Pair{Int,Int})


    sum3 = 0
    for st in eachindex(exclusive(factors,
                                  searchsortedfirst(factors,60),
                                  searchsortedfirst(factors,61)))
        v = deref_value((factors,st))
        sum3 += v
    end
    my_assert(sum3 == 1 + 2 + 3 + 4 + 5 + 6 + 10 + 12 + 15 + 20 + 30 + 60)
    my_assert(eltype(eachindex(exclusive(factors,
                                     searchsortedfirst(factors,70),
                                     searchsortedlast(factors,70)))) == IntSemiToken)


    sum4 = 0
    for k in keys(factors)
        sum4 += k
    end
    my_assert(sum4 == sum1)
    my_assert(eltype(keys(factors)) == Int)




    sum5 = 0
    for v in values(factors)
        sum5 += v
    end

    my_assert(sum5 == sum2a)
    my_assert(eltype(values(factors)) == Int)

    sum2 = 0
    for k in keys(inclusive(factors,
                            searchsortedfirst(factors,70),
                            searchsortedlast(factors,70)))
        sum2 += k
    end
    my_assert(sum2 == 70 * 8)
    my_assert(eltype(keys(inclusive(factors,
                                searchsortedfirst(factors,70),
                                searchsortedlast(factors,70)))) ==  Int)


    sum3 = 0
    for k in keys(exclusive(factors,
                            searchsortedfirst(factors,60),
                            searchsortedfirst(factors,61)))
        sum3 += k
    end
    my_assert(sum3 == 60 * 12)
    my_assert(eltype(keys(exclusive(factors,
                                searchsortedfirst(factors,60),
                                searchsortedfirst(factors,61)))) == Int)



    sum2 = 0
    for v in values(inclusive(factors,
                              searchsortedfirst(factors,70),
                              searchsortedlast(factors,70)))
        sum2 += v
    end
    my_assert(sum2 == 1 + 2 + 5 + 7 + 10 + 14 + 35 + 70)
    my_assert(eltype(values(inclusive(factors,
                                  searchsortedfirst(factors,60),
                                  searchsortedfirst(factors,61)))) == Int)

    sum3 = 0
    for v in values(exclusive(factors,
                              searchsortedfirst(factors,60),
                              searchsortedfirst(factors,61)))
        sum3 += v
    end
    my_assert(sum3 == 1 + 2 + 3 + 4 + 5 + 6 + 10 + 12 + 15 + 20 + 30 + 60)
    my_assert(eltype(values(exclusive(factors,
                                  searchsortedfirst(factors,60),
                                  searchsortedfirst(factors,61)))) == Int)

    sum1b = 0
    sum2b = 0
    for (st,k,v) in semitokens(factors)
        my_assert(deref_value((factors,st)) == v)
        sum1b += k
        sum2b += v
    end
    my_assert(sum1b == sum1a && sum2b == sum2a)
    my_assert(eltype(semitokens(factors)) == Tuple{IntSemiToken, Int, Int})

    sum2 = 0
    for (st,k,v) in semitokens(inclusive(factors,
                                         searchsortedfirst(factors,70),
                                         searchsortedlast(factors,70)))
        my_assert(deref_value((factors,st)) == v)
        sum2 += v
    end
    my_assert(sum2 == 1 + 2 + 5 + 7 + 10 + 14 + 35 + 70)
    my_assert(eltype(semitokens(inclusive(factors,
                                         searchsortedfirst(factors,70),
                                         searchsortedlast(factors,70)))) ==
        Tuple{IntSemiToken, Int, Int})

    sum3 = 0
    for (st,k,v) in semitokens(exclusive(factors,
                                         searchsortedfirst(factors,60),
                                         searchsortedfirst(factors,61)))
        my_assert(deref_value((factors,st)) == v)
        sum3 += v
    end
    my_assert(sum3 == 1 + 2 + 3 + 4 + 5 + 6 + 10 + 12 + 15 + 20 + 30 + 60)
    my_assert(eltype(semitokens(exclusive(factors,
                                      searchsortedfirst(factors,60),
                                      searchsortedfirst(factors,61)))) ==
         Tuple{IntSemiToken, Int, Int})

    sum4 = 0
    for (st,k) in semitokens(keys(factors))
        my_assert(deref_key((factors,st)) == k && mod(k,deref_value((factors,st))) == 0)
        sum4 += k
    end
    my_assert(sum4 == sum1)
    my_assert(eltype(semitokens(keys(factors))) == Tuple{IntSemiToken,Int})

    sum5 = 0
    for (st,v) in semitokens(values(factors))
        my_assert(deref_value((factors,st)) == v)
        sum5 += v
    end
    my_assert(sum5 == sum2a)
    my_assert(eltype(semitokens(values(factors))) == Tuple{IntSemiToken,Int})

    sum2 = 0
    for (st,k) in semitokens(keys(inclusive(factors,
                                           searchsortedfirst(factors,70),
                                           searchsortedlast(factors,70))))
        my_assert(deref_key((factors,st)) == k && mod(k,deref_value((factors,st))) == 0)
        sum2 += k
    end
    my_assert(sum2 == 70 * 8)
    my_assert(eltype(semitokens(keys(inclusive(factors,
                                           searchsortedfirst(factors,70),
                                           searchsortedlast(factors,70))))) ==
        Tuple{IntSemiToken, Int})

    sum3 = 0
    for (st,k) in semitokens(keys(inclusive(factors,
                                            searchsortedfirst(factors,60),
                                            searchsortedlast(factors,60))))
        my_assert(deref_key((factors,st)) == k && mod(k,deref_value((factors,st))) == 0)
        sum3 += k
    end
    my_assert(sum3 == 60 * 12)
    my_assert(eltype(semitokens(keys(inclusive(factors,
                                            searchsortedfirst(factors,60),
                                            searchsortedlast(factors,60))))) ==
        Tuple{IntSemiToken, Int})

    sum2 = 0
    for (st,v) in semitokens(values(inclusive(factors,
                                              searchsortedfirst(factors,70),
                                              searchsortedlast(factors,70))))
        my_assert(deref_value((factors,st)) == v)
        sum2 += v
    end
    my_assert(sum2 == 1 + 2 + 5 + 7 + 10 + 14 + 35 + 70)
    my_assert(eltype(semitokens(values(inclusive(factors,
                                              searchsortedfirst(factors,70),
                                              searchsortedlast(factors,70))))) ==
      Tuple{IntSemiToken, Int})

    sum3 = 0
    for (st,v) in semitokens(values(exclusive(factors,
                                              searchsortedfirst(factors,60),
                                              searchsortedfirst(factors,61))))
        my_assert(deref_value((factors,st)) == v)
        sum3 += v
    end
    my_assert(sum3 == 1 + 2 + 3 + 4 + 5 + 6 + 10 + 12 + 15 + 20 + 30 + 60)
    my_assert(eltype(semitokens(values(exclusive(factors,
                                              searchsortedfirst(factors,60),
                                              searchsortedfirst(factors,61))))) ==
       Tuple{IntSemiToken, Int})

    s = SortedSet([39, 24, 2, 14, 45, 107, 66])
    my_assert(typeof(s) == SortedSet{Int, ForwardOrdering})
    sum1 = 0
    for k in s
        sum1 += k
    end
    my_assert(sum1 == sum([39, 24, 2, 14, 45, 107, 66]))

    sum1 = 0
    for (st,k) in semitokens(s)
        my_assert(deref((s,st)) == k)
        sum1 += k
    end
    my_assert(sum1 == sum([39, 24, 2, 14, 45, 107, 66]))
    my_assert(eltype(semitokens(s)) == Tuple{IntSemiToken, Int})


    sum1 = 0
    for st in onlysemitokens(s)
        k = deref((s,st))
        sum1 += k
    end
    my_assert(sum1 == sum([39, 24, 2, 14, 45, 107, 66]))
    my_assert(eltype(onlysemitokens(s)) == IntSemiToken)


    sum1 = 0
    for st in eachindex(s)
        k = deref((s,st))
        sum1 += k
    end
    my_assert(sum1 == sum([39, 24, 2, 14, 45, 107, 66]))
    my_assert(eltype(eachindex(s)) == IntSemiToken)


    sum2 = 0
    for k in inclusive(s,
                       searchsortedfirst(s, 24),
                       searchsortedfirst(s, 66))
        sum2 += k
    end
    my_assert(sum2 == 24 + 39 + 45 + 66)
    my_assert(eltype(inclusive(s,
                       searchsortedfirst(s, 24),
                       searchsortedfirst(s, 66))) == Int)


    sum2 = 0
    for st in eachindex(inclusive(s,
                                  searchsortedfirst(s, 24),
                                  searchsortedfirst(s, 66)))
        sum2 += deref((s,st))
    end
    my_assert(sum2 == 24 + 39 + 45 + 66)
    my_assert(eltype(eachindex(inclusive(s,
                                     searchsortedfirst(s, 24),
                                     searchsortedfirst(s, 66)))) == IntSemiToken)




    sum2 = 0
    for (st,k) in semitokens(inclusive(s,
                                       searchsortedfirst(s, 24),
                                       searchsortedfirst(s, 66)))
        my_assert(deref((s,st)) == k)
        sum2 += k
    end
    my_assert(sum2 == 24 + 39 + 45 + 66)
    my_assert(eltype(semitokens(inclusive(s,
                                       searchsortedfirst(s, 24),
                                       searchsortedfirst(s, 66)))) ==
      Tuple{IntSemiToken, Int})


    sum2 = 0
    for st in onlysemitokens(inclusive(s,
                                       searchsortedfirst(s, 24),
                                       searchsortedfirst(s, 66)))
        sum2 += deref((s,st))
    end
    my_assert(sum2 == 24 + 39 + 45 + 66)
    my_assert(eltype(onlysemitokens(inclusive(s,
                                          searchsortedfirst(s, 24),
                                          searchsortedfirst(s, 66)))) == IntSemiToken)




    sum3 = 0
    for k in exclusive(s,
                       searchsortedfirst(s, 24),
                       searchsortedfirst(s, 66))
        sum3 += k
    end
    my_assert(sum3 == 24 + 39 + 45)
    my_assert(eltype(exclusive(s,
                       searchsortedfirst(s, 24),
                       searchsortedfirst(s, 66))) == Int)


    sum3 = 0
    for (st,k) in semitokens(exclusive(s,
                                       searchsortedfirst(s, 24),
                                       searchsortedfirst(s, 66)))
        my_assert(deref((s,st)) == k)
        sum3 += k
    end
    my_assert(sum3 == 24 + 39 + 45)
    my_assert(eltype(semitokens(exclusive(s,
                                       searchsortedfirst(s, 24),
                                       searchsortedfirst(s, 66)))) ==
     Tuple{IntSemiToken, Int})


    sum3 = 0
    for st in eachindex(exclusive(s,
                                  searchsortedfirst(s, 24),
                                  searchsortedfirst(s, 66)))
        sum3 += deref((s,st))
    end
    my_assert(sum3 == 24 + 39 + 45)
    my_assert(eltype(eachindex(exclusive(s,
                                     searchsortedfirst(s, 24),
                            searchsortedfirst(s, 66)))) == IntSemiToken)
    true
end






function testSortedDictOrderings()
    ## Test use of alternative orderings in test5
    keylist = ["Apple", "aPPle", "berry", "CHerry", "Dairy", "diary"]
    vallist = [6,9,-4,2,1,8]
    m = SortedDict{String,Int}()
    for j = 1:6
        m[keylist[j]] = vallist[j]
    end
    checkcorrectness(m.bt, false)
    expectedord1 = [1,4,5,2,3,6]
    count = 0
    for p in m
        count += 1
        my_assert(p[1] == keylist[expectedord1[count]] &&
                p[2] == vallist[expectedord1[count]])
    end
    my_assert(count == 6)
    m2 = SortedDict((Dict{String, Int}()), Reverse)
    for j = 1 : 6
        m2[keylist[j]] = vallist[j]
    end
    checkcorrectness(m2.bt, false)
    expectedord2 = [6,3,2,5,4,1]
    count = 0
    for p in m2
        count += 1
        my_assert(p[1] == keylist[expectedord2[count]] &&
                p[2] == vallist[expectedord2[count]])
    end
    my_assert(count == 6)
    m3 = SortedDict((Dict{String, Int}()), CaseInsensitive())
    for j = 1 : 6
        m3[keylist[j]] = vallist[j]
    end
    my_assert("BERRY" in keys(m3))
    my_assert(!("BERRY" in collect(keys(m3))))
    checkcorrectness(m3.bt, false)
    expectedord3 = [2,3,4,5,6]
    count = 0
    for p in m3
        count += 1
        my_assert(p[1] == keylist[expectedord3[count]] &&
                p[2] == vallist[expectedord3[count]])
    end
    my_assert(count == 5)
    m3empty = empty(m3)
    my_assert(eltype(m3empty) == Pair{String, Int} &&
       orderobject(m3empty) == CaseInsensitive() &&
       length(m3empty) == 0 && ordtype(m3empty) == CaseInsensitive &&
       ordtype(typeof(m3empty)) == CaseInsensitive)
    m4 = SortedDict((Dict{String,Int}()), Lt((x,y) -> isless(lowercase(x),lowercase(y))))
    for j = 1 : 6
        m4[keylist[j]] = vallist[j]
    end
    checkcorrectness(m4.bt, false)
    count = 0
    for p in m4
        count += 1
        my_assert(p[1] == keylist[expectedord3[count]] &&
                p[2] == vallist[expectedord3[count]])
    end
    my_assert(count == 5)
    true
end

function testSortedMultiDict()
    test_dict = Dict('a'=>1, 'b'=>2, 'c'=>3)

    # Test all methods of SortedMultiDict except loops
    factors = SortedMultiDict{Int,Int}()
    my_assert(typeof(factors) == SortedMultiDict{Int,Int,ForwardOrdering})
    factors2 = SortedMultiDict(test_dict)
    my_assert(typeof(factors2) == SortedMultiDict{Char,Int,ForwardOrdering})
    factors3 = SortedMultiDict{Char,Int}(test_dict)
    my_assert(typeof(factors3) == SortedMultiDict{Char,Int,ForwardOrdering})
    factors4 = SortedMultiDict{Char,Float32}(Reverse, test_dict)
    my_assert(typeof(factors4) == SortedMultiDict{Char,Float32,ReverseOrdering{ForwardOrdering}})

    test_pair_array = Pair{Char}['a'=>1, 'b'=>2, 'c'=>3]
    factors5 = SortedMultiDict(test_pair_array)
    my_assert(typeof(factors5) == SortedMultiDict{Char,Any,ForwardOrdering})

    #@test factors2 == factors3   # Broken!  TODO: fix me...
    my_assert(isequal(factors2, factors3))

    N = 1000
    checkcorrectness(factors.bt, true)
    len = 0
    for factor = 1 : N
        for multiple = factor : factor : N
            insert!(factors, multiple, factor)
            len += 1
        end
    end
    my_assert(length(factors) == len)
    my_assert(Pair(70,2) in factors)
    my_assert(Pair(70,14) in factors)
    my_assert(!(Pair(70,15) in factors))
    my_assert(!(Pair(N+1,15) in factors))
    my_assert(eltype(factors) == Pair{Int,Int})
    my_assert(eltype(typeof(factors)) == Pair{Int,Int})

    my_assert(keytype(factors) == Int)
    my_assert(keytype(typeof(factors)) == Int)
    my_assert(valtype(factors) == Int)
    my_assert(valtype(typeof(factors)) == Int)
    my_assert(ordtype(factors) == ForwardOrdering)
    my_assert(ordtype(typeof(factors)) == ForwardOrdering)

    push!(factors, 70 => 3)
    my_assert(length(factors) == len+1)
    my_assert(Pair(70,3) in factors)
    i = searchsortedfirst(factors, 70)
    dcount = 0
    for (s,k,v) in semitokens(inclusive(factors, i, lastindex(factors)))
        my_assert(k == 70)
        if v == 3
            delete!((factors,s))
            dcount += 1
            break
        end
    end
    my_assert(dcount == 1)

    my_assert(orderobject(factors) == Forward)
    my_assert(haskey(factors, 60))
    my_assert(!haskey(factors, -1))
    my_assert(60 in keys(factors))
    my_assert(!(-1 in keys(factors)))
    checkcorrectness(factors.bt, true)
    i = startof(factors)
    i = advance((factors,i))
    my_assert(deref((factors,i)) == Pair(2,1))
    my_assert(deref_key((factors,i)) == 2)
    my_assert(deref_value((factors,i)) == 1)
    my_assert(factors[i] == 1)
    factors[i] = 7
    my_assert(deref((factors,i)) == Pair(2,7))
    factors[i] = 1
    i = regress((factors,i))
    i = regress((factors,i))
    my_assert(i == beforestartsemitoken(factors))
    pr = first(factors)
    my_assert(pr == Pair(1,1))
    pr2 = last(factors)
    my_assert(pr2 == Pair(N,N))
    i = searchsortedfirst(factors,77)
    my_assert(deref((factors,i)) == Pair(77,1))
    i = searchsortedlast(factors,77)
    my_assert(deref((factors,i)) == Pair(77,77))
    i = searchsortedafter(factors,77)
    my_assert(deref((factors,i)) == Pair(78,1))
    expected = [1,2,4,5,8,10,16,20,40,80]
    i1,i2 = searchequalrange(factors, 80)
    i = i1
    for e in expected
        my_assert(deref_value((factors,i)) == e)
        i = advance((factors,i))
    end
    my_assert(compare(factors,i,i2) != 0)
    my_assert(compare(factors,regress((factors,i)),i2) == 0)
    my_assert(compare(factors,i,i1) != 0)
    insert!(factors, 80, 6)
    my_assert(length(factors) == len + 1)
    checkcorrectness(factors.bt, true)
    expected1 = deepcopy(expected)
    push!(expected1, 6)
    i1,i2 = searchequalrange(factors, 80)
    i = i1
    for e in expected1
        my_assert(deref_value((factors,i)) == e)
        i = advance((factors,i))
    end
    my_assert(compare(factors,i2,regress((factors,i))) == 0)
    my_assert(compare(factors,i,i1) != 0)
    delete!((factors,i2))
    my_assert(length(factors) == len)
    checkcorrectness(factors.bt, true)
    i1,i2 = searchequalrange(factors, 80)
    i = i1
    for e in expected
        my_assert(deref_value((factors,i)) == e)
        i = advance((factors,i))
    end
    my_assert(compare(factors,regress((factors,i)),i2) == 0)
    my_assert(!isempty(factors))
    empty!(factors)
    checkcorrectness(factors.bt, true)
    my_assert(length(factors) == 0)
    my_assert(isempty(factors))
    i = startof(factors)
    my_assert(i == pastendsemitoken(factors))
    i = lastindex(factors)
    my_assert(i == beforestartsemitoken(factors))
    i1,i2 = searchequalrange(factors, N + 2)
    my_assert(i1 == pastendsemitoken(factors))
    my_assert(i2 == beforestartsemitoken(factors))
    m1 = SortedMultiDict("apples"=>2.0, "apples"=>1.0, "bananas"=>1.5)
    my_assert(typeof(m1) == SortedMultiDict{String, Float64, ForwardOrdering})
    checkcorrectness(m1.bt, true)
    m2 = SortedMultiDict("bananas"=>1.5, "apples"=>2.0, "apples"=>1.0)
    checkcorrectness(m2.bt, true)
    m3 = SortedMultiDict("apples"=>1.0, "apples"=>2.0, "bananas"=>1.5)
    checkcorrectness(m3.bt, true)
    my_assert(isequal(m1,m2))
    my_assert(!isequal(m1,m3))
    my_assert(!isequal(m1, SortedMultiDict("apples"=>2.0)))
    stok = insert!(m2, "cherries", 6.1)
    checkcorrectness(m2.bt, true)
    my_assert(!isequal(m1,m2))
    delete!((m2,stok))
    checkcorrectness(m2.bt, true)
    my_assert(isequal(m1,m2))
    m4 = deepcopy(m2)
    checkcorrectness(m4.bt, true)
    my_assert(isequal(m1,m4))
    m5 = packcopy(m2)
    checkcorrectness(m5.bt, true)
    my_assert(isequal(m1,m5))
    m6 = packdeepcopy(m2)
    checkcorrectness(m6.bt, true)
    my_assert(isequal(m1,m6))

    m1 = SortedMultiDict(zip(["bananas", "apples", "cherries", "cherries", "oranges"],
                             [1.0, 2.0, 3.0, 4.0, 5.0]))
    my_assert(typeof(m1) == SortedMultiDict{String, Float64, ForwardOrdering})
    m2 = SortedMultiDict(zip(["apples", "cherries", "cherries", "bananas", "plums"],
                             [6.0, 7.0, 8.0, 9.0, 10.0]))
    m3 = SortedMultiDict(zip(["apples", "apples", "bananas", "bananas",
                              "cherries", "cherries", "cherries", "cherries",
                              "oranges", "plums"],
                             [2.0, 6.0, 1.0, 9.0, 3.0, 4.0, 7.0, 8.0, 5.0, 10.0]))
    m3empty = empty(m3)
    my_assert((eltype(m3empty) == Pair{String, Float64}) &&
        orderobject(m3empty) == Forward &&
        length(m3empty) == 0)
    m4 = merge(m1, m2)
    my_assert(isequal(m3, m4))
    m5 = merge(m2, m1)
    my_assert(!isequal(m3, m5))
    merge!(m1, m2)
    my_assert(isequal(m1, m3))
    m7 = SortedMultiDict{Int,Int}()
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
            my_assert(key == k)
            my_assert(v == k + count)
        end
        my_assert(count == 2)
        count = 0
        for (key,v) in inclusive(m7, searchequalrange(m7,k))
            count += 1
            my_assert(key == k)
            my_assert(v == k + count)
        end
        my_assert(count == 2)
    end
    # issue #216
    my_assert(DataStructures.isordered(SortedMultiDict{Int, String}))
    # issue #773
    s = SortedMultiDict{Int, Int}()           
    insert!(s, 4, 41)
    insert!(s, 3, 31)
    insert!(s, 2, 21)
    insert!(s, 2, 22)
    insert!(s, 2, 23)
    insert!(s, 2, 24)
    insert!(s, 2, 25)
    insert!(s, 2, 26)
    insert!(s, 1, 11)
    insert!(s, 1, 12)
    st1 = insert!(s, 1, 13)
    st2 = insert!(s, 1, 14)
    st3 = insert!(s, 1, 15)
    st4 = insert!(s, 1, 16)
    st5 = insert!(s, 1, 17)
    st6 = insert!(s, 1, 18)
    delete!((s, st6))
    delete!((s, st5))
    delete!((s, st4))
    delete!((s, st3))
    delete!((s, st2))
    delete!((s, st1))
    insert!(s, 1, 19)
    checkcorrectness(s.bt, true)
    true
end


function testSortedSet()
    # Test SortedSet
    N = 1000
    sm = 0.0

    m = SortedSet(Float64[])
    my_assert(typeof(m) == SortedSet{Float64, ForwardOrdering})
    mm = SortedSet{Float64}()
    my_assert(typeof(mm) == SortedSet{Float64, ForwardOrdering})
    #@test m == mm   # Broken!  TODO: Fix me...
    my_assert(isequal(m, mm))

    my_assert(typeof(SortedSet()) == SortedSet{Any, ForwardOrdering})
    my_assert(typeof(SortedSet{Float64}()) == SortedSet{Float64, ForwardOrdering})
    my_assert(typeof(SortedSet(Reverse)) == SortedSet{Any, ReverseOrdering{ForwardOrdering}})
    my_assert(typeof(SortedSet{Float64}(Reverse)) == SortedSet{Float64, ReverseOrdering{ForwardOrdering}})
    my_assert(typeof(SortedSet([1,2,3])) == SortedSet{Int, ForwardOrdering})
    my_assert(typeof(SortedSet{Float32}([1,2,3])) == SortedSet{Float32, ForwardOrdering})
    my_assert(typeof(SortedSet(Reverse, [1,2,3])) == SortedSet{Int, ReverseOrdering{ForwardOrdering}})
    my_assert(typeof(SortedSet{Float32}(Reverse, [1,2,3])) == SortedSet{Float32, ReverseOrdering{ForwardOrdering}})
    my_assert(typeof(SortedSet([1,2,3], Reverse)) == SortedSet{Int, ReverseOrdering{ForwardOrdering}})
    my_assert(typeof(SortedSet{Float32}([1,2,3], Reverse)) == SortedSet{Float32, ReverseOrdering{ForwardOrdering}})

    # @test_throws ArgumentError SortedSet(Reverse, Reverse)
    # @test_throws ArgumentError SortedSet{Int}(Reverse, Reverse)

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
    my_assert(isnew)
    my_assert(deref((m,st)) == 72.5)
    delete!((m,st))
    isnew,st = insert!(m, 73.5)
    my_assert(isnew)
    my_assert(deref((m,st)) == 73.5)
    delete!(m, 73.5)
    checkcorrectness(m.bt, false)
    count = 0
    sm2 = 0.0
    prev = -1.0
    for k in m
        sm2 += k
        count += 1
        my_assert(k >= prev)
    end
    my_assert(abs(sm2 - sm) <= 1e-10)
    my_assert(count == N)
    my_assert(length(m) == N)
    ii2 = searchsortedfirst(m, 0.5)
    i3 = startof(m)
    v = first(m)
    my_assert(v == smallest)
    my_assert(deref((m,i3)) == v)
    i4 = lastindex(m)
    w = last(m)
    my_assert(w == largest)
    my_assert(deref((m,i4)) == w)
    i5 = beforestartsemitoken(m)
    my_assert(advance((m,i5)) == i3)
    i6 = pastendsemitoken(m)
    my_assert(regress((m,i6)) == i4)
    my_assert(advance((m,i5)) != i4)
    my_assert(regress((m,i6)) != i3)
    j1 = searchsortedfirst(m,0.5)
    j2 = searchsortedlast(m,0.5)
    j3 = searchsortedafter(m,0.5)
    my_assert(deref((m,j1)) > 0.5)
    my_assert(deref((m,j2)) < 0.5)
    my_assert(advance((m,j2)) == j1)
    my_assert(j1 == j3)
    k1 = searchsortedfirst(m,smallest)
    k2 = searchsortedlast(m,smallest)
    k3 = searchsortedafter(m,smallest)
    my_assert(deref((m,k1)) == smallest)
    my_assert(deref((m,k2)) == smallest)
    my_assert(deref((m,regress((m,k3)))) == smallest)
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
        my_assert(k < 0.4 || k > 0.6)
    end
    my_assert(newcount == N - dcount)
    my_assert(smallest in m)
    my_assert(haskey(m,smallest))
    my_assert(!(0.5 in m))
    my_assert(!haskey(m,0.5))
    my_assert(eltype(m) == Float64)
    my_assert(eltype(typeof(m)) == Float64)
    my_assert(keytype(m) == Float64)
    my_assert(keytype(typeof(m)) == Float64)
    my_assert(orderobject(m) == Forward)
    my_assert(ordtype(m) == ForwardOrdering)
    my_assert(ordtype(typeof(m)) == ForwardOrdering)
    pop!(m, smallest)
    checkcorrectness(m.bt, false)
    my_assert(length(m) == N - dcount - 1)
    key1 = pop!(m)
    my_assert(key1 == secondsmallest)
    my_assert(length(m) == N - dcount - 2)
    checkcorrectness(m.bt, false)
    my_assert(!isempty(m))
    empty!(m)
    my_assert(isempty(m))
    m1 = SortedSet(["blue", "orange", "red"])
    my_assert(typeof(m1) == SortedSet{String, ForwardOrdering})
    m2 = SortedSet(["orange", "blue", "red"])
    m3 = SortedSet(["orange", "yellow", "red"])
    m3empty = empty(m3)
    my_assert(typeof(m3empty) == SortedSet{String, ForwardOrdering})
    my_assert(eltype(m3empty) == String &&
       length(m3empty) == 0)
    my_assert(isequal(m1,m2))
    my_assert(!isequal(m1,m3))
    my_assert(!isequal(m1, SortedSet(["blue"])))
    m4 = packcopy(m3)
    my_assert(typeof(m4) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m3,m4))
    m5 = packdeepcopy(m4)
    my_assert(typeof(m5) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m3,m4))
    m6 = deepcopy(m5)
    my_assert(typeof(m6) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m3,m5))
    checkcorrectness(m1.bt, false)
    checkcorrectness(m2.bt, false)
    checkcorrectness(m3.bt, false)
    checkcorrectness(m4.bt, false)
    checkcorrectness(m5.bt, false)
    checkcorrectness(m5.bt, false)
    m7 = union(m1, ["yellow"])
    my_assert(typeof(m7) == SortedSet{String, ForwardOrdering})
    m8 = union(m3, SortedSet(["blue"]))
    my_assert(typeof(m8) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m7,m8))
    my_assert(!isequal(m1,m8))
    union!(m1, ["yellow"])
    my_assert(isequal(m1,m8))
    m8a = intersect(m8)
    my_assert(typeof(m8a) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m8a,m8))
    m9 = intersect(m8, SortedSet(["yellow", "red", "white"]))
    my_assert(typeof(m9) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m9, SortedSet(["red", "yellow"])))
    m9a = intersect(m8, SortedSet(["yellow", "red", "white"]), m8)
    my_assert(typeof(m9a) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m9a, SortedSet(["red", "yellow"])))
    m10 = symdiff(m8,  SortedSet(["yellow", "red", "white"]))
    my_assert(typeof(m10) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m10, SortedSet(["white", "blue", "orange"])))
    m11 = symdiff(m8, SortedSet(["yellow", "red", "blue", "orange",
                                 "zinc"]))
    my_assert(typeof(m11) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m11, SortedSet(["zinc"])))
    m12 = symdiff(SortedSet(["yellow", "red", "blue", "orange",
                                 "zinc"]), m8)
    my_assert(isequal(m12, SortedSet(["zinc"])))
    my_assert(typeof(m12) == SortedSet{String, ForwardOrdering})
    m13 = setdiff(m8, SortedSet(["yellow", "red", "white"]))
    my_assert(typeof(m13) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m13, SortedSet(["blue", "orange"])))
    m14 = setdiff(m8, SortedSet(["blue"]))
    my_assert(typeof(m14) == SortedSet{String, ForwardOrdering})
    my_assert(isequal(m14, SortedSet(["orange", "yellow", "red"])))
    my_assert(issubset(["yellow", "blue"], m8))
    my_assert(!issubset(["blue", "green"], m8))
    setdiff!(m8, SortedSet(["yellow", "red", "white"]))
    my_assert(isequal(m8, SortedSet(["blue", "orange"])))
    true
end


# test the constructors of SortedDict and SortedMultiDict

function testSortedDictConstructors()
    sd1 = SortedDict("w" => 64, "p" => 12)
    my_assert(typeof(sd1) == SortedDict{String, Int, ForwardOrdering})
    my_assert(length(sd1) == 2 && first(sd1) == ("p"=>12) &&
        last(sd1) == ("w"=>64))
    sd2 = SortedDict(Reverse, "w" => 64, "p" => 12)
    my_assert(typeof(sd2) == SortedDict{String, Int, ReverseOrdering{ForwardOrdering}})
    my_assert(length(sd2) == 2 && last(sd2) == ("p"=>12) &&
        first(sd2) == ("w"=>64))
    sd3 = SortedDict(("w"=>64, "p"=>12))
    my_assert(typeof(sd3) == SortedDict{String, Int, ForwardOrdering})
    my_assert(length(sd3) == 2 && first(sd3) == ("p"=>12) &&
        last(sd3) == ("w"=>64))
    sd4 = SortedDict(("w"=>64, "p"=>12), Reverse)
    my_assert(typeof(sd4) == SortedDict{String, Int, ReverseOrdering{ForwardOrdering}})
    my_assert(length(sd4) == 2 && last(sd4) == ("p"=>12) &&
        first(sd4) == ("w"=>64))

    my_assert(typeof(SortedDict()) == SortedDict{Any,Any,ForwardOrdering})
    my_assert(typeof(SortedDict(CaseInsensitive())) == SortedDict{Any,Any,CaseInsensitive})
    my_assert(typeof(SortedDict{Int,Int}(Reverse)) == SortedDict{Int,Int,ReverseOrdering{ForwardOrdering}})
    my_assert(typeof(SortedDict{Int,Int}(Reverse, 1=>2)) == SortedDict{Int,Int,ReverseOrdering{ForwardOrdering}})
    my_assert(typeof(SortedDict{Int,Int}(1=>2)) == SortedDict{Int,Int,ForwardOrdering})

    # @test_throws ArgumentError SortedDict(Reverse, Reverse)
    true
end

function testSortedMultiDictConstructors()
    sm1 = SortedMultiDict("w" => 64, "p" => 12, "p" => 9)
    my_assert(typeof(sm1) == SortedMultiDict{String, Int, ForwardOrdering})
    my_assert(length(sm1) == 3 && first(sm1) == ("p"=>12) &&
        last(sm1) == ("w"=>64))
    sm2 = SortedMultiDict(Reverse, "w" => 64, "p" => 12, "p" => 9)
    my_assert(typeof(sm2) == SortedMultiDict{String, Int, ReverseOrdering{ForwardOrdering}})
    my_assert(length(sm2) == 3 && last(sm2) == ("p"=>9) &&
        first(sm2) == ("w"=>64))
    sm3 = SortedMultiDict(("w"=>64, "p"=>12, "p"=> 9))
    my_assert(typeof(sm3) == SortedMultiDict{String, Int, ForwardOrdering})
    my_assert(length(sm3) == 3 && first(sm3) == ("p"=>12) &&
        last(sm3) == ("w"=>64))
    sm4 = SortedMultiDict(("w"=> 64, "p"=>12, "p"=>9), Reverse)
    my_assert(typeof(sm4) == SortedMultiDict{String, Int, ReverseOrdering{ForwardOrdering}})
    my_assert(length(sm4) == 3 && last(sm4) == ("p"=>9) &&
        first(sm4) == ("w"=>64))

    my_assert(typeof(SortedMultiDict()) == SortedMultiDict{Any,Any,ForwardOrdering})
    my_assert(typeof(SortedMultiDict(CaseInsensitive())) == SortedMultiDict{Any,Any,CaseInsensitive})
    my_assert(typeof(SortedMultiDict{Int,Int}(Reverse)) == SortedMultiDict{Int,Int,ReverseOrdering{ForwardOrdering}})
    # @test typeof(SortedMultiDict{Int,Int}(Reverse, 1=>2)) == SortedMultiDict{Int,Int,ReverseOrdering{ForwardOrdering}}
    # @test typeof(SortedMultiDict{Int,Int}(1=>2)) == SortedMultiDict{Int,Int,ForwardOrdering}
    true
end


@testset "SortedContainers" begin
    @test testSortedDictBasic()
    @test testSortedDictMethods()
    @test testSortedDictLoops()
    @test testSortedDictOrderings()
    @test testSortedMultiDict()
    @test testSortedSet()
    @test testSortedDictConstructors()
    @test testSortedMultiDictConstructors()


    # test all the errors of sorted containers
    m = SortedDict(Dict("a" => 6, "bb" => 9))
    @test_throws KeyError println(m["b"])
    m2 = SortedDict{String,Int}()
    @test_throws BoundsError println(first(m2))
    @test_throws BoundsError println(last(m2))
    i1 = findkey(m,"a")
    delete!((m,i1))
    i2 = findkey(m,"bb")
    @test_throws BoundsError iterate(inclusive(m,i1,i2))
    @test_throws BoundsError iterate(exclusive(m,i1,i2))
    @test m === delete!(m,"a") # Okay to delete! nonexistent keys
    @test_throws KeyError pop!(m,"a")
    m3 = SortedDict((Dict{String, Int}()), Reverse)
    @test_throws ArgumentError isequal(m2, m3)
    @test_throws BoundsError m[i1]
    @test_throws BoundsError regress((m,beforestartsemitoken(m)))
    @test_throws BoundsError advance((m,pastendsemitoken(m)))
    m1 = SortedMultiDict{Int,Int}()
    @test_throws ArgumentError SortedMultiDict([1,2,3])
    @test_throws ArgumentError SortedMultiDict(Forward, [1,2,3])
    @test_throws ArgumentError SortedMultiDict{Int,Int}([1,2,3])
    @test_throws ArgumentError SortedMultiDict{Int,Int}(Forward, [1,2,3])
    @test_throws ArgumentError SortedMultiDict(Forward, Reverse)
    @test_throws ArgumentError isequal(SortedMultiDict("a"=>1), SortedMultiDict("b"=>1.0))
    @test_throws ArgumentError isequal(SortedMultiDict(["a"=>1],Reverse), SortedMultiDict(["b"=>1]))
    @test_throws MethodError SortedMultiDict{Char,Int}(Forward, ["aa"=>2, "bbb"=>5])
    @test_throws MethodError SortedMultiDict(Forward, [("aa",2)=>2, "bbb"=>5])
    @test_throws BoundsError first(m1)
    @test_throws BoundsError last(m1)

    s = SortedSet([3,5])
    @test s === delete!(s,7) # Okay to delete! nonexistent keys
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

    s = SortedSet([10,30,50])
    @test pop!(s,10) == 10
    @test pop!(s,30,-1) == 30
    @test pop!(s,30, nothing) == nothing
    @test pop!(s,50, nothing) == 50
    @test pop!(s,50, nothing) == nothing
    @test isempty(s)

    # Test AbstractSet/AbstractDict interface
    for m in [SortedSet([1,2]), SortedDict(1=>2, 2=>3), SortedMultiDict(1=>2, 1=>3)]
        # copy()
        let m1 = copy(m)
            @test isequal(m1, m)
            @test typeof(m1) === typeof(m)
        end
        let m1 = Base.copymutable(m)
            @test isequal(m1, m)
            @test typeof(m1) === typeof(m)
        end
    end
end
