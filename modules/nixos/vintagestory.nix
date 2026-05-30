{
  config,
  lib,
  pkgs,
  ...
}: let
  description = "Server for Vintage Story, an indie sandbox adventure game";

  inherit (lib) mkIf mkOption types;
  cfg = config.services.vintagestory;
in {
  options.services.vintagestory = {
    enable = lib.mkEnableOption description;
    dataDir = mkOption {
      default = "/opt/vintagestory";
      description = "Data path (config and state)";
      type = types.path;
    };
    autostart = mkOption {
      default = true;
      description = "Automatically start the gameserver";
      type = types.bool;
    };
    openFirewall = mkOption {
      default = true;
      description = "Allow the configured port through the firewall";
      type = types.bool;
    };
    package = lib.mkPackageOption pkgs "vintagestory" {};
    port = mkOption {
      type = types.nullOr types.port;
      default = 42420;
      description = ''
        Which port to open in the firewall and listen on for socket activation.
        Must match your config file!
      '';
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
    addGroupManagementPolicy = lib.mkEnableOption ''
      Add polkit and sudoers rules to allow users in the service's group to
      restart the service and view its logs
    '';
  };

  config = mkIf cfg.enable {
    networking.firewall = mkIf (cfg.port != null && cfg.openFirewall) {
      allowedTCPPorts = [cfg.port];
      allowedUDPPorts = [cfg.port];
    };
    systemd.services.vintagestory = let
      deps = [cfg.package];
    in {
      inherit description;
      after = ["network.target"];
      wantedBy = lib.mkIf cfg.autostart ["multi-user.target"];
      confinement = {
        enable = true;
        binSh = null;
        mode = "full-apivfs"; # chroot-only breaks CoreCLR
        packages = deps;
      };
      path = deps;
      serviceConfig = {
        ExecStart = ''${cfg.package}/bin/vintagestory-server --dataPath "${cfg.dataDir}"'';

        Type = "simple";
        Restart = "on-failure";
        RestartSec = 3;
        SyslogIdentifier = "vintagestory";
        User = cfg.user;
        Group = cfg.group;

        BindPaths = [cfg.dataDir];
        BindReadOnlyPaths = [
          "/etc/resolv.conf"
          "/etc/ssl/certs/ca-bundle.crt"
          "/etc/passwd" # it really wants to get the user info itself
        ];
        CapabilityBoundingSet = "";
        LockPersonality = true;
        #MemoryDenyWriteExecute = true; # dotnet...
        MountAPIVFS = false;
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
        RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
        SystemCallFilter = ["@system-service" "~@privileged"];
        SystemCallArchitectures = "native";
        UMask = "0007";
      };
    };
    systemd.tmpfiles.settings.vintagestory."${cfg.dataDir}".d = {
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

    security.polkit.extraConfig = mkIf cfg.addGroupManagementPolicy ''
      polkit.addRule(function(action, subject) {
        if (
          action.id === "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") === "vintagestory.service" &&
          subject.isInGroup("${cfg.group}")
        ) {
          const verb = action.lookup("verb");
          if (verb === "start" || verb === "stop" || verb === "restart") {
            return polkit.Result.YES;
          }
        }
      });
    '';
    security.sudo = mkIf cfg.addGroupManagementPolicy {
      execWheelOnly = false;
      extraRules = [
        {
          groups = [cfg.group];
          commands = map (args: {
            options = ["NOPASSWD"];
            command = "/run/current-system/sw/bin/journalctl -u vintagestory.service ${args}";
          }) ["" "-f"];
        }
      ];
    };
  };
}
