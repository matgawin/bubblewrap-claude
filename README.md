# Bubblewrap Claude Code Sandbox

A Nix flake providing a secure, isolated environment for running Claude Code using bubblewrap sandboxing. Features a profile-based architecture for language-specific development environments.

## Quick Start

### Standalone Usage

```bash
# Enter development environment
nix develop
# or
direnv allow

# Run base sandbox in current directory
nix run

# Run sandbox in specific directory
nix run .#claude-sandbox /path/to/project

# Use language-specific profiles
nix run .#claude-sandbox-go        # Go development
nix run .#claude-sandbox-python    # Python development
nix run .#claude-sandbox-rust      # Rust development
nix run .#claude-sandbox-js        # JavaScript/TypeScript development
nix run .#claude-sandbox-devops    # DevOps tooling
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
    # Create custom profile sandbox
    packages.${system}.my-sandbox = bwLib.mkSandbox {
      name = "my-project";
      packages = with pkgs; [ docker kubectl terraform ];
      env = { MY_VAR = "value"; };
      args = [ "--ro-bind-try /home/$USER/.config/myapp /home/$USER/.config/myapp" ];
    };

    # Extended dev shell
    devShells.${system}.default = bwLib.mkDevShell {
      packages = with pkgs; [ docker kubectl terraform ];
    };
  };
}
```

## Built-in Language Profiles

Pre-configured development environments:

| Profile | Command | Tools | Cache Binds |
|---------|---------|-------|-------------|
| **Base** | `claude-sandbox` | Core utilities, git, jujutsu, vim | - |
| **Bare** | `claude-sandbox-bare` | Minimal: bash, coreutils only | - |
| **Nix** | `claude-sandbox-nix` | nix, alejandra | `/nix` |
| **Go** | `claude-sandbox-go` | go, gopls, delve, golangci-lint, gotools, gofumpt | `~/go/pkg/mod` |
| **Python** | `claude-sandbox-python` | python3, pip, poetry, ruff, pyright, uv | `~/.cache/pip`, `~/.cache/pypoetry`, `~/.cache/uv` |
| **Rust** | `claude-sandbox-rust` | rustc, cargo, rust-analyzer, clippy, rustfmt | `~/.cargo/registry`, `~/.cargo/git` |
| **C++** | `claude-sandbox-cpp` | gcc, clang, cmake, make, clang-tools | `~/.cache/ccache`, `~/.ccache` |
| **JavaScript** | `claude-sandbox-js` | nodejs, yarn, pnpm, bun, typescript, eslint, prettier | `~/.npm`, `~/.yarn`, `~/.bun`, pnpm store |
| **DevOps** | `claude-sandbox-devops` | docker, kubectl, terraform, helm, awscli2, pgcli | `~/.kube`, `~/.aws`, `~/.cache/helm`, `~/.terraform.d` |

## Extensible API

### Core Functions

#### `mkSandbox`
Creates a sandbox package from a profile specification.

```nix
bwLib.mkSandbox {
  name = "my-sandbox";  # required
  packages = with pkgs; [ git vim ];  # required
  env = { VAR = "value"; };  # optional environment variables
  args = [ "--ro-bind /path /path" ];  # optional bubblewrap arguments
  url = "api.example.com";  # optional API URL
  ips = [ "1.2.3.4" ];  # optional IP addresses for URL
}
```

#### `mkDevShell`
Creates a development shell with sandbox tools available.

```nix
bwLib.mkDevShell {
  packages = with pkgs; [ docker kubectl ];  # optional additional packages
  shellHook = "echo 'Welcome!'";  # optional shell initialization
}
```

#### `profiles`
Access to built-in profile definitions.

```nix
# Use existing profile
bwLib.mkSandbox bwLib.profiles.go

# Extend existing profile
bwLib.mkSandbox (bwLib.deriveProfile bwLib.profiles.python {
  packages = with pkgs; [ jupyter ];
  env = { JUPYTER_CONFIG_DIR = "/tmp/jupyter"; };
})
```

#### `deriveProfile`
Extends a base profile with additional configuration.

```nix
bwLib.deriveProfile baseProfile {
  name = "extended-profile";  # optional: override name
  packages = with pkgs; [ extra-tool ];  # additional packages
  env = { EXTRA_VAR = "value"; };  # additional environment variables
  args = [ "--extra-arg" ];  # additional bubblewrap arguments
}
```

## Base Sandbox Tools

All profiles include these core utilities:

**System**: bash, coreutils, diffutils, findutils, procps, which, file
**Version Control**: git, jujutsu
**Text Processing**: ripgrep, fd, jq, yq, less, gawk, gnugrep, gnused
**File Operations**: tree, rsync, zip/unzip, gnutar, gzip, patch
**Editor**: vim, man

## Usage Examples

### Custom Development Environment

```nix
let
  myProfile = bwLib.deriveProfile bwLib.profiles.python {
    name = "data-science";
    packages = with pkgs; [
      python3Packages.pandas
      python3Packages.jupyter
      python3Packages.matplotlib
      R
      sqlite
    ];
    env = {
      JUPYTER_CONFIG_DIR = "/tmp/jupyter";
      R_LIBS_USER = "/tmp/R-libs";
    };
    args = [
      "--ro-bind-try /home/$USER/datasets /home/$USER/datasets"
    ];
  };
in {
  packages.${system}.data-science = bwLib.mkSandbox myProfile;
}
```

### Multi-Language Project

```nix
{
  packages.${system} = {
    # Frontend development
    frontend = bwLib.mkSandbox (bwLib.deriveProfile bwLib.profiles.js {
      name = "frontend";
      packages = with pkgs; [ sass tailwindcss ];
    });

    # Backend development
    backend = bwLib.mkSandbox (bwLib.deriveProfile bwLib.profiles.go {
      name = "backend";
      packages = with pkgs; [ postgresql redis-cli ];
      env = { DATABASE_URL = "postgres://localhost/mydb"; };
    });

    # Full-stack environment
    fullstack = bwLib.mkSandbox {
      name = "fullstack";
      packages = bwLib.profiles.js.packages ++ bwLib.profiles.go.packages ++ (with pkgs; [
        postgresql redis-cli sass tailwindcss
      ]);
      env = bwLib.profiles.js.env // bwLib.profiles.go.env // {
        DATABASE_URL = "postgres://localhost/mydb";
      };
      args = bwLib.profiles.js.args ++ bwLib.profiles.go.args;
    };
  };
}
```

### Conditional Package Loading

```nix
let
  conditionalPackages = with pkgs; [
    git vim jq
  ] ++ lib.optionals stdenv.isLinux [
    docker systemd
  ] ++ lib.optionals (system == "x86_64-linux") [
    podman buildah
  ];
in {
  packages.${system}.platform-specific = bwLib.mkSandbox {
    name = "platform-sandbox";
    packages = conditionalPackages;
    env = { PLATFORM = system; };
  };
}
```

## Security Model

- **Process isolation**: Complete namespace isolation with `--unshare-all`
- **Filesystem restrictions**: Only project directory and `/tmp` are writable
- **Network access**: Controlled via custom `/etc/hosts` and DNS configuration
- **Configuration persistence**: Host `~/.claude.json` automatically mounted if present
- **Cache management**: Language-specific caches mounted read-only where appropriate
- **Privilege separation**: Runs as host user with restricted capabilities
- **Telemetry disabled**: All Claude Code telemetry and auto-updates disabled

## Advanced Configuration

### Custom Hosts and Network

Profiles automatically configure network access for Claude Code's API. You can customize this:

```nix
bwLib.mkSandbox {
  name = "custom-network";
  packages = with pkgs; [ curl ];
  url = "custom-api.example.com";
  ips = [ "192.168.1.100" "10.0.0.50" ];
}
```

### Environment Variable Management

```nix
let
  devProfile = bwLib.deriveProfile bwLib.base {
    name = "development";
    env = {
      NODE_ENV = "development";
      DEBUG = "app:*";
      LOG_LEVEL = "debug";
      # Inherit from host for API keys
      ANTHROPIC_API_KEY = "\${ANTHROPIC_API_KEY:-}";
    };
  };
```

## Requirements

- Nix with flakes enabled
- Linux (x86_64 or aarch64)
- Bubblewrap (automatically included)

## License

MIT