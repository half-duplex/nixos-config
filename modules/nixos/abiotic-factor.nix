{
  config,
  lib,
  pkgs,
  ...
}: let
  description = "Server for Abiotic Factor, a survival crafting game";

  inherit (lib) mkIf mkOption optionalString types;
  inherit (lib.strings) escapeShellArgs;
  cfg = config.services.abiotic-factor;

  serviceName = "abiotic-factor";
  worldName = "Cascade";
in {
  options.services.abiotic-factor = with types; let
    # This is technically not the correct type. Steam IDs are u64, nix can
    # only do 2^63-1, but the first 8 bits are a "Universe" ID which is
    # currently a max of 5
    steamId = ints.unsigned;
  in {
    enable = lib.mkEnableOption description;
    dataDir = mkOption {
      type = path;
      default = "/var/run/abiotic-factor";
      description = "Directory for gameserver installation and wineprefix";
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
    openFirewall = lib.mkEnableOption "Allow the configured ports through the firewall.";
    port = mkOption {
      type = port;
      default = 7777;
      description = "Gameserver port";
    };
    queryPort = mkOption {
      type = nullOr port;
      default = null;
      description = "Query port. Purpose unclear.";
    };
    serverName = mkOption {
      type = str;
      default = "Abiotic Factor Server";
      description = "Server name (shown in server browser)";
    };
    serverPasswordFile = mkOption {
      type = nullOr str;
      default = "${cfg.dataDir}/server-password";
      description = ''
        File containing server connect password. Set to `null` to allow
        connecting without a password.
        NOTE: The password will be visible in `ps`
      '';
    };
    sessionFile = mkOption {
      type = nullOr path;
      default = "${cfg.dataDir}/session";
      description = "File to write the session shortcode to on server startup";
    };
    maxPlayers = mkOption {
      type = ints.between 1 24;
      default = 6;
      description = ''
        Maximum simultaneous player count. The official documentation
        and game warn against having more than 6 players.
      '';
    };
    moderators = mkOption {
      type = listOf steamId;
      default = [];
      description = "A list of the 64-bit numeric Steam IDs of server moderators";
      example = [76561197960287930];
    };
    bannedPlayers = mkOption {
      type = listOf steamId;
      default = [];
      description = "A list of the 64-bit numeric Steam IDs of banned players";
      example = [76561197960287930];
    };
    sandboxSettings = mkOption {
      description = ''
        Sandbox (world) options.
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
              Upon player death, what items are kept, dropped, or destroyed.
              0 = Keep all
              1 = Keep equipped & hotbar
              2 = Keep hotbar
              3 = Keep equipped
              4 = Drop all
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
    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall (
      (lib.optional (! isNull cfg.port) cfg.port)
      ++ (lib.optional (! isNull cfg.queryPort) cfg.queryPort)
    );

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
      deps = with pkgs; [
        coreutils
        steamcmd
        wine64
      ];
      abioticLogPath = "${cfg.dataDir}/game/AbioticFactor/Saved/Logs/AbioticFactor.log";
      isSet = val: val != null;
    in {
      inherit description;
      after = ["network.target"];
      wantedBy = lib.mkIf cfg.autostart ["multi-user.target"];
      confinement = {
        enable = true;
        binSh = null;
        mode = "full-apivfs";
        packages = deps;
      };
      enableStrictShellChecks = true;
      environment = {
        WINEPREFIX = "${cfg.dataDir}/wineprefix";
        WINEDEBUG = "fixme-all";
        # "explorer.exe,services.exe=d" prevents graceful shutdown...
        WINEDLLOVERRIDES = "services.exe=d";
      };
      path = deps;
      serviceConfig = {
        Type = "notify";
        #Restart = "on-failure"; # TODO: back to on-failure
        Restart = "no";
        RestartSec = 10;
        SyslogIdentifier = serviceName;
        User = cfg.user;
        Group = cfg.group;
        UMask = "0007";
        WorkingDirectory = cfg.dataDir;

        #ExitType = "cgroup"; # let wineserver etc shut down
        #KillMode = "process"; # SIGINT of wineserver causes immediate main thread death, so don't
        #KillSignal = "SIGINT"; # SIGTERM doesn't stop gracefully (no map save)
        NotifyAccess = "all";

        BindPaths = [
          cfg.dataDir
          "/run/systemd/notify" # $NOTIFY_SOCKET for systemd-notify
        ];
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
      };
      preStart = ''
        # Set null graphics driver to reduce log spam & make sure winedevice.exe exits
        wine64 cmd /c \
          'reg add HKEY_CURRENT_USER\Software\Wine\Drivers /v Graphics /t REG_SZ /d null /f'
        wineserver -k || true

        # Install the game
        systemd-notify --status="Installing/updating server content"
        steamcmd \
          +@sSteamCmdForcePlatformType windows \
          +force_install_dir "${cfg.dataDir}/game" \
          +login anonymous \
          +app_update 2857200 \
          +quit

        # Link the config files
        # I would prefer to use the command line options, but those don't
        # understand absolute paths...
        ln -sf \
          "${adminIni.outPath}" \
          "${cfg.dataDir}/game/AbioticFactor/Saved/SaveGames/Server/Admin.ini"
        ln -sf \
          "${sandboxIni.outPath}" \
          "${cfg.dataDir}/game/AbioticFactor/Saved/SaveGames/Server/Worlds/${worldName}/SandboxSettings.ini"

        rm -f "${abioticLogPath}"

        # Ensure it's gone, to avoid complaints from systemd
        wineserver -k -w || true
      '';
      script = let
        gameCmd =
          escapeShellArgs ([
              "wine64"
              "${cfg.dataDir}/game/AbioticFactor/Binaries/Win64/AbioticFactorServer-Win64-Shipping.exe"
              "-log"
              "-MaxServerPlayers=${toString cfg.maxPlayers}"
              "-PORT=${toString cfg.port}"
              "-SteamServerName=${cfg.serverName}"
              "-tcp"
              "-useperfthreads"
              "-WorldSaveName=${worldName}"
            ]
            ++ (lib.optional (isSet cfg.queryPort) "-QUERYPORT=${toString cfg.queryPort}"))
          + (optionalString (isSet cfg.serverPasswordFile) " -ServerPassword=\"$(cat ${cfg.serverPasswordFile})\"")
          + (optionalString (isSet cfg.extraArgs) (" " + cfg.extraArgs));
      in ''
        report_status() {
          systemd-notify --status="Waiting for server to start"

          session_file="${toString cfg.sessionFile}"
          running=0
          session=""
          tail -F "${abioticLogPath}" 2>/dev/null \
            | while IFS= read -r fullline ; do
              line="$(expr "$fullline" : '\[[0-9:.-]*\]\[ *[0-9]*\]\(.*\)')" || true
              case "$line" in
                "LogInit: Display: Engine is initialized."*)
                  [ "$running" -eq 1 ] && continue
                  systemd-notify --ready
                  [ -n "$session" ] && return
                  running=1
                  ;;
                "LogAbiotic: Warning: Session short code: "*)
                  session="$(expr "$line" : '.*Session short code: \([A-Z0-9]*\)')"
                  systemd-notify --status "Running - Session shortcode: $session"
                  [ -n "$session_file" ] && echo "$session" >"$session_file"
                  [ "$running" -eq 1 ] && return
                  ;;
              esac
            done || true
        }

        report_status &
        exec ${gameCmd}
      '';
      preStop = ''
        systemd-notify --status=""
        if [ -n "$MAINPID" ] ; then
          kill -s INT "$MAINPID"
          tail -f --pid="$MAINPID"
        fi
        wineserver -k -w || true
      '';
      postStop = ''rm -f "${cfg.sessionFile}"'';
    };
    systemd.tmpfiles.settings.${serviceName}.${cfg.dataDir}.d = {
      user = cfg.user;
      group = cfg.group;
      mode = "0750";
    };
    users.users = mkIf (cfg.user == "abiotic") {
      abiotic = {
        group = cfg.group;
        home = cfg.dataDir;
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
