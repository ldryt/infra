{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";
    mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-24.05";
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      sops-nix,
      disko,
      lanzaboote,
      nixos-hardware,
      impermanence,
      mailserver,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            config.allowUnfree = true;
            inherit system;
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
              export TF_VAR_cloudflare_token_file=~/.keyring/cloudflare_token
              export TF_VAR_hcloud_token_file=~/.keyring/hcloud_token
            '';
          };
        }
      );

      nixosConfigurations = {
        tinkerbell =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
            };
            inherit system;
            modules = [
              ./hosts/tinkerbell
              nixos-hardware.nixosModules.framework-13-7040-amd
              sops-nix.nixosModules.sops
              lanzaboote.nixosModules.lanzaboote
              disko.nixosModules.disko
              impermanence.nixosModules.impermanence
              home-manager.nixosModules.home-manager
            ];
          };
        silvermist = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          system = "x86_64-linux";
          modules = [
            ./hosts/silvermist
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            home-manager.nixosModules.home-manager
            mailserver.nixosModules.mailserver
          ];
        };
        domus =
          let
            system = "aarch64-linux";
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
            };
            inherit system;
            modules = [
              ./hosts/domus
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
            ];
          };
        printer =
          let
            system = "aarch64-linux";
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
            };
            inherit system;
            modules = [
              ./hosts/printer
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
            ];
          };
      };

      packages = forAllSystems (system: {
        sdImage-printer = self.nixosConfigurations.printer.config.system.build.sdImage;
        sdImage-domus = self.nixosConfigurations.domus.config.system.build.sdImage;
      });

      homeConfigurations."lucas.ladreyt" =
        let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./users/lucas.ladreyt ];
        };
    };
}
