using Graphs: tree # extra import necessary
include("networks/Network-Graphs.jl") # uses Graphs
include("networks/Util.jl") # is_tree


mutable struct Token{T<:Integer}
    pos::T # 0 if in message Queue
end

struct LiftContent <: MessageContent end

struct LiftAlgorithm{T<:Integer}
    nw::Network{T} # contains graph and global message queue
    inquirer::Set{T}
    token::Token
    outgoing_edges::Vector{T} # local view of the nodes
    request_sets::Vector{Set{T}} # buffer for received requests
    lift_content::LiftContent

    function LiftAlgorithm{T}(graph::DiGraph{T}, inquirer::Set{T}) where {T<:Integer}
        issubset(inquirer, vertices(graph)) || throw(error("Inquirer must be nodes in the graph!"))
        is_tree(graph) || throw(error("Graph must be a directed tree!"))
        outgoing_edges = zeros(Int64, nv(t))
        token_pos = 0
        for i = 1:nv(t)
            outgoing_edge = outneighbors(t, i)
            0 ≤ length(outgoing_edge) ≤ 1 || throw(error("There must be at most one outgoing edge per node!"))
            if length(outgoing_edge) == 1
                outgoing_edges[i] = outgoing_edge[1]
            else
                token_pos == 0 || throw(error("There must be exactly one token!"))
                token_pos = i
            end
        end
        token_pos > 0 || throw(error("There must be exactly one token!"))
        request_sets = [Set{Int64}() for i = 1:nv(t)]
        new(Network{T}(graph), inquirer, Token(token_pos), outgoing_edges, request_sets, LiftContent())
    end

end

has_token(lift_alg::LiftAlgorithm, node::T) where {T<:Integer} = lift_alg.outgoing_edges[node] === 0
has_terminated(lift_alg::LiftAlgorithm) = isempty(lift_alg.inquirer) && !has_letters(lift_alg.nw)
is_dead(lift_alg::LiftAlgorithm) = !isempty(lift_alg.inquirer) && !has_letters(lift_alg.nw)

function send_outgoing_request!(lift_alg::LiftAlgorithm, node::T) where {T<:Integer}
    dst = lift_alg.outgoing_edges[node]
    send!(lift_alg.nw, node, dst, request, lift_alg.lift_content)
end

function receive_request!(lift_alg::LiftAlgorithm, src::T, dst::T) where {T<:Integer}
    if has_token(lift_alg, dst)
        send_token!(lift_alg, dst, src)
    else
        if isempty(lift_alg.request_sets[dst])
            send_outgoing_request!(lift_alg, dst)
        end
        push!(lift_alg.request_sets[dst], src)

    end
end


function receive_token!(lift_alg::LiftAlgorithm, token_edge::Edge) where {T<:Integer}
    # token_edge is flipped to the edge in the graph
    # flip edge and optionally send token further
    recipient = dst(token_edge)
    flip_edge!(lift_alg.nw.graph, reverse(token_edge)) # flip here since token_edge is not in the graph
    lift_alg.token.pos = recipient
    lift_alg.outgoing_edges[recipient] = 0
    delete!(lift_alg.inquirer, recipient)
    requests = lift_alg.request_sets[recipient]
    if !isempty(requests)
        token_dst = pop!(requests)
        send_token!(lift_alg, recipient, token_dst)
        if !isempty(requests) # send request after token
            send!(lift_alg.nw, recipient, token_dst, request, lift_alg.lift_content)
        end
    end
end

function send_token!(lift_alg::LiftAlgorithm, token_src::T, token_dst::T) where {T<:Integer}
    lift_alg.outgoing_edges[token_src] = token_dst # flip edge locally
    lift_alg.token.pos = 0
    send!(lift_alg.nw, token_src, token_dst, token, lift_alg.lift_content)
end


function init_lift_algorithm!(lift_alg::LiftAlgorithm) where {T<:Integer}
    # init requests of inquirer
    for inq ∈ lift_alg.inquirer
        send_outgoing_request!(lift_alg, inq)
    end
    return lift_alg
end


function lift_algorithm_step!(lift_alg::LiftAlgorithm) where {T<:Integer}
    if has_terminated(lift_alg)
        println("Terminated!")
    elseif is_dead(lift_alg)
        println("Algorithm is dead!")
    else
        letter = pop_letter!(lift_alg.nw)
        if letter.m == token
            receive_token!(lift_alg, letter.e) # token_edge
        else # request received
            receive_request!(lift_alg, src(letter.e), dst(letter.e))
        end
    end
    # TODO insert inquirer at random times 
    ## not the one with the token
    ## send request from inquirer
    return lift_alg
end





