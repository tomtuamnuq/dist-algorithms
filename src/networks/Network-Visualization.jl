using Compose, Plots, Printf
import Cairo, Fontconfig
using Graphs: AbstractGraph, Edge
using GraphPlot: spring_layout, gplot
using Colors: Colorant, FixedPointNumbers, RGB

struct FixedGraphPlot{T<:Integer}
    # fixed graph plot to change colors and edgelables
    graph::AbstractGraph{T}
    locs_x::Vector{Float64}
    locs_y::Vector{Float64}
    NODESIZE::Float64
    nodelabels::Union{Vector{T},Vector{String}}
    nodecolors::Vector{RGB{FixedPointNumbers.N0f8}}
    edgeindices::Dict{Edge,T} # not compatbile with flip_edge! - call reset_edgeindices after an edge has changed
    edgelabels::Vector{Char}
    edgecolors::Vector{RGB{FixedPointNumbers.N0f8}}

    function FixedGraphPlot{T}(graph::AbstractGraph{T}; layout = spring_layout(graph), NODESIZE = 0.25 / sqrt(nv(graph)), nodelabels = 1:nv(graph)) where {T<:Integer}
        locs_x, locs_y = layout
        nodelabels = collect(nodelabels)
        nodecolors = fill(colorant"white", nv(graph))
        edgeindices = Dict{Edge,T}()
        for (i, e) in enumerate(edges(graph))
            edgeindices[e] = i
            edgeindices[reverse(e)] = i
        end
        edgelabels = fill(' ', ne(graph))
        edgecolors = fill(colorant"purple", ne(graph))
        new(graph, locs_x, locs_y, NODESIZE, nodelabels, nodecolors, edgeindices, edgelabels, edgecolors)
    end
end

function reset_edgeindices!(fgp::FixedGraphPlot, clear = false)
    if clear
        empty!(fgp.edgeindices)
    end
    for (i, e) in enumerate(edges(fgp.graph))
        fgp.edgeindices[e] = i
        fgp.edgeindices[reverse(e)] = i
    end
    return fgp
end


function frame(anim::Animation, gp::Context, width = 20cm, height = 12cm; dpi = 96)
    i = length(anim.frames) + 1
    filename = @sprintf("%06d.png", i)
    draw(PNG(joinpath(anim.dir, filename), width, height, dpi = dpi), gp)
    push!(anim.frames, filename)
end

function graph_context(fgp::FixedGraphPlot)
    return gplot(fgp.graph, fgp.locs_x, fgp.locs_y, NODESIZE = fgp.NODESIZE, nodelabel = fgp.nodelabels, nodefillc = fgp.nodecolors, edgelabel = fgp.edgelabels, edgestrokec = fgp.edgecolors)
end