{
  config,
  flake,
  inputs,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.strings) concatStringsSep;

  inherit (flake.lib) nginxHeaders;

  cfg = config.mal.services.authentik;
in {
  imports = [inputs.authentik-nix.nixosModules.default];

  options.mal.services.authentik = {
    enable = lib.mkEnableOption "Configure the authentik IDP";
    nginx = {
      enable = lib.mkOption {
        default = true;
        description = "Configure nginx as a reverse proxy";
        type = lib.types.bool;
      };
      hostname = lib.mkOption {
        default = "auth.sec.gd";
        description = "The nginx vhost to configure";
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets =
        lib.genAttrs [
          "AUTHENTIK_SECRET_KEY"
          "AUTHENTIK_EMAIL__PASSWORD"
        ] (_: {
          restartUnits = ["authentik.service"];
          sopsFile = secrets/${config.networking.hostName}.yaml;
        });
      templates."authentik.env" = {
        content = concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${v}")
          ((lib.genAttrs [
              "AUTHENTIK_SECRET_KEY"
              "AUTHENTIK_EMAIL__PASSWORD"
            ] (v: builtins.getAttr v config.sops.placeholder))
            // {
              # Default includes RFC1918 too
              AUTHENTIK_LISTEN__TRUSTED_PROXY_CIDRS = concatStringsSep "," ["127.0.0.1/32" "::1/128"];
            }));
      };
    };

    services = {
      authentik = {
        enable = true;
        environmentFile = config.sops.templates."authentik.env".path;
        nginx = {
          enable = true;
          host = "${cfg.nginx.hostname}";
        };
        settings = {
          avatars = "initials";
          disable_startup_analytics = true;
          email = {
            # TODO
          };
        };
      };
      nginx.virtualHosts = lib.mkIf cfg.nginx.enable {
        ${cfg.nginx.hostname} = {
          # proxy configured by services.authentik
          onlySSL = true;
          enableACME = lib.mkForce true; # override authentik-nix
          extraConfig = nginxHeaders {
            Content-Security-Policy = {
              connect-src = "'self'";
              font-src = "'self' data:";
              img-src = "'self' data:";
              script-src = "'self' 'unsafe-eval' 'unsafe-inline'";
              style-src = "'self' 'unsafe-inline'";
            };
          };
        };
      };
    };
  };
}
