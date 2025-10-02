{pkgs}: {
  nix = with pkgs; [
    nix
    alejandra
  ];

  go = with pkgs; [
    go
    gopls
    delve
    golangci-lint
    gotools
  ];

  python = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.virtualenv
    poetry
    ruff
    pyright
  ];

  rust = with pkgs; [
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
  ];

  cpp = with pkgs; [
    gcc
    clang
    cmake
    gnumake
    clang-tools
  ];
}
