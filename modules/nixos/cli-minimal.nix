{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) mapAttrs;
  inherit (lib) filterAttrs;
in {
  imports = [
    ./vim.nix
  ];

  environment.systemPackages = with pkgs; [
    binutils
    cryptsetup
    dnsutils
    e2fsprogs
    file
    gptfdisk
    htop
    lm_sensors
    lsof
    ncdu
    nvd
    openssl
    parallel
    parted # incl. partprobe
    psmisc # killall, etc
    pv
    sbctl
    smartmontools
    tcpdump
    unzip
    usbutils
    wget
    wireguard-tools

    darkhttpd
    exiftool
    git
    mediainfo
    mosh
    nmap
    rsync
    socat
    uv
    wol
    zip

    # make nix-ld work for python
    (let
      pyWithPkgs = python3.withPackages (py-pkgs:
        with py-pkgs; [
          requests
        ]);
    in (writeShellScriptBin "python" ''
      export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
      exec ${pyWithPkgs}/bin/python "$@"
    ''))

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

  nix = {
    nixPath = lib.attrsets.mapAttrsToList (name: _: "${name}=flake:${name}") config.nix.registry;
    # nixos-raspberrypi's forked nixpkgs breaks this, so for now skip on aarch64
    registry = lib.mkIf (pkgs.stdenv.hostPlatform.system != "aarch64-linux") (
      mapAttrs (_: f: {flake = f;}) (filterAttrs (_: f: f? outputs) inputs)
    );
  };

  environment = {
    sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_DESKTOP_DIR = "$HOME/desktop";
      XDG_DOCUMENTS_DIR = "$HOME/library/documents";
      XDG_DOWNLOAD_DIR = "$HOME/downloads";
      XDG_MUSIC_DIR = "$HOME/library/music";
      XDG_PICTURES_DIR = "$HOME/library/pictures";
      XDG_STATE_HOME = "$HOME/.local/state";
    };
    variables = {
      HISTCONTROL = "ignoreboth";
      HISTSIZE = "5000";
      HISTTIMEFORMAT = "%Y.%m.%d %T ";
      PATH = "$HOME/.local/bin:$PATH";

      MOSH_TITLE_NOPREFIX = "1";
      PLGO_HOSTNAMEFG = "0";
      PLGO_HOSTNAMEBG = "114";
      KRB5CCNAME = "DIR:/tmp/krb5cc_\${UID}_d/";

      # Hack around lack of XDG base dir spec support
      ANDROID_SDK_HOME = "$XDG_CONFIG_HOME/android";
      CARGO_HOME = "$XDG_DATA_HOME/cargo";
      DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
      GNUPGHOME = "$XDG_CONFIG_HOME/gnupg";
      GRADLE_USER_HOME = "$XDG_DATA_HOME/gradle";
      HISTFILE = "$XDG_STATE_HOME/bash/history";
      NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/npmrc";
      NODE_REPL_HISTORY = "$XDG_DATA_HOME/node_repl_history";
      NUGET_PACKAGES = "$XDG_CACHE_HOME/nuget-packages";
      PYTHON_HISTORY = "$XDG_STATE_HOME/python/history";
      PYTHONUSERBASE = "$XDG_DATA_HOME/python";
      RANDFILE = "$XDG_DATA_HOME/openssl/rnd";
      TERMINFO = "$XDG_DATA_HOME/terminfo";
      TERMINFO_DIRS = "$XDG_DATA_HOME/terminfo:$TERMINFO_DIRS";
      WGETRC = "$XDG_CONFIG_HOME/wget/wgetrc";
      WINEPREFIX = "$XDG_DATA_HOME/wineprefixes/default";
    };
  };

  programs.mtr.enable = true;

  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
  };

  programs.bash.interactiveShellInit = ''
    stty -ixon

    TMUXA="`tmux list-sessions -f '#{session_attached}' 2>/dev/null | wc -l`"
    TMUXU="`tmux list-sessions -f '#{?session_attached,0,1}' 2>/dev/null | wc -l`"
    [ "$TMUXA" -gt 0 ] && TMUXAS="\e[92m$TMUXA attached\e[0m"
    [ "$TMUXU" -gt 0 ] && TMUXUS="\e[93m$TMUXU unattached\e[0m"
    [ "$TMUXA" -gt 0 -a "$TMUXU" -gt 0 ] && TMUXAND=","
    [ "$((TMUXA+TMUXU))" -gt 1 -o '(' ! -v TMUX -a "$((TMUXA+TMUXU))" -gt 0 ')' ] && \
        echo -e "tmux sessions: $TMUXAS$TMUXAND $TMUXUS" | sed -re 's/ +/ /g'
    unset TMUXA TMUXU TMUXAS TMUXUS TMUXAND
  '';

  programs.nix-ld.enable = true;
}
