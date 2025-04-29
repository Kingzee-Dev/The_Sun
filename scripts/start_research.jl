using Pkg

# Activate and resolve project environment
Pkg.activate(dirname(dirname(@__FILE__)))
Pkg.resolve()
Pkg.instantiate()

# Add ScientificResearcher to load path rather than developing it
push!(LOAD_PATH, joinpath(dirname(dirname(@__FILE__)), "src"))

using ScientificResearcher
using UniversalCelestialIntelligence
using UniversalLawObservatory
using JSON3

function main()
    println("🔬 Starting Scientific Research Session...")
    
    try
        # Create new research session
        session = ResearchSession()
        
        # Create and initialize real system
        println("📦 Creating celestial system...")
        system = create_celestial_system()
        
        println("🚀 Initializing system...")
        init_result = initialize!(system)
        
        if !init_result[:success]
            error("System initialization failed: $(init_result[:error])")
        end
        
        # Load universal laws configuration
        println("📚 Loading universal laws configuration...")
        laws_config_path = joinpath(dirname(dirname(@__FILE__)), "config", "universal_human_laws.json")
        laws_config = JSON3.read(read(laws_config_path, String))

        # Initialize law observatory with known laws
        println("📚 Initializing law observatory with known laws...")
        system.law_observatory = UniversalLawObservatory.create_law_engine()
        
        # Register laws from configuration
        for (domain, laws) in laws_config["laws"]
            for (category, category_laws) in laws
                for (law_name, law_info) in category_laws
                    law_id = "$(domain)_$(category)_$(law_name)"
                    println("  └─ Registering known law: $law_id")
                    register_law!(system.law_observatory, law_id)
                end
            end
        end
        
        println("\n📋 Starting research cycle...")
        println("📂 Research directory: $(session.research_dir)")
        
        # Run the research cycle with law file generation
        session = run_research_cycle!(system, session, laws_config)
        
        println("\n✅ Research session completed!")
        println("📊 Results:")
        for domain in ScientificResearcher.DOMAINS
            n_laws = length(get(session.discovered_laws, domain, []))
            println("   - $(uppercase(domain)): $(n_laws) new laws discovered")
        end
        println("\n📝 Full report saved in: $(joinpath(session.research_dir, "research_review.md"))")
        
    catch e
        println("\n❌ Error during research session:")
        println(e)
        return 1
    end
    
    return 0
end

# Run the script if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
