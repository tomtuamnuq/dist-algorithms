include("networks/Network-Visualization.jl")
include("LiftAlgorithm.jl")

function lift_visualization!(fgp::FixedGraphPlot, lift_alg::LiftAlgorithm)
    _lift_nodecolors!(fgp, lift_alg)
    _lift_edges_visualization!(fgp, lift_alg)
    return fgp
end


function _lift_nodecolors!(fgp::FixedGraphPlot, lift_alg::LiftAlgorithm)
    map!(s -> isempty(s) ? colorant"white" : colorant"snow4", fgp.nodecolors, lift_alg.request_sets)
    for inq_node ∈ lift_alg.inquirer
        fgp.nodecolors[inq_node] = colorant"navajowhite"
    end
    token_pos = lift_alg.token.pos
    if token_pos != 0
        fgp.nodecolors[token_pos] = colorant"crimson"
    end
    return fgp
end


function _lift_edges_visualization!(fgp::FixedGraphPlot, lift_alg::LiftAlgorithm)
    fill!(fgp.edgecolors, colorant"green")
    fill!(fgp.edgelabels, ' ')

    for letter in all_letters(lift_alg.nw)
        edge = fgp.edgeindices[letter.e]
        if letter.m == token
            fgp.edgelabels[edge] = 'T'
            fgp.edgecolors[edge] = colorant"crimson"
        else
            fgp.edgelabels[edge] = 'R'
        end
    end
    return fgp
end
