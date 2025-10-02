{pkgs}: let
  systemPrompt = builtins.readFile ./sandbox-prompt.txt;
  claudeAlias = "claude -- --dangerously-skip-permissions --disallowedTools WebSearch,WebFetch --append-system-prompt ${pkgs.lib.escapeShellArg systemPrompt}";

  customBashProfile = pkgs.writeText "bash_profile" ''
    if [ -f "/tmp/claude.json" ]; then
      cp /tmp/claude.json $HOME/.claude.json
    fi

    alias claude="bunx --silent --bun -p @anthropic-ai/claude-code ${claudeAlias}"
    claude
  '';

  customBash = pkgs.writeShellScript "custom-bash" ''
    exec ${pkgs.bash}/bin/bash --rcfile ${customBashProfile} -i
  '';

  apiUrl = "https://api.anthropic.com";

  sandboxTools = with pkgs; [
    bash
    bun
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
    jq
    jujutsu
    less
    man
    nodejs
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
in {
  inherit sandboxTools;

  makeSandboxScript = extraPackages: let
    allTools = sandboxTools ++ extraPackages;
  in
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
        --bind /home/$USER/.bun /home/$USER/.bun \
        --chdir "/home/$USER/project" \
        --setenv HOME "/home/$USER" \
        --setenv TMPDIR /tmp \
        --setenv USER $USER \
        --setenv PATH "${pkgs.lib.makeBinPath allTools}" \
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
