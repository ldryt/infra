{ inputs, ... }:
{
  system = "x86_64-linux";
  modules = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
  ];
}
