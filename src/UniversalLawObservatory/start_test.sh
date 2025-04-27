#!/bin/bash

echo "🌟 Starting Universal Celestial Intelligence System..."

# Check internet connectivity and search integration
check_internet() {
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "✅ Internet connection: Connected"
        return 0
    else
        echo "❌ Internet connection: Disconnected"
        return 1
    fi
}

# Get system resource metrics
get_system_resources() {
    echo "💻 System Resources:"
    echo "   - CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% used"
    echo "   - Memory: $(free -m | awk '/Mem:/ {printf "%.1f%%", $3/$2*100}')"
    echo "   - Disk: $(df -h . | awk 'NR==2 {print $5}')"
}

# Get system metrics and patterns
get_system_metrics() {
    echo "📊 System Metrics:"
    echo "   - Files: $(find ../.. -type f -name "*.jl" | wc -l) Julia files"
    echo "   - Code size: $(find ../.. -type f -name "*.jl" -exec cat {} \; | wc -l) lines"
    echo "   - Components: $(ls ../../src | wc -l) major modules"
    echo ""
    get_system_resources
}

# Monitor system evolution and patterns
monitor_evolution() {
    local start_time=$SECONDS
    local iteration=0
    
    while true; do
        clear
        echo "🌞 The Sun - Universal Celestial Intelligence"
        echo "⏱️  Runtime: $((SECONDS - start_time)) seconds"
        echo "🔄 Iteration: $iteration"
        echo ""
        
        # Display current metrics
        get_system_metrics
        echo ""
        
        # Check internet connectivity
        check_internet
        echo ""
        
        # Start Julia REPL with enhanced monitoring
        if [[ ! -f ".evolution_running" ]]; then
            touch .evolution_running
            julia --project=../.. -e '
                using UniversalCelestialIntelligence
                using Printf

                # Initialize system
                system = create_celestial_system()
                
                # Monitor and display evolution metrics
                while true
                    perf = analyze_system_performance(system)
                    @printf("\n🧬 Evolution Metrics:\n")
                    @printf("   Fitness: %.2f\n", perf.current_fitness)
                    @printf("   Components evolved: %d\n", length(perf.components_to_evolve))
                    @printf("   System stability: %.2f%%\n", perf.stability * 100)
                    
                    # Generate and display system report
                    report = generate_system_report(system)
                    @printf("\n📈 System Report:\n")
                    @printf("   Health: %.2f%%\n", get(report["health"], "overall", 0.0) * 100)
                    @printf("   Active patterns: %d\n", length(get(report["state"], "active_patterns", [])))
                    @printf("   Recent events: %d\n", length(get(report, "recent_events", [])))
                    
                    # Evolution step
                    evolve_system!(system)
                    
                    # Optimize system
                    optimize_system!(system)
                    
                    # Update iteration counter
                    iteration += 1
                    
                    sleep(5)
                end
            '
        fi
        
        ((iteration++))
        sleep 10
    done
}

# Main execution
echo "🚀 Initializing system..."
julia --project=../.. -e '
    using UniversalCelestialIntelligence
    system = create_celestial_system()
    initialize!(system)
    run_complete_session!(system)
'
