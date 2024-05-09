{ lib, pkgs, ... }:
{
  sconfig = {
    profile = "server";
    hardware = "physical";
    remoteUnlock = true;
  };

  hardware.cpu.amd.updateMicrocode = true;
  boot.initrd.availableKernelModules = [ "nvme" ];
  boot.kernelParams = [ "ip=10.0.0.5::10.0.0.1:255.255.255.0::eth0:none" ];
  console.earlySetup = true;

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9oQ5Cdab1hZF5LhQ8FTWdAV8QQ/S1/0krreiRzT62n mal@awdbox.sec.gd"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+ejh/zHzsMdmTNeNUkKgpYHBQguKi5lg1bvrpA2O+e mal@nova.sec.gd"
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
            address = "10.0.0.5";
            prefixLength = 24;
          }
        ];
        ipv6.addresses = [];
      };
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
      "/home" = { device = "tank/home"; fsType = "zfs"; };
      "/data" = { device = "awen-data/data"; fsType = "zfs"; };
      "/data/backups" = { device = "awen-data/backups"; fsType = "zfs"; };
    }
    (lib.forEach (lib.range 1 5) (n: {
      "/mnt/crypt${toString n}" = {
        device = "/dev/mapper/crypt${toString n}";
        options = [ "noauto" "noatime" ];
      };
    }));

  networking.firewall.allowedTCPPorts = [ 445 ];
  services = {
    avahi = {
      enable = true;
      nssmdns = true;
    };
    mosquitto = {
      enable = true;
      listeners = [
        {
          port = 1883;
        }
      ];
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
    smartd.enable = true;
    tor = {
      enable = true;
      client.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    rtorrent
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

  system.stateVersion = "23.11";
}
