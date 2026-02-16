{
  pkgs,
  allowList ? [],
  ...
}: let
  domainAcls = builtins.concatStringsSep "\n" (
    pkgs.lib.lists.imap0 (i: host: "acl allowed_domain_${toString i} dstdomain ${host}") allowList
  );

  allowRules = builtins.concatStringsSep "\n" (
    pkgs.lib.lists.imap0 (i: host: "http_access allow allowed_domain_${toString i}") allowList
  );

  squidConfig = ''
    # Use writable directories
    cache_dir null /tmp
    coredump_dir /tmp

    # Access control lists
    acl SSL_ports port 443
    acl Safe_ports port 80
    acl Safe_ports port 443
    acl CONNECT method CONNECT

    # Allowed domains
    ${domainAcls}

    # Access rules - allow access to whitelisted domains
    ${allowRules}

    # Deny all other access
    http_access deny all

    # Disable caching
    cache deny all

    # Logging
    access_log stdio:/tmp/squid-access.log squid
    cache_log stdio:/tmp/squid-cache.log

    # Custom detailed log format showing full URLs
    logformat detailed %ts.%03tu %6tr %>a %Ss/%03>Hs %<st %rm %ru %[un %Sh/%<a %mt
    access_log stdio:/tmp/squid-detailed.log detailed

    # Don't reveal proxy identity
    forwarded_for delete

    # Performance tuning
    shutdown_lifetime 3 seconds
    dns_timeout 10 seconds
    connect_timeout 30 seconds
  '';
in
  pkgs.writeText "squid.conf" squidConfig
