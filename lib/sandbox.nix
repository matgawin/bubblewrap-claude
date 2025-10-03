{pkgs}: let
  claudePackage = pkgs.callPackage ./claude-package.nix {inherit pkgs;};
  systemPrompt = builtins.readFile ./sandbox-prompt.txt;

  disallowedTools = "WebSearch,WebFetch,Read(/nix/store/**),Bash(curl:*),Bash(wget:*)";
  claudeArgs = "--dangerously-skip-permissions --disallowedTools ${pkgs.lib.escapeRegex disallowedTools} --append-system-prompt ${pkgs.lib.escapeShellArg systemPrompt}";

  customBashProfile = pkgs.writeText "bash_profile" ''
    alias claude="claude ${claudeArgs}"
    claude
  '';

  customBash = pkgs.writeShellScript "custom-bash" ''
    exec ${pkgs.bash}/bin/bash --rcfile ${customBashProfile} -i
  '';

  apiUrl = "https://api.anthropic.com";
in {
  makeSandboxScript = packages:
    pkgs.writeShellScript "claude-sandbox" ''
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
      if [ -d "/home/$USER/.claude" ]; then
        CLAUDE_SETTINGS="--bind /home/$USER/.claude /home/$USER/.claude"
      fi
      if [ -f "/home/$USER/.claude.json" ]; then
        CLAUDE_SETTINGS="$CLAUDE_SETTINGS --bind /home/$USER/.claude.json /home/$USER/.claude.json"
      fi

      USER="$(whoami)"

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
        --dir /usr/bin \
        --dir /etc/ssl \
        --dir /etc/ssl/certs \
        --ro-bind /etc/resolv.conf /etc/resolv.conf \
        --ro-bind ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-bundle.crt \
        --symlink /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt \
        --symlink ${pkgs.coreutils}/bin/env /usr/bin/env \
        --ro-bind /nix /nix \
        --ro-bind /etc/passwd /etc/passwd \
        --ro-bind /etc/group /etc/group \
        $CLAUDE_SETTINGS \
        --bind "$PROJECT_DIR" "/home/$USER/project" \
        --chdir "/home/$USER/project" \
        --setenv HOME "/home/$USER" \
        --setenv TMPDIR /tmp \
        --setenv USER $USER \
        --setenv PATH "${pkgs.lib.makeBinPath (packages ++ [claudePackage])}" \
        --setenv SHELL "${pkgs.bash}/bin/bash" \
        --setenv CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC "1" \
        --setenv DISABLE_AUTOUPDATER "1" \
        --setenv DISABLE_ERROR_REPORTING "1" \
        --setenv DISABLE_NON_ESSENTIAL_MODEL_CALLS "1" \
        --setenv DISABLE_TELEMETRY "1" \
        --setenv ANTHROPIC_API_URL "${apiUrl}" \
        ${customBash}
    '';
}
