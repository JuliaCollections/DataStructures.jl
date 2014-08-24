using DataStructures



## Function fulldump dumps the entire tree; helpful for debugging.

function fulldump{K,D}(t::DataStructures.BalancedTree{K,D})
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




function checkcorrectness{K,D}(t::DataStructures.BalancedTree{K,D})
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
        if s > levstart[tdpth] && !isless(maxkeys[s - 1], minkeys[s])
            error("Data nodes out of order")
        end
        if s < bfstreesize || c3 > 0
            if t.tree[anc].splitkey1 != t.data[c2].k
                error("Splitkey1 of leaf should match key of 2nd child")
            end
        end
        if s < bfstreesize && c3 > 0
            if t.tree[anc].splitkey2 != t.data[c3].k
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
            @assert(s == levstart[curdepth] || isless(mk1,mk2))
            if c3 > 0 
                if t.tree[c3].parent != anc
                    error("Parent/child3 links do not match")
                end
                mk3 = minkeys[cp]
                cp += 1
                @assert(isless(mk2, mk3))
            end
            if s > levstart[curdepth]
                minkeys[s] = mk1
            end
            if t.tree[anc].splitkey1 != mk2
                error("Minkey2 not equal to minimum key among descendants of child2")
            end
            if c3 > 0 && t.tree[anc].splitkey2 != mk3
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
    if in(:useddatacells, names(DataStructures.BalancedTree))
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
    m1 = SortedDict((ASCIIString=>ASCIIString)[])
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
    i1 = ind_first(m1)
    while !is_ind_past_end(m1,i1)
        k,d = deref_ind(m1,i1)
        #println("+ reading: k = $k, d = $d")
        i1 = advance_ind(m1,i1)
        checkcorrectness(m1.bt)
    end
end

function test2()
    m0 = SortedDict((Int=>Float64)[])
    m1 = SortedDict([8=>32.0, 12=>33.1, 6=>18.2])
    expected = ([6,8,12], [18.2, 32.0, 33.1])
    checkcorrectness(m1.bt)
    ii = ind_first(m1)
    m2 = packdeepcopy(m1)
    m3 = packcopy(m1)
    p = first(m1)
    @assert(p[1] == 6 && p[2] == 18.2)
    for j = 1 : 3
        @assert(!is_ind_past_end(m1, ii))
        pr = deref_ind(m1, ii)
        @assert(pr[1] == expected[1][j] && pr[2] == expected[2][j])
        checkcorrectness(m1.bt)
        oldii = ii
        ii = advance_ind(m1, ii)
        delete_ind!(m1, oldii)
    end
    checkcorrectness(m1.bt)
    checkcorrectness(m2.bt)
    @assert(length(m2) == 3)
    ii = ind_first(m2)
    for j = 1 : 3
        pr = deref_ind(m2, ii)
        @assert(pr[1] == expected[1][j] && pr[2] == expected[2][j])
        ii = advance_ind(m2, ii)
    end

    checkcorrectness(m3.bt)
    @assert(length(m3) == 3)
    ii = ind_first(m3)
    for j = 1 : 3
        pr = deref_ind(m3, ii)
        @assert(pr[1] == expected[1][j] && pr[2] == expected[2][j])
        ii = advance_ind(m3, ii)
    end




    @assert(isempty(m1))
    @assert(length(m1) == 0)
    @assert(is_ind_past_end(m1, ii))
    N = 100
    for i = N : -1 : 2
        m1[i] = convert(Float64,i) ^ 2
        checkcorrectness(m1.bt)
    end
    @assert(!isempty(m1))
    assert(length(m1) == N - 1)
    for i = 2 : N
        pop!(m1, i)
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
        ii = ind_greater(m1, lastprime)
        if is_ind_past_end(m1, ii)
            break
        end
        j = deref_key_only_ind(m1, ii)
        for k = j * 2 : j : N
            p = ind_find(m1, k)
            if !is_ind_past_end(m1,p)
                delete_ind!(m1, p)
                checkcorrectness(m1.bt)
            end
        end
        lastprime = j
    end
    t = 0
    u = 0.0
    for pr = m1
        t += pr[1]
        u += pr[2]
    end
    numprimes = length(m1)
    @assert(t == sum(primes(N)))
    @assert(u == sum(primes(N).^2))
    m1[6] = 49.0
    @assert(length(m1) == numprimes + 1)
    @assert(m1[6] == 49.0)
    b, i6 = ind_insert!(m1, 6, 50.0)
    @assert(length(m1) == numprimes + 1)
    @assert(!b)
    p = deref_ind(m1, i6)
    @assert(p[1] == 6 && p[2] == 50.0)
    b2, i7 = ind_insert!(m1, 8, 51.0)
    @assert(length(m1) == numprimes + 2)
    @assert(b2)
    p = deref_ind(m1, i7)
    @assert(p[1] == 8 && p[2] == 51.0)
    delete_ind!(m1, i7)
    z = pop!(m1, 6)
    checkcorrectness(m1.bt)
    @assert(z == 50.0)
    i8 = ind_first(m1)
    p = deref_ind(m1, i8)
    @assert(p[1] == 2 && p[2] == 4.0)
    @assert(!is_ind_before_start(m1,i8))
    i9 = regress_ind(m1, i8)
    @assert(is_ind_before_start(m1,i9))
    i10 = ind_find(m1, 17)
    i11 = regress_ind(m1, i10)
    @assert(deref_key_only_ind(m1, i11) == 13)
    i12 = ind_equal_or_greater(m1, 47)
    i13 = ind_equal_or_greater(m1, 48)
    @assert(deref_key_only_ind(m1, i12) == 47)
    @assert(deref_key_only_ind(m1, i13) == 53)
    i14 = ind_greater(m1, 47)
    i15 = ind_greater(m1, 48)
    @assert(deref_key_only_ind(m1, i14) == 53)
    @assert(deref_key_only_ind(m1, i15) == 53)
    ww = primes(N)
    ww2 = Array(Int, 0)
    lb = 50
    ub = 70
    for i in ww
        if lb <= i < ub
            push!(ww2, i)
        end
    end
    count = 1
    for pr = sorted_dict_range_iteration(m1, ind_equal_or_greater(m1, lb),
                                          ind_equal_or_greater(m1, ub))
        @assert(pr[1] == ww2[count] && pr[2] == convert(Float64,ww2[count])^2)
        count += 1
    end
    @assert(length(ww2) == count - 1)
    pp = primes(N)
    count = 1
    for pr2 = enumerate_ind(m1)
        dr = deref_ind(m1, pr2[1])
        @assert(dr[1] == pp[count])
        @assert(pr2[2][1] == pp[count])
        @assert(pr2[2][2] == convert(Float64,pp[count])^2)
        count += 1
    end
    @assert(length(pp) == count - 1)
    count = 1
    for pt = enumerate_ind(sorted_dict_range_iteration(m1, 
                                                        ind_equal_or_greater(m1, lb),
                                                        ind_equal_or_greater(m1, ub)))
        pa = pt[1]
        pr = pt[2]
        @assert(pr[1] == ww2[count] && pr[2] == convert(Float64,ww2[count])^2)
        @assert(deref_key_only_ind(m1, pa) == pr[1])
        count += 1
    end
    @assert(length(ww2) == count - 1)
    pp = primes(N)
    count = 1
    for pr2 = enumerate_ind(m1)
        dr = deref_ind(m1, pr2[1])
        @assert(dr[1] == pp[count])
        @assert(pr2[2][1] == pp[count])
        @assert(pr2[2][2] == convert(Float64,pp[count])^2)
        count += 1
    end
    @assert(length(pp) == count - 1)
    count = 1
    for j = keys(m1)
        @assert(j == pp[count])
        count += 1
    end
    @assert(length(pp) == count - 1)
    count = 1
    for pj = enumerate_ind(keys(m1))
        @assert(deref_key_only_ind(m1,pj[1]) == pj[2])
        @assert(pj[2] == pp[count])
        count += 1
    end
    @assert(length(pp) == count - 1)
    count = 1
    for q = values(m1)
        @assert(q == convert(Float64,pp[count])^2)
        count += 1
    end
    @assert(length(pp) == count - 1)
    count = 1
    for qj = enumerate_ind(values(m1))
        @assert(convert(Float64,deref_key_only_ind(m1,qj[1]))^2 == qj[2])
        @assert(qj[2] == convert(Float64,pp[count])^2)
        count += 1
    end
    @assert(length(pp) == count - 1)
    cc = last(m1)
    assert(cc[1] == last(pp))
    ww = first(m1)
    assert(ww[1] == 2)
    tpr = eltype(m1)
    @assert(tpr[1] == Int && tpr[2] == Float64)
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
    @assert(getkey(m1,12, 9) == 9)
    delete!(m1, 17)
    @assert(length(m1) == length(pp) - 1)
    @assert(deref_key_only_ind(m1, advance_ind(m1, ind_find(m1,13))) == 19)

    empty!(m1)
    checkcorrectness(m1.bt)
    @assert(isempty(m1))
    c1 = SortedDict(["England"=>3, 
                        "France"=>9, 
                        "Albania"=>7])
    c2 = SortedDict(["England"=>6, 
                        "Hungary"=>19, 
                        "Moldova"=>11])
    c3 = merge(c1, c2)
    c4 = SortedDict(["Albania"=>7, 
                        "France"=>9,
                        "England"=>6,
                        "Moldova"=>11,
                        "Hungary"=>19])
    @assert(isequal(c3,c4))
    merge!(c1,c2)
    @assert(isequal(c3,c1))
end



function seekfile(fname)
    global LOAD_PATH
    for item = LOAD_PATH
        if item[end] != '\\' && item[end] != '/'
            fullname = item * "/../test/" * fname
        else
            fullname = item * "../test/" * fname
        end
        if filesize(fullname) > 0
            return fullname
        end
    end
    error("file $fname not found in LOAD_PATH/../test/ which is\n $LOAD_PATH")
end

function dumpstringascii(x::ASCIIString)
    for j = 1 : length(x)
        print(convert(Int, x[j]))
        print(' ')
    end
    println("")
end


function test6(numtrial::Int, expectedk::ASCIIString, expectedd::ASCIIString)
    NSTRINGPAIR = 50000
    m1 = SortedDict((ASCIIString=>ASCIIString)[])
    strlist = ASCIIString[]
    open(seekfile("wordsScram.txt"), "r") do inio
        for j = 1 : NSTRINGPAIR * 2
            push!(strlist, readline(inio))
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
        ekn = expectedk * "\r\n"
        edn = expectedd * "\r\n"
        @assert(k == ekn && d == edn)
    end
end

function test7()
    m1 = MultiMap(["a", "b", "a", "c", "f", "ehi"], [9,2,1,8,6,3])
    checkcorrectness(m1.bt)
    expected_out = (["a", "a", "b", "c", "ehi", "f"], [9,1,2,8,3,6])
    count = 1
    for pr = m1
        @assert(pr[1] == expected_out[1][count] && pr[2] == expected_out[2][count])
        count += 1
    end
    @assert(count == 7)
    @assert(first(m1) == ("a", 9))
    m2 = packcopy(m1)
    count = 1
    for pr = m2
        @assert(pr[1] == expected_out[1][count] && pr[2] == expected_out[2][count])
        count += 1
    end
    @assert(count == 7)
    count = 1
    m3 = packdeepcopy(m1)
    for pr = m3
        @assert(pr[1] == expected_out[1][count] && pr[2] == expected_out[2][count])
        count += 1
    end
    @assert(count == 7)
    count = 1
    for pr0 = enumerate_ind(m1)
        pr = pr0[2]
        @assert(pr[1] == expected_out[1][count] && pr[2] == expected_out[2][count])
        @assert(deref_ind(m1,pr0[1]) == pr)
        count += 1
    end
    @assert(count == 7)

    em1 = MultiMap(expected_out[1], expected_out[2])
    @assert(isequal(m1,em1))
    ind_insert!(m1, "at", 6)
    @assert(!isequal(m1,em1))
    ind_insert!(em1, "at", 6)
    @assert(isequal(m1,em1))
    m1 = MultiMap(Float64[], Int[])
    N = 200
    for j = -N : N
        c = convert(Float64, j*j)
        i = ind_insert!(m1, convert(Float64, j*j), j)
        checkcorrectness(m1.bt)
        pr = deref_ind(m1, i)
        @assert(pr[1] == c && pr[2] == j)
        k = deref_key_only_ind(m1,i)
        @assert(k == c)
    end
    @assert(length(m1) == 2*N + 1)
    dcount = 0
    p = before_start(m1)
    p = advance_ind(m1, p)
    @assert(p == ind_first(m1))
    p2 = past_end(m1)
    @assert(is_ind_past_end(m1, p2))
    p2 = regress_ind(m1, p2)
    @assert(p2 == endof(m1))
    l = last(m1)
    @assert(l[1] == convert(Float64, N*N) && l[2] == N)
    ff = first(m1)
    @assert(ff[1] == 0.0 && ff[2] == 0)
    i = ind_equal_or_greater(m1, 16.0)
    pi = deref_ind(m1,i)
    @assert(pi[1] == 16.0 && pi[2] == -4)
    i2 = ind_equal_or_greater(m1, 17.0)
    pi2 = deref_ind(m1,i2)
    @assert(pi2[1] == 25.0 && pi2[2] == -5)
    i = ind_greater(m1, 16.0)
    pi = deref_ind(m1,i)
    @assert(pi[1] == 25.0 && pi[2] == -5)
    i2 = ind_greater(m1, 17.0)
    pi2 = deref_ind(m1,i2)
    @assert(pi2[1] == 25.0 && pi2[2] == -5)
    @assert(haskey(m1, 49.0))
    @assert(!haskey(m1, 50.0))
    for j = div(N,3) : div(N,2)
        c = convert(Float64, j*j)
        i1,i2 = ind_findrange(m1, c)
        @assert(!is_ind_past_end(m1, i1) && !is_ind_past_end(m1, i2))
        dcounti = 0
        for pr = multimap_range_iteration(m1, i1, i2)
            @assert(pr[1] == c)
            dcounti += 1
        end
        @assert(dcounti == 2)
            
        dcounti = 0
        for i = enumerate_ind(multimap_range_iteration(m1, i1, i2))
            delete_ind!(m1, i[1])
            checkcorrectness(m1.bt)
            dcounti += 1
            dcount += 1
        end
        @assert(dcounti == 2)
    end
    @assert(length(m1) == 2 * N + 1 - dcount)
    @assert(!isempty(m1) && length(m1) > 0)
    empty!(m1)
    checkcorrectness(m1.bt)
    @assert(isempty(m1) && length(m1) == 0)
    pr = eltype(m1)
    @assert(pr == (Float64, Int64))
end


function test8(ntrial::Int, expecteddelcount::Int, expectedk::ASCIIString, 
               expectedd::ASCIIString)
    NSTRING = 100000
    m1 = MultiMap(ASCIIString[], ASCIIString[])
    strlist = ASCIIString[]
    open(seekfile("wordsScram.txt"), "r") do inio
        for j = 1 : NSTRING
            push!(strlist, readline(inio))
        end
    end
    dlist = ["de", "al", "sh", "pe", "zk", "to"]
    for trial = 1 : ntrial
        empty!(m1)
        for j = 1 : NSTRING
            if length(strlist[j]) > 1
                ind_insert!(m1,strlist[j][1:2],strlist[j])
            else
                s = strlist[j] * "  "
                k = s[1:2]
                d = s
                ind_insert!(m1,k,d)
            end
        end
        delcount = 0
        for item = dlist
            istart, iend = ind_findrange(m1, item)
            delcount1 = 0
            for pr = enumerate_ind(multimap_range_iteration(m1, istart, iend))
                delete_ind!(m1, pr[1])
                delcount1 += 1
            end
            # println("for prefix $item, $delcount1 items were deleted")
            delcount += delcount1
        end
        @assert(delcount == expecteddelcount)
        spec = div(NSTRING * 3,4)
        l = ind_first(m1)
        for j = 1 : spec
            l = advance_ind(m1,l)
        end
        k,d = deref_ind(m1,l)
        edn = expectedd * "\r\n"
        @assert(k == expectedk && d == edn)
        #println("word pair #$spec k = $k d = $d")
    end
end


function test9()
    m1 = SortedSet(ASCIIString[])
    @assert(length(m1) == 0)
    @assert(isempty(m1))
    checkcorrectness(m1.bt)
    push!(m1, "hello")
    checkcorrectness(m1.bt)
    push!(m1, "apple")
    checkcorrectness(m1.bt)
    push!(m1, "ap")
    checkcorrectness(m1.bt)
    f = first(m1)
    @assert(f == "ap")
    @assert(is_ind_past_end(m1, ind_find(m1, "applepie")))
    q = ind_find(m1, "apple")
    @assert(!is_ind_past_end(m1,q))
    b, p = ind_insert!(m1, "applecake")
    checkcorrectness(m1.bt)
    @assert(b)
    b, q2 = ind_insert!(m1, "hello")
    checkcorrectness(m1.bt)
    @assert(!b)
    b, r = ind_insert!(m1, "appleII")
    checkcorrectness(m1.bt)
    @assert(b)


    delete_ind!(m1, q)
    checkcorrectness(m1.bt)
    s = past_end(m1)
    @assert(is_ind_past_end(m1,s))
    w = before_start(m1)
    @assert(is_ind_before_start(m1,w))
    @assert(!is_ind_before_start(m1,s))
    @assert(advance_ind(m1, r) == p)
    @assert(regress_ind(m1, p) == r)
    @assert(ind_find(m1, "hello") == endof(m1))
    @assert(last(m1) == "hello")
    @assert(first(m1) == "ap")
    @assert(deref_ind(m1,r) == "appleII")
    @assert(deref_key_only_ind(m1,r) == "appleII")
    s = ind_equal_or_greater(m1, "applecake")
    @assert(s == p)
    s2 = ind_greater(m1, "applecake")
    @assert(s2 == q2)
    l2 = ["ap", "appleII", "applecake", "hello"]
    count = 1
    for item = m1
        @assert(item == l2[count])
        count += 1
    end
    @assert(count == 5)

    m2 = packcopy(m1)
    count = 1
    for item = m2
        @assert(item == l2[count])
        count += 1
    end
    @assert(count == 5)

    m3 = packdeepcopy(m1)
    count = 1
    for item = m3
        @assert(item == l2[count])
        count += 1
    end
    @assert(count == 5)


    count = 1
    for item = sorted_set_range_iteration(m1, r, endof(m1))
        @assert(item == l2[count + 1])
        count += 1
    end
    @assert(count == 3)
    
    count = 1
    for pr = enumerate_ind(m1)
        @assert(deref_ind(m1,pr[1]) == pr[2])
        @assert(pr[2] == l2[count])
        count += 1
    end
    @assert(count == 5)

    count = 1
    for pr = enumerate_ind(sorted_set_range_iteration(m1, r, endof(m1)))
        @assert(deref_ind(m1,pr[1]) == pr[2])
        @assert(pr[2] == l2[count + 1])
        count += 1
    end
    @assert(count == 3)
    @assert(eltype(m1) == ASCIIString)
    delete!(m1, "ap")
    @assert(length(m1) == 3)
    @assert(!in("ap", m1))
    @assert(in("appleII", m1))
    m2 = SortedSet(l2)
    checkcorrectness(m2.bt)
    @assert(!isequal(m1,m2))
    push!(m1, "ap")
    checkcorrectness(m1.bt)
    @assert(length(m1) == 4)
    @assert(isequal(m1,m2))
    w = SortedSet(["ap", "hello", "appleII"])
    h = ["appleII", "applecake"]
    @assert(isequal(m1, union(w, SortedSet(h))))
    q = intersect(w, SortedSet(h))
    checkcorrectness(q.bt)
    @assert(length(q) == 1)
    @assert(deref_ind(q, ind_first(q)) == "appleII")
    @assert(last(q) == "appleII")
    y = symdiff(w,SortedSet(h))
    checkcorrectness(y.bt)
    @assert(length(y) == 3)
    @assert(isequal(y, SortedSet(["applecake", "hello", "ap"])))
    z = setdiff(w, SortedSet(h))
    checkcorrectness(z.bt)
    @assert(isequal(z, SortedSet(["hello", "ap"])))
    w2 = deepcopy(w)
    checkcorrectness(w2.bt)
    setdiff!(w2, h)
    checkcorrectness(w2.bt)
    @assert(length(w2) == 2)
    @assert(isequal(w2, SortedSet(["hello", "ap"])))
    @assert(issubset(w2, m1))
    @assert(!issubset(w2, SortedSet(h)))
    union!(w, h)
    checkcorrectness(w.bt)
    @assert(isequal(m1, w))
    empty!(m1)
    checkcorrectness(m1.bt)
    @assert(length(m1) == 0)
end
    

function test10(ntrial::Int, expecteddelcount::Int, expectedk::ASCIIString)
    NSTRING = 100000
    m1 = SortedSet(ASCIIString[])
    strlist = ASCIIString[]
    open(seekfile("wordsScram.txt"), "r") do inio
        for j = 1 : NSTRING
            push!(strlist, readline(inio))
        end
    end
    startendlist = [("de","df"), ("al","am"),
                    ("sh","si"), ("pe", "pf"),
                    ("zk","zl"), ("to", "tp")]
    for trial = 1 : ntrial
        empty!(m1)
        for j = 1 : NSTRING
            ind_insert!(m1,strlist[j])
        end
        delcount = 0
        for item = startendlist
            istart = ind_equal_or_greater(m1, item[1])
            iend = ind_equal_or_greater(m1,item[2])
            delcount1 = 0
            for pr = enumerate_ind(sorted_set_range_iteration(m1, istart, iend))
                delete_ind!(m1, pr[1])
                delcount1 += 1
            end
            #println("for prefix $item, $delcount1 items were deleted")
            delcount += delcount1
        end
        #println("$delcount total items deleted")
        @assert(delcount == expecteddelcount)
        spec = div(NSTRING * 3,4)
        l = ind_first(m1)
        for j = 1 : spec
            l = advance_ind(m1,l)
        end
        k = deref_ind(m1,l)
        @assert(k == expectedk * "\r\n")
    end
end


function test11(N)
    primes1 = SortedSet(Int[])
    for i = N : -1 : 2
        push!(primes1, i)
    end
    lastprime = 1
    while true
        nextprime_ind = ind_greater(primes1, lastprime)
        if is_ind_past_end(primes1, nextprime_ind)
            break
        end
        nextprime = deref_ind(primes1, nextprime_ind)
        for m = nextprime * 2 : nextprime : N
            i = ind_find(primes1, m)
            if !is_ind_past_end(primes1, i)
                delete_ind!(primes1, i)
            end
        end
        lastprime = nextprime
    end
    s = 0
    for p = primes1
        s += p
    end
    #println("sum of primes up to $N is $s")
    @assert(s == sum(primes(N)))
end


    
isequal_l(x::ASCIIString, y::ASCIIString) = isequal(x,y)
isequal_l(x::Int, y::Int) = isequal(x,y)

test1()
test2()
test6(2, "soothingly", "compere")
test7()
test8(2, 6177, "re", "resistors")
test9()
test10(2, 6177, "reglazed")
test11(30000)
