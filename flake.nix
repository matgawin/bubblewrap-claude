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
        sandboxTools = with pkgs; [
          bash
          bat
          claude-code
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
          jujutsu
          jq
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

        claudeAlias = "${pkgs.claude-code}/bin/claude --dangerously-skip-permissions --disallowedTools WebSearch,WebFetch";
        customBashProfile = pkgs.writeText "bash_profile" ''
          if [ -f "/tmp/claude.json" ]; then
            cp /tmp/claude.json $HOME/.claude.json
          fi
          alias claude="${claudeAlias}"
          claude
        '';

        customBash = pkgs.writeShellScript "custom-bash" ''
          exec ${pkgs.bash}/bin/bash --rcfile ${customBashProfile} -i
        '';

        apiUrl = "https://api.anthropic.com";

        sandboxScript = pkgs.writeShellScript "claude-sandbox" ''
          #!/usr/bin/env bash
          set -euo pipefail

          PROJECT_DIR="$(pwd)"
          if [ $# -gt 0 ]; then
            PROJECT_DIR="$(realpath "$1")"
            if [ ! -d "$PROJECT_DIR" ]; then
              echo "Error: Directory '$1' does not exist"
              exit 1
            fi
          fi

          CLAUDE_SETTINGS=""
          if [ -f "$HOME/.claude.json" ]; then
            CLAUDE_SETTINGS="--ro-bind $HOME/.claude.json /tmp/claude.json"
          fi

          USER="$(whoami)"
          SANDBOX_NAME="bubblewrap-claude"

          echo "Starting bubblewrap sandbox in: $PROJECT_DIR"
          exec ${pkgs.bubblewrap}/bin/bwrap \
            --die-with-parent \
            --unshare-all \
            --share-net \
            --proc /proc \
            --dev /dev \
            --tmpfs /tmp \
            --dir /var \
            --dir /run \
            --dir /etc/ssl \
            --dir /etc/ssl/certs \
            --ro-bind /etc/resolv.conf /etc/resolv.conf \
            --ro-bind ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-bundle.crt \
            --symlink /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt \
            --ro-bind /nix /nix \
            --ro-bind /etc/passwd /etc/passwd \
            --ro-bind /etc/group /etc/group \
            $CLAUDE_SETTINGS \
            --bind "$PROJECT_DIR" "/home/$USER/project" \
            --chdir "/home/$USER/project" \
            --setenv HOME "/home/$USER" \
            --setenv TMPDIR /tmp \
            --setenv USER $USER \
            --setenv PATH "${pkgs.lib.makeBinPath sandboxTools}" \
            --setenv CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC "1" \
            --setenv DISABLE_AUTOUPDATER "1" \
            --setenv DISABLE_ERROR_REPORTING "1" \
            --setenv DISABLE_NON_ESSENTIAL_MODEL_CALLS "1" \
            --setenv DISABLE_TELEMETRY "1" \
            --setenv ANTHROPIC_API_URL "${apiUrl}" \
            ${customBash}
        '';
      in {
        packages.claude-sandbox = pkgs.stdenv.mkDerivation {
          name = "claude-sandbox";
          buildInputs = [pkgs.makeWrapper];
          unpackPhase = "true";
          installPhase = ''
            mkdir -p $out/bin
            cp ${sandboxScript} $out/bin/claude-sandbox
            chmod +x $out/bin/claude-sandbox
            wrapProgram $out/bin/claude-sandbox --prefix PATH : ${pkgs.lib.makeBinPath sandboxTools}
          '';
        };
        packages.default = self'.packages.claude-sandbox;

        devShells.default = pkgs.mkShell {
          buildInputs = [pkgs.bubblewrap] ++ sandboxTools;

          shellHook = ''
            echo "Bubblewrap sandbox environment loaded!"
            echo "Run 'nix run' or 'nix run .#claude-sandbox [directory]' to enter the isolated environment"
            echo "  - 'nix run' uses current directory"
            echo ""
            echo "Available commands in sandbox:"
            echo "  - Basic shell tools (bash, ls, bat, grep, etc.)"
            echo "  - Text editor (vim)"
            echo "  - Git/JJ (version control)"
            echo "  - Claude Code (AI assistant)"
          '';
        };
      };
    };
}
