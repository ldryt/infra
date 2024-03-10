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
    colmena = {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        specialArgs = { inherit inputs; };
      };
      kiwi = {
        deployment = {
          targetHost = "kiwi"; # details in ~/.ssh/config
          targetUser = "colon";
          buildOnTarget = true;
          keys = {
            "sops_kiwi_age_key" = {
              keyFile = "/var/lib/sops/sops_kiwi_age_key";
              destDir = "/var/lib/sops";
            };
          };
        };
        imports = [ ./hosts/kiwi sops-nix.nixosModules.sops ];
      };
    };
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
      auternas = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";
        modules = [ ./hosts/auternas disko.nixosModules.disko ];
      };
    };
  };
}
