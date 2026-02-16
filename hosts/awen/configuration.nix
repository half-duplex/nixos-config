{
  config,
  flake,
  hostName,
  lib,
  modulesPath,
  perSystem,
  pkgs,
  ...
}: let
  inherit (flake.lib) nginxHeaders;
in {
  imports = with flake.modules.nixos; [
    (modulesPath + "/installer/scan/not-detected.nix")
    base
    cli

    authentik
    frigate
    immich
    navidrome
    rtorrent
    samba
    ups
    vintagestory
    werehouse

    ./backup-repo.nix
    #./frigate.nix
  ];

  mal = {
    hardware = "physical";
    nix-cache.serve.enable = true;
    services = {
      authentik.enable = true;
      frigate = {
        enable = true;
        hostname = "panopticon.sec.gd";
        settings = {
          mqtt = {
            host = "[::1]";
            user = "frigate";
            password = "{FRIGATE_MQTT_PASSWORD}";
          };
          cameras = {
            wyze = {
              enabled = true;
              live = {stream_name = "wyze";};
              ffmpeg.inputs = [
                {
                  path = "rtsp://[::1]:8554/wyze";
                  roles = ["detect"];
                }
                {
                  path = "rtsp://[::1]:8554/wyze_hd";
                  roles = ["record"];
                }
              ];
              detect.enabled = true;
              record.enabled = true;
              motion.enabled = true;
            };
          };
          go2rtc.streams = {
            wyze = "rtsp://\${cam_wyze}/sd";
            wyze_hd = "rtsp://\${cam_wyze}/hd";
          };
        };
        secrets = ["cam_wyze"];
      };
      immich.enable = true;
      navidrome.enable = true;
      nut = {
        enable = true;
        localCyberPower = true;
        users.hass.passwordFile = config.sops.secrets."nut_password_hass".path;
      };
      rtorrent = {
        enable = true;
        port = 41519;
      };
      rutorrent.enable = true;
      flood.enable = true;
      samba = {
        enable = true;
        discoverable = true;
        interface = "br0";
      };
      vintagestory = {
        enable = true;
        addGroupManagementPolicy = true;
      };
      werehouse = {
        enable = true;
        hostname = "artchive.sec.gd";
      };
    };
  };

  boot.kernelParams = ["ip=10.0.0.6::10.0.0.1:255.255.255.0::eth0:off:10.0.0.1"];
  boot.initrd.availableKernelModules = ["nvme" "r8169"];
  console.earlySetup = true;
  hardware = {
    cpu.amd.updateMicrocode = true;
    graphics.enable = true; # enable hw video acceleration
  };

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9oQ5Cdab1hZF5LhQ8FTWdAV8QQ/S1/0krreiRzT62n mal@awdbox"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+ejh/zHzsMdmTNeNUkKgpYHBQguKi5lg1bvrpA2O+e mal@nova"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSqbI35Krvjngna/q9iuB/i9fd/u8l0q3qG3rLMEKl8 mal@t14s"
  ];
  users.users.root.openssh.authorizedKeys.keys = [
    "command=\"zrepl stdinserver awdbox\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDCo6e8qf5a3NPz55vmLKxBr0J8fiIR4AiXEZRw/lmSD root@awdbox"
    "command=\"zrepl stdinserver awen\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtpIj6zB4jeoYCWUH9jAxvTaNKfWQ7OMqTVD3lXw3Xh root@awen"
    "command=\"zrepl stdinserver t14s\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBlIAZVeRbfsFpbsoywqneHtIDvXTWv7myK5YOvnSsx7 root@t14s"
  ];

  # vintage story
  users.users.nadia = {
    isNormalUser = true;
    extraGroups = ["ssh-users" "vintagestory"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ59U5sahxc6qtBdtJuk+83Hn0pEb0V6LepQWQo63mlU"
    ];
  };

  networking = {
    inherit hostName;
    bridges.br0.interfaces = ["eth0"];
    defaultGateway = "10.0.0.1";
    interfaces = {
      br0 = {
        ipv4.addresses = [
          {
            address = "10.0.0.6";
            prefixLength = 24;
          }
        ];
        ipv6.addresses = [];
      };
      eth0.wakeOnLan.enable = true;
    };
    nameservers = [
      "10.0.0.1"
      "2001:4860:4860::8888"
      "2001:4860:4860::8844"
      "8.8.8.8"
      "8.8.4.4"
    ];
  };

  fileSystems =
    lib.foldl (a: b: a // b)
    {
      "/data" = {
        device = "/mnt/data";
        options = ["bind"];
      };
      "/mnt/data" = {
        device = "pool/data";
        fsType = "zfs";
      };
      "/mnt/data/backups" = {
        device = "pool/backups";
        fsType = "zfs";
      };
      "/mnt/data/downloads" = {
        device = "pool/downloads";
        fsType = "zfs";
      };
      "/mnt/data/immich" = {
        device = "pool/immich";
        fsType = "zfs";
      };
      "/mnt/data/nobackup" = {
        device = "pool/nobackup";
        fsType = "zfs";
      };
    }
    (lib.forEach (lib.range 1 5) (n: {
      "/mnt/crypt${toString n}" = {
        device = "/dev/mapper/crypt${toString n}";
        options = ["noauto" "noatime"];
      };
    }));

  networking.firewall.allowedTCPPorts = [80 443 445 1883];
  # work around etc.overlay permissions bug
  environment.etc."mosquitto/acl-0.conf" = {
    uid = config.users.users.mosquitto.uid;
    gid = config.users.groups.mosquitto.gid;
  };
  services = {
    avahi.enable = true;
    jellyfin = {
      enable = true;
    };
    mosquitto = {
      enable = true;
      listeners = [
        {
          port = 1883;
          users = {
            "hass.awen.sec.gd".hashedPassword = "$7$101$ZGKtPJuxva6PLF3R$A1iUE1AAwwPLXTN9D6UwHPa0bGPgsFqFdnSj++4lwZXqnpMCxlXRuYjKHGQyVMWemhC4arNdF86CB1VVc9jHEw==";
            "frigate".hashedPassword = "$7$101$LYQGV/6R0ooY6CfN$kgh9oUq//bV9jS73Ogu6B4rMhq4eZRtTWEOe+I+KRZxIEJj9LDzCWtrcoGWOub88xz87AHJWmClVYEkfkNXA3g==";
          };
        }
      ];
    };
    nginx = {
      enable = true;
      # default headers, if none are overridden in a location block
      appendHttpConfig = ''
        # content vhost
        limit_conn_zone $binary_remote_addr zone=content_addr:5m;
        geo $content_rate_limit {
          10.0.0.0/16 0;  # lan, unlimited
          default     10m;  # 80mbps
        }
        # less cursed than it looks - actually allowed by spec:
        # https://www.rfc-editor.org/rfc/rfc4918#section-9.4
        map $request_method $webdav_location {
          GET     @direct;
          HEAD    @direct;
          default @webdav;
        }
      '';
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      #recommendedZstdSettings = true;  # causes response truncation
      virtualHosts = let
        webdavDestination = ''
          # fix COPY/MOVE: https://github.com/hacdias/webdav#nginx-configuration-example
          set $destination $http_destination;
          if ($http_destination ~ "^$scheme://$host/(?<path>.*)") {
            set $destination /$path;
          }
          proxy_set_header Destination $destination;
        '';
      in {
        "default" = {
          default = true;
          # Can't use globalRedirect because it adds a bonus http://
          extraConfig = ''
            return 301 https://$http_host$request_uri;
          '';
          listen = [
            {
              addr = "0.0.0.0";
              extraParameters = ["deferred"];
            }
            {
              addr = "0.0.0.0";
              extraParameters = ["deferred"];
              port = 443;
              ssl = true;
            }
            {
              addr = "[::]";
              extraParameters = ["deferred"];
            }
            {
              addr = "[::]";
              extraParameters = ["deferred"];
              port = 443;
              ssl = true;
            }
          ];
          rejectSSL = true;
        };
        "content.awen.sec.gd" = {
          basicAuthFile = "/persist/nginx/htpasswd-content";
          enableACME = true;
          onlySSL = true;
          root = "/mnt/data/downloads";
          extraConfig =
            nginxHeaders {Content-Disposition = "inline";}
            + ''
              access_log /var/log/nginx/content.log;
              aio threads;
              autoindex on;
              charset utf8;
              autoindex_exact_size off;
              set_real_ip_from 100.64.0.6;
              limit_rate $content_rate_limit;
              limit_conn content_addr 2;
              proxy_buffering off;
              proxy_request_buffering off;
              try_files /dev/null $webdav_location;
            '';
          locations = let
            contentDavConfig =
              ''proxy_set_header Authorization "Basic Y29udGVudDp0bmV0bm9j";''
              + webdavDestination;
          in {
            "@direct" = {};
            "@webdav" = {
              extraConfig = contentDavConfig;
              proxyPass = "http://127.0.0.1:45496";
            };
            "/library/".alias = "/mnt/data/library/";
            "/now/" = {
              alias = "/mnt/data/downloads/";
              extraConfig = ''
                try_files $uri $uri/ =404; # no webdav
                limit_rate 18m; # 144mbps
                limit_conn content_addr 2;
              '';
            };
          };
        };
        "dav.awen.sec.gd" = {
          # this vhost must have nginx basic auth, else the content-dav proxy credentials can be abused
          basicAuthFile = pkgs.writeText "htpasswd-dav" ''
            mal-seedvault:$2b$12$tDSmS7YpvUybDvIE4D5GrulR7JaMIShDQa./q5TFEl14n0W3DM14C
          '';
          enableACME = true;
          onlySSL = true;
          extraConfig =
            webdavDestination
            + ''
              proxy_buffering off;
              proxy_request_buffering off;
            '';
          locations."/".proxyPass = "http://127.0.0.1:45496";
        };
        "hass.sec.gd" = {
          onlySSL = true;
          enableACME = true;
          extraConfig = nginxHeaders {
            Content-Security-Policy = {
              connect-src = "'self' https://brands.home-assistant.io"; # icons via SW
              font-src = "'self' data: https://cdnjs.cloudflare.com";
              frame-ancestors = "'self'";
              img-src = "'self' data: https://basemaps.cartocdn.com https://brands.home-assistant.io";
              script-src = "'self' 'unsafe-inline' https://cdnjs.cloudflare.com";
              style-src = "'self' 'unsafe-inline' https://cdnjs.cloudflare.com";
            };
          };
          locations."/" = {
            proxyPass = "http://10.0.0.7:8123";
            proxyWebsockets = true;
          };
        };
        "media.sec.gd" = {
          onlySSL = true;
          enableACME = true;
          extraConfig = nginxHeaders {
            Content-Security-Policy = {
              font-src = "'self' data:";
              img-src = [
                "'self'"
                "blob:"
                "https://repo.jellyfin.org/releases/plugin/images/"
                "https://raw.githubusercontent.com/firecore/InfuseSync/master/"
              ];
              script-src = "'self' 'unsafe-inline' blob:";
              style-src = "'self' 'unsafe-inline' blob:";
              frame-ancestors = "'self'";
            };
            Cross-Origin-Opener-Policy = "same-origin";
            Cross-Origin-Embedder-Policy = "credentialless";
            Cross-Origin-Resource-Policy = "same-origin";
          };
          locations."/" = {
            proxyPass = "http://127.0.0.1:8096";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_buffering off;
            '';
          };
        };
        "notes.sec.gd" = {
          # proxy configured by services.trilium-server
          onlySSL = true;
          enableACME = true;
          extraConfig = nginxHeaders {
            Content-Security-Policy = {
              connect-src = "'self' https://api.github.com/repos/TriliumNext/Notes/releases/latest";
              img-src = "'self' data:";
              script-src = "'self' 'unsafe-inline' 'unsafe-eval'";
              style-src = "'self' 'unsafe-inline'";
            };
          };
        };
      };
    };
    postgresql = {
      enable = true;
      #package = pkgs.postgresql_15;
      authentication = lib.mkOverride 10 ''
        local all all peer
        host all all 127.0.0.1/32 scram-sha-256
        host all all ::1/128 scram-sha-256
      '';
    };
    samba.settings.public = {
      path = "/data/public";
      #writeable = "yes";
      public = "yes";
    };
    smartd.enable = true;
    teamspeak3 = {
      enable = true;
      dataDir = "/persist/teamspeak3-server";
      defaultVoicePort = 36609;
      openFirewall = true;
    };
    tor = {
      enable = true;
      client.enable = true;
    };
    trilium-server = {
      enable = true;
      package = pkgs.trilium-next-server;
      port = 37962;
      dataDir = "/persist/trilium";
      nginx.enable = true;
      nginx.hostName = "notes.sec.gd";
    };
    webdav = {
      enable = true;
      settings = {
        address = "127.0.0.1";
        port = 45496;
        debug = true;
        noSniff = true;
        behindProxy = true;
        permissions = "";
        directory = "/dev/null";
        users = [
          {
            username = "content";
            password = "tnetnoc";
            directory = "/mnt/data/downloads/";
            permissions = "R";
          }
          {
            username = "mal-seedvault";
            password = "{bcrypt}$2b$12$tDSmS7YpvUybDvIE4D5GrulR7JaMIShDQa./q5TFEl14n0W3DM14C";
            directory = "/data/backups/phone/";
            permissions = "CRUD";
          }
        ];
      };
    };
    zrepl.settings.jobs = [
      {
        name = "tank_sink";
        type = "sink";
        serve = {
          type = "stdinserver";
          client_identities = [
            "awdbox"
            "awen" # TODO: use local instead
            "t14s"
          ];
        };
        root_fs = "pool/backups";
      }
      {
        name = "data_snap_nobackup";
        type = "snap";
        filesystems = {
          "pool/nobackup" = true;
        };
        snapshotting = {
          type = "periodic";
          interval = "5m";
          prefix = "zrepl_";
        };
        pruning = {
          keep = [
            {
              type = "grid";
              grid = "1x1h(keep=all) | 32x15m | 24x1h";
              regex = "^zrepl_.*";
            }
            {
              type = "regex";
              negate = true;
              regex = "^zrepl_.*";
            }
          ];
        };
      }
      {
        # TODO: replicate to nvme or awdbox
        name = "data_snap";
        type = "snap";
        filesystems = {
          "pool<" = true;
          "pool/backups<" = false;
          "pool/nobackup<" = false;
        };
        snapshotting = {
          type = "periodic";
          interval = "5m";
          prefix = "zrepl_";
        };
        pruning = {
          keep = [
            {
              type = "grid";
              grid = "1x1d(keep=all) | 96x15m | 72x1h | 30x1d | 52x1w";
              regex = "^zrepl_.*";
            }
            {
              type = "regex";
              negate = true;
              regex = "^zrepl_.*";
            }
          ];
        };
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    perSystem.self.immich-stacker
    virtio-win
  ];

  #virtualisation.vmware.host.enable = true;
  environment.etc."vmware/networking".text = ''
    VERSION=1,0
    answer VNET_1_DHCP yes
    answer VNET_1_DHCP_CFG_HASH E6C455D2CBA13FA45DC691E32B4C123AC135B271
    answer VNET_1_HOSTONLY_NETMASK 255.255.255.0
    answer VNET_1_HOSTONLY_SUBNET 192.168.5.0
    answer VNET_1_VIRTUAL_ADAPTER yes
    answer VNET_8_DHCP yes
    answer VNET_8_DHCP_CFG_HASH A5D1873DCC8584C7CC36C59448BC6DF5A6515428
    answer VNET_8_HOSTONLY_NETMASK 255.255.255.0
    answer VNET_8_HOSTONLY_SUBNET 192.168.168.0
    answer VNET_8_NAT yes
    answer VNET_8_VIRTUAL_ADAPTER yes
    answer VNL_DEFAULT_BRIDGE_VNET -1
    add_bridge_mapping br0 0
    add_bridge_mapping eth1 2
  '';

  # while the ups is away
  systemd.services.upsdrv.wantedBy = lib.mkForce [];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
