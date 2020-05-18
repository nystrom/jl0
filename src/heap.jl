function gc(state::State)
    ################################################################
    # TODO: this code needs to written by you
    # 
    # Implement mark-sweep garbage collection.
    # The root set is the call stack (`state.frames`).
    # Anything reachable from the `vars` and `stack` of any frame in
    # the call stack is not garbage. Anything else is garbage.
    #
    # You'll need to modify `alloc`, below, to add a mark bit
    # to the object representation. Add a `MarkBit` after the tag,
    # initializing to `Unmarked`.
    #
    # Traverse the graph from the root set, marking objects.
    #
    # Once marked, sweep the heap from the bottom, clearing any
    # unmarked object. Overwrite the entire object with `nothing`.
    # Reset the mark bit of any reachable objects to `Unmarked`.
    #
    # You can assume (once you've changed alloc, below) that
    # objects are laid out as follows.
    #
    # Assume the program:
    #
    #     struct Point x; y; end
    #     p = Point(1,2)
    #     q = Point(3,4)
    #
    # Then the heap will look like:
    #
    # [0] :Point   :: Symbol
    # [1] Unmarked :: MarkBit
    # [2] INT(1)   :: Value
    # [3] INT(2)   :: Value
    # [4] :Point   :: Symbol
    # [5] Unmarked :: MarkBit
    # [6] INT(3)   :: Value
    # [7] INT(4)   :: Value
    #
    # p will be LOC(0)
    # q will be LOC(4)
    #
    # After evaluating `p = nothing` and garbage collection, the
    # heap should look like:
    #
    # [0] nothing  :: Nothing
    # [1] nothing  :: Nothing
    # [2] nothing  :: Nothing
    # [3] nothing  :: Nothing
    # [4] :Point   :: Symbol
    # [5] Unmarked :: MarkBit
    # [6] INT(3)   :: Value
    # [7] INT(4)   :: Value
    #
    ################################################################
end

# count the number of allocated slots in the heap
# actually, just count the tags
function count_allocated_objects(state::State)
    count(x -> x isa Symbol, state.heap)
end

# count the number of allocated slots in the heap
function count_allocated_slots(state::State)
    count(x -> x != nothing, state.heap)
end

# find the first block of the heap that can fit size slots
# return nothing on failure
function first_fit(state::State, size::Int)::Union{LOC, Nothing}
    # try to find a free slot in the heap
    for (i, x) in enumerate(state.heap[1:end-size])
        if x == nothing
            # check if there's room
            fits = true
            for j in i:(i + size)
                if state.heap[j] != nothing
                    fits = false
                end
            end

            if fits
                return LOC(i)
            end
        end
    end

    return nothing
end

function struct_size(state::State, tag::Symbol)::Int
    ################################################################
    # TODO: this code needs to be modified to add space for a
    # MarkBit to the object representation after the tag
    ################################################################

    haskey(state.structs, tag) || @error("struct $tag does not exist")
    s = state.structs[tag]
    # add one for the tag
    size = length(s.fields) + 1
end

function alloc(state::State, tag::Symbol)::LOC
    size = struct_size(state, tag)
    
    h = first_fit(state, size)
    if h == nothing
        # Ran out of space. garbage collect
        gc(state)

        # Try again
        h = first_fit(state, size)
        if h == nothing
            # Still not space, increase the heap size
            n = length(state.heap)
            heap::Vector{HeapValue} = fill(nothing, nextpow(2, n + size))
            heap[1:n] = state.heap
            state.heap = heap

            # Try one last time. This one should work!
            h = first_fit(state, size)
        end
    end

    h == nothing && @error("out of memory")

    ################################################################
    # TODO: this code needs to be modified to add a MarkBit to the
    # object representation after the tag
    ################################################################

    state.heap[h.value] = tag
    return h
end

function getfield(state::State, h::LOC, x::Symbol)
    1 <= h.value <= length(state.heap) || @error("invalid heap location")

    tag = state.heap[h.value]
    tag isa Symbol || @error("location $h does not hold struct tag")
    haskey(state.structs, tag) || @error("struct $tag does not exist")

    s = state.structs[tag]

    i = findfirst(==(x), s.fields)
    i != nothing || @error("field $x not found")

    ################################################################
    # TODO: this code needs to be modified to account for the MarkBit
    ################################################################

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

    ################################################################
    # TODO: this code needs to be modified to account for the MarkBit
    ################################################################

    p = h.value + i
    1 <= p <= length(state.heap) || @error("invalid heap location")

    state.heap[p] = v
    return v
end

