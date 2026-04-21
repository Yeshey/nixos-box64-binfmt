{
  description = "Box64 Binfmt NixOS Module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-linux" "riscv64-linux" ];

      # ---------------------------------------------------------------------------
      # Flake-level outputs (not per-system)
      # ---------------------------------------------------------------------------
      flake = {
        # Overlay that adds pkgs.x86 — a full x86_64 package set usable from an
        # aarch64 host.  Useful for installing x86 packages in your configuration.
        overlays.default = final: prev: {
          x86 = import inputs.nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
            config.allowUnsupportedSystem = true;
          };
        };

        # Classic NixOS module consumed via nixosModules.default.
        nixosModules.default = import ./modules/nixos {
          inherit inputs;
          self = inputs.self;
        };

        # flake-parts module: exposes the NixOS module under
        # flake.modules.nixos.box64-binfmt so dendritic-style configs can
        # import it with a single `imports` line.
        flakeModules.default = { ... }: {
          flake.modules.nixos.box64-binfmt = import ./modules/nixos {
            inherit inputs;
            self = inputs.self;
          };
        };
      };

      # ---------------------------------------------------------------------------
      # Per-system outputs
      # ---------------------------------------------------------------------------
      perSystem = { pkgs, system, ... }: let
        mkBox32 = pkgs.callPackage ./pkgs/box32.nix {
          hello-x86_64 =
            if pkgs.stdenv.hostPlatform.isx86_64
            then pkgs.hello
            else pkgs.pkgsCross.gnu64.hello;
        };
      in {
        packages = {
          default = mkBox32;
          box32   = mkBox32;
        };
      };
    };
}
