{pkgs}: let
  version = "2.0.5";
  claudeCodeTarball = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-vT+Csqi3vtAbQam6p2qzefBycFDkUO+k5EdHHcCPT2k=";
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "claude-code";
    inherit version;
    src = claudeCodeTarball;
    nativeBuildInputs = with pkgs; [nodejs];

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
