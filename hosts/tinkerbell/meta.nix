{ inputs, ... }:
rec {
  system = "x86_64-linux";
  modules = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
  ];
  specialArgs.pkgs-pie = import inputs.nixpkgs-pie.inputs.nixpkgs { inherit system; };
}
