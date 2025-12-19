{pkgs, ...}: {
  imports = [
    ./cli-minimal.nix
  ];

  #console.font = "Lat2-Terminus16"; # todo pick
  environment.systemPackages = with pkgs; [
    jq
    libva-utils # for vainfo
    nfs-utils
    nvme-cli
    pciutils
    virtiofsd

    age
    ansible
    openvpn
    sqlite
    vbindiff
    whois
    xclip

    alejandra
    black # python-black
    cloc
    gcc
    gnumake
    lua-language-server
    nil
    nodejs
    pkg-config
    pyright
    rustc
    rustup
    shellcheck
    tree-sitter
    vim-language-server
  ];

  boot.binfmt.emulatedSystems = builtins.filter (sys: sys != pkgs.stdenv.hostPlatform.system) ["aarch64-linux"];
}
