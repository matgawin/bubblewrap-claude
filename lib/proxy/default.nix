{
  pkgs,
  sandbox,
  allowList,
  port,
  ...
}: let
  squidConf = import ./squid.nix {
    inherit pkgs allowList port;
  };
in
  pkgs.writeShellScript "claude-sandbox-proxy" ''
    #!/usr/bin/env bash
    set -euo pipefail

    PROXY_PID=""
    cleanup() {
      if [ -n "$PROXY_PID" ]; then
        echo "Stopping proxy (PID: $PROXY_PID)..."
        kill $PROXY_PID 2>/dev/null || true
        wait $PROXY_PID 2>/dev/null || true
      fi
    }

    trap cleanup EXIT INT TERM

    echo "Starting proxy on port ${port}"
    ${pkgs.squid}/bin/squid -d -1 -N -f ${squidConf} &
    PROXY_PID=$!

    for i in {1..30}; do
      if ${pkgs.curl}/bin/curl -s http://localhost:${port}/ > /dev/null 2>&1; then
        break
      fi
      if [ $i -eq 30 ]; then
        echo "Proxy failed to start within 30 seconds"
        exit 1
      fi
      sleep 1
    done

    export HTTP_PROXY="http://localhost:${port}"
    export HTTPS_PROXY="http://localhost:${port}"
    export http_proxy="http://localhost:${port}"
    export https_proxy="http://localhost:${port}"

    "${sandbox}" "$@"
  ''
