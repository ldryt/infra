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
    devShells.x86_64-linux =
      let pkgs = import nixpkgs { system = "x86_64-linux"; };
      in {
        default = pkgs.mkShell {
          buildInputs = with pkgs;
            with pulumiPackages; [
              pulumi
              pulumi-language-nodejs
              nodejs
              sops
            ];
          shellHook = ''
            export PULUMI_SKIP_UPDATE_CHECK=true
            export SOPS_AGE_KEY_FILE=~/.keyring/sops_age_ldryt.key
          '';
        };
      };
    nixosConfigurations = {
      tinkerbell = let
        vars =
          (builtins.fromJSON (builtins.readFile ./hosts/tinkerbell/vars.json))
          // (builtins.fromJSON
            (builtins.readFile ./hosts/tinkerbell/vars.gitcrypt.json));
      in nixpkgs.lib.nixosSystem {
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
            home-manager.extraSpecialArgs = { inherit vars; };
            home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
          }
        ];
      };
      kiwi = let
        vars = (builtins.fromJSON (builtins.readFile ./hosts/kiwi/vars.json))
          // (builtins.fromJSON
            (builtins.readFile ./hosts/kiwi/vars.gitcrypt.json));
      in nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          inherit vars;
        };
        system = "aarch64-linux";
        modules = [ ./hosts/kiwi sops-nix.nixosModules.sops ];
      };
      bozi = let
        vars = (builtins.fromJSON (builtins.readFile ./hosts/bozi/vars.json))
          // (builtins.fromJSON
            (builtins.readFile ./hosts/bozi/vars.gitcrypt.json));
      in nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          inherit vars;
        };
        system = "x86_64-linux";
        modules =
          [ ./hosts/bozi sops-nix.nixosModules.sops disko.nixosModules.disko ];
      };
    };
  };
}
