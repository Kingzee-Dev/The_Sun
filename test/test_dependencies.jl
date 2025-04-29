using Test
using UniversalCelestialIntelligence
using UniversalLawObservatory

@testset "Dependency Tests" begin
    @test isdefined(UniversalCelestialIntelligence, :apply_physical_laws!)
    @test isdefined(UniversalLawObservatory, :apply_physical_laws!)
    @test hasmethod(apply_physical_laws!, Tuple{UniversalLawObservatory.LawObservatory, Dict{String, Any}})
end
