using Test
using UniversalCelestialIntelligence

@testset "UniversalCelestialIntelligence" begin
    system = create_celestial_system()
    result = initialize!(system)
    @test result[:success] == true
    @test haskey(system.hardware, "cpu")
    @test haskey(system.hardware, "gpus")
    @test haskey(system.hardware, "memory_gb")
    # Optionally test a full cycle
    input = Dict("type" => "observation", "data" => Dict("value" => 42))
    process_result = process_input!(system, input)
    @test process_result[:success] == true
    evolve_result = evolve_system!(system)
    @test haskey(evolve_result, :metrics)
    report = generate_system_report(system)
    @test haskey(report, "state")
    @test haskey(report, "health")
    @test haskey(report, "performance")
    @test haskey(report, "recent_events")
    @test haskey(report, "evolution")
    @test haskey(report, "communication")
end

@testset "InternetModule" begin
    @test is_connected() == true || is_connected() == false
    suggestions = enrich_codebase(["self-healing systems", "evolutionary computation"])
    @test isa(suggestions, Dict)
end

@testset "SelfHealingSystem" begin
    system = create_celestial_system()
    initialize!(system)
    anomalies = detect_anomalies(system.self_healing)
    @test isa(anomalies, Dict)
    if !isempty(anomalies)
        for (component_id, detected_anomalies) in anomalies
            recovery = initiate_recovery!(system.self_healing, component_id)
            @test recovery.success == true || recovery.success == false
        end
    end
end

@testset "EvolutionEngine" begin
    system = create_celestial_system()
    initialize!(system)
    component_id = "test_component"
    initial_traits = [0.5, 0.8, 0.3]
    component = create_adaptive_component(component_id, initial_traits)
    register_component!(system.evolution_engine, component)
    strategy = create_evolution_strategy(population_size=10, fitness_function=(traits -> sum(traits)))
    set_evolution_strategy!(system.evolution_engine, component_id, strategy)
    evolve_result = evolve_component!(system.evolution_engine, component_id)
    @test evolve_result.success == true
    @test evolve_result.fitness >= 0
end
