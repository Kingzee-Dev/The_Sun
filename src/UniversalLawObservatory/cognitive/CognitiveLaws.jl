module CognitiveLaws

using DataStructures
using Statistics

"""
    AttentionState
Represents the current focus of the system.
"""
mutable struct AttentionState
    focus_keys::Vector{String}
    intensity::Dict{String, Float64}
end

"""
    MemoryStore
Stores episodic and semantic memories.
"""
mutable struct MemoryStore
    episodic::Vector{Dict{String, Any}}
    semantic::Dict{String, Any}
end

"""
    InsightEvent
Represents a creative or insightful event.
"""
struct InsightEvent
    description::String
    context::Dict{String, Any}
    timestamp::Float64
end

"""
    SelfModel
Tracks self-awareness and internal state.
"""
mutable struct SelfModel
    identity::String
    state::Dict{String, Any}
    awareness_level::Float64
end

# Attention mechanism: prioritize keys with highest intensity
function update_attention!(attn::AttentionState, inputs::Dict{String, Any})
    for k in keys(inputs)
        attn.intensity[k] = get(attn.intensity, k, 0.0) + rand() * 0.5
    end
    attn.focus_keys = sort(collect(keys(attn.intensity)), by=k->-attn.intensity[k])
end

# Memory formation: store new episode, update semantic memory
function store_memory!(mem::MemoryStore, episode::Dict{String, Any})
    push!(mem.episodic, episode)
    for (k, v) in episode
        mem.semantic[k] = v
    end
end

# Memory recall: retrieve most recent or matching episode
function recall_memory(mem::MemoryStore, query::Dict{String, Any})
    for ep in reverse(mem.episodic)
        if all(get(ep, k, nothing) == v for (k, v) in query)
            return ep
        end
    end
    return nothing
end

# Insight: combine unrelated memories for creative output
function generate_insight(mem::MemoryStore)
    if length(mem.episodic) < 2
        return nothing
    end
    idxs = rand(1:length(mem.episodic), 2)
    ep1, ep2 = mem.episodic[idxs[1]], mem.episodic[idxs[2]]
    combined = merge(ep1, ep2)
    return InsightEvent("Combined memory insight", combined, time())
end

# Self-awareness: update self-model based on internal state
function update_self_awareness!(self::SelfModel, new_state::Dict{String, Any})
    self.state = merge(self.state, new_state)
    self.awareness_level = min(1.0, self.awareness_level + 0.01 * length(new_state))
end

export AttentionState, MemoryStore, InsightEvent, SelfModel,
       update_attention!, store_memory!, recall_memory, generate_insight, update_self_awareness!

end # module
