{ inputs, self }:
{ lib, pkgs, config, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.box64-binfmt;
  box32 = inputs.self.packages.${system}.box32;
in

{
  options.box64-binfmt = {
    enable = lib.mkEnableOption "box64-binfmt";
  };

  imports = [
    (import ./steam.nix { inherit inputs self; })
  ];

  config = lib.mkIf cfg.enable {

    # Prefer box64 over the static qemu-user emulators; the static emulators
    # cause segfaults when used alongside box64.
    boot.binfmt.preferStaticEmulators = false;

    # Register box32 (box64 with BOX32=ON) as the binfmt interpreter for
    # x86-64 and i386 ELF binaries so they run transparently via box64.
    boot.binfmt.registrations = {
      x86_64 = {
        interpreter = "${box32}/bin/box64";
        magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
        mask             = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
        wrapInterpreterInShell = false;
        preserveArgvZero = false;
        openBinary = false;
      };
      i386 = {
        interpreter = "${box32}/bin/box64";
        magicOrExtension = ''\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00'';
        mask             = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
        wrapInterpreterInShell = false;
        preserveArgvZero = false;
        openBinary = false;
      };
    };

    # Make box32 itself available system-wide.
    environment.systemPackages = [ box32 ];

    # Add pkgs.x86 — the full x86_64 package set — so consumers can install
    # x86 packages with e.g. pkgs.x86.steam or pkgs.x86.vectoroids.
    # Note: boot.binfmt.emulatedSystems and nix.settings.extra-platforms are
    # left to the consumer so they can do the required first rebuild with
    # box64-binfmt.enable = false before enabling binfmt registration.
    nixpkgs.overlays = [
      (final: prev: {
        x86 = import pkgs.path {
          system = "x86_64-linux";
          config.allowUnfree = true;
          config.allowUnsupportedSystem = true;
        };
      })
    ];
  };
}