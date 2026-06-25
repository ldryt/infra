{
  nixConfig = {
    extra-substituters = [
      "https://nix-cache.ldryt.dev?priority=100"
      "https://nix-community.cachix.org?priority=50"
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
    nixpkgs-pie.url = "git+https://gitlab.cri.epita.fr/forge/infra/nixpie.git";
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
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";
    mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
    stm32cubeide.url = "github:ldryt/stm32cubeide-nix";
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-master,
      nixpkgs-pie,
      home-manager,
      sops-nix,
      disko,
      lanzaboote,
      nixos-hardware,
      nixos-raspberrypi,
      impermanence,
      mailserver,
      stm32cubeide,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      nixosConfigurations = lib.genAttrs (builtins.attrNames (builtins.readDir ./hosts)) (
        name:
        let
          meta = import (./hosts/${name}/meta.nix) { inherit inputs; };
          inherit (meta) system;
        in
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self system;
            inherit (self) nixosConfigurations;
            pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
            pkgs-master = inputs.nixpkgs-master.legacyPackages.${system};
          }
          // (meta.specialArgs or { });
          modules = [
            ./hosts/${name}
            inputs.sops-nix.nixosModules.sops
            inputs.impermanence.nixosModules.impermanence
            inputs.home-manager.nixosModules.home-manager
            { networking.hostName = name; }
          ]
          ++ (meta.modules or [ ]);
        }
      );

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
          sdImage-printer = self.nixosConfigurations.printer.config.system.build.sdImage;
        }
      );

      homeConfigurations =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          pkgs-master = import nixpkgs-master {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        in
        {
          "lucas.ladreyt" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              inherit pkgs-master;
            };
            modules = [
              ./users/lucas.ladreyt
              sops-nix.homeManagerModules.sops
            ];
          };
          "ldryt" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              inherit pkgs-master;
            };
            modules = [
              ./users/ldryt
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
            let
              isCompatible = name: (self.packages.${platform}.${name}.system) == platform;
            in
            builtins.map (name: {
              inherit name platform;
              target = ".#packages.${platform}.${name}";
            }) (builtins.filter isCompatible (builtins.attrNames self.packages.${platform}))
          ) (builtins.attrNames self.packages)
        ));
    };
}
