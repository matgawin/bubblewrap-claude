{pkgs}: let
  sandbox = import ./sandbox.nix {inherit pkgs;};
  profiles = import ./profiles.nix {inherit pkgs;};
  inherit (sandbox) sandboxTools makeSandboxScript;

  mkDerivation = {
    extraPackages ? [],
    name ? "claude-sandbox",
  }: let
    sandboxScript = makeSandboxScript extraPackages;
    allPackages = sandboxTools ++ extraPackages;
    packagePath = pkgs.lib.makeBinPath allPackages;
  in
    pkgs.stdenv.mkDerivation {
      inherit name;
      buildInputs = [pkgs.makeWrapper];
      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp ${sandboxScript} $out/bin/${name}
        chmod +x $out/bin/${name}
        wrapProgram $out/bin/${name} --prefix PATH : ${packagePath}
      '';
    };
in rec {
  mkSandbox = {
    extraPackages ? [],
    name ? "claude-sandbox",
  }:
    mkDerivation {
      inherit extraPackages name;
    };

  extendSandbox = baseSandbox: extraPackages:
    mkDerivation {
      inherit extraPackages;
      inherit (baseSandbox) name;
    };

  mkDevShell = {
    extraPackages ? [],
    shellHook ? "",
  }:
    pkgs.mkShell {
      buildInputs = [pkgs.bubblewrap] ++ sandboxTools ++ extraPackages;

      shellHook = ''
        echo "Bubblewrap sandbox environment loaded!"
        echo "Available profiles: [ nix, go, python, rust, cpp ]"
        echo ""
        echo "Run 'nix run' or 'nix run .#claude-sandbox [directory]' to enter the isolated environment"
        echo "  - 'nix run' uses current directory"
        echo "  - 'nix run .#claude-sandbox-<profile> [directory]' to enter sandbox with specific profile"
        ${shellHook}
      '';
    };

  inherit sandboxTools makeSandboxScript profiles;

  mkProfile = profileName: extraPackages:
    mkSandbox {
      inherit extraPackages;
      name = "claude-sandbox-${profileName}";
    };

  mkHomeManagerSandbox = {
    extraPackages ? [],
    name ? "claude-sandbox",
  }: {
    home.packages = [
      (mkSandbox {
        inherit extraPackages name;
      })
    ];
  };
}
