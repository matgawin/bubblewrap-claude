{pkgs}: let
  sandboxModule = import ./sandbox.nix {inherit pkgs;};
  inherit (sandboxModule) sandboxTools makeSandboxScript;

  profiles = {
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
    ];
    rust = with pkgs; [
      rustc
      cargo
      rustfmt
      rust-analyzer
    ];
    cpp = with pkgs; [
      gcc
      clang
      cmake
      gnumake
      clang-tools
    ];
    nix = with pkgs; [
      nix
      alejandra
    ];
  };

  mkProfilePackage = title: extraPkgs:
    pkgs.stdenv.mkDerivation rec {
      name = "claude-sandbox${title}";
      buildInputs = [pkgs.makeWrapper];
      unpackPhase = "true";
      installPhase = let
        script = makeSandboxScript extraPkgs;
        allPkgs = sandboxTools ++ extraPkgs;
      in ''
        mkdir -p $out/bin
        cp ${script} $out/bin/${name}
        chmod +x $out/bin/${name}
        wrapProgram $out/bin/${name} --prefix PATH : ${pkgs.lib.makeBinPath allPkgs}
      '';
    };
in {
  inherit sandboxTools;

  claude-sandbox = mkProfilePackage "" [];
  claude-sandbox-nix = mkProfilePackage "-nix" profiles.nix;
  claude-sandbox-go = mkProfilePackage "-go" profiles.go;
  claude-sandbox-python = mkProfilePackage "-python" profiles.python;
  claude-sandbox-rust = mkProfilePackage "-rust" profiles.rust;
  claude-sandbox-cpp = mkProfilePackage "-cpp" profiles.cpp;
}
