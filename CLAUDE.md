# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nix flake that creates a secure bubblewrap sandbox environment specifically designed for running Claude Code. The project uses a profile-based architecture to provide language-specific development environments with network isolation. The flake is designed to be easily imported and extended with custom profiles in other projects.

## Architecture

The flake defines sandboxed environments using:
- **Bubblewrap**: Provides process isolation and filesystem sandboxing
- **Nix**: Manages dependencies and creates reproducible environments
- **Claude Code**: Pre-installed and aliased with `--dangerously-skip-permissions`
- **Profile System**: Structured configuration for language-specific toolchains

Key components:
- `lib/sandbox.nix`: Core sandbox script generation
- `lib/default.nix`: Extensible API functions (mkSandbox, mkDevShell, deriveProfile)
- `lib/profiles.nix`: Language-specific profile definitions
- `flake.nix`: Main flake configuration and package exports

## Profile-Based Architecture

Profiles are structured configurations containing:
- `name`: Profile identifier
- `packages`: List of Nix packages to include
- `env`: Environment variables
- `preStartHooks`: Array of shell commands to execute at sandbox startup
- `args`: Additional bubblewrap arguments (for cache binds, etc.)
- `url`: API endpoint URL (defaults to api.anthropic.com)
- `ips`: IP addresses for the API endpoint

Base profile (`base`) provides core utilities, and other profiles extend it using `deriveProfile`.

## Extensible API

The flake exports functions for creating and customizing sandboxes:

### Core Functions
- `mkSandbox profile`: Create sandbox from profile specification
- `mkDevShell { packages, shellHook }`: Create extensible development shell
- `deriveProfile baseProfile extensions`: Extend existing profile
- `profiles`: Access to predefined language-specific profiles

### Profile Structure
```nix
{
  name = "profile-name";
  packages = with pkgs; [ tool1 tool2 ];
  env = { VAR = "value"; };
  preStartHooks = [  # optional
    ''export SECRET="$(cat /path/to/secret)"''
    ''echo "Setup complete"''
  ];
  args = [ "--ro-bind-try /cache /cache" ];
  url = "api.example.com";  # optional
  ips = [ "1.2.3.4" ];      # optional
}
```

## Available Profiles

### Language Development Profiles
- **base**: Core development tools (git, vim, ripgrep, etc.)
- **bare**: Minimal environment (bash, coreutils only)
- **nix**: Nix development (nix, alejandra) with `/nix` bind
- **go**: Go development with module cache binding
- **python**: Python development with pip/poetry/uv cache binding
- **rust**: Rust development with cargo cache binding
- **cpp**: C++ development with ccache binding
- **js**: JavaScript/TypeScript with npm/yarn/pnpm/bun cache binding
- **devops**: DevOps tools (docker, kubectl, terraform) with config binding

### Cache Management
Each profile automatically binds appropriate cache directories:
- Go: `~/go/pkg/mod`
- Python: `~/.cache/pip`, `~/.cache/pypoetry`, `~/.cache/uv`
- Rust: `~/.cargo/registry`, `~/.cargo/git`
- JavaScript: `~/.npm`, `~/.yarn`, `~/.bun`, pnpm store
- DevOps: `~/.kube`, `~/.aws`, `~/.cache/helm`, `~/.terraform.d`

## Commands

### Development Environment
```bash
# Enter development shell
nix develop
# or with direnv
direnv allow

# Run base sandbox in current directory
nix run

# Run sandbox in specific directory
nix run .#claude-sandbox [directory]
```

### Language-Specific Profiles
```bash
# Available profiles
nix run .#claude-sandbox-bare      # Minimal environment
nix run .#claude-sandbox-nix       # Nix development
nix run .#claude-sandbox-go        # Go development
nix run .#claude-sandbox-python    # Python development
nix run .#claude-sandbox-rust      # Rust development
nix run .#claude-sandbox-cpp       # C++ development
nix run .#claude-sandbox-js        # JavaScript/TypeScript
nix run .#claude-sandbox-devops    # DevOps tooling
```

### Inside the Sandbox
```bash
# Claude Code is aliased and ready to use
claude

# Available in all profiles:
# - Version control: git, jujutsu
# - Text processing: ripgrep, fd, jq, yq, less
# - File operations: tree, rsync, zip/unzip, tar, gzip
# - System tools: bash, coreutils, procps, which, file
# - Editor: vim with man pages
```

## Importing and Extending

### Basic Import
```nix
{
  inputs.bubblewrap-claude.url = "github:matgawin/bubblewrap-claude";

  outputs = {nixpkgs, bubblewrap-claude, ...}: let
    system = "x86_64-linux";
    bwLib = bubblewrap-claude.lib.${system};
  in {
    packages.${system}.my-sandbox = bwLib.mkSandbox {
      name = "my-project";
      packages = with pkgs; [ docker kubectl terraform ];
      env = { PROJECT_ENV = "development"; };
    };
  };
}
```

### Extending Existing Profiles
```nix
let
  customGoProfile = bwLib.deriveProfile bwLib.profiles.go {
    name = "go-web";
    packages = with pkgs; [ air templ ];
    env = { GO_ENV = "development"; };
    preStartHooks = [
      ''export API_KEY="$(cat /run/secrets/go-api-key)"''
      ''echo "Go web environment ready"''
    ];
    args = [ "--ro-bind-try /home/$USER/.config/air /home/$USER/.config/air" ];
  };
in {
  packages.${system}.go-web = bwLib.mkSandbox customGoProfile;
}
```

### Extended Development Shell
```nix
devShells.${system}.default = bwLib.mkDevShell {
  packages = with pkgs; [ docker kubectl terraform ];
  shellHook = ''
    echo "Custom development environment loaded!"
    echo "Available sandboxes:"
    echo "  nix run .#claude-sandbox-go"
    echo "  nix run .#claude-sandbox-js"
    echo "  nix run .#fullstack"
  '';
};
```

## Security Model

The sandbox enforces strict isolation while maintaining development workflow:

### Process Isolation
- Complete namespace isolation with `--unshare-all`
- Runs as host user but with restricted capabilities
- Process tree isolation from host system

### Filesystem Access
- Project directory: read-write access to current/specified directory
- Temporary directory: isolated `/tmp` for each sandbox session
- System directories: read-only access to `/nix`, `/etc` (controlled)
- Cache directories: read-only binding for language-specific caches
- Host configuration: `~/.claude.json` mounted if present

### Network Configuration
- Custom `/etc/hosts` with Anthropic API endpoints
- Controlled DNS resolution via custom `resolv.conf`
- Network access enabled for API calls while maintaining filesystem isolation
- Profile-specific API endpoint configuration

### Environment Control
- Telemetry and auto-updates disabled via environment variables
- Language-specific environment setup (PATH, cache locations, etc.)
- Custom environment variables per profile
- Pre-start hooks for runtime secret loading and dynamic configuration
- Inheritance control for sensitive variables (API keys)

## Debugging and Development

### Profile Development
When creating new profiles, use the base profile structure:
```nix
myProfile = bwLib.deriveProfile bwLib.base {
  name = "my-tool";
  packages = with pkgs; [ my-tool ];
  env = { MY_TOOL_CONFIG = "/tmp/config"; };
  preStartHooks = [
    ''export MY_API_KEY="$(cat /run/secrets/my-tool-key)"''
    ''echo "My-tool environment initialized"''
  ];
  args = [ "--ro-bind-try /home/$USER/.my-tool /home/$USER/.my-tool" ];
};
```

### Common Patterns
- Use `--ro-bind-try` for optional cache directories
- Bind configuration directories when tools expect them in `$HOME`
- Set tool-specific environment variables for cache locations in `/tmp`
- Include language servers and formatters in development profiles
- Use pre-start hooks to load secrets at runtime from sops-nix or other secret management systems
- Validate environment setup in pre-start hooks with conditional logic

### Testing Profiles
```bash
# Test profile in isolation
nix run .#my-custom-sandbox /tmp/test-project

# Check available tools
nix run .#my-custom-sandbox -- which my-tool

# Verify cache bindings
nix run .#my-custom-sandbox -- ls -la ~/.cache/
```
