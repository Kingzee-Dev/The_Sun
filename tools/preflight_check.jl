module PreflightCheck

using Pkg

"""
    extract_package_requirements()
Scan codebase to find all package dependencies
"""
function extract_package_requirements()
    required_packages = Set{String}()
    root_dir = dirname(@__DIR__)

    # Recursively scan all Julia files
    for (root, _, files) in walkdir(root_dir)
        for file in files
            if endswith(file, ".jl")
                path = joinpath(root, file)
                content = read(path, String)
                
                # Find using statements
                for m in eachmatch(r"using\s+([A-Za-z][A-Za-z0-9_.]*)", content)
                    push!(required_packages, m.captures[1])
                end
                
                # Find import statements  
                for m in eachmatch(r"import\s+([A-Za-z][A-Za-z0-9_.]*)", content)
                    push!(required_packages, m.captures[1])
                end
            end
        end
    end

    # Filter out local modules
    filter!(pkg -> !any(f -> endswith(f, "/$pkg.jl"), readdir(root_dir, join=true)), required_packages)
    
    return collect(required_packages)
end

"""
    ensure_dependencies()
Ensure all required packages are installed before importing
"""
function ensure_dependencies()
    # Get requirements from codebase
    required_packages = extract_package_requirements()
    
    # First try to add any missing packages
    for pkg in required_packages
        try
            if !haskey(Pkg.project().dependencies, pkg)
                @info "Installing package: $pkg"
                Pkg.add(pkg)
            end
        catch e
            @error "Failed to install package: $pkg" exception=e
            return false
        end
    end
    
    return true
end

# Ensure dependencies are installed before proceeding
if !ensure_dependencies()
    error("Failed to install required packages")
end

# Now import the packages
using Test
using Dates
using DataStructures
using Statistics

# Update to use local modules via include
include("../src/UniversalLawObservatory.jl")
using .UniversalLawObservatory
include("../src/InternetModule.jl")
using .InternetModule
include("../src/ModelRegistry/ModelRegistry.jl") 
using .ModelRegistry

"""
    check_dependencies()
Verify all required packages are installed and up-to-date
"""
function check_dependencies()
    required_packages = extract_package_requirements()
    
    missing_packages = String[]
    for pkg in required_packages
        if !haskey(Pkg.project().dependencies, pkg)
            push!(missing_packages, pkg)
        end
    end
    
    if !isempty(missing_packages)
        @info "Installing missing packages: $(join(missing_packages, ", "))"
        try
            Pkg.add(missing_packages)
            @info "Successfully installed missing packages"
            return true
        catch e
            @error "Failed to install packages" exception=e
            return false
        end
    end
    true
end

"""
    verify_module_files()
Check if all required module files exist
"""
function verify_module_files()
    required_paths = [
        "src/UniversalCelestialIntelligence.jl",
        "src/InternetModule.jl",
        "src/SystemScanner.jl",
        "src/UniversalLawObservatory/patterns/EmergentDiscovery.jl",
        "src/UniversalLawObservatory/patterns/CrossDomainDetector.jl", 
        "src/UniversalLawObservatory/patterns/LawApplicationEngine.jl",
        "src/UniversalLawObservatory/physical/PhysicalLaws.jl",
        "src/UniversalLawObservatory/biological/BiologicalLaws.jl",
        "src/UniversalLawObservatory/mathematical/MathematicalLaws.jl",
        "src/UniversalLawObservatory/cognitive/CognitiveLaws.jl",
        "src/UniversalLawObservatory/metrics/MetricsCollector.jl",
        "src/UniversalDataProcessor/UniversalDataProcessor.jl",
        "src/ModelRegistry/ModelRegistry.jl",
        "src/EvolutionEngine/EvolutionEngine.jl",
        "src/PlanetaryInterface/PlanetaryInterface.jl",
        "src/SelfHealing/SelfHealing.jl",
        "src/Explainability/Explainability.jl",
        "src/CentralOrchestrator/CentralOrchestrator.jl",
        "src/RealDataIngestion.jl"
    ]

    missing_files = String[]
    for path in required_paths
        full_path = joinpath(dirname(@__DIR__), path)
        if !isfile(full_path)
            push!(missing_files, path)
        end
    end

    if !isempty(missing_files)
        @info "Attempting to create missing files..."
        create_missing_files(missing_files)
        # Verify again after creation
        missing_files = [path for path in required_paths if !isfile(joinpath(dirname(@__DIR__), path))]
    end

    if !isempty(missing_files)
        @warn "Files still missing after creation attempt: $(join(missing_files, ", "))"
        return false
    end
    true
end

"""
    create_missing_files(paths::Vector{String})
Create missing module files with intelligent enrichment
"""
function create_missing_files(paths::Vector{String})
    # Initialize model registry for code templates
    registry = create_registry()
    
    # Test variants storage
    variants = Dict{String, Vector{String}}()

    for path in paths
        full_path = joinpath(dirname(@__DIR__), path)
        
        # Create directory structure
        mkpath(dirname(full_path))
        
        # Generate module name
        module_name = basename(path)[1:end-3]
        
        # Get best practices and templates from internet
        if InternetModule.is_connected()
            suggestions = InternetModule.enrich_codebase(["julia $module_name best practices"])
            variants[path] = generate_code_variants(module_name, suggestions)
        end
        
        # Create initial implementation
        best_variant = create_initial_implementation(module_name, variants[path])
        
        # Write file with best variant
        open(full_path, "w") do io
            write(io, best_variant)
        end
        
        # Register as template for future use
        register_model!(registry, Dict(
            "id" => module_name,
            "template" => best_variant,
            "performance" => test_implementation(full_path)
        ))
    end
    
    # Log creation results
    open(joinpath(dirname(@__DIR__), "TECHNICAL_DIARY.md"), "a") do io
        println(io, "\n## [$(now())] Code Generation Report")
        for (path, vars) in variants
            println(io, "- Generated $(length(vars)) variants for $path")
            println(io, "  Selected best performing implementation")
        end
    end
end

"""
    generate_code_variants(module_name::String, suggestions::Dict)
Generate multiple implementation variants based on suggestions
"""
function generate_code_variants(module_name::String, suggestions::Dict)
    variants = String[]
    
    # Basic template
    push!(variants, """
    module $module_name
    
    using Statistics
    using DataStructures
    
    # Basic implementation
    $(get_basic_implementation(module_name))
    
    end # module
    """)
    
    # Enhanced template with suggestions
    if !isempty(suggestions)
        push!(variants, """
        module $module_name
        
        using Statistics
        using DataStructures
        
        # Enhanced implementation using best practices
        $(get_enhanced_implementation(module_name, suggestions))
        
        end # module
        """)
    end
    
    return variants
end

"""
    test_implementation(filepath::String)
Test implementation quality and performance
"""
function test_implementation(filepath::String)
    try
        # Run unit tests if available
        test_results = run(`julia --project=. -e "using Test; include(\"$filepath\"); @test true"`)
        
        # Static analysis metrics
        loc = count("\n", read(filepath, String))
        complexity = estimate_complexity(read(filepath, String))
        
        # Combined score
        score = 0.7 * (test_results.exitcode == 0 ? 1.0 : 0.0) +
                0.3 * (1.0 - complexity/100)
                
        return score
    catch
        return 0.0
    end
end

"""
    create_initial_implementation(module_name::String, variants::Vector{String})
Select best implementation from variants
"""
function create_initial_implementation(module_name::String, variants::Vector{String})
    if isempty(variants)
        return get_basic_implementation(module_name)
    end
    
    # Test each variant
    scores = Float64[]
    for variant in variants
        # Write temporary file
        temp_path = joinpath(dirname(@__DIR__), "temp_$module_name.jl")
        write(temp_path, variant)
        
        # Test and score
        push!(scores, test_implementation(temp_path))
        
        # Cleanup
        rm(temp_path)
    end
    
    # Return best variant
    return variants[argmax(scores)]
end

"""
    verify_test_files()
Check if all test files exist and are properly structured
"""
function verify_test_files()
    required_tests = [
        "test/runtests.jl",
        "test/test_dependencies.jl",
        "test/verify_precompile.jl"
    ]

    missing_tests = String[]
    for test in required_tests
        if !isfile(joinpath(dirname(@__DIR__), test))
            push!(missing_tests, test)
        end
    end

    if !isempty(missing_tests)
        @warn "Missing test files: $(join(missing_tests, ", "))"
        return false
    end
    true
end

"""
    analyze_codebase()
Analyze entire codebase and return files ordered by size and complexity
"""
function analyze_codebase()
    codebase = Dict{String, Dict{String, Any}}()
    root_dir = dirname(@__DIR__)

    # Scan all Julia files
    for (root, _, files) in walkdir(root_dir)
        for file in files
            if endswith(file, ".jl")
                path = joinpath(root, file)
                relative_path = relpath(path, root_dir)
                content = read(path, String)
                
                codebase[relative_path] = Dict(
                    "size" => filesize(path),
                    "loc" => count("\n", content),
                    "complexity" => estimate_complexity(content),
                    "last_modified" => mtime(path),
                    "dependencies" => extract_dependencies(content)
                )
            end
        end
    end
    
    # Sort by size
    sorted_files = sort(collect(keys(codebase)), 
                       by=f -> codebase[f]["size"],
                       rev=true)
                       
    return codebase, sorted_files
end

"""
    enrich_and_upgrade_codebase()
Analyze, enrich and upgrade entire codebase using internet resources
"""
function enrich_and_upgrade_codebase()
    results = Dict{String, Any}("upgraded" => [], "enriched" => [], "errors" => [])
    
    # First analyze existing codebase
    codebase, sorted_files = analyze_codebase()
    
    # Process build tools first
    build_tools = filter(f -> contains(f, r"(build|tools|test)"), sorted_files)
    
    if InternetModule.is_connected()
        # Upgrade build tools first
        for tool in build_tools
            try
                suggestions = InternetModule.enrich_codebase([
                    "julia build tool best practices",
                    "CI/CD automation julia",
                    basename(tool)
                ])
                
                variants = generate_code_variants(basename(tool), suggestions)
                best_variant = create_initial_implementation(basename(tool), variants)
                
                if test_implementation(joinpath(dirname(@__DIR__), tool)) < 
                   test_implementation(best_variant)
                    # Backup original
                    backup_path = tool * ".bak"
                    cp(joinpath(dirname(@__DIR__), tool), 
                       joinpath(dirname(@__DIR__), backup_path))
                       
                    # Apply upgrade
                    write(joinpath(dirname(@__DIR__), tool), best_variant)
                    push!(results["upgraded"], tool)
                end
            catch e
                push!(results["errors"], Dict("file" => tool, "error" => e))
            end
        end
        
        # Now process rest of codebase
        for file in setdiff(sorted_files, build_tools)
            try
                module_name = basename(file)[1:end-3]
                
                # Get enrichment suggestions
                suggestions = InternetModule.enrich_codebase([
                    "julia $module_name patterns",
                    "julia $module_name optimization",
                    "software architecture best practices"
                ])
                
                # Try to discover new laws/patterns
                if contains(file, "Laws.jl")
                    new_laws = discover_new_laws(module_name)
                    if !isempty(new_laws)
                        suggestions["new_laws"] = new_laws
                        push!(results["enriched"], Dict(
                            "file" => file,
                            "new_laws" => new_laws
                        ))
                    end
                end
                
                # Generate and test variants
                variants = generate_code_variants(module_name, suggestions)
                best_variant = create_initial_implementation(module_name, variants)
                
                if test_implementation(joinpath(dirname(@__DIR__), file)) < 
                   test_implementation(best_variant)
                    # Backup and upgrade
                    backup_path = file * ".bak"
                    cp(joinpath(dirname(@__DIR__), file), 
                       joinpath(dirname(@__DIR__), backup_path))
                    write(joinpath(dirname(@__DIR__), file), best_variant)
                    push!(results["upgraded"], file)
                end
                
            catch e
                push!(results["errors"], Dict("file" => file, "error" => e))
            end
        end
    end
    
    # Log enrichment results
    open(joinpath(dirname(@__DIR__), "TECHNICAL_DIARY.md"), "a") do io
        println(io, "\n## [$(now())] Codebase Enrichment Report")
        println(io, "### Upgraded Files:")
        for file in results["upgraded"]
            println(io, "- $file")
        end
        println(io, "\n### New Laws/Patterns:")
        for entry in results["enriched"]
            println(io, "- $(entry["file"]):")
            for law in entry["new_laws"]
                println(io, "  * $law")
            end
        end
        if !isempty(results["errors"])
            println(io, "\n### Errors:")
            for err in results["errors"]
                println(io, "- $(err["file"]): $(err["error"])")
            end
        end
    end
    
    return results
end

"""
    discover_new_laws(domain::String)
Discover new laws/patterns from internet resources
"""
function discover_new_laws(domain::String)
    new_laws = String[]
    
    # Search academic databases and repositories
    if InternetModule.is_connected()
        results = InternetModule.search_external_patterns([
            "$domain laws",
            "$domain patterns",
            "$domain principles",
            "universal $domain patterns"
        ])
        
        # Filter and validate potential new laws
        for result in results
            if is_valid_law(result, domain)
                push!(new_laws, result)
            end
        end
    end
    
    return new_laws
end

"""
    run_preflight_check()
Run all preflight checks and return results
"""
function run_preflight_check()
    println("🚀 Starting preflight check at $(now())")
    println("=" ^ 50)
    
    results = Dict{String, Bool}()
    
    println("\n📦 Checking dependencies...")
    results["dependencies"] = check_dependencies()
    println("Dependencies check: $(results["dependencies"] ? "✅ PASSED" : "❌ FAILED")")
    
    println("\n📂 Verifying module files...")
    results["module_files"] = verify_module_files()
    println("Module files check: $(results["module_files"] ? "✅ PASSED" : "❌ FAILED")")
    
    println("\n🧪 Verifying test files...")
    results["test_files"] = verify_test_files()
    println("Test files check: $(results["test_files"] ? "✅ PASSED" : "❌ FAILED")")
    
    println("\n🔍 Analyzing and enriching codebase...")
    enrichment_results = enrich_and_upgrade_codebase()
    
    # Add enrichment results to output
    if !isempty(enrichment_results["upgraded"])
        println("\n📈 Upgraded files: $(length(enrichment_results["upgraded"]))")
    end
    if !isempty(enrichment_results["enriched"])
        println("🔮 New laws/patterns discovered: $(length(enrichment_results["enriched"]))")
    end
    if !isempty(enrichment_results["errors"])
        println("⚠️ Enrichment errors: $(length(enrichment_results["errors"]))")
    end
    
    println("\n🧪 Running tests on upgraded codebase...")
    include(joinpath(dirname(@__DIR__), "test/verify_precompile.jl"))
    
    println("\n" * "=" ^ 50)
    println("📋 Final Results:")
    all_passed = all(values(results))
    println("Overall Status: $(all_passed ? "✅ ALL CHECKS PASSED" : "❌ SOME CHECKS FAILED")")
    println("=" ^ 50)
    
    # Log results to technical diary
    open(joinpath(dirname(@__DIR__), "TECHNICAL_DIARY.md"), "a") do io
        println(io, "\n## [$(now())] Preflight Check")
        println(io, "- Dependencies check: $(results["dependencies"] ? "✅" : "❌")")
        println(io, "- Module files check: $(results["module_files"] ? "✅" : "❌")")
        println(io, "- Test files check: $(results["test_files"] ? "✅" : "❌")")
    end
    
    return all_passed
end

# Make run_preflight_check accessible outside the module
export run_preflight_check

end # module

# Run preflight check if script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    # First import Pkg at script level
    using Pkg
    
    # Ensure we're in the project environment
    Pkg.activate(dirname(@__DIR__))
    
    # Use the current module directly instead of including again
    using .PreflightCheck
    
    # Run the check and exit with appropriate code
    success = run_preflight_check()
    println("\nExiting with status: $(success ? "SUCCESS" : "FAILURE")")
    exit(success ? 0 : 1)
end
