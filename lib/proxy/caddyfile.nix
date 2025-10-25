{
  pkgs,
  allowList ? [],
  port ? "56789",
  ...
}: let
  hostHandlers = builtins.concatStringsSep "\n\n" (map (host: ''
      @${host} host ${host}
      handle @${host} {
          reverse_proxy https://${host} {
              header_up Host ${host}
          }
      }
    '')
    allowList);
  caddyfileContent = ''
    {
        auto_https off
        log {
            output file /tmp/caddy.log
        }
    }

    :${port} {
        ${hostHandlers}
        respond "Access Denied" 403
    }
  '';
in
  pkgs.runCommand "Caddyfile" {} ''
    echo '${caddyfileContent}' | ${pkgs.caddy}/bin/caddy fmt - > $out
  ''
