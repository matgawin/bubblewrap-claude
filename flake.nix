{
  description = "Bubblewrap sandbox claude code environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];

      perSystem = {
        self',
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        packages = import ./packages {inherit pkgs;};
        inherit (packages) sandboxTools;
      in {
        packages = packages // {default = self'.packages.claude-sandbox;};

        devShells.default = pkgs.mkShell {
          buildInputs = [pkgs.bubblewrap] ++ sandboxTools;

          shellHook = ''
            echo "Bubblewrap sandbox environment loaded!"
            echo "Available profiles: [ nix, go, python, rust, cpp ]"
            echo ""
            echo "Run 'nix run' or 'nix run .#claude-sandbox [directory]' to enter the isolated environment"
            echo "  - 'nix run' uses current directory"
            echo "  - 'nix run .#claude-sandbox-<profile> [directory]' to enter sandbox with specific profile"
          '';
        };
      };
    };
}
