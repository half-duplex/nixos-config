{ path, nixosModule, ... }@inputs:
let
    hostMetadata = builtins.mapAttrs
        (name: _: import (path + "/${name}"))
        (builtins.readDir path);

    hardwareModules = {
        physical = (x: { imports = [ "${x.modulesPath}/installer/scan/not-detected.nix" ]; });
        qemu = (x: {
            services.qemuGuest.enable = true;
            imports = [ "${x.modulesPath}/profiles/qemu-guest.nix" ];
        });
    };

    getHostConfig = hostName: hostMeta:
        inputs.${hostMeta.pkgs}.lib.nixosSystem {
            inherit (hostMeta) system;
            modules = [
                (nixosModule)
                (hostMeta.module)
                (hardwareModules.${hostMeta.hardware})
                (_: { networking.hostName = hostName; })
            ];
        };
in
builtins.mapAttrs getHostConfig hostMetadata
