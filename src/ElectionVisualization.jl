include("networks/Network-Visualization.jl")
include("ElectionAlgorithm.jl")

function election_visualization!(fgp::FixedGraphPlot{T}, elec_alg::ElectionAlgorithm{T}, process_id_label_map::Dict{T,String}) where {T <: Integer}
    _election_nodecolors!(fgp, elec_alg, process_id_label_map)
    if has_winner(elec_alg)
        _winner_visualization!(fgp, elec_alg.winner.echo_algorithm_instance)
    end
    return fgp
end


function _election_nodecolors!(fgp::FixedGraphPlot{T}, elec_alg::ElectionAlgorithm{T}, process_id_label_map::Dict{T,String}) where {T <: Integer}
    fill!(fgp.nodecolors, colorant"white")
    active_initiator_nodes = Set(echo_alg.initiator for echo_alg ∈ elec_alg.echo_algorithms)
    for initiator_node ∈ values(elec_alg.initiator_id_nodes_map)
        fgp.nodecolors[initiator_node] = initiator_node ∈ active_initiator_nodes ?  colorant"red" : colorant"blue"
    end
    for (i, process_id) ∈ enumerate(elec_alg.process_ids)
        strongest_id = elec_alg.strongest_ids[i]
        strongest_label = strongest_id == 0 ? "" : process_id_label_map[strongest_id]
        fgp.nodelabels[i] = "$(process_id_label_map[process_id]) $strongest_label" 
    end
    return fgp
end


function _winner_visualization!(fgp::FixedGraphPlot, echo_alg::EchoAlgorithm)
    fgp.nodecolors[echo_alg.initiator] = colorant"green"
    for (i, j) in enumerate(echo_alg.activation_edges)
        if j != 0
            edge_index = fgp.edgeindices[Edge(i, j)]
            fgp.edgecolors[edge_index] = colorant"green"
        end
    end
    return fgp
end
