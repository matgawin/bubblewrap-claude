{
  pkgs,
  allowList ? [],
  port ? "56789",
  ...
}: let
  domainAcls = builtins.concatStringsSep "\n" (
    pkgs.lib.lists.imap0 (i: host: "acl allowed_domain_${toString i} dstdomain ${host}") allowList
  );

  allowRules = builtins.concatStringsSep "\n" (
    pkgs.lib.lists.imap0 (i: host: "http_access allow allowed_domain_${toString i}") allowList
  );

  squidConfig = ''
    http_port 127.0.0.1:${port}

    # Use writable directories
    pid_filename /tmp/squid.pid
    cache_dir null /tmp
    coredump_dir /tmp

    # Access control lists
    acl SSL_ports port 443
    acl CONNECT method CONNECT

    # Allowed domains
    ${domainAcls}

    # Access rules
    # Allow CONNECT to SSL ports for allowed domains
    ${allowRules}

    # Deny CONNECT to other ports
    http_access deny CONNECT !SSL_ports

    # Deny access to all other destinations
    http_access deny all

    # Disable caching
    cache deny all

    # Logging
    access_log stdio:/tmp/squid-access.log
    cache_log /tmp/squid-cache.log

    # Don't reveal proxy identity (suppress warnings)
    forwarded_for delete

    # Performance tuning
    shutdown_lifetime 3 seconds
    dns_timeout 10 seconds
    connect_timeout 30 seconds
  '';
in
  pkgs.writeText "squid.conf" squidConfig
