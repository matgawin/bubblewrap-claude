{pkgs}: let
  claudePackage = pkgs.callPackage ./claude-package.nix {inherit pkgs;};
  defaultSystemPrompt = builtins.readFile ./sandbox-prompt.txt;

  disallowedTools = "WebSearch,WebFetch,Read(/nix/store/**),Bash(curl:*),Bash(wget:*)";

  customResolvConf = pkgs.writeText "resolv.conf" ''
    nameserver 192.0.2.1
  '';

  concat = first: second: first + "\n\n" + second;

  customBash = bashProfile:
    pkgs.writeShellScript "custom-bash" ''
      exec ${pkgs.bash}/bin/bash --rcfile ${bashProfile} -i
    '';

  mkCustomHosts = url: ips:
    pkgs.writeText "hosts" ''
      127.0.0.1 localhost
      ::1 localhost ip6-localhost ip6-loopback
      ${builtins.concatStringsSep "\n" (map (ip: "${ip} ${url}") ips)}
    '';
in {
  makeSandboxScript = profile: let
    args = builtins.concatStringsSep " " profile.args;
    customHosts = mkCustomHosts profile.url profile.ips;
    env =
      pkgs.lib.concatStringsSep " "
      (pkgs.lib.mapAttrsToList (k: v: "--setenv ${k} ${pkgs.lib.escapeShellArg v}") profile.env);

    packagesList = builtins.concatStringsSep "," (map (pkg: "${pkgs.lib.getName pkg}") profile.packages);
    packagePrompt = concat defaultSystemPrompt "Only these programs are available in the sandbox: ${packagesList}";

    systemPrompt = concat packagePrompt (profile.customPrompt or "");
    claudeArgs = "--dangerously-skip-permissions --disallowedTools ${pkgs.lib.escapeRegex disallowedTools} --append-system-prompt ${pkgs.lib.escapeShellArg systemPrompt}";

    customBashProfile = pkgs.writeText "bash_profile" ''
      ${pkgs.lib.optionalString (profile ? preStartHooks && builtins.length profile.preStartHooks > 0) ''
        echo "Running pre-start hook(s)..."
        ${pkgs.lib.concatStringsSep "\n" profile.preStartHooks}
        echo "Pre-start hooks completed."
      ''}

      alias claude="claude ${claudeArgs}"
      claude
    '';

    customBashScript = customBash customBashProfile;
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
        --dir /bin \
        --dir /etc/ssl \
        --dir /etc/ssl/certs \
        --ro-bind ${customResolvConf} /etc/resolv.conf \
        --ro-bind ${customHosts} /etc/hosts \
        --ro-bind ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-bundle.crt \
        --symlink /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt \
        --symlink ${pkgs.coreutils}/bin/env /usr/bin/env \
        --symlink ${pkgs.bash}/bin/bash /bin/sh \
        --ro-bind /nix /nix \
        --ro-bind /etc/passwd /etc/passwd \
        --ro-bind /etc/group /etc/group \
        --bind-try /home/$USER/.claude /home/$USER/.claude \
        --bind-try /home/$USER/.claude.json /home/$USER/.claude.json \
        ${args} \
        --bind "$PROJECT_DIR" "/home/$USER/project" \
        --chdir "/home/$USER/project" \
        --setenv HOME "/home/$USER" \
        --setenv USER $USER \
        --setenv PATH "${pkgs.lib.makeBinPath (profile.packages ++ [claudePackage])}" \
        ${env} \
        ${customBashScript}
    '';
}
