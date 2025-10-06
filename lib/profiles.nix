{pkgs}: let
  base = with pkgs; [
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
in {
  inherit base;

  bare = with pkgs; [
    bash
    coreutils
  ];

  nix = with pkgs;
    [
      nix
      alejandra
    ]
    ++ base;

  go = with pkgs;
    [
      go
      gopls
      delve
      golangci-lint
      gotools
      gofumpt
    ]
    ++ base;

  python = with pkgs;
    [
      python3
      python3Packages.pip
      python3Packages.virtualenv
      poetry
      ruff
      pyright
      uv
    ]
    ++ base;

  rust = with pkgs;
    [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
    ]
    ++ base;

  cpp = with pkgs;
    [
      gcc
      clang
      cmake
      gnumake
      clang-tools
    ]
    ++ base;

  js = with pkgs;
    [
      nodejs
      yarn
      pnpm
      bun
      typescript
      typescript-language-server
      eslint
      prettier
    ]
    ++ base;

  devops = with pkgs;
    [
      docker
      docker-compose
      podman
      kubernetes-helm
      kubectl
      terraform
      pgcli
      cloudflared
      awscli2
    ]
    ++ base;
}
