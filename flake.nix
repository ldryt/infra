{
  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";

    sops-nix.url = "github:mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-stable";
  };
  outputs =
    {
      nixpkgs-unstable,
      nixpkgs-stable,
      home-manager,
      sops-nix,
      disko,
      ...
    }@inputs:
    {
      devShells.x86_64-linux =
        let
          pkgs = import nixpkgs-stable {
            config.allowUnfree = true;
            system = "x86_64-linux";
          };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              sops
              terraform
              jq
            ];
            shellHook = ''
              export SOPS_AGE_KEY_FILE=~/.keyring/sops_age_ldryt.key
            '';
          };
        };
      nixosConfigurations = {
        tinkerbell = nixpkgs-unstable.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          system = "x86_64-linux";
          modules = [
            ./hosts/tinkerbell
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ldryt = import ./users/ldryt;
              home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
            }
          ];
        };
        silvermist = nixpkgs-stable.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          system = "x86_64-linux";
          modules = [
            ./hosts/silvermist
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        };
        zarina = nixpkgs-stable.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          system = "x86_64-linux";
          modules = [
            ./hosts/zarina
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        };
      };
    };
}
