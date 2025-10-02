{
  description = "Bubblewrap sandbox claude code environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];

      perSystem = {system, ...}: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        sandboxLib = import ./lib {inherit pkgs;};
        profilePackages =
          pkgs.lib.mapAttrs' (profileName: packages: rec {
            name = "claude-sandbox-${profileName}";
            value = sandboxLib.mkSandbox {inherit name packages;};
          })
          sandboxLib.profiles;
      in {
        packages =
          profilePackages
          // rec {
            claude-sandbox = sandboxLib.mkSandbox {
              packages = sandboxLib.profiles.base;
            };
            default = claude-sandbox;
          };

        devShells.default = sandboxLib.mkDevShell {};
      };

      flake.lib = let
        forAllSystems = inputs.nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
      in
        forAllSystems (system: let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
          import ./lib {inherit pkgs;});
    };
}
