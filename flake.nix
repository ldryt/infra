{
  nixConfig = {
    extra-substituters = [
      "https://nix-cache.ldryt.dev?priority=50"
      "https://nix-community.cachix.org?priority=41"
      "https://s3.cri.epita.fr/cri-nix-cache.s3.cri.epita.fr?priority=90"
    ];
    extra-trusted-public-keys = [
      "nix-cache.ldryt.dev:LcILZm4hXqCkD31rz94/W+hhvap6ZZJZn9nt3gqvlDg="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nix.cri.epita.fr:qDIfJpZWGBWaGXKO3wZL1zmC+DikhMwFRO4RVE6VVeo="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpie.url = "git+https://gitlab.cri.epita.fr/forge/infra/nixpie.git";
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
    mac-style-plymouth = {
      url = "github:SergioRibera/s4rchiso-plymouth-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";
    mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-master,
      home-manager,
      sops-nix,
      disko,
      lanzaboote,
      nixos-hardware,
      nixos-raspberrypi,
      impermanence,
      mailserver,
      nixpie,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
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
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              inputs.self.packages.${system}.sops-keepass
              inputs.self.packages.${system}.tofu-keepass
              opentofu
              sops
              jq
            ];
          };
        }
      );

      nixosConfigurations = {
        tinkerbell = nixpkgs.lib.nixosSystem rec {
          specialArgs = {
            inherit inputs;
            pkgs-pie = import nixpie.inputs.nixpkgs {
              inherit system;
            };
            pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          };
          system = "x86_64-linux";
          modules = [
            ./hosts/tinkerbell
            sops-nix.nixosModules.sops
            lanzaboote.nixosModules.lanzaboote
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            home-manager.nixosModules.home-manager
          ];
        };
        silvermist = nixpkgs.lib.nixosSystem rec {
          specialArgs = {
            inherit inputs;
            pkgs-master = nixpkgs-master.legacyPackages.${system};
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
        luke = nixpkgs.lib.nixosSystem rec {
          specialArgs = {
            inherit inputs;
            pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
            pkgs-master = nixpkgs-master.legacyPackages.${system};
          };
          system = "aarch64-linux";
          modules = [
            ./hosts/luke
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            home-manager.nixosModules.home-manager
          ];
        };
        domus = nixpkgs.lib.nixosSystem rec {
          specialArgs = {
            inherit inputs;
            pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          };
          system = "aarch64-linux";
          modules = [
            ./hosts/domus
            sops-nix.nixosModules.sops
            impermanence.nixosModules.impermanence
            home-manager.nixosModules.home-manager
          ];
        };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          sops-keepass = pkgs.callPackage ./pkgs/keepass-wrappers/sops-keepass.nix { };
          tofu-keepass = pkgs.callPackage ./pkgs/keepass-wrappers/tofu-keepass.nix { };
          www-lucasladreyt-eu = pkgs.callPackage ./pkgs/www.lucasladreyt.eu { };
          sdImage-domus = self.nixosConfigurations.domus.config.system.build.sdImage;
        }
      );

      homeConfigurations = {
        "lucas.ladreyt" =
          let
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./users/lucas.ladreyt
              sops-nix.homeManagerModules.sops
            ];
          };
        "ldryt" =
          let
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./users/lucas.ladreyt
              sops-nix.homeManagerModules.sops
            ];
          };
      };

      ghaMatrix =
        (builtins.map (name: {
          inherit name;
          platform = self.nixosConfigurations.${name}.config.nixpkgs.system;
          target = ".#nixosConfigurations.${name}.config.system.build.toplevel";
        }) (builtins.attrNames self.nixosConfigurations))
        ++ (builtins.map (name: {
          inherit name;
          platform = self.homeConfigurations.${name}.pkgs.stdenv.hostPlatform.system;
          target = ".#homeConfigurations.\\\"${name}\\\".activationPackage";
        }) (builtins.attrNames self.homeConfigurations))
        ++ (builtins.concatLists (
          builtins.map (
            platform:
            builtins.map (name: {
              inherit name platform;
              target = ".#packages.${platform}.${name}";
            }) (builtins.attrNames self.packages.${platform})
          ) (builtins.attrNames self.packages)
        ));
    };
}
