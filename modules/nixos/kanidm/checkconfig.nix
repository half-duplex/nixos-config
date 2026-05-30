# Check Kanidm config at build time
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.kanidm;

  clientConfigFile = config.environment.etc."kanidm/config".source;
  serverConfigFile = config.environment.etc."kanidm/server.toml".source;

  checkClientConfig = pkgs.runCommand "kanidm-client-checkconfig" {} ''
    ${cfg.package}/bin/kanidm_unixd --configtest -c "${clientConfigFile}" -u /dev/null
    touch "$out"
  '';
  checkServerConfig = pkgs.runCommand "kanidm-server-checkconfig" {} ''
    # We can only check syntax during build, other problems will be shown on service start
    TEMP="$(mktemp -dt kanidm-server-checkconfig.XXXXXXXX)"
    export \
      KANIDM_ADMIN_BIND_PATH="$TEMP/sock" \
      KANIDM_DB_PATH="$TEMP/db" \
      KANIDM_ONLINE_BACKUP_PATH="$TEMP/backup" \
      KANIDM_TLS_CHAIN="$TEMP/cert.pem" \
      KANIDM_TLS_KEY="$TEMP/key.pem"
    ${cfg.package}/bin/kanidmd cert-generate -c "${serverConfigFile}"

    ${cfg.package}/bin/kanidmd configtest -c "${serverConfigFile}" >/dev/null

    rm -rf "$TEMP"
    touch "$out"
  '';
in {
  options.services.kanidm = let
    inherit (lib) mkOption types;
  in {
    client.checkConfig = mkOption {
      type = types.bool;
      default = true;
      description = "Check the syntax of the generated config file at build time";
    };
    server.checkConfig = mkOption {
      type = types.bool;
      default = true;
      description = "Check the syntax of the generated config file at build time";
    };
    # unix: probably need to mock/override the home dir
  };

  config.system.checks =
    lib.optional (
      cfg.client.enable && cfg.client.checkConfig && pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform
    )
    checkClientConfig
    ++ lib.optional (
      cfg.server.enable && cfg.server.checkConfig && pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform
    )
    checkServerConfig;
}
