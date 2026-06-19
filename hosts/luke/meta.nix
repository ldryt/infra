{ inputs, ... }:
{
  system = "aarch64-linux";
  modules = [ inputs.disko.nixosModules.disko ];
}
