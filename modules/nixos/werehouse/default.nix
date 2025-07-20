{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.lists) toList;
  inherit (lib.strings) concatStringsSep toJSON;

  cfg = config.${namespace}.services.werehouse;
  impermanent = config.${namespace}.impermanence.enable;
in {
  options.${namespace}.services.werehouse = {
    enable = lib.mkOption {
      default = false;
      description = "Configure the werehouse art archival service";
      type = lib.types.bool;
    };
    domain = lib.mkOption {
      description = "The domain werehouse will be accessible on";
      type = lib.types.str;
    };
    dataDir = lib.mkOption {
      default = "/persist/werehouse";
      description = "The data storage directory for werehouse";
      type = lib.types.path;
    };
  };

  config = mkIf cfg.enable {
    systemd.services.werehouse = {
      confinement = {
        enable = true;
        binSh = null;
        mode = "chroot-only";
      };
      serviceConfig = {
        # `systemd-analyze security` is a miserable pile of lies that does
        # not understand that when using RootDirectory (via confinement) and
        # MountAPIVFS=false, the following (and likely others) interact badly
        # and *soften* the sandboxing rather than *harden* it.
        #  PrivateDevices ProtectControlGroups ProtectKernelTunables ProtectProc
        #  ProtectSystem ProcSubset
        # Others do nothing but are left because why not

        BindPaths = [(cfg.dataDir + ":/werehouse")];
        BindReadOnlyPaths = ["/etc/resolv.conf"];
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        MountAPIVFS = false;
        NoNewPrivileges = true;
        PrivateTmp = true;
        #PrivateUsers = true; # breaks without MountAPIVFS=true...??
        ProtectClock = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6"]; # "AF_UNIX" "AF_NETLINK"];
        SystemCallFilter = ["@system-service" "~@privileged"];
        SystemCallArchitectures = "native";
        UMask = "0077";

        EnvironmentFile = config.sops.secrets."werehouse.env".path;
      };
    };

    services.werehouse = {
      enable = true;
      dataDir = "/werehouse";
      verboseLevel = 1;
      enableNginxVhost = true;
      publicDomainName = cfg.domain;
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      # proxy configured by services.werehouse
      basicAuthFile = "/persist/rutorrent/htpasswd";
      onlySSL = true;
      extraConfig = ''access_log /var/log/nginx/artchive.log;'';
    };

    sops.secrets."werehouse.env" = {
      sopsFile = secrets/${config.networking.hostName}.yaml;
    };
  };
}
