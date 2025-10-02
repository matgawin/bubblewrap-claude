# Bubblewrap Claude Code Sandbox

A Nix flake providing a secure, isolated environment for running Claude Code using bubblewrap sandboxing. This flake is designed to be easily imported and extended with custom packages in other projects.

## Quick Start

### Standalone Usage

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

### Import in Other Flakes

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bubblewrap-claude.url = "github:matgawin/bubblewrap-claude";
  };

  outputs = {nixpkgs, bubblewrap-claude, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    bwLib = bubblewrap-claude.lib.${system};
  in {
    # Create sandbox with your custom tools
    packages.${system}.my-sandbox = bwLib.mkSandbox {
      extraPackages = with pkgs; [ docker kubectl terraform ];
      name = "my-project-sandbox";
    };

    # Extended dev shell
    devShells.${system}.default = bwLib.mkDevShell {
      extraPackages = with pkgs; [ docker kubectl terraform ];
    };
  };
}
```

### Home Manager Integration

```nix
{ inputs, pkgs, ... }: {
  home.packages = [
    (inputs.bubblewrap-claude.lib.${pkgs.system}.mkSandbox {
      extraPackages = with pkgs; [ docker kubectl terraform ];
      name = "my-sandbox";
    })
  ];
}
```

## Extensible API

### Core Functions

#### `mkSandbox`
Creates a sandbox package with optional extra tools.

```nix
bwLib.mkSandbox {
  extraPackages = with pkgs; [ docker kubectl terraform ];  # optional
  name = "my-sandbox";  # optional, defaults to "claude-sandbox"
}
```

#### `mkDevShell`
Creates an extensible development shell.

```nix
bwLib.mkDevShell {
  extraPackages = with pkgs; [ docker kubectl ];  # optional
  shellHook = "echo 'Welcome!'";  # optional
}
```

#### `mkProfile`
Creates a named profile sandbox.

```nix
bwLib.mkProfile "devops" (with pkgs; [ docker kubectl terraform ])
# Creates: claude-sandbox-devops
```

#### `mkHomeManagerSandbox`
Helper for Home Manager integration.

```nix
bwLib.mkHomeManagerSandbox {
  extraPackages = with pkgs; [ docker kubectl ];
  name = "my-sandbox";
}
```

### Usage Examples

#### Multiple Specialized Environments

```nix
{
  packages.${system} = {
    # Web development
    web-sandbox = bwLib.mkProfile "web" (with pkgs; [
      nodejs yarn typescript
      nodePackages.prettier nodePackages.eslint
    ]);

    # DevOps tooling
    devops-sandbox = bwLib.mkProfile "devops" (with pkgs; [
      docker kubectl terraform ansible
      awscli2 helmfile
    ]);

    # Data science
    data-sandbox = bwLib.mkProfile "data" (with pkgs; [
      python3 python3Packages.pandas
      python3Packages.jupyter R sqlite
    ]);
  };
}
```

#### Project-Specific Configuration

```nix
{
  devShells.${system}.default = bwLib.mkDevShell {
    extraPackages = with pkgs; [
      # Project dependencies
      nodejs postgresql redis

      # Development tools
      docker-compose curl jq

      # Monitoring
      htop iotop
    ];

    shellHook = ''
      echo "Project development environment loaded!"
      echo "Run 'nix run .#project-sandbox' to enter isolated environment"
    '';
  };
}
```

## Built-in Language Profiles

Pre-configured toolchains available out of the box:

| Profile | Command | Includes |
|---------|---------|----------|
| **Nix** | `nix run .#claude-sandbox-nix` | nix, alejandra |
| **Go** | `nix run .#claude-sandbox-go` | go, gopls, delve, golangci-lint, gotools |
| **Python** | `nix run .#claude-sandbox-python` | python3, pip, poetry, ruff, pyright |
| **Rust** | `nix run .#claude-sandbox-rust` | rustc, cargo, rust-analyzer, clippy |
| **C++** | `nix run .#claude-sandbox-cpp` | gcc, clang, cmake, make |

## Base Sandbox Tools

The sandbox environment includes:

**Core tools**: bash, coreutils, git, jujutsu, vim, which
**Text processing**: ripgrep, fd, jq, yq, bat, less
**File operations**: tree, rsync, zip/unzip, tar, gzip
**Development**: nodejs, bun, patch, diffutils
**Network**: curl (via git), CA certificates
**System**: procps, file, findutils

## Security Model

- **Process isolation**: Complete namespace isolation with `--unshare-all`
- **Filesystem restrictions**: Only project directory and `/tmp` are writable
- **Network access**: Enabled for API calls while maintaining filesystem isolation
- **Configuration persistence**: Host `~/.claude.json` automatically mounted if present
- **Privilege separation**: Runs as host user with restricted capabilities
- **Telemetry disabled**: All Claude Code telemetry and auto-updates disabled

## Advanced Usage

### Conditional Package Inclusion

```nix
let
  conditionalPackages = with pkgs; [
    git vim jq
  ] ++ lib.optionals stdenv.isLinux [
    docker systemd
  ] ++ lib.optionals (system == "x86_64-linux") [
    # x86_64 specific tools
  ];
in {
  packages.${system}.conditional-sandbox = bwLib.mkSandbox {
    extraPackages = conditionalPackages;
  };
}
```

## Requirements

- Nix with flakes enabled
- Linux (x86_64 or aarch64)
- Bubblewrap (automatically included)

## License

MIT