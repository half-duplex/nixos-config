# Installing to sdcard from other host

1. Change the device in disks.nix
2. Change the pool name, if the running machine also uses `tank`
3. Change the architecture to the host's so disko works
4. `nix build .#nixosConfigurations.moose.config.system.build.diskoScript`
5. `sudo ./result`
6. Revert flake changes
7. `sudo nixos-install --flake .#moose -v --no-channel-copy --no-root-password`


10. `zpool rename $temp_name tank` does this even work when tank already exists augh
11. `sudo zpool export .....?`

_I am very annoyed at disko_
