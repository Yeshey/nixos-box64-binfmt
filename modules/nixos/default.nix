{ inputs, self }:
{ lib, pkgs, config, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg   = config.box64-binfmt;
  box32 = inputs.self.packages.${system}.box32;
in

{
  imports = [
    (import ./steam.nix { inherit inputs self; })
  ];

  options.box64-binfmt = {
    enable = lib.mkEnableOption "box64-binfmt";
  };

  config = lib.mkIf cfg.enable {

    # Don't let the qemu static emulators (registered by emulatedSystems) win
    # over our binfmt entries.
    boot.binfmt.preferStaticEmulators = false;

    # Register box32 as the binfmt interpreter for x86-64 and i386 ELFs.
    #
    # We do NOT go through boot.binfmt.emulatedSystems for x86 here because
    # emulatedSystems registers qemu interpreters and also populates
    # nix.settings.extra-sandbox-paths with interpreterSandboxPath values.
    # Mixing our registrations with emulatedSystems entries via lib.mkForce
    # causes those sandbox path entries to become null (type error).
    #
    # Instead we own the registrations directly — no conflict, no mkForce.
    # Cross-compilation support comes from nix.settings.extra-platforms below,
    # NOT from emulatedSystems.
    boot.binfmt.registrations = {
      # 64-bit x86 ELF (EM_X86_64 = 0x3e)
      "x86_64-linux" = {
        interpreter            = "${box32}/bin/box64";
        magicOrExtension       = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
        mask                   = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
        wrapInterpreterInShell = false;
        preserveArgvZero       = false;
        openBinary             = false;
      };
      # 32-bit x86 ELF (EM_386 = 0x03) — used by steamcmd linux32/, Wine 32-bit, etc.
      "i386-linux" = {
        interpreter            = "${box32}/bin/box64";
        magicOrExtension       = ''\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00'';
        mask                   = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
        wrapInterpreterInShell = false;
        preserveArgvZero       = false;
        openBinary             = false;
      };
      # i686/i486/i586 ELFs use EM_486 (0x06) — distinct machine type from i386.
      "i686-linux" = {
        interpreter            = "${box32}/bin/box64";
        magicOrExtension       = ''\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x06\x00'';
        mask                   = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
        wrapInterpreterInShell = false;
        preserveArgvZero       = false;
        openBinary             = false;
      };
    };

    # Allow the Nix daemon to evaluate and build x86 packages on this aarch64
    # host.  This replaces the role that boot.binfmt.emulatedSystems would
    # normally play for cross-compilation.
    #
    # IMPORTANT: you must set this (and nixos-rebuild once) BEFORE enabling
    # box64-binfmt.enable, so that Nix can build the box32 package itself.
    # The README has the bootstrap procedure.
    nix.settings.extra-platforms = [
      "x86_64-linux"
      "i686-linux"
      "i386-linux"
    ];

    # Make box32 available system-wide.
    environment.systemPackages = [ box32 ];

    # Add pkgs.x86 — the full x86_64 package set — so consumers can do
    # pkgs.x86.steam, pkgs.x86.vectoroids, etc.
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