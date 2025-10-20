{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types;

  inherit (lib.${namespace}) nginxHeaders;

  rtCfg = config.${namespace}.services.rtorrent;
  rutCfg = config.${namespace}.services.rutorrent;
in {
  options.${namespace}.services = {
    rtorrent = {
      enable = mkOption {
        default = false;
        description = "Configure the rtorrent torrent client";
        type = types.bool;
      };
      watchDir = mkOption {
        default = "/persist/rtorrent/watch";
        description = "Path for watched load/start directories";
        type = types.path;
      };
      sessionDir = mkOption {
        default = "/persist/rtorrent/session";
        description = "Path for torrent session data";
        type = types.path;
      };
      dataDir = mkOption {
        default = "/mnt/data/downloads";
        description = "The default save path";
        type = types.path;
      };
      logDir = mkOption {
        default = "/persist/rtorrent/log";
        description = "Path for torrent logs";
        type = types.path;
      };
      port = mkOption {
        description = "The listen port to configure and open in the firewall";
        type = types.port;
      };
    };
    rutorrent = {
      enable = mkOption {
        default = false;
        description = "Configure the rutorrent frontend for rtorrent";
        type = types.bool;
      };
      hostName = mkOption {
        default = "rt.${config.networking.fqdn}";
        description = "The hostname rutorrent will be accessible on";
        type = types.str;
      };
      htpasswdFile = mkOption {
        default = "/persist/rutorrent/htpasswd";
        description = ''
          The htpasswd file protecting rutorrent.
          Generate hashes with `mkpasswd -m yescrypt`
        '';
        type = types.path;
      };
    };
  };

  config = mkIf rtCfg.enable {
    environment.systemPackages = with pkgs; [
      pyrosimple
      transmission_4 # useful for transmission-show etc
    ];
    services.rtorrent = {
      enable = true;
      dataDir = rtCfg.dataDir;
      openFirewall = true;
      port = rtCfg.port;
      # TODO: create sessionDir and watchDir/{start,load} with tmpfiles.d
      configText = lib.mkOverride 10 ''
        directory.default.set = "${rtCfg.dataDir}"
        method.insert = cfg.rpcsock, private|const|string, (cat,"/run/rtorrent/rpc.sock")

        network.port_range.set = ${toString config.services.rtorrent.port}-${toString config.services.rtorrent.port}
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

        session.path.set = "${rtCfg.sessionDir}"
        log.execute = "${rtCfg.logDir}/execute.log"
        #log.xmlrpc = (cat, (cfg.logs), "xmlrpc.log")
        #execute.nothrow = sh, -c, (cat, "echo >", (session.path), "rtorrent.pid", " ", (system.pid))

        encoding.add = utf8
        system.umask.set = 0027
        # what is system.cwd.set used for?
        system.cwd.set = "${rtCfg.sessionDir}"
        network.http.dns_cache_timeout.set = 25

        schedule2 = watch_start, 120, 10, ((load.start, (cat, "${rtCfg.watchDir}", "/start/*.torrent")))
        schedule2 = watch_load, 130, 10, ((load.normal, (cat, "${rtCfg.watchDir}", "/load/*.torrent")))

        # Logging:
        #   Levels = critical error warn notice info debug
        #   Groups = connection_* dht_* peer_* rpc_* storage_* thread_* tracker_* torrent_*
        log.open_file = "log", (cat,"${rtCfg.logDir}/",(system.time),".log")
        log.add_output = "info", "log"
        #log.add_output = "tracker_debug", "log"

        scgi_local = (cfg.rpcsock)
        schedule = scgi_group,0,0,"execute.nothrow=chown,\":rtorrent\",(cfg.rpcsock)"
        schedule = scgi_permission,0,0,"execute.nothrow=chmod,\"g+w,o=\",(cfg.rpcsock)"
      '';
    };

    services.rutorrent = mkIf rutCfg.enable {
      # This nixpkgs module is cursed, it creates a service to dumps the
      # entire application into the dataDir... TODO: fix it
      # also TODO: enable canUseXSendFile
      enable = true;
      dataDir = "/persist/rutorrent";
      hostName = rutCfg.hostName;
      nginx.enable = true;
      plugins = [
        "httprpc"
        "_getdir"
        "_noty2"
        "_task"
        "autotools"
        "chunks"
        "data"
        "datadir"
        "diskspace"
        "edit"
        "erasedata"
        "filedrop"
        "geoip"
        "history"
        "mediainfo"
        "seedingtime"
        "theme"
        "throttle"
        "tracklabels"
      ];
    };
    services.nginx.virtualHosts.${rutCfg.hostName} = mkIf rutCfg.enable {
      # proxy configured by services.rutorrent
      basicAuthFile = rutCfg.htpasswdFile;
      onlySSL = true;
      enableACME = true;
      extraConfig = nginxHeaders {
        Content-Security-Policy = {
          font-src = "'self' data:";
          script-src = "'self' 'unsafe-eval' 'unsafe-inline'";
          style-src = "'self' 'unsafe-inline'";
          frame-ancestors = "'self'";
        };
      };
    };
  };
}
