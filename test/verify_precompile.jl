using UniversalCelestialIntelligence
using Test

function test_precompilation()
    # Create a simple test system
    system = create_celestial_system()
    
    # Verify system initialization
    @assert system !== nothing "System creation failed"
    
    # Test basic functionality
    result = initialize!(system)
    @assert result.success "System initialization failed"
    
    # Verify all major components
    @assert isdefined(system, :law_observatory) "Law observatory missing"
    @assert isdefined(system, :orchestrator) "Orchestrator missing"
    @assert isdefined(system, :data_processor) "Data processor missing"
    @assert isdefined(system, :model_registry) "Model registry missing"
    @assert isdefined(system, :evolution_engine) "Evolution engine missing"
    @assert isdefined(system, :planetary_interface) "Planetary interface missing"
    @assert isdefined(system, :self_healing) "Self-healing system missing"
    @assert isdefined(system, :explainability) "Explainability system missing"
    
    # Verify hardware scanning
    @assert haskey(system.hardware, "cpu") "CPU info missing"
    @assert haskey(system.hardware, "gpus") "GPU info missing"
    @assert haskey(system.hardware, "memory_gb") "Memory info missing"
    
    println("✅ Precompilation verification passed")
    println("🔍 System components verified")
    println("💻 Hardware information captured")
    return true
end

if abspath(PROGRAM_FILE) == @__FILE__
    test_precompilation()
end
