{
  config,
  lib,
  ...
}: let
  cfg = config.mal.services.samba;
in {
  options.mal.services.samba = {
    enable = lib.mkEnableOption "Configure samba server";
    interface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Network interface for wsdd";
    };
    discoverable = lib.mkEnableOption "Enable wsdd and avahi broadcasts";
  };

  config = lib.mkIf cfg.enable {
    services = {
      samba = {
        enable = true;
        nmbd.enable = false;
        winbindd.enable = false;
        settings = {
          global = {
            "server string" = "%h";
            # TODO: deploy with sops
            "passdb backend" = "tdbsam:/persist/etc/samba/private/passdb.tdb";
            "hosts deny" = "ALL";
            "hosts allow" = ["127.0.0.1" "::1" "10.0.0.0/16" "fe80::/10" "100.64.0.0/24"];
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
        };
      };
      avahi = lib.mkIf cfg.discoverable {
        enable = true;
        publish = {
          enable = true;
          addresses = true;
          workstation = true;
        };
        extraServiceFiles.smb = ''
          <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h</name>
            <service>
              <type>_smb._tcp</type>
              <port>445</port>
            </service>
          </service-group>
        '';
      };
      samba-wsdd = lib.mkIf cfg.discoverable {
        enable = true;
        interface = cfg.interface;
        openFirewall = true;
      };
    };
  };
}
