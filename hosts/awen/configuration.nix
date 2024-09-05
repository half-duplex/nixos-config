{ lib, pkgs, ... }:
let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.lists) toList;
  inherit (lib.strings) concatStringsSep toJSON;
in
{
  sconfig = {
    dvorak = true;
    profile = "server";
    hardware = "physical";
    remoteUnlock = true;
    secureboot = true;
  };

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;  # hardened currently causes boot loops
  boot.kernelParams = [ "ip=10.0.0.6::10.0.0.1:255.255.255.0::eth0:none" ];
  boot.initrd.availableKernelModules = [ "nvme" "r8169" ];
  hardware.cpu.amd.updateMicrocode = true;
  console.earlySetup = true;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9oQ5Cdab1hZF5LhQ8FTWdAV8QQ/S1/0krreiRzT62n mal@awdbox.sec.gd"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+ejh/zHzsMdmTNeNUkKgpYHBQguKi5lg1bvrpA2O+e mal@nova.sec.gd"
  ];
  users.users.syncoid.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4xsLvnw2YX7qNdnJkWmEzsx5wIaFiXR0spwj1/5ga0 syncoid@awdbox"
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

  fileSystems = lib.foldl (a: b: a // b)
    {
      "/mnt/data" = { device = "pool"; fsType = "zfs"; };
      "/mnt/data/backups" = { device = "pool/backups"; fsType = "zfs"; };
      "/mnt/data/downloads" = { device = "pool/downloads"; fsType = "zfs"; };
    }
    (lib.forEach (lib.range 1 5) (n: {
      "/mnt/crypt${toString n}" = {
        device = "/dev/mapper/crypt${toString n}";
        options = [ "noauto" "noatime" ];
      };
    }));

  networking.firewall.allowedTCPPorts = [ 80 443 445 ];
  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
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
      '';
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedZstdSettings = true;
      virtualHosts = {
        "default" = {
          default = true;
          # Can't use globalRedirect because it adds a bonus http://
          extraConfig = ''
            return 301 https://$host$request_uri;
          '';
          listen = [
            { addr = "0.0.0.0"; extraParameters = [ "deferred" ]; }
            { addr = "[::]"; extraParameters = [ "deferred" ]; }
          ];
          rejectSSL = true;
        };
        "hass.sec.gd" = {
          onlySSL = true;
          enableACME = true;
          extraConfig = concatStringsSep "\n" (
            mapAttrsToList (
              k: v: "add_header ${k} ${toJSON (concatStringsSep " " (toList v))} always;"
            ) {
              Content-Security-Policy = mapAttrsToList (
                k: v: "${k} ${concatStringsSep " " (toList v)};"
              ) {
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
      };
    };
    samba = {
      enable = true;
      enableWinbindd = false;
      enableNmbd = false;
      extraConfig = ''
        server string = %h
        passdb backend = tdbsam:/persist/etc/samba/private/passdb.tdb
        hosts deny = ALL
        hosts allow = ::1 127.0.0.1 10.0.0.0/16
        logging = syslog
        printing = bsd
        printcap name = /dev/null
        load printers = no
        disable spoolss = yes
        disable netbios = yes
        dns proxy = no
        inherit permissions = yes
        map to guest = Bad User
        client min protocol = SMB3
        server min protocol = SMB3
        ;restrict anonymous = 2  ; even =1 breaks anon from windows
        smb ports = 445
        client signing = desired
        client smb encrypt = desired
        server signing = desired
        ;server smb encrypt = desired  ; breaks anon from windows
      '';
      shares = {
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
    sanoid = {
      datasets = {
        "pool" = {
          use_template = [ "default" ];
          recursive = true;
        };
      };
    };
    syncoid = {
      enable = true;
      commands = {
        "awen" = {
          source = "tank";
          target = "pool/backups/awen/tank";
        };
      };
    };
    smartd.enable = true;
    tor = {
      enable = true;
      client.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    rtorrent
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

  system.stateVersion = "24.05";
}
