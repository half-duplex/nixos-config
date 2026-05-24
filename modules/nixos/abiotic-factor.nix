{
  config,
  lib,
  pkgs,
  ...
}: let
  description = "Server for Abiotic Factor, a survival crafting game";

  inherit (lib) mkIf mkOption types;
  inherit (lib.strings) escapeShellArg escapeShellArgs;
  cfg = config.mal.services.abiotic-factor;

  serviceName = "abiotic-factor";
in {
  options.mal.services.abiotic-factor = with types; {
    enable = lib.mkEnableOption description;
    directory = mkOption {
      type = path;
      default = "/persist/abiotic-factor";
      description = "Installation directory";
    };
    user = mkOption {
      type = str;
      default = "abiotic";
      description = "The user the server should run as";
    };
    group = mkOption {
      type = str;
      default = "abiotic";
      description = "The group the server should run as";
    };
    addGroupManagementPolicy = lib.mkEnableOption ''
      Add polkit and sudoers rules to allow users in the service's group to
      restart the service and view its logs
    '';
    autostart = lib.mkEnableOption "Automatically start the gameserver";
    port = mkOption {
      type = port;
      default = 7777;
      description = "Game port";
    };
    queryPort = mkOption {
      type = nullOr port;
      default = null;
      description = "Query port. Purpose unclear.";
    };
    serverName = mkOption {
      type = str;
      default = "Abiotic Factor Server";
      description = "Server name";
    };
    serverPasswordFile = mkOption {
      type = str;
      default = "${cfg.directory}/server-password";
      description = ''
        File containing server connect password.
        NOTE: The password will be visible in `ps`
      '';
    };
    maxPlayers = mkOption {
      type = ints.between 1 24;
      default = 6;
      description = ''
        Maximum simultaneous player count. The official documentation
        and game warn against player counts above 6.
      '';
    };
    moderators = mkOption {
      # This is technically not the correct type. Steam IDs are u64, nix can
      # only do 2^63-1, but the first 8 bits are a "Universe" ID which is
      # currently a max of 5
      type = listOf ints.unsigned;
      default = [];
      description = "A list of the 64-bit numeric Steam IDs of server moderators";
      example = [76561197960287930];
    };
    bannedPlayers = mkOption {
      type = listOf ints.unsigned;
      default = [];
      description = "A list of the 64-bit numeric Steam IDs of banned players";
      example = [76561197960287930];
    };
    sandboxSettings = mkOption {
      description = ''
        Additional sandbox (world) options.
        Documentation: https://github.com/DFJacob/AbioticFactorDedicatedServer/wiki/Technical-%E2%80%90-Sandbox-Options
      '';
      default = {};
      type = submodule {
        freeformType = attrsOf anything;
        options = {
          GameDifficulty = mkOption {
            type = ints.between 1 3;
            description = ''
              Game difficulty. Affects enemy count, aggression, and reaction time.
              1 = Normal, 2 = Hard, 3 = Apocalyptic
            '';
            default = 1;
          };
          DeathPenalties = mkOption {
            type = ints.between 0 5;
            description = ''
              What players keep and lose upon death.
              0 = Keep all
              1 = Keep equipped & hotbar
              2 = Keep hotbar
              3 = Keep equipped
              4 = Lose all
              5 = Destroy all
            '';
            default = 1;
          };
        };
      };
    };
    extraArgs = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        Additional command line arguments added to the gameserver command unsanitized.
        Documentation: https://github.com/DFJacob/AbioticFactorDedicatedServer/wiki/Technical-%E2%80%90-Launch-Parameters
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedUDPPorts =
      (lib.optional (! isNull cfg.port) cfg.port)
      ++ (lib.optional (! isNull cfg.queryPort) cfg.queryPort);

    systemd.services.${serviceName} = let
      adminIni = pkgs.writeText "abiotic-factor-Admin.ini" (
        lib.generators.toINI {listsAsDuplicateKeys = true;} {
          Moderators.Moderator = cfg.moderators;
          BannedPlayers.BannedPlayer = cfg.bannedPlayers;
        }
      );
      sandboxIni = pkgs.writeText "abiotic-factor-SandboxSettings.ini" (
        lib.generators.toINI {} {SandboxSettings = cfg.sandboxSettings;}
      );
      worldName = "Cascade";
      winePkg = pkgs.wine64;
    in {
      inherit description;
      after = ["network.target"];
      wantedBy = lib.mkIf cfg.autostart ["multi-user.target"];
      confinement = {
        enable = true;
        binSh = null;
        mode = "full-apivfs";
        packages = with pkgs; [
          coreutils
          wine64
          steamcmd
        ];
      };
      environment = {
        WINEPREFIX = "${cfg.directory}/wineprefix";
        WINEDEBUG = "fixme-all";
      };
      #path = with pkgs; [
      #  coreutils
      #  wine64
      #];
      serviceConfig = {
        Type = "simple";
        #Restart = "on-failure";
        Restart = "no";
        RestartSec = 10;
        SyslogIdentifier = serviceName;
        User = cfg.user;
        Group = cfg.group;

        BindPaths = [cfg.directory];
        BindReadOnlyPaths = [
          "/etc/resolv.conf"
          "/etc/ssl/certs/ca-certificates.crt"
        ];
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MountAPIVFS = false;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectProc = "invisible";
        ProtectSystem = true;
        RemoveIPC = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];
        RestrictNamespaces = ["user" "mnt" "net"];
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = ["native" "x86"];
        SystemCallFilter = ["@system-service" "~@privileged" "capset" "@mount"];

        UMask = "0007";
        WorkingDirectory = cfg.directory;
        ExecStartPre = [
          # Set null graphics driver
          # If this isn't done, winedevice.exe runs until systemd times out and kills it
          (escapeShellArgs [
            "${winePkg}/bin/wine64"
            "cmd"
            "/c"
            ''reg add HKEY_CURRENT_USER\\Software\\Wine\\Drivers /v Graphics /t REG_SZ /d null /f''
          ])
          # Install the game
          (escapeShellArgs [
            "${pkgs.steamcmd}/bin/steamcmd"
            "+@sSteamCmdForcePlatformType"
            "windows"
            "+force_install_dir"
            "${cfg.directory}/game"
            "+login"
            "anonymous"
            "+app_update"
            "2857200"
            "+quit"
          ])
          # Link the config files
          # I would prefer to use the command line options, but those don't
          # understand absolute paths...
          (escapeShellArgs [
            "${pkgs.coreutils}/bin/ln"
            "-sf"
            adminIni.outPath
            "${cfg.directory}/game/AbioticFactor/Saved/SaveGames/Server/Admin.ini"
          ])
          (escapeShellArgs [
            "${pkgs.coreutils}/bin/ln"
            "-sf"
            sandboxIni.outPath
            "${cfg.directory}/game/AbioticFactor/Saved/SaveGames/Server/Worlds/${worldName}/SandboxSettings.ini"
          ])
        ];
        ExecStop = (lib.escapeShellArg "${pkgs.coreutils}/bin/kill") + " -s INT \"$MAINPID\"";
        ExecStopPost = escapeShellArgs ["-${winePkg}/bin/wineserver" "-k" "-w"];
      };
      script =
        ''
          SERVER_PASSWORD="$(cat ${cfg.serverPasswordFile})"
        ''
        + (
          lib.strings.escapeShellArgs (
            [
              "exec"
              "${winePkg}/bin/wine64"
              "${cfg.directory}/game/AbioticFactor/Binaries/Win64/AbioticFactorServer-Win64-Shipping.exe"
              "-log"
              "-MaxServerPlayers=${toString cfg.maxPlayers}"
              "-PORT=${toString cfg.port}"
              "-SteamServerName=${cfg.serverName}"
              "-tcp"
              "-useperfthreads"
              "-WorldSaveName=${worldName}"
            ]
            ++ (lib.optional (! isNull cfg.queryPort) "-QUERYPORT=${toString cfg.queryPort}")
          )
        )
        + (lib.optionalString (! isNull cfg.serverPasswordFile) " -ServerPassword=\"$SERVER_PASSWORD\"")
        + (lib.optionalString (! isNull cfg.extraArgs) (" " + cfg.extraArgs));
    };
    systemd.tmpfiles.settings.${serviceName}.${cfg.directory}.d = {
      user = cfg.user;
      group = cfg.group;
      mode = "0750";
    };
    users.users = mkIf (cfg.user == "abiotic") {
      abiotic = {
        group = cfg.group;
        home = cfg.directory;
        isSystemUser = true;
      };
    };
    users.groups = mkIf (cfg.group == "abiotic") {${cfg.group} = {};};

    security.polkit.extraConfig = mkIf cfg.addGroupManagementPolicy ''
      polkit.addRule(function(action, subject) {
        if (
          action.id === "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") === "${serviceName}.service" &&
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
            command = "/run/current-system/sw/bin/journalctl -u ${serviceName}.service ${args}";
          }) ["" "-f"];
        }
      ];
    };
  };
}
