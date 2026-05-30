# ACME for Kanidm
# https://github.com/NixOS/nixpkgs/issues/326206
{
  config,
  lib,
  pkgs,
  ...
}: let
  nsCfg = config.mal.services.kanidm;
  cfg = config.services.kanidm.server;
  acmeDir = config.security.acme.certs.${nsCfg.hostname}.directory;
in {
  options.services.kanidm.server.enableACME =
    lib.mkEnableOption "Use ACME to request a certificate for Kanidm";

  config = lib.mkIf cfg.enableACME {
    security.acme.certs.${nsCfg.hostname}.reloadServices = ["kanidm.service"];

    # Other modules add the service to the `acme` group, but there's no reason
    # to have access to other certs. Could use file group, but nginx wants that.
    # certs.<name>.postRun only runs post-renewal, we need this after kanidm is enabled
    systemd.services."acme-order-renew-${nsCfg.hostname}".postStart = ''
      ${pkgs.acl}/bin/setfacl -m u:kanidm:x "${acmeDir}"
      ${pkgs.acl}/bin/setfacl -m u:kanidm:r "${acmeDir}"/{fullchain,key}.pem
    '';

    services.kanidm.server.settings = {
      tls_chain = acmeDir + "/fullchain.pem";
      tls_key = acmeDir + "/key.pem";
    };

    systemd.services.kanidm = {
      unitConfig.After = ["acme-${nsCfg.hostname}.service"];
    };
  };
}
