module Explainability

using Statistics
using DataStructures
using Graphs
using StatsBase

using ..InformationTheory
using ..CrossDomainDetector
using ..EmergentDiscovery

struct CrossDomainPattern
    id::String
    domains::Vector{String}
    characteristics::Dict{String, Any}
    confidence::Float64
    support::Dict{String, Float64}
end

struct ExplanationContext
    timestamp::Float64
    domain::Symbol
    state_before::Dict{String, Any}
    state_after::Dict{String, Any}
    active_patterns::Vector{CrossDomainPattern}
    causal_chain::Vector{String}
end

struct Explanation
    id::String
    context::ExplanationContext
    description::String
    confidence::Float64
    evidence::Vector{Dict{String, Any}}
    alternative_explanations::Vector{String}
    abstraction_level::Int
end

struct ExplanationModel
    pattern_detectors::Vector{Function}
    causal_analyzers::Vector{Function}
    confidence_estimators::Vector{Function}
    abstraction_rules::Vector{Function}
    validation_checks::Vector{Function}
end

mutable struct ExplainabilitySystem
    explanation_history::CircularBuffer{Explanation}
    active_models::Dict{Symbol, ExplanationModel}
    pattern_registry::Dict{String, CrossDomainPattern}
    confidence_thresholds::Dict{String, Float64}
    causal_graph::SimpleDiGraph
end

mutable struct ExplainabilityEngine
    patterns::Dict{String, CrossDomainPattern}
    evidence_history::CircularBuffer{Dict{String, Any}}
end

# Constructor functions
function create_explainability_system(history_size::Int=1000)
    ExplainabilitySystem(
        CircularBuffer{Explanation}(history_size),
        Dict{Symbol, ExplanationModel}(),
        Dict{String, CrossDomainPattern}(),
        Dict{String, Float64}(),
        SimpleDiGraph(0)
    )
end

# Export needed types and functions
export ExplainabilitySystem, Explanation, ExplanationModel, ExplanationContext,
       CrossDomainPattern, ExplainabilityEngine,
       create_explainability_system

end # module