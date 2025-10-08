{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  description = "Server for Vintage Story, an indie sandbox adventure game";

  inherit (lib) mkIf mkOption types;
  cfg = config.${namespace}.services.vintagestory;
in {
  options.${namespace}.services.vintagestory = {
    enable = lib.mkEnableOption description;
    dataPath = mkOption {
      default = "/persist/vintagestory";
      description = "Data path (config and state)";
      type = types.path;
    };
    package = lib.mkPackageOption pkgs "vintagestory" {};
    #config = mkOption {
    #  default = {};
    #  description = ''
    #    Configuration for the Vintage Story server.
    #    See <https://wiki.vintagestory.at/Special:MyLanguage/Server_Config>
    #  '';
    #  type = types.submodule {
    #    freeformType = settingsFormat.type;
    #    options = {
    #      port = mkOption {
    #        type = types.port;
    #        default = 42420;
    #        description = "Which port the server will listen on";
    #      };
    #      ServerIdentifier = mkOption {
    #        type = types.nullOr (types.strMatching "^[a-z0-9]{8}(-[a-z0-9]{4}){3}-[a-z0-9]{12}$");
    #        default = null;
    #        description = "A UUID generated for this server, or null";
    #      };
    #    };
    #  };
    #};
    firewallPort = mkOption {
      type = types.nullOr types.port;
      default = 42420;
      description = "Which port to open for the server. Should match your config file.";
    };
    user = mkOption {
      type = types.str;
      default = "vintagestory";
      description = "The user the Vintage Story server should run as.";
    };
    group = mkOption {
      type = types.str;
      default = "vintagestory";
      description = "The group the Vintage Story server should run as.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.vintagestory-server = {
      inherit description;
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      path = [cfg.package pkgs.strace];
      confinement = {
        enable = true;
        binSh = null;
        #mode = "chroot-only";
        mode = "full-apivfs";
      };
      #environment = {"COMPlus_EnableDiagnostics" = "0";};
      serviceConfig = {
        #ExecStart = ''${pkgs.strace}/bin/strace -f -- ${cfg.package}/bin/vintagestory-server --dataPath "${cfg.dataPath}"'';
        ExecStart = ''${cfg.package}/bin/vintagestory-server --dataPath "${cfg.dataPath}"'';

        Type = "simple";
        Restart = "on-failure";
        RestartSec = 3;
        SyslogIdentifier = "vintagestory";
        User = cfg.user;
        Group = cfg.group;

        BindPaths = [cfg.dataPath];
        ##BindReadOnlyPaths = ["/etc/resolv.conf"];
        #CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        #MountAPIVFS = false;
        NoNewPrivileges = true;
        PrivateTmp = true;
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
        #SystemCallFilter = ["@system-service" "~@privileged"];
        SystemCallArchitectures = "native";
        UMask = "0027";
      };
    };
    systemd.tmpfiles.settings.vintagestory."${cfg.dataPath}".d = {
      user = cfg.user;
      group = cfg.group;
      mode = "0750";
    };
    users.users = mkIf (cfg.user == "vintagestory") {
      vintagestory = {
        group = cfg.group;
        isSystemUser = true;
      };
    };
    users.groups = mkIf (cfg.group == "vintagestory") {${cfg.group} = {};};
  };
}
