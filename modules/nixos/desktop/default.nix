{
  config,
  pkgs,
  lib,
  namespace,
  ...
}: {
  options.${namespace}.archetypes.desktop = {
    enable = lib.mkOption {
      default = false;
      description = "Install a desktop environment and related tools and config";
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.${namespace}.archetypes.desktop.enable {
    time.timeZone = "US/Eastern";

    hardware.bluetooth.enable = true;
    networking.networkmanager.enable = true;

    services.xserver.xkb.options = "compose:ralt";

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    environment.systemPackages = with pkgs; [
      ddcui
      ddcutil
      gparted
      ntfs3g
      pavucontrol
      powertop
      redshift

      carla
      rnnoise-plugin
      ffmpeg-full
      mediainfo
      gimp
      exiftool
      yt-dlp

      wine
      dxvk

      discord
      element-desktop
      evolution
      #nixpkgsUnstable.obsidian  # Requires ancient electron
      signal-desktop
      teamspeak_client
      nixpkgsUnstable.teamspeak6-client
      telegram-desktop
      thunderbird

      alacritty
      chirp
      gedit
      gnome-text-editor
      ghidra
      imhex
      #pgadmin # ancient
      (nixpkgsUnstable.proxmark3.override {hardwarePlatform = "PM3GENERIC";})
      remmina
      virt-manager
      wireshark

      evince # may be implicit with gnome
      google-chrome
      libreoffice-fresh
      nixpkgsStaging.tor-browser
      yubikey-manager
      yubikey-manager-qt
      zoom-us

      protontricks
      r2modman

      android-tools

      (mpv.override {scripts = [mpvScripts.mpris];})

      (vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
          #ms-python.python  # https://github.com/NixOS/nixpkgs/issues/262000
          ms-vscode.cpptools
        ];
      })
    ];

    #programs.adb.enable = true;
    services.flatpak.enable = true;
    services.udev.packages = [pkgs.android-udev-rules];
    services.pcscd.enable = true; # yubikey ccid/piv
    users.users.mal.extraGroups = ["adbusers"];
    security = {
      polkit.enable = true;
      pam.services.kwallet.enableKwallet = true;
    };
    programs = {
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = ["mal"];
      };
      dconf.enable = true;
      steam.enable = true;
    };
    nixpkgs.overlays = [
      (final: prev: {
        steam = prev.steam.override ({extraLibraries ? pkgs': [], ...}: {
          extraLibraries = pkgs':
            (extraLibraries pkgs')
            ++ [
              pkgs'.gperftools
            ];
        });
      })
    ];
  };
}
