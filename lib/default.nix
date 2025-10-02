{pkgs}: let
  sandbox = import ./sandbox.nix {inherit pkgs;};
  profiles = import ./profiles.nix {inherit pkgs;};
  inherit (sandbox) makeSandboxScript;

  mkSandbox = {
    packages ? [],
    name ? "claude-sandbox",
  }: let
    sandboxScript = makeSandboxScript packages;
    allPackages = packages;
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
in {
  inherit makeSandboxScript profiles mkSandbox;

  extendSandbox = baseSandbox: packages:
    mkSandbox {
      inherit packages;
      inherit (baseSandbox) name;
    };

  mkDevShell = {
    packages ? [],
    shellHook ? "",
  }:
    pkgs.mkShell {
      buildInputs = [pkgs.bubblewrap] ++ packages;

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

  mkProfile = profileName: packages:
    mkSandbox {
      inherit packages;
      name = "claude-sandbox-${profileName}";
    };

  mkHomeManagerSandbox = {
    packages ? [],
    name ? "claude-sandbox",
  }: {
    home.packages = [
      (mkSandbox {
        inherit name packages;
      })
    ];
  };
}
