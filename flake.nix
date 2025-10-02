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

        sandboxLib = import ./lib {inherit pkgs;};

        mkProfileSandbox = profileName: packages:
          sandboxLib.mkSandbox {
            inherit packages;
            name = "claude-sandbox-${profileName}";
          };

        profilePackages =
          pkgs.lib.mapAttrs' (profileName: packages: {
            name = "claude-sandbox-${profileName}";
            value = mkProfileSandbox profileName packages;
          })
          sandboxLib.profiles;
      in {
        packages =
          profilePackages
          // {
            claude-sandbox = sandboxLib.mkSandbox {
              packages = sandboxLib.profiles.base;
            };
            default = self'.packages.claude-sandbox;
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
