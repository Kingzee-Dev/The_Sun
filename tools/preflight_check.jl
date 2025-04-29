module PreflightCheck

using Pkg
include("DependencyManager.jl")
using .DependencyManager

"""
    run_checks()
Run all preflight checks
"""
function run_checks()
    println("Running preflight checks...")
    
    try
        # Create channel for completion signal
        done = Channel{Bool}(1)
        
        # Start dependency resolution in task
        task = @async begin
            try
                result = DependencyManager.resolve()
                put!(done, result)
            catch e
                @error "Dependency resolution failed" exception=e
                put!(done, false)
            end
        end
        
        # Wait with progressive timeouts
        for timeout in [120, 180, 300]  # 2min, 3min, 5min
            completed = timedwait(timeout) do
                isready(done)
            end
            
            if completed != :timed_out
                break
            end
            
            println("\n⚠️ Taking longer than expected, but still working...")
            println("   (Timeout will increase to $timeout seconds)")
        end
        
        if !isready(done)
            error("Dependency resolution timed out")
        end
        
        success = take!(done)
        if !success
            error("Dependency resolution failed")
        end
        
        println("\n✅ All checks passed")
        return true
        
    catch e
        if e isa InterruptException
            println("\n❌ Dependency resolution interrupted")
        else
            @error "Check failed" exception=e
        end
        return false
    finally
        GC.gc() # Final cleanup
    end
end

# Run checks when called directly
if abspath(PROGRAM_FILE) == @__FILE__
    if !run_checks()
        exit(1)
    end
    @info "Preflight check completed successfully"
end

end # module
