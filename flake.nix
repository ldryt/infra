{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, home-manager, sops-nix, disko, ... }@inputs: {
    nixosConfigurations = {
      tinkerbell = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";
        modules = [
          ./hosts/tinkerbell
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ldryt = import ./users/ldryt;
          }
        ];
      };
      kiwi = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "aarch64-linux";
        modules = [ ./hosts/kiwi sops-nix.nixosModules.sops ];
      };
      auternas = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";
        modules = [ ./hosts/auternas disko.nixosModules.disko ];
      };
    };
  };
}
