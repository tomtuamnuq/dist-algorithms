include("EchoAlgorithm.jl")


struct ElectionIDMessage{T <: Integer} <: MessageContent
    id::T
end

struct Swallow <: StopContent end

mutable struct ElectionAlgorithmWinner{T <: Integer}
    echo_algorithm_instance::Union{EchoAlgorithm,Nothing}
    winner_process_id::T
    ElectionAlgorithmWinner{T}() where T <: Integer = new(nothing, 0)

end

struct ElectionAlgorithm{T <: Integer}
    graph::AbstractGraph{T}
    process_ids::AbstractArray{T} # unique identity p
    strongest_ids::AbstractArray{T} # local variable M_p per process
    strongest_id_callback::Function
    initiators::AbstractArray{T} # process id of initiators
    initiator_id_nodes_map::Dict{T,T}
    echo_algorithms::AbstractArray{EchoAlgorithm}
    winner::ElectionAlgorithmWinner{T}
    
    function ElectionAlgorithm{T}(graph::AbstractGraph{T}, process_ids::AbstractArray{T}, initiators::AbstractArray{T}) where T <: Integer
        1 ≤ length(initiators) ≤ length(process_ids) || throw(error("There must not be more initiators than processes and at least one initiator!"))
        length(process_ids) == nv(graph) || throw(error("Number of processes and vertices of the graph must be equal!"))
        allunique(process_ids) || throw(error("There must be no duplicate process ids!"))
        is_connected(graph) || throw(error("Graph must be connected!"))
        initiator_id_nodes_map = Dict{T,T}()
        for (i, id) ∈ enumerate(process_ids)
            if id ∈ initiators
                initiator_id_nodes_map[id] =  i
            end 
        end
        length(keys(initiator_id_nodes_map)) == length(initiators) || throw(error("All initiators must have a process id in the array!"))
        echo_algorithms = map(i -> EchoAlgorithm{T}(graph, initiator_id_nodes_map[i]), initiators)
        strongest_ids = zeros(T, length(process_ids))
        strongest_id_callback = _elec_algorithm_echo_callback_gen(strongest_ids)
        new(graph, process_ids, strongest_ids, strongest_id_callback, initiators, initiator_id_nodes_map, echo_algorithms, ElectionAlgorithmWinner{T}())
    end
end
function _elec_algorithm_echo_callback_gen(strongest_ids::AbstractArray{T}) where {T <: Integer}
    swallow = Swallow()
    return function elec_content_callback(letter::Letter{T,ElectionIDMessage{T}}) where {T <: Integer}
        recipient_node, content = dst(letter.e), letter.content
        if strongest_ids[recipient_node] <= content.id 
            strongest_ids[recipient_node] = content.id
            return content
        end 
        return swallow
    end
end

function ElectionAlgorithm{T}(graph::AbstractGraph{T}) where {T <: Integer} 
    processes = collect(T, vertices(graph))
    ElectionAlgorithm{T}(graph, processes, processes)
end

has_winner(elec_alg::ElectionAlgorithm) = elec_alg.winner.echo_algorithm_instance !== nothing
has_terminated(elec_alg::ElectionAlgorithm) = has_winner(elec_alg) && has_terminated(elec_alg.winner.echo_algorithm_instance) # TODO implement last round
is_dead(elec_alg::ElectionAlgorithm) = !isempty(elec_alg.echo_algorithms) && all(is_dead.(elec_alg.echo_algorithms))

function init_election_algorithm!(elec_alg::ElectionAlgorithm)
    for initiator ∈ elec_alg.initiators # set M_p to p
        elec_alg.strongest_ids[elec_alg.initiator_id_nodes_map[initiator]] = initiator
    end
    init_echo_algorithm!.(elec_alg.echo_algorithms, [ElectionIDMessage(id) for id in elec_alg.initiators])
    return elec_alg
end

function election_algorithm_step!(elec_alg::ElectionAlgorithm)
    if has_winner(elec_alg)
        return _winner_step!(elec_alg)
    else
        dead_echo_instances = Vector{Int64}()           
        for (i, echo_alg) in enumerate(elec_alg.echo_algorithms)
            if has_terminated(echo_alg)
                return _establish_winner!(elec_alg, echo_alg)
            elseif is_dead(echo_alg)
                push!(dead_echo_instances, i)
            else
                echo_algorithm_step!(echo_alg, elec_alg.strongest_id_callback)           
            end
        end
        deleteat!(elec_alg.echo_algorithms, dead_echo_instances)
        return elec_alg
    end
end

function _establish_winner!(elec_alg::ElectionAlgorithm, winner_echo_instance::EchoAlgorithm)
    elec_alg.winner.echo_algorithm_instance = winner_echo_instance
    elec_alg.winner.winner_process_id = elec_alg.process_ids[winner_echo_instance.initiator]
    empty!(elec_alg.echo_algorithms)
    return elec_alg
end

function _winner_step!(elec_alg::ElectionAlgorithm) # TODO implement last distribution of winner
    return elec_alg
end