function gc(state::State)
    # TODO: fill in this code
end

function count_allocated(state::State)
    count(x -> x != nothing, state.heap)
end

function alloc(state::State, tag::Symbol)::LOC
    haskey(state.structs, tag) || @error("struct $tag does not exist")
    s = state.structs[tag]
    size = length(s.fields)

    # try to find a free slot in the heap
    for (i, x) in enumerate(state.heap)
        if x == nothing
            state.heap[i] = tag
            return LOC(i)
        end
    end

    # ran out of space. garbage collect
    gc(state)

    # try again
    for (i, x) in enumerate(state.heap)
        if x == nothing
            state.heap[i] = tag
            return LOC(i)
        end
    end

    n = length(state.heap)

    # still no space, increase the heap size
    heap = fill(nothing, n * 2)
    heap[1:n] = state.heap
    state.heap = heap

    # add the new object to the heap
    h = n+1
    state.heap[h] = tag

    return LOC(h)
end

function free(state::State, h::LOC)
    1 <= h.value <= length(state.heap) || @error("invalid heap location")
    state.heap[h.value] = nothing
end

function getfield(state::State, h::LOC, x::Symbol)
    1 <= h.value <= length(state.heap) || @error("invalid heap location")

    tag = state.heap[h.value]
    tag isa Symbol || @error("location $h does not hold struct tag")
    haskey(state.structs, tag) || @error("struct $tag does not exist")

    s = state.structs[tag]

    i = findfirst(==(x), s.fields)
    i != nothing || @error("field $x not found")

    p = h.value + i
    1 <= p <= length(state.heap) || @error("invalid heap location")

    return state.heap[p]
end

function putfield(state::State, h::LOC, x::Symbol, v::Value)
    1 <= h.value <= length(state.heap) || @error("invalid heap location")

    tag = state.heap[h.value]
    tag isa Symbol || @error("location $h does not hold struct tag")
    haskey(state.structs, tag) || @error("struct $tag does not exist")

    s = state.structs[tag]

    i = findfirst(==(x), s.fields)
    i != nothing || @error("field $x not found")

    p = h.value + i
    1 <= p <= length(state.heap) || @error("invalid heap location")

    state.heap[p] = v
    return v
end

