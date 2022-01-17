include("networks/Network-Graphs.jl")

@enum COLORSTATE begin
    white # not informed
    red # informed but no echo
    green # informed and echo
end

struct EchoAlgorithm{T <: Integer}
    nw::Network{T}
    initiator::T
    informed::Vector{Bool}
    activation_edges::Vector{T}
    count::Vector{T}
    colors::Vector{COLORSTATE}

    function EchoAlgorithm{T}(nw::Network{T}, initiator::T) where T <: Integer
        initiator ∈ vertices(nw.graph) || throw(error("Initiator must be a Node of the graph!"))
        is_connected(nw.graph) || throw(error("Graph must be connected!"))
        new(nw, initiator, falses(nv(g)), zeros(T, nv(g)), zeros(T, nv(g)), fill(white, nv(g)))
    end

end

function EchoAlgorithm{T}(g::AbstractGraph{T}, initiator::T) where {T <: Integer}
    EchoAlgorithm{T}(Network{T}(g), initiator)
end

has_terminated(echo_alg::EchoAlgorithm) = echo_alg.count[echo_alg.initiator] == length(neighbors(echo_alg.nw.graph, echo_alg.initiator))

is_dead(echo_alg::EchoAlgorithm) = !has_letters(echo_alg.nw)

function _become_informed!(echo_alg::EchoAlgorithm{T}, v::T) where {T <: Integer}
    echo_alg.colors[v] = red
    echo_alg.informed[v] = true
    return echo_alg
end

function init_echo_algorithm!(echo_alg::EchoAlgorithm, content::S) where {S <: MessageContent}
    has_terminated(echo_alg) && throw(error("Algorithm has terminated! Please reinstantiate EchoAlgorithm."))
    v = echo_alg.initiator
    _become_informed!(echo_alg, v)
    send!(echo_alg.nw, v, neighbors(echo_alg.nw.graph, v), explorer, content)
    return echo_alg
end

function echo_algorithm_step!(echo_alg::EchoAlgorithm, content_cb::Function) # deliver content
    if has_terminated(echo_alg) 
        println("Algorithm has already terminated!") 
        return echo_alg
    end
    letter = pop_letter!(echo_alg.nw)
    content = content_cb(letter) # callback to use echo algorithm for
    sender, v = src(letter.e), dst(letter.e) # recipient v
    v_neighbors = neighbors(echo_alg.nw.graph, v)
    if !echo_alg.informed[v]
        _become_informed!(echo_alg, v)
        dsts = copy(v_neighbors)
        deleteat!(dsts, findfirst(isequal(sender), dsts))

        if ! (typeof(content) <: StopContent)
            send!(echo_alg.nw, v, dsts, explorer, content) # deliver content
        end
        echo_alg.activation_edges[v] = sender
    end
    echo_alg.count[v] += 1
    if echo_alg.count[v] == length(v_neighbors)

        if ! (typeof(content) <: StopContent) && v != echo_alg.initiator
            send!(echo_alg.nw, v, echo_alg.activation_edges[v], echo, content) # deliver content
        end
        echo_alg.colors[v] = green
    end
    return echo_alg
end