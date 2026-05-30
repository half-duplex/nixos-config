{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  inherit (flake.lib) nginxHeaders;
  cfg = config.mal.services.authelia;
in {
  options.mal.services.authelia = {
    enable = lib.mkEnableOption "Configure the authelia IDP";
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
    services.authelia.instances."sec.gd" = {
      enable = true;
      settings = let
        secretFile = path: ''{{ secret "${path}" }}'';
      in {
        theme = "auto";
        authentication_backend = {
          file = {
            path = "/persist/authelia/users.yml";
            watch = true;
            search.email = true;
            extra_attributes = {
              immich_quota_gb.value_type = "integer";
            };
          };
        };
        webauthn = {
          enable_passkey_login = true;
          experimental_enable_passkey_uv_two_factors = true;
          display_name = "sec.gd";
          metadata.enabled = true;
        };
        session = {
          name = "sso_session";
          remember_me = "3 months";
          cookies = [
            {
              domain = "sec.gd";
              authelia_url = "https://auth.sec.gd";
            }
          ];
        };
        storage = {
          local.path = "/persist/authelia/authelia.db";
        };
        notifier.filesystem.filename = "/persist/authelia/notifications.txt";
        identity_providers.oidc = {
          authorization_policies = {
            policy_name = {
              rules = [
                {
                  policy = "deny";
                  networks = [
                    "10.0.0.1"
                    "10.0.0.6"
                    "10.0.0.7"
                    "10.0.1.1"
                  ];
                }
              ];
            };
          };
          claims_policies.immich.custom_claims = {
            immich_role.attribute = "immich_role";
            immich_quota_gb.attribute = "immich_quota_gb";
          };
          scopes.immich.claims = ["immich_role" "immich_quota_gb"];
          clients = [
            {
              client_name = "Immich";
              client_id = secretFile config.sops.secrets."awen/authelia/oidc/immich/client_id".path;
              client_secret = secretFile config.sops.secrets."awen/authelia/oidc/immich/client_secret_hash".path;
              require_pkce = true;
              pkce_challenge_method = "S256";
              redirect_uris = [
                "https://photos.sec.gd/auth/login"
                "https://photos.sec.gd/auth/user-settings"
                "app.immich:///oauth-callback"
              ];
              claims_policy = "immich";
              scopes = ["openid" "profile" "email" "immich"];
              token_endpoint_auth_method = "client_secret_post";
            }
          ];
        };
        definitions = {
          network = {
            lan = ["10.0.0.0/24" "10.0.1.0/24"];
            moosevpn = ["10.11.0.0/24"];
          };
          user_attributes = {
            immich_role.expression = ''("admin" in groups || "admin.immich" in groups) ? "admin" : "user"'';
          };
        };
        server.endpoints.authz.forward-auth.implementation = "ForwardAuth";
        access_control = {
          default_policy = "deny";
          rules = [
            {
              domain = "*.sec.gd";
              networks = ["lan" "moosevpn"];
              policy = "one_factor";
            }
            {
              domain = "*.sec.gd";
              policy = "two_factor";
            }
          ];
        };
        regulation.modes = ["user" "ip"];
      };
      secrets = lib.genAttrs' [
        "sessionSecret"
        "storageEncryptionKey"
        "jwtSecret"
        "oidcHmacSecret"
        "oidcIssuerPrivateKey"
      ] (secret: lib.nameValuePair "${secret}File" config.sops.secrets."awen/authelia/${secret}".path);
    };
    systemd.services."authelia-sec.gd".serviceConfig.BindPaths = ["/persist/authelia"];
    services.nginx = lib.mkIf cfg.nginx.enable (let
      upstream = "http://localhost:9091";
      usesLegacyAuth = builtins.any (v: v.implementation == "Legacy") (lib.attrValues config.services.authelia.instances."sec.gd".settings.server.endpoints.authz);
      upstreamAuthReq = "${upstream}/api/authz/auth-request";
      autheliaAuthRequest = ''
        auth_request /internal/authelia/authz;
        auth_request_set $user $upstream_http_remote_user;
        auth_request_set $groups $upstream_http_remote_groups;
        auth_request_set $name $upstream_http_remote_name;
        auth_request_set $email $upstream_http_remote_email;
        proxy_set_header Remote-User $user;
        proxy_set_header Remote-Groups $groups;
        proxy_set_header Remote-Email $email;
        proxy_set_header Remote-Name $name;
        auth_request_set $redirection_url $upstream_http_location;
        error_page 401 =302 $redirection_url;
      '';
      autheliaLocation = {
        "/internal/authelia/authz" = {
          extraConfig = ''
            internal;
            # aoeu aoeu aoeu
            proxy_pass_request_body off;
            #proxy_next_upstream
            #proxy_redirect
            proxy_cache_bypass $cookie_session;
            proxy_no_cache $cookie_session;
            proxy_buffers 4 32k;
            #client_body_buffer_size 128k;
          '';
          proxy_pass = upstreamAuthReq;
        };
      };
    in {
      additionalModules = lib.mkIf usesLegacyAuth (with pkgs.nginxModules; [develkit set-misc]);
      virtualHosts = {
        ${cfg.nginx.hostname} = {
          onlySSL = true;
          enableACME = true;
          extraConfig = nginxHeaders {
            Content-Security-Policy = {
              style-src = "'self' 'unsafe-inline'";
            };
          };
          locations = {
            "/".proxyPass = upstream;
            "/api/authz/".proxyPass = upstream;
            "= /api/verify".proxyPass = upstream;
          };
        };
      };
    });
    sops.secrets =
      lib.genAttrs' [
        "sessionSecret"
        "storageEncryptionKey"
        "jwtSecret"
        "oidcHmacSecret"
        "oidcIssuerPrivateKey"
        "oidc/immich/client_id"
        "oidc/immich/client_secret"
        "oidc/immich/client_secret_hash"
      ] (
        secret:
          lib.nameValuePair "${config.networking.hostName}/authelia/${secret}" {
            sopsFile = secrets/${config.networking.hostName}.yaml;
            # TODO: make instance name dynamic?
            owner = config.services.authelia.instances."sec.gd".user;
            reloadUnits = ["authelia-sec.gd.service"];
          }
      );
  };
}
