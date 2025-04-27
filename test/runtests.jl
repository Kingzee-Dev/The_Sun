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
end
