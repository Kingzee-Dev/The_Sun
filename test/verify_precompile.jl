# Add parent directory to load path
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using UniversalCelestialIntelligence
using Test
# Add package imports to verify
using CSV, CUDA, DataFrames, DataStructures, DifferentialEquations
using Distributions, Graphs, HTTP, JSON3, LinearAlgebra
using SHA, Statistics, StatsBase

function test_precompilation()
    # Verify critical packages
    @testset "Package Loading" begin
        @test isdefined(@__MODULE__, :CSV)
        @test isdefined(@__MODULE__, :CUDA)
        @test isdefined(@__MODULE__, :DataFrames)
        @test isdefined(@__MODULE__, :HTTP)
        @test isdefined(@__MODULE__, :JSON3)
    end

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

    # Verify package functionality
    @testset "Package Functionality" begin
        # Test DataFrames
        @test DataFrame(A=1:3, B=4:6) isa DataFrame
        # Test JSON3
        @test JSON3.read("{\"test\": 123}") isa JSON3.Object
        # Test HTTP (async to avoid blocking)
        response = fetch(@async HTTP.get("http://example.com"))
        @test response.status == 200
    end

    println("✅ All packages successfully loaded and tested")
    println("✅ Precompilation verification passed")
    println("🔍 System components verified")
    println("💻 Hardware information captured")
    return true
end

if abspath(PROGRAM_FILE) == @__FILE__
    test_precompilation()
end
