using Graphs
using StatsBase: Weights, sample!


function create_random_topology(n::Int, m::Int = ceil(Int, n / 2) + 1)
    @assert m > n / 2
    g = SimpleGraph(n)
    while ne(g) < m
        v1, v2 = rand(vertices(g), 2)
        add_edge!(g, v1, v2)
    end
    return g
end


function create_small_world_topology(n, k::Int = 2, p::Float64 = 0.05)
    @assert 1 ≤ k ≤ n
    @assert 0 ≤ p ≤ 1
    g = SimpleGraph(n)
    for v1 in vertices(g)
        for i = 1:k
            v2 = mod1(v1 + i, length(vertices(g)))
            add_edge!(g, v1, v2)
        end
    end
    if p > 0
        for e in edges(g)
            if rand() ≤ p
                v1 = src(e)
                rem_edge!(g, e)
                v2 = rand(vertices(g))
                add_edge!(g, v1, v2)
            end
        end
    end
    return g
end

function create_scale_free_topology(n::Int, n0::Int = 3, n1::Int = 2)
    @assert 2 ≤ n1 ≤ n0 ≤ n
    g = create_partial_ring(n, n0)
    _add_scale_free_topopolgy!(g, n0, n1)
    return g

end

function create_scale_free_topology(base_graph::SimpleGraph, n0::Int = 3, n1::Int = 2)
    @assert 2 ≤ n1 ≤ n0 ≤ length(vertices(base_graph))
    g = deepcopy(base_graph)
    _add_scale_free_topopolgy!(g, n0, n1)
    return g
end



function create_partial_ring(total_nodes::Int, ring_nodes::Int)
    g = SimpleGraph(total_nodes)
    for v1 = 1:ring_nodes
        v2 = mod1(v1 + 1, length(vertices(g)))
        add_edge!(g, v1, v2)
    end
    return g
end



function _add_scale_free_topopolgy!(g::SimpleGraph, n0::Int, n1::Int)
    n = length(vertices(g))
    neighbors = Vector{Int64}(undef, n1)
    for v1 = n0+1:n
        wv = Weights([degree(g, v) for v in vertices(g)])
        sample!(vertices(g), wv, neighbors, replace = false)
        for v2 in neighbors
            add_edge!(g, v1, v2)
        end
    end
    return g
end

is_tree(g::AbstractGraph) = is_connected(g) && ne(g) === nv(g) - 1


function flip_edge!(g::AbstractGraph, e::Edge)
    has_edge(g, e) || throw(error("Edge e is not in g!"))
    rem_edge!(g, e)
    add_edge!(g, reverse(e))
    return g

end