{
  config,
  pkgs,
  lib,
  namespace,
  ...
}: let
  impermanent = config.${namespace}.impermanence.enable;
in {
  services.openssh = {
    enable = lib.mkDefault true;
    hostKeys = [
      {
        path = (if impermanent then "/persist" else "/etc") + "/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = (if impermanent then "/persist" else "/etc") + "/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
    settings = {
      AllowGroups = ["ssh-users"];
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;

      # https://blog.stribik.technology/2015/01/04/secure-secure-shell.html
      # https://infosec.mozilla.org/guidelines/openssh
      KexAlgorithms = [
        #"sntrup761x25519-sha512"
        #"sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group-exchange-sha256"
      ];
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
        "hmac-sha2-512"
        "hmac-sha2-256"
        "umac-128@openssh.com"
      ];
    };
  };
  programs.ssh = {
    extraConfig = ''
      Host *.onion
          ProxyCommand socat - SOCKS4A:localhost:%h:%p,socksport=9050
      Host *
          IdentitiesOnly yes
          PasswordAuthentication no
          PubkeyAuthentication no
          ControlPath ~/.ssh/control/%C.sock
    '';
    knownHosts = lib.mapAttrs (name: value: value // {extraHostNames = ["${name}.sec.gd" "${name}.vpn.sec.gd"];}) {
      "nova".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFdMktqbADswjjuvchDjw7yPzxEKPjVvmlDQ9KSmXETm";
      "awdbox".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGaHPoXU8rSgo1xnGzdycTE4V12s7r9UCorttLN3uijo";
      "awen".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGX39naSG1lKKC/Ap/flCR20JTV2i3FiSgQTtJ8pL6lR";
      "t14s".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7TXKM5OichO/g4S51tAc5taggPefpazAxJV8l7kfbv";
    };

    # https://blog.stribik.technology/2015/01/04/secure-secure-shell.html
    # https://infosec.mozilla.org/guidelines/openssh
    hostKeyAlgorithms = [
      "ssh-ed25519-cert-v01@openssh.com"
      "ssh-rsa-cert-v01@openssh.com"
      "ssh-ed25519"
      "ssh-rsa"
    ];
    kexAlgorithms = [
      #"sntrup761x25519-sha512"
      #"sntrup761x25519-sha512@openssh.com"
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
      "diffie-hellman-group-exchange-sha256"
    ];
    ciphers = [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
      "aes128-gcm@openssh.com"
      #"aes256-ctr"
      #"aes192-ctr"
      #"aes128-ctr"
    ];
    macs = [
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256-etm@openssh.com"
      "umac-128-etm@openssh.com"
      #"hmac-sha2-512"
      #"hmac-sha2-256"
      #"umac-128@openssh.com"
    ];
  };
}
