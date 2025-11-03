{
  config,
  lib,
  pkgs,
  ...
}: let
  description = "Server for Vintage Story, an indie sandbox adventure game";

  inherit (lib) mkIf mkOption types;
  cfg = config.mal.services.vintagestory;
in {
  options.mal.services.vintagestory = {
    enable = lib.mkEnableOption description;
    dataPath = mkOption {
      default = "/persist/vintagestory";
      description = "Data path (config and state)";
      type = types.path;
    };
    package = lib.mkPackageOption pkgs "vintagestory" {};
    port = mkOption {
      type = types.nullOr types.port;
      default = 42420;
      description = ''
        Which port to open in the firewall and listen on for socket activation.
        Must match your config file.
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
    mal.services.vintagestory.package = pkgs.vintagestory.overrideAttrs (_: rec {
      version = "1.21.5";
      src = pkgs.fetchurl {
        url = "https://cdn.vintagestory.at/gamefiles/stable/vs_client_linux-x64_${version}.tar.gz";
        hash = "sha256-dG1D2Buqht+bRyxx2ie34Z+U1bdKgi5R3w29BG/a5jg=";
      };
    });

    networking.firewall = {
      allowedTCPPorts = [cfg.port];
      allowedUDPPorts = [cfg.port];
    };
    systemd.services.vintagestory = {
      inherit description;
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      path = [
        cfg.package
        pkgs.coreutils
        pkgs.cacert
        #pkgs.strace
      ];
      confinement = {
        enable = true;
        binSh = null;
        #mode = "chroot-only"; # TODO: why does this break CoreCLR
        mode = "full-apivfs";
      };
      serviceConfig = {
        ExecStart = ''${cfg.package}/bin/vintagestory-server --dataPath "${cfg.dataPath}"'';

        Type = "simple";
        Restart = "on-failure";
        RestartSec = 3;
        SyslogIdentifier = "vintagestory";
        User = cfg.user;
        Group = cfg.group;

        BindPaths = [cfg.dataPath];
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
