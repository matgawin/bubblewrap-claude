# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nix flake that creates a secure bubblewrap sandbox environment specifically designed for running Claude Code. The project sets up an isolated environment and a curated set of development tools. The flake is designed to be easily imported and extended with custom packages in other projects.

## Architecture

The flake defines a sandboxed environment using:
- **Bubblewrap**: Provides process isolation and filesystem sandboxing
- **Nix**: Manages dependencies and creates reproducible environments
- **Claude Code**: Pre-installed and aliased with `--dangerously-skip-permissions`

Key components:
- `lib/sandbox.nix`: Core sandbox script generation and tool definitions
- `lib/default.nix`: Extensible API functions (mkSandbox, mkDevShell, mkProfile)
- `lib/profiles.nix`: Language-specific development profiles definitions
- `flake.nix`: Main flake configuration and package exports

## Extensible API

The flake exports several functions for easy integration:

### Core Functions
- `mkSandbox { packages, name }`: Create custom sandbox with additional packages
- `mkDevShell { packages, shellHook }`: Create extensible development shell
- `mkProfile profileName packages`: Create named profile sandbox
- `mkHomeManagerSandbox { packages, name }`: Helper for Home Manager integration
- `profiles`: Access to predefined language-specific tool sets

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

# C++ development
nix run .#claude-sandbox-cpp
```

Each profile includes language-specific tools:
- **nix**: nix, alejandra
- **go**: go, gopls, delve, golangci-lint, gotools
- **python**: python3, pip, virtualenv, poetry, ruff, pyright
- **rust**: rustc, cargo, rustfmt, clippy, rust-analyzer
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

## Importing and Extending

### Basic Import
Add to your flake inputs:
```nix
{
  inputs.bubblewrap-claude.url = "github:matgawin/bubblewrap-claude";

  outputs = {nixpkgs, bubblewrap-claude, ...}: let
    bwLib = bubblewrap-claude.lib.${system};
  in {
    packages.${system}.my-sandbox = bwLib.mkSandbox {
      packages = with pkgs; [ docker kubectl terraform ];
      name = "my-project-sandbox";
    };
  };
}
```

### Home Manager Integration
```nix
{ inputs, pkgs, ... }: {
  home.packages = [
    (inputs.bubblewrap-claude.lib.${pkgs.system}.mkSandbox {
      packages = with pkgs; [ docker kubectl terraform ];
      name = "my-sandbox";
    })
  ];
}
```

### Extended Development Shell
```nix
devShells.${system}.default = bwLib.mkDevShell {
  packages = with pkgs; [ docker kubectl terraform ];
  shellHook = ''
    echo "Custom development environment loaded!"
    echo "Additional tools: docker, kubectl, terraform"
  '';
};
```

## Security Model

The sandbox enforces strict isolation:
- Filesystem access limited to the project directory
- Temporary directory isolation (`/tmp`)
- Process isolation with `--unshare-all`
- Claude Code configuration loaded from host's `~/.claude.json` if present