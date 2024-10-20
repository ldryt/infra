{ ... }:
{
  imports = [
    ../../modules/dnscrypt.nix
    ../../modules/chrony.nix
  ];
  networking = {
    hostName = "rpi";
  };
}
