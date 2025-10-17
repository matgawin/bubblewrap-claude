{pkgs}: let
  sandbox = import ./sandbox.nix {inherit pkgs;};
  profiles = import ./profiles.nix {inherit pkgs;};
  inherit (sandbox) makeSandboxScript;

  mkSandbox = profile: let
    sandboxScript = makeSandboxScript profile;
    packagePath = pkgs.lib.makeBinPath profile.packages;
    name = profile.name;
  in
    pkgs.stdenv.mkDerivation {
      inherit name;
      pname = name;
      meta = {
        description = "Isolated environment for development with Claude Code";
        homepage = "https://github.com/matgawin/bubblewrap-claude";
        license = pkgs.lib.licenses.mit;
        mainProgram = name;
      };
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
  inherit makeSandboxScript mkSandbox;
  inherit (profiles) profiles deriveProfile base;

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
}
