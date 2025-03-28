{
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.lists) toList;
  inherit (lib.strings) concatStrings concatStringsSep toJSON;
in {
  ${namespace} = {
    dvorak = true;
    hardware = "physical";
    remoteUnlock.enable = true;
    boot.secureboot.enable = true;
    services = {
      authentik.enable = true;
      immich.enable = true;
    };
  };

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages; # hardened currently causes boot loops
  boot.kernelParams = ["ip=10.0.0.6::10.0.0.1:255.255.255.0::eth0:none"];
  boot.initrd.availableKernelModules = ["nvme" "r8169"];
  console.earlySetup = true;
  hardware = {
    cpu.amd.updateMicrocode = true;
    graphics.enable = true; # enable hw video acceleration
  };

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9oQ5Cdab1hZF5LhQ8FTWdAV8QQ/S1/0krreiRzT62n mal@awdbox.sec.gd"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+ejh/zHzsMdmTNeNUkKgpYHBQguKi5lg1bvrpA2O+e mal@nova.sec.gd"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSqbI35Krvjngna/q9iuB/i9fd/u8l0q3qG3rLMEKl8 mal@t14s.sec.gd"
  ];
  users.users.root.openssh.authorizedKeys.keys = [
    "command=\"zrepl stdinserver awdbox\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDCo6e8qf5a3NPz55vmLKxBr0J8fiIR4AiXEZRw/lmSD root@awdbox"
    "command=\"zrepl stdinserver awen\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtpIj6zB4jeoYCWUH9jAxvTaNKfWQ7OMqTVD3lXw3Xh root@awen"
    "command=\"zrepl stdinserver t14s\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBlIAZVeRbfsFpbsoywqneHtIDvXTWv7myK5YOvnSsx7 root@t14s"
  ];

  networking = {
    bridges = {
      br0 = {
        interfaces = [
          "eth0"
        ];
      };
    };
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
        device = "pool";
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
    }
    (lib.forEach (lib.range 1 5) (n: {
      "/mnt/crypt${toString n}" = {
        device = "/dev/mapper/crypt${toString n}";
        options = ["noauto" "noatime"];
      };
    }));

  networking.firewall.allowedTCPPorts = [80 443 445 1883];
  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
    jellyfin = {
      enable = true;
    };
    mosquitto = {
      enable = true;
      listeners = [
        {
          port = 1883;
        }
      ];
    };
    nginx = {
      enable = true;
      # default headers, if none are overridden in a location block
      appendHttpConfig = ''
        add_header Content-Security-Policy "default-src 'self'; frame-ancestors 'none';" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "same-origin" always;
        add_header Permissions-Policy "join-ad-interest-group=(), run-ad-auction=(), interest-cohort=()" always;

        # content vhost
        limit_conn_zone $binary_remote_addr zone=content_addr:5m;
        geo $content_rate_limit {
          10.0.0.0/16 0;  # lan, unlimited
          default     2m;  # 2m=16mbps
        }
      '';
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      #recommendedZstdSettings = true;  # causes response truncation
      virtualHosts = {
        "default" = {
          default = true;
          # Can't use globalRedirect because it adds a bonus http://
          extraConfig = ''
            return 301 https://$host$request_uri;
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
            ''
              access_log /var/log/nginx/content.log;
              aio threads;
              autoindex on;
              charset utf8;
              autoindex_exact_size off;
              set_real_ip_from 100.64.0.6;
              limit_rate $content_rate_limit;
              limit_conn content_addr 2;
            ''
            + concatStringsSep "\n" (
              mapAttrsToList
              (
                k: v: "add_header ${k} ${toJSON (concatStringsSep " " (toList v))} always;"
              )
              {
                Content-Disposition = "inline";
                Content-Security-Policy =
                  mapAttrsToList
                  (
                    k: v: "${k} ${concatStringsSep " " (toList v)};"
                  )
                  {
                    default-src = "'self'";
                    frame-ancestors = "'none'";
                  };
                Strict-Transport-Security = "max-age=31536000; includeSubdomains; preload";
                X-Content-Type-Options = "nosniff";
                Referrer-Policy = "same-origin";
                Permissions-Policy = "join-ad-interest-group=(), run-ad-auction=(), interest-cohort=()";
              }
            );
          locations = {
            "/dav/".proxyPass = "http://127.0.0.1:45496";
            "/library/".alias = "/mnt/data/library/";
            "/now/" = {
              alias = "/mnt/data/downloads/";
              extraConfig = ''
                limit_rate 4608k;  # 4m=32mbps, 4608k=4.5m=36mbps
                limit_conn content_addr 2;
              '';
            };
          };
        };
        "hass.sec.gd" = {
          onlySSL = true;
          enableACME = true;
          extraConfig = concatStringsSep "\n" (
            mapAttrsToList
            (
              k: v: "add_header ${k} ${toJSON (concatStringsSep " " (toList v))} always;"
            )
            {
              Content-Security-Policy =
                mapAttrsToList
                (
                  k: v: "${k} ${concatStringsSep " " (toList v)};"
                )
                {
                  default-src = "'self'";
                  font-src = "'self' data: https://cdnjs.cloudflare.com";
                  frame-ancestors = "'self'";
                  img-src = "'self' data: https://basemaps.cartocdn.com https://brands.home-assistant.io";
                  script-src = "'self' 'unsafe-inline' https://cdnjs.cloudflare.com";
                  style-src = "'self' 'unsafe-inline' https://cdnjs.cloudflare.com";
                };
              Strict-Transport-Security = "max-age=31536000; includeSubdomains; preload";
              X-Content-Type-Options = "nosniff";
              Referrer-Policy = "same-origin";
              Permissions-Policy = "join-ad-interest-group=(), run-ad-auction=(), interest-cohort=()";
            }
          );
          locations."/" = {
            proxyPass = "http://10.0.0.7:8123";
            proxyWebsockets = true;
          };
        };
        "media.sec.gd" = {
          onlySSL = true;
          enableACME = true;
          extraConfig = concatStringsSep "\n" (
            mapAttrsToList
            (
              k: v: "add_header ${k} ${toJSON (concatStringsSep " " (toList v))} always;"
            )
            {
              Content-Security-Policy =
                mapAttrsToList
                (
                  k: v: "${k} ${concatStringsSep " " (toList v)};"
                )
                {
                  default-src = "'self'";
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
              Strict-Transport-Security = "max-age=31536000; includeSubdomains; preload";
              X-Content-Type-Options = "nosniff";
              Referrer-Policy = "same-origin";
              Permissions-Policy = "join-ad-interest-group=(), run-ad-auction=(), interest-cohort=()";
            }
          );
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
          extraConfig = concatStringsSep "\n" (
            mapAttrsToList
            (
              k: v: "add_header ${k} ${toJSON (concatStringsSep " " (toList v))} always;"
            )
            {
              Content-Security-Policy =
                mapAttrsToList
                (
                  k: v: "${k} ${concatStringsSep " " (toList v)};"
                )
                {
                  default-src = "'self'";
                  connect-src = "'self' https://api.github.com/repos/TriliumNext/Notes/releases/latest";
                  img-src = "'self' data:";
                  script-src = "'self' 'unsafe-inline' 'unsafe-eval'";
                  style-src = "'self' 'unsafe-inline'";
                  frame-ancestors = "'none'";
                };
              Strict-Transport-Security = "max-age=31536000; includeSubdomains; preload";
              X-Content-Type-Options = "nosniff";
              Referrer-Policy = "same-origin";
              Permissions-Policy = "join-ad-interest-group=(), run-ad-auction=(), interest-cohort=()";
            }
          );
        };
        "rt.awen.sec.gd" = {
          # proxy configured by services.rutorrent
          basicAuthFile = "/persist/rutorrent/htpasswd";
          onlySSL = true;
          enableACME = true;
          extraConfig = concatStringsSep "\n" (
            mapAttrsToList
            (
              k: v: "add_header ${k} ${toJSON (concatStringsSep " " (toList v))} always;"
            )
            {
              Content-Security-Policy =
                mapAttrsToList
                (
                  k: v: "${k} ${concatStringsSep " " (toList v)};"
                )
                {
                  default-src = "'self'";
                  script-src = "'self' 'unsafe-eval' 'unsafe-inline'";
                  style-src = "'self' 'unsafe-inline'";
                  frame-ancestors = "'self'";
                };
              Strict-Transport-Security = "max-age=31536000; includeSubdomains; preload";
              X-Content-Type-Options = "nosniff";
              Referrer-Policy = "same-origin";
              Permissions-Policy = "join-ad-interest-group=(), run-ad-auction=(), interest-cohort=()";
            }
          );
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
    rtorrent = {
      enable = true;
      dataDir = "/persist/rtorrent";
      openFirewall = true;
      port = 41519;
      configText = lib.mkOverride 10 ''
        directory.default.set = "/mnt/data/downloads"
        network.port_range.set = 41519-41519
        method.insert = cfg.basedir, private|const|string, (cat,"/persist/rtorrent/")

        method.insert = cfg.watch,   private|const|string, (cat,(cfg.basedir),"watch/")
        method.insert = cfg.logs,    private|const|string, (cat,(cfg.basedir),"log/")
        method.insert = cfg.logfile, private|const|string, (cat,(cfg.logs),(system.time),".log")
        method.insert = cfg.rpcsock, private|const|string, (cat,"/run/rtorrent/rpc.sock")
        execute.throw = sh, -c, (cat, "mkdir -p ", (cfg.basedir), "/session ", (cfg.watch), " ", (cfg.logs))

        network.port_random.set = no

        dht.mode.set = disable
        protocol.pex.set = no
        trackers.use_udp.set = no

        throttle.max_uploads.set = 100
        throttle.max_uploads.global.set = 250

        # min/max peers to try to connect
        throttle.min_peers.normal.set = 20
        throttle.max_peers.normal.set = 60
        throttle.min_peers.seed.set = 30
        throttle.max_peers.seed.set = 80
        trackers.numwant.set = 80

        protocol.encryption.set = allow_incoming,try_outgoing,enable_retry

        network.http.max_open.set = 128
        network.max_open_files.set = 600
        network.max_open_sockets.set = 3000

        pieces.memory.max.set = 1800M
        network.xmlrpc.size_limit.set = 8M

        session.path.set = (cat, (cfg.basedir), "session/")
        log.execute = (cat, (cfg.logs), "execute.log")
        #log.xmlrpc = (cat, (cfg.logs), "xmlrpc.log")
        execute.nothrow = sh, -c, (cat, "echo >", (session.path), "rtorrent.pid", " ", (system.pid))

        encoding.add = utf8
        system.umask.set = 0027
        system.cwd.set = (cfg.basedir)
        network.http.dns_cache_timeout.set = 25

        schedule2 = watch_start, 120, 10, ((load.start, (cat, (cfg.watch), "start/*.torrent")))
        schedule2 = watch_load, 130, 10, ((load.normal, (cat, (cfg.watch), "load/*.torrent")))

        # Logging:
        #   Levels = critical error warn notice info debug
        #   Groups = connection_* dht_* peer_* rpc_* storage_* thread_* tracker_* torrent_*
        print = (cat, "Logging to ", (cfg.logfile))
        log.open_file = "log", (cfg.logfile)
        log.add_output = "info", "log"
        ##log.add_output = "tracker_debug", "log"

        scgi_local = (cfg.rpcsock)
        schedule = scgi_group,0,0,"execute.nothrow=chown,\":rtorrent\",(cfg.rpcsock)"
        schedule = scgi_permission,0,0,"execute.nothrow=chmod,\"g+w,o=\",(cfg.rpcsock)"
      '';
    };
    rutorrent = {
      enable = true;
      hostName = "rt.awen.sec.gd";
    };
    samba = {
      enable = true;
      nmbd.enable = false;
      winbindd.enable = false;
      settings = {
        global = {
          "server string" = "%h";
          "passdb backend" = "tdbsam:/persist/etc/samba/private/passdb.tdb";
          "hosts deny" = "ALL";
          "hosts allow" = ["::1" "127.0.0.1" "10.0.0.0/16"];
          "logging" = "syslog";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "load printers" = "no";
          "disable spoolss" = "yes";
          "disable netbios" = "yes";
          "dns proxy" = "no";
          "inherit permissions" = "yes";
          "map to guest" = "Bad User";
          "client min protocol" = "SMB3";
          "server min protocol" = "SMB3";
          #"restrict anonymous" = 2;  # even =1 breaks anon from windows
          "smb ports" = 445;
          "client signing" = "desired";
          "client smb encrypt" = "desired";
          "server signing" = "desired";
          #"server smb encrypt" = "desired";  # breaks anon from windows
        };
        homes = {
          browseable = "no";
          writeable = "yes";
          "valid users" = "%S";
        };
        public = {
          path = "/data/public";
          #writeable = "yes";
          public = "yes";
        };
      };
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
      dataDir = "/persist/var/lib/trilium";
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
        permissions = "R";
        prefix = "/dav/";
        directory = "/data/downloads";
        noPassword = true;
        users = [
          # https://github.com/hacdias/webdav/issues/216
          #{
          #  username = "mal-seedvault";
          #  directory = "/data/backups/phone/";
          #  permissions = "CRUD";
          #}
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
    ];
  };

  environment.systemPackages = with pkgs; [
    mal.immich-stacker
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

  system.stateVersion = "24.11";
}
