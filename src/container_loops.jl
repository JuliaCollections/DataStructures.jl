using Iterators

import Base.keys
import Base.values

# Helper
immutable RangeIterator{T,S}
    it::T
    start::S
    stop::S
end
start(r::RangeIterator) = r.start
next(r::RangeIterator, state) = next(r.it, state)
done(r::RangeIterator, state) = state == r.stop

# Iterate over elements
element_it(m::SAContainer, it = Leaves(m.bt)) = imap(it) do st
    node = st.tree.data[st.idx]
    node.k => node.d
end
start(m::SAContainer) = start(element_it(m))
next(m::SAContainer, state) = next(element_it(m), state)
done(m::SAContainer, state) = done(element_it(m), state)

keys(m::SAContainer) = imap(st->st.tree.data[st.idx].k, Leaves(m.bt))
values(m::SAContainer) = imap(st->st.tree.data[st.idx].d, Leaves(m.bt))

onlysemitokens(m::SAContainer) = imap(st->IntSemiToken(st.idx), Leaves(m.bt))

exclusive(m::SAContainer, start, stop) = element_it(m,
    RangeIterator(Leaves.m.bt,Subtree(m.bt,start,m.bt.depth),
        Subtree(m.bt,stop,m.bt.depth)))
exclusive(m::SAContainer, ii::Tuple) = exclusive(m, ii...)
inclusive(m::SAContainer, start, stop) = element_it(m,
    RangeIterator(Leaves.m.bt,Subtree(m.bt,start,m.bt.depth),
        get(next(Leaves(m.bt),Subtree(m.bt,stop,m.bt.depth))[2])))
inclusive(m::SAContainer, ii::Tuple) = inclusive(m, ii...)

eachindex(sd::SortedDict) = keys(sd)
eachindex(sdm::SortedMultiDict) = onlysemitokens(sdm)
eachindex(ss::SortedSet) = onlysemitokens(ss)

empty!(m::SAContainer) =  empty!(m.bt)
length(m::SAContainer) = length(m.bt.data) - length(m.bt.freedatainds)
isempty(m::SAContainer) = length(m) == 0
