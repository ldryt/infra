{ inputs, ... }:
rec {
  system = "x86_64-linux";
  modules = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.stm32cubeide.nixosModules.default
  ];
  specialArgs.pkgs-pie = import inputs.nixpkgs-pie.inputs.nixpkgs { inherit system; };
}
