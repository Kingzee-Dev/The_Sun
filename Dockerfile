# syntax=docker/dockerfile:1
# Multi-stage Dockerfile for Universal Celestial Intelligence (UCI)
# See: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

# --- Builder stage ---
FROM julia:1.10 as builder
WORKDIR /app

# Copy only dependency files first for better build cache usage
COPY Project.toml /app/
RUN julia -e 'using Pkg; Pkg.instantiate()'

# Copy the rest of the source
COPY src /app/src
COPY README.md /app/

# Precompile packages (optional, speeds up runtime)
RUN julia -e 'using Pkg; Pkg.precompile()'

# --- Final stage ---
FROM julia:1.10-slim as runtime
WORKDIR /app

# Copy only what is needed from builder
COPY --from=builder /app /app

# Expose a port if your app serves a web API (optional)
# EXPOSE 8080

# Set environment variables (optional)
# ENV JULIA_NUM_THREADS=2

# Default command: start Julia REPL
CMD ["julia"]
