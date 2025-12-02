{
  flake,
  lib,
  pkgs,
  ...
}: {
  imports = with flake.modules.nixos; [
    cli
    ./plymouth.nix

    ./chromium.nix
    ./firefox.nix
  ];

  config = {
    boot.loader.timeout = 0;
    time.timeZone = "US/Eastern";

    hardware.bluetooth.enable = true;
    networking = {
      modemmanager.enable = false;
      networkmanager = {
        enable = true;
        wifi.macAddress = "random";
      };
    };
    systemd.services.NetworkManager-wait-online.enable = lib.mkDefault false;

    services.avahi.enable = true;

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    services.xserver.xkb.options = "compose:ralt";

    environment.systemPackages = with pkgs; [
      amdgpu_top
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
      gimp
      yt-dlp

      wine
      dxvk

      discord
      element-desktop
      evolution
      signal-desktop
      teamspeak3
      nixpkgsUnstable.teamspeak6-client
      telegram-desktop
      thunderbird

      alacritty
      chirp
      gedit
      gnome-text-editor
      imhex
      (nixpkgsUnstable.proxmark3.override {hardwarePlatform = "PM3GENERIC";})
      remmina
      virt-manager
      wireshark

      evince # may be implicit with gnome
      google-chrome
      libreoffice-fresh
      nixpkgsStaging.tor-browser
      yubikey-manager
      yubioath-flutter
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
    nixpkgs.config.permittedInsecurePackages = [
      "qtwebengine-5.15.19" # for teamspeak3
    ];

    programs = {
      #adb.enable = true;
      ghidra.enable = true;
    };
    services = {
      flatpak.enable = true;
      pcscd.enable = true; # yubikey ccid/piv
    };
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
      (_: prev: {
        steam = prev.steam.override ({extraLibraries ? _: [], ...}: {
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
