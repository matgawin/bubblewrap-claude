# Bubblewrap Claude Code Sandbox

A Nix flake providing a secure, isolated environment for running Claude Code using bubblewrap sandboxing.

## Quick Start

```bash
# Enter development environment
nix develop
# or
direnv allow

# Run sandbox in current directory
nix run

# Run sandbox in specific directory
nix run .#claude-sandbox /path/to/project

# Use language-specific profile
nix run .#claude-sandbox-go        # Go development
nix run .#claude-sandbox-python    # Python development
nix run .#claude-sandbox-rust      # Rust development
```

## Home Manager Integration

Add to your home-manager configuration:

```nix
{
  inputs = {
    bubblewrap-claude = {
        url = "github:matgawin/bubblewrap-claude";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  home.packages = [
    inputs.bubblewrap-claude.packages.${pkgs.system}.claude-sandbox
  ];
}
```

Then run `claude-sandbox` from anywhere to start the sandboxed environment.

## Features

- **Process isolation**: Complete namespace isolation with `--unshare-all`
- **Filesystem restrictions**: Only project directory and `/tmp` are writable
- **Curated toolset**: Pre-selected development tools available in sandbox
- **Claude Code integration**: Pre-installed with `--dangerously-skip-permissions`
- **Configuration persistence**: Host `~/.claude.json` automatically mounted if present

## Language Profiles

Pre-configured toolchains available out of the box:

| Profile | Command | Includes |
|---------|---------|----------|
| **Nix** | `nix run .#claude-sandbox-nix` | nix, alejandra |
| **Go** | `nix run .#claude-sandbox-go` | go, gopls, delve, golangci-lint, gotools |
| **Python** | `nix run .#claude-sandbox-python` | python3, pip, poetry, ruff, pyright |
| **Rust** | `nix run .#claude-sandbox-rust` | rustc, cargo, rust-analyzer, clippy |
| **Haskell** | `nix run .#claude-sandbox-haskell` | ghc, cabal, hls, stack |
| **Java** | `nix run .#claude-sandbox-java` | jdk, gradle, maven |
| **C++** | `nix run .#claude-sandbox-cpp` | gcc, clang, cmake, make |

## Base Sandbox Tools

The sandbox environment includes:

- **Core tools**: bash, coreutils, git, jujutsu
- **Text processing**: ripgrep, fd, jq, yq, bat
- **File operations**: tree, rsync, zip/unzip
- **Editor**: vim

Network access is enabled for API calls while maintaining filesystem isolation.

## Security Model

- Project directory bind-mounted as writable
- `/nix` store read-only mounted
- Temporary filesystem for `/tmp`
- CA certificates for HTTPS
- Host user/group mapping preserved
- Telemetry and auto-updates disabled

## Requirements

- Nix with flakes enabled
- Linux (x86_64 or aarch64)

## License

MIT
