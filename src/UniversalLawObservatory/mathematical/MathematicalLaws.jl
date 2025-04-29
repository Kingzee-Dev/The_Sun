module MathematicalLaws

using Statistics
using LinearAlgebra

# Import from parent module
using ..FractalArchitecture: analyze_fractal_properties
using ..ChaosTheory: analyze_attractor
using ..InformationTheory: analyze_information_flow

"""
    apply_mathematical_laws!(observatory, data)
Apply all mathematical laws to the given data
"""
function apply_mathematical_laws!(observatory, data::Dict{String, Any})
    result_state = Dict{String, Any}()
    observations = Dict{String, Any}()

    # Apply fractal laws with explicit error handling
    if haskey(data, "pattern")
        try
            result_state["fractal"] = analyze_fractal_properties(observatory.fractal_system, "main")
        catch e
            @warn "Error applying fractal laws" exception=e
            result_state["fractal"] = Dict{String,Any}()
        end
    end

    # Apply chaos theory laws
    if haskey(data, "trajectory")
        result_state["chaos"] = analyze_attractor(observatory.attractor_system, "main")
    end

    # Apply information theory laws
    if haskey(data, "signal")
        result_state["information"] = analyze_information_flow(observatory.information_system)
    end

    return (state=result_state, observations=observations)
end

# Register with law application engine
function register_mathematical_laws!(engine)
    register_law!(engine, "fractal_analysis", analyze_fractal_properties)
    register_law!(engine, "chaos_analysis", analyze_attractor)
    register_law!(engine, "information_analysis", analyze_information_flow)
end

export apply_mathematical_laws!, register_mathematical_laws!

end # module
