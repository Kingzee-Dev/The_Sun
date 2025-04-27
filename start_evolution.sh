#!/bin/bash

# --- Initial Metrics ---
get_codebase_metrics() {
    echo "📦 Codebase Metrics:"
    echo "  - Julia files: $(find src -type f -name '*.jl' | wc -l)"
    echo "  - Total lines: $(find src -type f -name '*.jl' -exec cat {} + | wc -l)"
    echo "  - Modules: $(ls src | grep -c .jl)"
    echo "  - Submodules: $(find src -type f -name '*.jl' | grep -v '^src/[^/]*.jl$' | wc -l)"
    echo "  - Last modified: $(find src -type f -name '*.jl' -printf '%T@ %p\n' | sort -n | tail -1 | awk '{print $2}')"
}

# --- Evolution Info Graph ---
show_info_graph() {
    echo "\nEvolution Info Graph (ASCII):"
    echo "-----------------------------"
    echo "|   Start   |   Now   | Δ   |"
    echo "-----------------------------"
    start_files=0
    start_lines=0
    if [ -f .codebase_start ]; then
        start_files=$(awk '/files/ {print $2}' .codebase_start)
        start_lines=$(awk '/lines/ {print $2}' .codebase_start)
    fi
    now_files=$(find src -type f -name '*.jl' | wc -l)
    now_lines=$(find src -type f -name '*.jl' -exec cat {} + | wc -l)
    delta_files=$((now_files - start_files))
    delta_lines=$((now_lines - start_lines))
    printf "| %8d | %7d | %+3d | files\n" "$start_files" "$now_files" "$delta_files"
    printf "| %8d | %7d | %+3d | lines\n" "$start_lines" "$now_lines" "$delta_lines"
    echo "-----------------------------"
}

# --- Save initial metrics if not present ---
if [ ! -f .codebase_start ]; then
    echo "files $(find src -type f -name '*.jl' | wc -l)" > .codebase_start
    echo "lines $(find src -type f -name '*.jl' -exec cat {} + | wc -l)" >> .codebase_start
fi

# --- Main ---
echo "🌞 Universal Celestial Intelligence Evolution Starter"
get_codebase_metrics
show_info_graph

echo "\n🔑 Press ENTER to start system evolution and monitoring..."
read

# --- Start system and monitor evolution ---
bash src/UniversalLawObservatory/start_test.sh

# --- After monitoring, check internet and enrich ---
echo "\n🌐 Checking internet connectivity and enrichment suggestions..."
julia --project=. -e '
    using InternetModule
    if is_connected()
        println("✅ Internet connection: Online")
        topics = ["self-healing systems", "evolutionary algorithms", "pattern recognition", "software observability"]
        suggestions = enrich_codebase(topics)
        println("\n🔎 Enrichment Suggestions:")
        for (topic, suggestion) in suggestions
            println("- $topic: ", suggestion)
        end
    else
        println("❌ Internet connection: Offline")
    end
'