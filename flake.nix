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

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs-stable";

    mcpulse.url = "github:ldryt/mcpulse";
  };
  outputs =
    {
      self,
      nixpkgs-unstable,
      nixpkgs-stable,
      home-manager,
      sops-nix,
      disko,
      nixos-generators,
      lanzaboote,
      mcpulse,
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

      forAllSystems = nixpkgs-stable.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs-unstable = import nixpkgs-unstable { inherit system; };
        in
        {
          zarina = nixos-generators.nixosGenerate {
            inherit system;
            format = "gce";
            specialArgs = {
              inherit inputs;
              inherit pkgs-unstable;
            };
            modules = [
              ./hosts/zarina
              sops-nix.nixosModules.sops
            ];
          };
        }
      );
      nixosConfigurations = {
        tinkerbell = nixpkgs-unstable.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          system = "x86_64-linux";
          modules = [
            ./hosts/tinkerbell
            sops-nix.nixosModules.sops
            lanzaboote.nixosModules.lanzaboote
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ldryt = import ./users/ldryt;
              home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
            }
          ];
        };
        silvermist =
          let
            system = "x86_64-linux";
            pkgs = import nixpkgs-stable {
              inherit system;
              overlays = [ (self: super: { mcpulse = mcpulse.packages.${system}.default; }) ];
            };
          in
          nixpkgs-stable.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              inherit pkgs;
              pkgs-unstable = import nixpkgs-unstable { inherit system; };
            };
            inherit system;
            modules = [
              ./hosts/silvermist
              sops-nix.nixosModules.sops
              disko.nixosModules.disko
            ];
          };
      };
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs-stable {
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
              go
              delve
            ];
            shellHook = ''
              export SOPS_AGE_KEY_FILE=~/.keyring/sops_age_ldryt.key
              export GCLOUD_KEYFILE_JSON=~/.keyring/gcloud-key-tidy-arena-428113-b3-2f902b588b01.json
              export TF_VAR_cloudflare_token_file=~/.keyring/cloudflare_token
              export TF_VAR_hcloud_token_file=~/.keyring/hcloud_token
            '';
            # https://github.com/go-delve/delve/issues/3085
            hardeningDisable = [ "fortify" ];
          };
        }
      );
    };
}
