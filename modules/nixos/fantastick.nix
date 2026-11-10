{
  config,
  lib,
  pkgs,
  ...
}: let
  description = "Fantastick, a discord bot for using custom stickers";

  inherit (lib) mkIf mkOption types;
  cfg = config.services.fantastick;
in {
  options.services.fantastick = {
    enable = lib.mkEnableOption description;
    createDatabase = lib.mkEnableOption ''
      Configure postgresql automatically. If false, you must add DATABASE_URL
      to the environment or envFile.
    '';
    dataDir = mkOption {
      default = "/opt/fantastick";
      description = "Data path (config and state)";
      type = types.path;
    };
    environment = lib.mkOption {
      default = {};
      description = "Non-sensitive service environment variables.";
      type = types.submodule {freeformType = types.attrsOf types.str;};
    };
    envFile = mkOption {
      description = "Environment file containing sensitive environment variables.";
      type = types.path;
    };
    package = lib.mkPackageOption pkgs "fantastick" {};
    user = mkOption {
      type = types.str;
      default = "fantastick";
      description = "The user fantastick should run under.";
    };
    group = mkOption {
      type = types.str;
      default = "fantastick";
      description = "The group fantastick should run under.";
    };
  };

  config = let
    deps = with pkgs; [
      cfg.package
      chromium
      ffmpeg
      prisma
    ];
    baseService = {
      after = ["network.target" "postgresql.target"];
      confinement = {
        enable = true;
        binSh = null;
        mode = "chroot-only";
        packages = deps;
      };
      path = deps;
      environment =
        {
          LOCAL = "true"; # be "a local version" instead of crashing when it can't find git info
          # Must specify /db else prisma defaults to `postgres`
          # Must specify ?host= or implicit auth doesn't work
          # Must specify user and localhost too or prisma breaks
          DATABASE_URL = lib.mkIf cfg.createDatabase "postgresql://fantastick@localhost/fantastick?host=/var/run/postgresql&schema=public";
          UA_STRING = "A Nix user's gh:WentTheFox/Fantastick";
          PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
          # Use nixpkgs prisma
          PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
          PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/query-engine";
          PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines}/lib/libquery_engine.node";
          PRISMA_FMT_BINARY = "${pkgs.prisma-engines}/bin/prisma-fmt";
        }
        // cfg.environment;
      preStart = ''
        ln -sf "${cfg.package}/src" "${cfg.dataDir}/" # for locales

        #cd "${cfg.package}"
        prisma migrate deploy \
          --config "${cfg.package}/prisma.config.ts" \
          --schema "${cfg.package}/prisma/schema.prisma"
      '';
      serviceConfig = {
        WorkingDirectory = cfg.dataDir;
        EnvironmentFile = cfg.envFile;

        Type = "simple";
        Restart = "on-failure";
        RestartSec = 3;
        User = cfg.user;
        Group = cfg.group;

        BindPaths =
          [cfg.dataDir]
          ++ (lib.lists.optional cfg.createDatabase "/var/run/postgresql");
        BindReadOnlyPaths = [
          "/etc/resolv.conf"
          "/etc/ssl/certs/ca-certificates.crt"
        ];
        CapabilityBoundingSet = "";
        LockPersonality = true;
        #MemoryDenyWriteExecute = true; # node...
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        #PrivateUsers = true; # ?
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectProc = "noaccess";
        ProtectSystem = "strict";
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
        SystemCallFilter = ["@system-service" "~@privileged"];
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };
  in
    mkIf cfg.enable {
      systemd.services.fantastick = lib.recursiveUpdate baseService {
        inherit description;
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = ''${pkgs.nodejs}/bin/node --enable-source-maps "${cfg.package}/build/src/index.js"'';
          SyslogIdentifier = "fantastick";
        };
      };
      systemd.services.fantastick-worker = lib.recursiveUpdate baseService {
        description = description + " - Queue Worker";
        wantedBy = ["fantastick.service"];
        serviceConfig = {
          ExecStart = ''${pkgs.nodejs}/bin/node --enable-source-maps "${cfg.package}/build/src/queue-worker.js"'';
          SyslogIdentifier = "fantastick-worker";
        };
      };
      systemd.tmpfiles.settings.fantastick."${cfg.dataDir}".d = {
        user = cfg.user;
        group = cfg.group;
        mode = "0750";
      };
      users.users = mkIf (cfg.user == "fantastick") {
        fantastick = {
          group = cfg.group;
          isSystemUser = true;
        };
      };
      users.groups = mkIf (cfg.group == "fantastick") {${cfg.group} = {};};

      services.postgresql = lib.mkIf cfg.createDatabase {
        enable = true;
        ensureDatabases = ["fantastick"];
        ensureUsers = [
          {
            name = "fantastick";
            ensureDBOwnership = true;
          }
        ];
      };
    };
}
