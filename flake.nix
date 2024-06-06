{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      sops-nix,
      disko,
      ...
    }@inputs:
    {
      devShells.x86_64-linux =
        let
          pkgs = import nixpkgs {
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
        tinkerbell =
          let
            vars =
              (builtins.fromJSON (builtins.readFile ./hosts/tinkerbell/vars.json))
              // (builtins.fromJSON (builtins.readFile ./hosts/tinkerbell/vars.gitcrypt.json));
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              inherit vars;
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
                home-manager.extraSpecialArgs = {
                  inherit vars;
                };
                home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
              }
            ];
          };
        silvermist =
          let
            vars =
              (builtins.fromJSON (builtins.readFile ./hosts/silvermist/vars.json))
              // (builtins.fromJSON (builtins.readFile ./hosts/silvermist/vars.gitcrypt.json));
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              inherit vars;
            };
            system = "x86_64-linux";
            modules = [
              ./hosts/silvermist
              sops-nix.nixosModules.sops
              disko.nixosModules.disko
            ];
          };
      };
    };
}
