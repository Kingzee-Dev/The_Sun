#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Start the Julia script
echo "🚀 Initializing Scientific Researcher..."
julia --project="$SCRIPT_DIR/.." "$SCRIPT_DIR/start_research.jl"
