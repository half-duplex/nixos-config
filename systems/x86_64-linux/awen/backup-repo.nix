{lib, ...}: let
  inherit (builtins) attrNames;
  inherit (lib.attrsets) genAttrs mapAttrs;

  backupSystems = {
    "family-desktop" = 2000;
    "family-laptop24" = 2001;
    "family-laptop19" = 2002;
  };
in {
  # samba user requires unix user
  users.users =
    mapAttrs (host: uid: {
      inherit uid;
      group = "nogroup";
      isNormalUser = true;
      shell = "/run/current-system/sw/bin/nologin";
    })
    backupSystems;

  services.samba.settings =
    {
      global."hosts allow" = ["10.11.0.0/24"];
    }
    // genAttrs (attrNames backupSystems) (
      host: {
        path = "/data/backups/${host}";
        "valid users" = host;
        writeable = "yes";
      }
    );
}
