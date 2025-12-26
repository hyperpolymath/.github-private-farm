# SPDX-License-Identifier: AGPL-3.0-or-later
# RSR-template-repo Containerfile
# Built with hyperpolymath/svalinn tooling on hyperpolymath/cerro-torre base
#
# Build: podman build -t rsr-template-repo .
# Run:   podman run --rm -it rsr-template-repo

# ═══════════════════════════════════════════════════════════════════════════════
# Stage 1: Build environment
# ═══════════════════════════════════════════════════════════════════════════════
FROM ghcr.io/hyperpolymath/cerro-torre:latest AS builder

LABEL org.opencontainers.image.source="https://github.com/hyperpolymath/RSR-template-repo"
LABEL org.opencontainers.image.description="RSR Template Repository - Build Stage"
LABEL org.opencontainers.image.licenses="AGPL-3.0-or-later"

# Install build dependencies based on project needs
# Uncomment the relevant sections for your project

# --- Idris 2 (Tier 0) ---
# RUN pack install-deps

# --- Rust (Tier 1) ---
# RUN rustup default stable

# --- Elixir (Tier 1) ---
# RUN mix local.hex --force && mix local.rebar --force

# --- Haskell (Tier 1) ---
# RUN cabal update

WORKDIR /build

# Copy dependency manifests first (for layer caching)
COPY guix.scm flake.nix flake.lock* ./
COPY justfile ./

# Copy source code
COPY . .

# Build the project
# Uncomment and modify for your build system
# RUN just build-release

# ═══════════════════════════════════════════════════════════════════════════════
# Stage 2: Runtime environment (minimal)
# ═══════════════════════════════════════════════════════════════════════════════
FROM ghcr.io/hyperpolymath/cerro-torre:minimal AS runtime

LABEL org.opencontainers.image.source="https://github.com/hyperpolymath/RSR-template-repo"
LABEL org.opencontainers.image.description="RSR Template Repository"
LABEL org.opencontainers.image.licenses="AGPL-3.0-or-later"
LABEL org.opencontainers.image.vendor="hyperpolymath"

# Security: Run as non-root user
RUN groupadd -r rsr && useradd -r -g rsr rsr
USER rsr

WORKDIR /app

# Copy built artifacts from builder stage
# COPY --from=builder /build/target/release/binary /app/
# COPY --from=builder /build/_build/prod/rel/app /app/

# Copy runtime configuration
COPY --chown=rsr:rsr .well-known/ /app/.well-known/

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/app/healthcheck"] || exit 1

# Default command
# CMD ["/app/binary"]

# ═══════════════════════════════════════════════════════════════════════════════
# Stage 3: Development environment
# ═══════════════════════════════════════════════════════════════════════════════
FROM ghcr.io/hyperpolymath/cerro-torre:latest AS development

LABEL org.opencontainers.image.description="RSR Template Repository - Development"

# Install development tools
RUN pacman -Sy --noconfirm \
    git \
    just \
    pre-commit \
    && pacman -Scc --noconfirm

WORKDIR /workspace

# Mount source code as volume in development
VOLUME ["/workspace"]

# Default to shell for development
CMD ["/bin/bash"]
