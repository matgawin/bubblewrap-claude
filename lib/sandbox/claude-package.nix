{pkgs}: let
  version = "2.0.35";
  claudeCodeTarball = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-WTbUW++l0ZyfD5OTM90e+lKIWAGCYJ7vDmDBXN0TtOw=";
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "claude-code";
    inherit version;
    src = claudeCodeTarball;
    nativeBuildInputs = with pkgs; [nodejs];
    meta = {
      description = "Claude Code";
      homepage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
      license = pkgs.lib.licenses.unfree;
      mainProgram = "claude";
    };

    unpackPhase = ''
      runHook preUnpack
      tar -xzf $src --strip-components=1
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib
      cp -r . $out/lib/

      cat > $out/bin/claude << 'EOF'
      #!/usr/bin/env bash
      exec ${pkgs.nodejs}/bin/node "$(dirname "$0")/../lib/cli.js" "$@"
      EOF
      chmod +x $out/bin/claude

      runHook postInstall
    '';
  }
