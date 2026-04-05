{ config, pkgs, ... }:
# https://discourse.nixos.org/t/nixos-and-raspberry-pi-zero-2w-pi-camera-module-v3/46319/2
{
  # https://github.com/Electrostasy/dots/blob/3b81723feece67610a252ce754912f6769f0cd34/hosts/phobos/klipper.nix#L11
  hardware.deviceTree = {
    enable = true;
    filter = "bcm2711-rpi-4-b.dtb";
    overlays =
      let
        # https://github.com/Electrostasy/dots/blob/3b81723feece67610a252ce754912f6769f0cd34/hosts/phobos/klipper.nix#L17-L42
        mkCompatibleDtsFile =
          dtbo:
          let
            drv =
              pkgs.runCommand (builtins.replaceStrings [ ".dtbo" ] [ ".dts" ] (baseNameOf dtbo))
                {
                  nativeBuildInputs = with pkgs; [
                    dtc
                    gnused
                  ];
                }
                ''
                  mkdir -p "$out"
                  dtc -I dtb -O dts '${dtbo}' | sed -e 's/bcm2835/bcm2711/g' > "$out/overlay.dts"
                '';
          in
          "${drv}/overlay.dts";
      in
      [
        {
          name = "ov5647";
          dtsFile = mkCompatibleDtsFile "${config.boot.kernelPackages.kernel}/dtbs/overlays/ov5647.dtbo";
        }
      ];
  };
}
