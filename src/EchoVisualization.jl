include("networks/Network-Visualization.jl")
include("EchoAlgorithm.jl")

const colorstate_map = Base.ImmutableDict(white => colorant"white", red => colorant"red", green => colorant"green")
const colorstate_map_sender = Base.ImmutableDict(white => colorant"honeydew", red => colorant"lightcoral", green => colorant"mediumspringgreen")
const colorstate_map_recipient = Base.ImmutableDict(white => colorant"snow4", red => colorant"darkred", green => colorant"darkgreen")
const colorstate_map_initiator = Base.ImmutableDict(white => colorant"navajowhite", red => colorant"crimson", green => colorant"yellowgreen")
const EXTRA_COLORSTATE_MAPS = [colorstate_map_sender colorstate_map_recipient colorstate_map_initiator]

function echo_visualization!(fgp::FixedGraphPlot, echo_alg::EchoAlgorithm)
    _echo_nodecolors!(fgp, echo_alg)
    _echo_edges_visualization!(fgp, echo_alg)
    return fgp
end


function _echo_nodecolors!(fgp::FixedGraphPlot, echo_alg::EchoAlgorithm)
    map!(c -> colorstate_map[c], fgp.nodecolors, echo_alg.colors)
    if has_letters(echo_alg.nw)
        letter = next_letter(echo_alg.nw)
        sender, recipient = src(letter.e), dst(letter.e)
        for (v, cm) in zip([sender recipient echo_alg.initiator], EXTRA_COLORSTATE_MAPS)
            fgp.nodecolors[v] = cm[echo_alg.colors[v]]
        end
    end
    return fgp
end


function _echo_edges_visualization!(fgp::FixedGraphPlot, echo_alg::EchoAlgorithm)
    fill!(fgp.edgecolors, colorant"purple")
    fill!(fgp.edgelabels, ' ')
    for (v, w) in enumerate(echo_alg.activation_edges)
        if w > 0
            fgp.edgecolors[fgp.edgeindices[Edge(v, w)]] = colorant"green"
        end
    end

    for letter in all_letters(echo_alg.nw)
        fgp.edgelabels[fgp.edgeindices[letter.e]] = letter.m == explorer ? 'M' : 'R'
    end
    return fgp
end
