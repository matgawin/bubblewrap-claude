# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nix flake that creates a secure bubblewrap sandbox environment specifically designed for running Claude Code. The project sets up an isolated environment and a curated set of development tools.

## Architecture

The flake defines a sandboxed environment using:
- **Bubblewrap**: Provides process isolation and filesystem sandboxing
- **Nix**: Manages dependencies and creates reproducible environments
- **Claude Code**: Pre-installed and aliased with `--dangerously-skip-permissions`

Key components:
- `sandboxScript`: Main script that sets up the bubblewrap environment (flake.nix:73-128)
- `sandboxTools`: Curated list of allowed tools in the sandbox (flake.nix:22-55)
- `customBashProfile`: Configuration for the sandboxed shell environment (flake.nix:58-65)

## Commands

### Development Environment
```bash
# Enter development shell
nix develop
# or
direnv allow

# Run the sandbox in current directory
nix run

# Run the sandbox in a specific directory
nix run .#claude-sandbox [directory]
```

### Language-Specific Profiles
Pre-configured toolchains for common languages:

```bash
# Nix development
nix run .#claude-sandbox-nix

# Go development
nix run .#claude-sandbox-go

# Python development
nix run .#claude-sandbox-python

# Rust development
nix run .#claude-sandbox-rust

# Haskell development
nix run .#claude-sandbox-haskell

# Java development
nix run .#claude-sandbox-java

# C++ development
nix run .#claude-sandbox-cpp
```

Each profile includes language-specific tools:
- **go**: go, gopls, delve, golangci-lint, gotools
- **python**: python3, pip, virtualenv, poetry, ruff, pyright
- **rust**: rustc, cargo, rustfmt, clippy, rust-analyzer
- **haskell**: ghc, cabal-install, haskell-language-server, stack
- **java**: jdk, gradle, maven
- **cpp**: gcc, clang, cmake, make, clang-tools

### Inside the Sandbox
```bash
# Claude Code is aliased and ready to use
claude

# Available tools include:
# - Version control: git, jujutsu
# - Text processing: ripgrep, fd, jq, yq
# - File operations: tree, rsync, zip/unzip
# - Editor: vim
```

## Security Model

The sandbox enforces strict isolation:
- Filesystem access limited to the project directory
- Temporary directory isolation (`/tmp`)
- Process isolation with `--unshare-all`
- Claude Code configuration loaded from host's `~/.claude.json` if present