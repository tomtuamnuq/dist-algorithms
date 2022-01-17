using Graphs
using DataStructures: Queue, enqueue!, dequeue!, iterate
include("Util.jl")

@enum MESSAGE begin
    explorer
    confirmation
    echo
    request
    token
end

abstract type MessageContent end
abstract type StopContent <: MessageContent end

struct Letter{T<:Integer,S<:MessageContent}
    e::Edge{T}
    m::MESSAGE
    content::S
end

struct Network{T<:Integer}
    graph::AbstractGraph{T}
    messages::Queue{Letter}
    Network{T}(graph::AbstractGraph{T}) where {T<:Integer} = new(graph, Queue{Letter}())
end

add_letter!(nw::Network, l::Letter) = enqueue!(nw.messages, l)
pop_letter!(nw::Network) = dequeue!(nw.messages)
next_letter(nw::Network) = first(nw.messages)
all_letters(nw::Network) = nw.messages
has_letters(nw::Network) = !isempty(nw.messages)

send!(nw::Network{T}, src::T, dst::T, m::MESSAGE, c::S) where {T<:Integer,S<:MessageContent} = add_letter!(nw, Letter(Edge(src, dst), m, c))
send!(nw::Network{T}, src::T, dsts::AbstractArray{T}, m::MESSAGE, c::S) where {T<:Integer,S<:MessageContent} = foreach(dst -> send!(nw, src, dst, m, c), dsts)

