{pkgs}:
pkgs.stdenv.mkDerivation rec {
  pname = "claude-code";
  version = "2.0.5";
  src = ./.;
  doCheck = false;
  dontFixup = true;
  buildInputs = with pkgs; [bun];
  buildPhase = ''
    runHook preBuild
    bun add @anthropic-ai/claude-code@${version} -E
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r node_modules $out/

    cat > $out/bin/claude << 'EOF'
    #!/usr/bin/env bash
    exec bun --bun run "$(dirname "$0")/../node_modules/@anthropic-ai/claude-code/cli.js" "$@"
    EOF
    chmod +x $out/bin/claude
  '';
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "sha256-rRiRu1nPJYsvblLIRyzrTMck3xl21gIA9OmRcqe132s=";
}
