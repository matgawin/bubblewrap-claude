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
    bun
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
}
