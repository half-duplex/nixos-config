{ pkgs, ... }:
{
  sconfig = {
    profile = "server";
    hardware = "physical";
    remoteUnlock = true;
  };

  # Delay for network device - work around https://github.com/NixOS/nixpkgs/issues/98741
  #boot.initrd.preLVMCommands = lib.mkOrder 400 "sleep 2";

  hardware.cpu.intel.updateMicrocode = true;
  boot = {
    initrd.availableKernelModules = [ "nvme" ]; # aoeu testing FIXME TODO
    #kernelParams = [ "console=ttyS0" ];
  };

  users.users.mal.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOeeYS98GjYsM/uI5kpAzz705G4w7aL0gfLixKs7EDJe mal@awdbox.sec.gd"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKYenMcXumgnwcAVa40KGhyXX3/VPqIZ9/YIej3g+RMC mal@luca.sec.gd"  # todo removeme aoeu
  ];

  networking = {
    bridges = {
      br0 = {
        interfaces = [
          "eth0"
          "eth2"
          "eth3"
        ];
      };
    };
    defaultGateway = "10.0.0.1";
    interfaces = {
      br0 = {
        ipv4.addresses = [
          {
            address = "10.0.0.7";
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

  environment.systemPackages = with pkgs; [
    rtorrent
  ];
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
    smartd.enable = true;
    tor = {
      enable = true;
      client.enable = true;
    };
  };

  virtualisation.vmware.host.enable = true;
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

  system.stateVersion = "22.11";
}
