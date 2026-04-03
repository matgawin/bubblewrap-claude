{pkgs}: let
  version = "2.1.91";

  system = pkgs.stdenv.hostPlatform.system;
  platform =
    {
      "x86_64-linux" = "linux-x64";
      "aarch64-linux" = "linux-arm64";
    }.${
      system
    } or (throw "Unsupported system: ${system}");

  hashes = {
    "linux-x64" = "sha256-AbdOGwLjMwlAs1JtL24AvzL3/Z5rOGG+amHgHP1yluY=";
    "linux-arm64" = "sha256-3duhALNS6m0Gqn4DbVr+SXSe3d0TCaSqIuRwSfr8rfk=";
  };

  claudeBinary = pkgs.fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platform}/claude";
    hash = hashes.${platform};
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "claude-code";
    inherit version;

    src = claudeBinary;

    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;

    nativeBuildInputs =
      [
        pkgs.makeBinaryWrapper
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
        pkgs.autoPatchelfHook
      ];

    buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
      pkgs.stdenv.cc.cc.lib
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp $src $out/bin/claude
      chmod +x $out/bin/claude

      wrapProgram $out/bin/claude \
        --set DISABLE_AUTOUPDATER 1 \
        --set CLAUDE_CODE_UPDATE_DISABLED 1 \
        --set ANTHROPIC_TELEMETRY_DISABLED 1

      runHook postInstall
    '';

    meta = {
      description = "Claude Code - AI-powered coding assistant";
      homepage = "https://claude.ai";
      license = pkgs.lib.licenses.unfree;
      mainProgram = "claude";
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
