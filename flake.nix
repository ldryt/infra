{
  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";

    sops-nix.url = "github:mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-stable";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs-stable";
  };
  outputs =
    {
      nixpkgs-unstable,
      nixpkgs-stable,
      home-manager,
      sops-nix,
      disko,
      nixos-generators,
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
              go
              delve
            ];
            shellHook = ''
              export SOPS_AGE_KEY_FILE=~/.keyring/sops_age_ldryt.key
            '';
            # https://github.com/go-delve/delve/issues/3085
            hardeningDisable = [ "fortify" ];
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
      };
      packages.x86_64-linux = {
        zarina = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "gce";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/zarina
            sops-nix.nixosModules.sops
          ];
        };
      };
    };
}
