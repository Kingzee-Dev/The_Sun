module UniversalLawObservatory

using LinearAlgebra
using Distributions
using DifferentialEquations
using DataStructures
using Statistics
using Graphs

# Abstract types for pattern interfaces
abstract type UniversalPattern end
abstract type PhysicalLaw <: UniversalPattern end
abstract type BiologicalLaw <: UniversalPattern end
abstract type MathematicalLaw <: UniversalPattern end

# Basic implementations for abstract types
struct BasicPhysicalLaw <: PhysicalLaw end
struct BasicBiologicalLaw <: BiologicalLaw end
struct BasicMathematicalLaw <: MathematicalLaw end

# Constructor functions
PhysicalLaw() = BasicPhysicalLaw()
BiologicalLaw() = BasicBiologicalLaw()
MathematicalLaw() = BasicMathematicalLaw()

# Include all sub-modules organized by domain
include("UniversalLawObservatory/patterns/EmergentDiscovery.jl")
include("UniversalLawObservatory/patterns/CrossDomainDetector.jl")
include("UniversalLawObservatory/patterns/LawApplicationEngine.jl")

include("UniversalLawObservatory/physical/GravitationalAllocation.jl")
include("UniversalLawObservatory/physical/ThermodynamicEfficiency.jl") 
include("UniversalLawObservatory/physical/QuantumProbability.jl")
include("UniversalLawObservatory/physical/PhysicalLaws.jl")

include("UniversalLawObservatory/biological/EvolutionaryPatterns.jl")
include("UniversalLawObservatory/biological/HomeostasisControl.jl")
include("UniversalLawObservatory/biological/SymbioticSystems.jl")
include("UniversalLawObservatory/biological/BiologicalLaws.jl")

include("UniversalLawObservatory/mathematical/FractalArchitecture.jl")  
include("UniversalLawObservatory/mathematical/ChaosTheory.jl")
include("UniversalLawObservatory/mathematical/InformationTheory.jl")
include("UniversalLawObservatory/mathematical/MathematicalLaws.jl")

include("UniversalLawObservatory/cognitive/CognitiveLaws.jl")
include("UniversalLawObservatory/metrics/MetricsCollector.jl")

# Re-export core functionality
export UniversalPattern, PhysicalLaw, BiologicalLaw, MathematicalLaw
export detect_patterns, apply_law, discover_emergent_laws
export validate_pattern, measure_law_effectiveness
export MetricsCollector, create_metrics_collector, record_metric!
export LawEngine, create_law_engine
export apply_physical_laws!, apply_biological_laws!, apply_mathematical_laws!

end # module
