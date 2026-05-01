{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
  in {
    packages = forAllSystems (system: rec {
      default = firmware;

      firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
        name = "firmware";

        src = nixpkgs.lib.sourceFilesBySuffices self [ ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi" ".json" ".keymap" ".overlay" ".shield" ".yml" ".yaml" "_defconfig" ];

        board = "nice_nano_v2";
        shield = "lily58_%PART% nice_view_adapter nice_view_battery";

        enableZmkStudio = true;

        zephyrDepsHash = "sha256-mfEKc/yrNP5/ecLpkEXBfxwcECq923lxqAUPN63Xjq0=";

        meta = {
          description = "ZMK firmware";
          license = nixpkgs.lib.licenses.unlicense;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      # flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
      update = zmk-nix.packages.${system}.update;
    });

    apps = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      flash = {
        type = "app";
        program = pkgs.lib.getExe (pkgs.callPackage ./flash.nix { firmware = self.packages.${system}.firmware; });
      };
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
