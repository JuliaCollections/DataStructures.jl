using DataStructures
import Base.Ordering
import Base.Forward
import Base.Reverse
import DataStructures.eq
import Base.lt
#import Base.Lt


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
    m1 = SortedDict((ASCIIString=>ASCIIString)[], Forward)
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
    @assert(count == 4)
end

function test2()
    # test all the methods here
    m0 = SortedDict((Int=>Float64)[])
    m1 = SortedDict([8=>32.0, 12=>33.1, 6=>18.2])
    expected = ([6,8,12], [18.2, 32.0, 33.1])
    checkcorrectness(m1.bt)
    ii = startof(m1)
    m2 = packdeepcopy(m1)
    m3 = packcopy(m1)
    p = first(m1)
    @assert(p[1] == 6 && p[2] == 18.2)
    for j = 1 : 3
        @assert(ii != pastendtoken(m1))
        pr = deref(ii)
        @assert(pr[1] == expected[1][j] && pr[2] == expected[2][j])
        checkcorrectness(m1.bt)
        oldii = ii
        ii = advance(ii)
        delete!(oldii)
    end
    checkcorrectness(m1.bt)
    checkcorrectness(m2.bt)
    @assert(length(m2) == 3)
    ii = startof(m2)
    for j = 1 : 3
        pr = deref(ii)
        @assert(pr[1] == expected[1][j] && pr[2] == expected[2][j])
        ii = advance(ii)
    end

    checkcorrectness(m3.bt)
    @assert(length(m3) == 3)
    ii = startof(m3)
    for j = 1 : 3
        pr = deref(ii)
        @assert(pr[1] == expected[1][j] && pr[2] == expected[2][j])
        ii = advance(ii)
    end

    @assert(isempty(m1))
    @assert(length(m1) == 0)
    N = 100
    for i = N : -1 : 2
        m1[i] = convert(Float64,i) ^ 2
        checkcorrectness(m1.bt)
    end
    @assert(!isempty(m1))
    assert(length(m1) == N - 1)
    for i = 2 : N
        d = pop!(m1, i)
        @assert(d == convert(Float64,i)^2)
        checkcorrectness(m1.bt)
    end
    @assert(isempty(m1))
    @assert(length(m1) == 0)
    for i = N : -1 : 2
        m1[i] = convert(Float64,i) ^ 2
        checkcorrectness(m1.bt)
    end
    lastprime = 1
    while true
        ii = searchsortedafter(m1, lastprime)
        if ii == pastendtoken(m1)
            break
        end
        j = deref_key(ii)
        for k = j * 2 : j : N
            p = findtoken(m1, k)
            if p != pastendtoken(m1)
                delete!(p)
                checkcorrectness(m1.bt)
            end
        end
        lastprime = j
    end
    @assert(ii == pastendtoken(m1))
    @assert(validtoken(ii) == 3)
    h = assembletoken(m1, semiextract(ii))
    @assert(validtoken(h) == 3)
    h2 = assembletoken(m1, 0)
    @assert(validtoken(h2) == 0)
    t = 0
    u = 0.0
    for pr = m1
        t += pr[1]
        u += pr[2]
    end
    numprimes = length(m1)
    pn = primes(N)
    @assert(t == sum(pn))
    @assert(u == sum(pn.^2))
    ij = endof(m1)
    @assert(deref_key(ij) == last(pn) && convert(Float64, last(pn)^2) ==  deref_value(ij))
    count = 0
    for p in startof(m1) : endof(m1)
        pt = itertoken(p)
        for q in excludelast(startof(m1), pastendtoken(m1))
            count += 1
            qt = itertoken(q)
            if isless(pt,qt)
                @assert(deref_key(pt) < deref_key(qt))
            elseif isequal(pt,qt)
                @assert(deref_key(pt) == deref_key(qt))
            else
                @assert(deref_key(pt) > deref_key(qt))
            end
        end
    end
    @assert(count == length(pn)^2)
    m1[6] = 49.0
    @assert(length(m1) == numprimes + 1)
    @assert(m1[6] == 49.0)
    b, i6 = insert!(m1, 6, 50.0)
    @assert(length(m1) == numprimes + 1)
    @assert(!b)
    p = deref(i6)
    @assert(p[1] == 6 && p[2] == 50.0)
    b2, i7 = insert!(m1, 8, 51.0)
    @assert(length(m1) == numprimes + 2)
    @assert(b2)
    p = deref(i7)
    @assert(p[1] == 8 && p[2] == 51.0)
    delete!(i7)
    z = pop!(m1, 6)
    checkcorrectness(m1.bt)
    @assert(z == 50.0)
    i8 = startof(m1)
    p = deref(i8)
    @assert(p[1] == 2 && p[2] == 4.0)
    @assert(i8 != beforestarttoken(m1))
    @assert(validtoken(i8) == 1)
    i9 = regress(i8)
    @assert(i9 == beforestarttoken(m1))
    @assert(validtoken(i9) == 2)
    i10 = findtoken(m1, 17)
    i11 = regress(i10)
    @assert(deref_key(i11) == 13)
    i12 = searchsortedfirst(m1, 47)
    i13 = searchsortedfirst(m1, 48)
    @assert(deref_key(i12) == 47)
    @assert(deref_key(i13) == 53)
    i14 = searchsortedafter(m1, 47)
    i15 = searchsortedafter(m1, 48)
    @assert(deref_key(i14) == 53)
    @assert(deref_key(i15) == 53)
    i16 = searchsortedlast(m1, 47)
    i17 = searchsortedlast(m1, 48)
    @assert(deref_key(i16) == 47)
    @assert(deref_key(i17) == 47)
    ww = primes(N)
    ww2 = Array(Int, 0)
    lb = 50
    ub = 70
    for i in ww
        if lb <= i < ub
            push!(ww2, i)
        end
    end
    count = 0
    for pr = excludelast(searchsortedfirst(m1, lb),
                         searchsortedfirst(m1, ub))
        count += 1
        @assert(pr[1] == ww2[count] && pr[2] == convert(Float64,ww2[count])^2)
        @assert(deref_key(itertoken(pr)) == ww2[count])
    end
    @assert(length(ww2) == count)
    count = 0
    for (k,v) = searchsortedfirst(m1,lb) : searchsortedlast(m1,ub-1)
        count += 1
        @assert(k == ww2[count])
        @assert(v == convert(Float64,ww2[count])^2)
    end
    @assert(length(ww2) == count)
    count = 0
    pp = primes(N)
    for j = keys(m1)
        count += 1
        @assert(j == pp[count])
    end
    @assert(length(pp) == count)
    count = 0
    for q = values(m1)
        count += 1
        @assert(q == convert(Float64,pp[count])^2)
    end
    @assert(length(pp) == count)
    cc = last(m1)
    assert(cc[1] == last(pp))
    ww = first(m1)
    assert(ww[1] == 2)
    tpr = eltype(m1)
    @assert(tpr[1] == Int && tpr[2] == Float64)
    co = orderobject(m1)
    @assert(co == Forward)
    @assert(haskey(m1, 71))
    @assert(!haskey(m1, 77))
    @assert(get(m1, 70, -45.2) == -45.2)
    @assert(get(m1, 83, -45.2) == convert(Float64,83)^2)
    h = get!(m1, 5, 27.0)
    @assert(h == 25.0)
    h = get!(m1, 6, 27.0)
    @assert(h == 27.0)
    @assert(m1[6] == 27.0)
    @assert(length(m1) == length(pp) + 1)
    pop!(m1, 6)
    @assert(getkey(m1,7, 9) == 7)
    @assert(getkey(m1,7.0, 9) == 7)
    @assert(getkey(m1,12, 9) == 9)
    delete!(m1, 17)
    @assert(length(m1) == length(pp) - 1)
    @assert(deref_key(advance(findtoken(m1,13))) == 19)
    empty!(m1)
    checkcorrectness(m1.bt)
    @assert(isempty(m1))
    c1 = SortedDict(["Eggplants"=>3, 
                        "Figs"=>9, 
                        "Apples"=>7])
    c2 = SortedDict(["Eggplants"=>6, 
                        "Honeydews"=>19, 
                        "Melons"=>11])
    c3 = merge(c1, c2)
    checkcorrectness(c3.bt)
    c4 = SortedDict(["Apples"=>7, 
                        "Figs"=>9,
                        "Eggplants"=>6,
                        "Melons"=>11,
                        "Honeydews"=>19])
    @assert(isequal(c3,c4))
    merge!(c1,c2)
    checkcorrectness(c1.bt)
    @assert(isequal(c3,c1))
    merge!(c3,c3)
    @assert(isequal(c3,c1))
    checkcorrectness(c3.bt)
end




function seekfile(fname)
    fullname = joinpath(Pkg.dir("DataStructures"), "test", fname)
end



immutable CaseInsensitive <: Ordering
end


lt(::CaseInsensitive, a, b) = isless(lowercase(a), lowercase(b))
eq(::CaseInsensitive, a, b) = isequal(lowercase(a), lowercase(b))

function test5()
    keylist = ["Apple", "aPPle", "berry", "CHerry", "Dairy", "diary"]
    vallist = [6,9,-4,2,1,8]
    m = SortedDict((ASCIIString=>Int)[])
    for j = 1:6
        m[keylist[j]] = vallist[j]
    end
    checkcorrectness(m.bt)
    expectedord1 = [1,4,5,2,3,6]
    count = 0
    for p in m
        count += 1
        @assert(p[1] == keylist[expectedord1[count]] && 
                p[2] == vallist[expectedord1[count]])
    end
    @assert(count == 6)
    m2 = SortedDict((ASCIIString=>Int)[], Reverse)
    for j = 1 : 6
        m2[keylist[j]] = vallist[j]
    end
    checkcorrectness(m2.bt)
    expectedord2 = [6,3,2,5,4,1]
    count = 0
    for p in m2
        count += 1
        @assert(p[1] == keylist[expectedord2[count]] && 
                p[2] == vallist[expectedord2[count]])
    end
    @assert(count == 6)
    m3 = SortedDict((ASCIIString=>Int)[], CaseInsensitive())
    for j = 1 : 6
        m3[keylist[j]] = vallist[j]
    end
    checkcorrectness(m3.bt)
    expectedord3 = [2,3,4,5,6]
    count = 0
    for p in m3
        count += 1
        @assert(p[1] == keylist[expectedord3[count]] &&
                p[2] == vallist[expectedord3[count]])
    end
    @assert(count == 5)
    m4 = SortedDict((ASCIIString=>Int)[], Lt((x,y) -> isless(lowercase(x),lowercase(y))))
    for j = 1 : 6
        m4[keylist[j]] = vallist[j]
    end
    checkcorrectness(m4.bt)
    count = 0
    for p in m4
        count += 1
        @assert(p[1] == keylist[expectedord3[count]] &&
                p[2] == vallist[expectedord3[count]])
    end
    @assert(count == 5)
end
    


function test6(numtrial::Int, expectedk::ASCIIString, expectedd::ASCIIString)
    NSTRINGPAIR = 50000
    m1 = SortedDict((ASCIIString=>ASCIIString)[])
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
            l = findtoken(m1, strlist[j * 2 + 1])
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
        @assert(k == ekn && d == edn)
    end
end



function test6a(numtrial::Int, expectedk::ASCIIString, expectedd::ASCIIString)
    NSTRINGPAIR = 50000
    m1 = SortedDict((ASCIIString=>ASCIIString)[], Lt(isless))
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
            l = ind_find(m1, strlist[j * 2 + 1])
            delete_ind!(m1,l)
        end
        spec = div(NSTRINGPAIR * 3,4)
        l = ind_first(m1)
        for j = 1 : spec
            l = advance_ind(m1,l)
        end
        k,d = deref_ind(m1,l)
        ekn = expectedk
        edn = expectedd
        @assert(k == ekn && d == edn)
    end
end

function SDConstruct(a::Associative; lt::Function=isless, by::Function=identity)
    if by == identity && lt == isless
        return SortedDict(a, Forward)
    elseif by == identity
        return SortedDict(a, Lt(lt))
    elseif lt == isless
        return SortedDict(a, By(by))
    else
        error("having both by and lt not both implemented")
    end
end

    


function test6b(numtrial::Int, expectedk::ASCIIString, expectedd::ASCIIString)
    NSTRINGPAIR = 50000
    m1 = SDConstruct((ASCIIString=>ASCIIString)[], lt=isless)
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
            l = ind_find(m1, strlist[j * 2 + 1])
            delete_ind!(m1,l)
        end
        spec = div(NSTRINGPAIR * 3,4)
        l = ind_first(m1)
        for j = 1 : spec
            l = advance_ind(m1,l)
        end
        k,d = deref_ind(m1,l)
        ekn = expectedk
        edn = expectedd
        @assert(k == ekn && d == edn)
    end
end




test1()
test2()
test5()
test6(2, "soothingly", "compere")

