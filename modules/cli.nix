{ pkgs, ... }:
let
  powerlineOpts = [
    "-mode=flat"
    "-colorize-hostname"
    "-cwd-mode=dironly"
    "-modules=user,host,cwd,nix-shell,git,jobs"
    "-git-assume-unchanged-size 0"
  ];
in
{
  #console.font = "Lat2-Terminus16"; # todo pick
  environment.systemPackages = with pkgs; [
    ansible
    binutils
    darkhttpd
    dnsutils
    file
    gcc
    git
    htop
    jq
    lm_sensors
    mosh
    ncdu
    nfs-utils
    nixpkgs-fmt
    nmap
    nvme-cli
    openssl
    parted
    pciutils
    psmisc
    pv
    rsync
    smartmontools
    sqlite
    tcpdump
    unzip
    usbutils
    virtiofsd
    wget
    wireguard-tools
    whois
    zip

    python3
    black  # python-black

    nodejs

    # https://github.com/buckley310/nixos-config/blob/a05bdb3ee24674bd1df706f881296458f3339c6f/modules/cli.nix#L52
    (writeShellScriptBin "needs-restart" ''
      set -e
      booted="$(readlink /run/booted-system/{initrd,kernel,kernel-modules})"
      built="$(readlink /nix/var/nix/profiles/system/{initrd,kernel,kernel-modules})"
      if [ "$booted" = "$built" ]
      then
          echo OK
          exit 0
      else
          echo REBOOT NEEDED
          exit 1
      fi
    '')
  ];

  environment.etc.nixpkgs.source = pkgs.path;
  nix.nixPath = [ "nixpkgs=/etc/nixpkgs" ];

  environment.variables.PLGO_HOSTNAMEFG = "0";
  environment.variables.PLGO_HOSTNAMEBG = "114";

  programs.mtr.enable = true;

  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
  };

  programs.bash.interactiveShellInit = ''
    stty -ixon
  '';

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      packages.sconfig.start = with pkgs.vimPlugins; [
        vim-gitgutter
        vim-nix
      ];
      customRC = ''
        set encoding=utf-8
        scriptencoding utf-8
      '';
    };
  };
}
