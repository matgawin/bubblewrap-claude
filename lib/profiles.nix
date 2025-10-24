{pkgs}: let
  basePackages = with pkgs; [
    bash
    coreutils
    diffutils
    fd
    file
    findutils
    gawk
    git
    gnugrep
    gnused
    gnutar
    gzip
    jq
    jujutsu
    less
    man
    patch
    procps
    ripgrep
    rsync
    tree
    unzip
    vim
    which
    yq
    zip
  ];

  base = {
    url = "api.anthropic.com";
    ips = ["160.79.104.10"];
    env = {
      TMPDIR = "/tmp";
      SHELL = "${pkgs.bash}/bin/bash";
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      DISABLE_AUTOUPDATER = "1";
      DISABLE_ERROR_REPORTING = "1";
      DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1";
      DISABLE_TELEMETRY = "1";
      ANTHROPIC_API_URL = "https://api.anthropic.com";
    };
    args = [
      "--ro-bind-try /home/$USER/.config/git /home/$USER/.config/git"
      "--ro-bind-try /home/$USER/.config/jj /home/$USER/.config/jj"
    ];
    preStartHooks = [];
    packages = basePackages;
    customPrompt = "";
  };

  deriveProfile = default: profile: {
    inherit (profile) name;
    url = profile.url or default.url;
    ips = profile.ips or default.ips;
    env = (default.env or {}) // (profile.env or {});
    args = (default.args or []) ++ (profile.args or []);
    packages = (default.packages or []) ++ (profile.packages or []);
    preStartHooks = (default.preStartHooks or []) ++ (profile.preStartHooks or []);
    customPrompt = (default.customPrompt or "") + (profile.customPrompt or "");
  };
  fromBase = deriveProfile base;
in {
  inherit base deriveProfile;

  profiles = {
    bare = {
      inherit (base) url ips env args preStartHooks customPrompt;
      packages = with pkgs; [
        bash
        coreutils
      ];
    };

    nix = fromBase {
      packages = with pkgs; [
        nix
        alejandra
      ];
    };

    go = fromBase {
      args = [
        "--ro-bind-try /home/$USER/go/pkg/mod /home/$USER/go/pkg/mod"
      ];
      packages = with pkgs; [
        go
        gopls
        delve
        golangci-lint
        gotools
        gofumpt
      ];
    };

    python = fromBase {
      args = [
        "--ro-bind-try /home/$USER/.cache/pip /home/$USER/.cache/pip"
        "--ro-bind-try /home/$USER/.cache/pypoetry /home/$USER/.cache/pypoetry"
        "--ro-bind-try /home/$USER/.cache/uv /home/$USER/.cache/uv"
      ];
      packages = with pkgs; [
        python3
        python3Packages.pip
        python3Packages.virtualenv
        poetry
        ruff
        pyright
        uv
      ];
    };

    rust = fromBase {
      args = [
        "--ro-bind-try /home/$USER/.cargo/registry /home/$USER/.cargo/registry"
        "--ro-bind-try /home/$USER/.cargo/git /home/$USER/.cargo/git"
      ];
      packages = with pkgs; [
        rustc
        cargo
        rustfmt
        clippy
        rust-analyzer
      ];
    };

    cpp = fromBase {
      args = [
        "--ro-bind-try /home/$USER/.cache/ccache /home/$USER/.cache/ccache"
        "--ro-bind-try /home/$USER/.ccache /home/$USER/.ccache"
      ];
      packages = with pkgs; [
        gcc
        clang
        cmake
        gnumake
        clang-tools
      ];
    };

    js = fromBase {
      args = [
        "--ro-bind-try /home/$USER/.npm /home/$USER/.npm"
        "--ro-bind-try /home/$USER/.yarn /home/$USER/.yarn"
        "--ro-bind-try /home/$USER/.cache/yarn /home/$USER/.cache/yarn"
        "--ro-bind-try /home/$USER/.local/share/pnpm /home/$USER/.local/share/pnpm"
        "--ro-bind-try /home/$USER/.bun /home/$USER/.bun"
      ];
      packages = with pkgs; [
        nodejs
        yarn
        pnpm
        bun
        typescript
        typescript-language-server
        eslint
        prettier
      ];
    };

    devops = fromBase {
      args = [
        "--ro-bind-try /home/$USER/.kube /home/$USER/.kube"
        "--ro-bind-try /home/$USER/.aws /home/$USER/.aws"
        "--ro-bind-try /home/$USER/.cache/helm /home/$USER/.cache/helm"
        "--ro-bind-try /home/$USER/.terraform.d /home/$USER/.terraform.d"
      ];
      packages = with pkgs; [
        docker
        docker-compose
        podman
        kubernetes-helm
        kubectl
        terraform
        pgcli
        cloudflared
        awscli2
      ];
    };
  };
}
