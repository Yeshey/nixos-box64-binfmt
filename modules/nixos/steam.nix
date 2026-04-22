# steam.nix — Steam workarounds for box64-binfmt on aarch64
#
# The stock pkgs.x86.steamcmd wrapper ends with:
#   x86_64-steam-run $STEAMROOT/steamcmd.sh
# That x86_64 steam-run calls its own x86_64 bwrap, which cannot create
# namespaces when running under box64 emulation.
#
# Fix: reproduce the steamcmd setup steps ourselves, then call steamcmd.sh
# directly inside a *native* (aarch64) buildFHSEnv that uses the setuid
# ARM64 bwrap.  Box64's binfmt registration handles the x86_64 ELF inside.
#
# Import this in modules/nixos/default.nix with:
#   imports = [ ./steam.nix ];
#
{ inputs, self }:   # ← add this line at the top
{ lib, pkgs, config, ... }:

let
  cfg   = config.box64-binfmt;
  box32 = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.box32;

  # The raw steamcmd package (x86_64 binaries, no wrapper).
  steamcmdPkg = pkgs.x86.steamcmd;

  # Native aarch64 FHS with no multiPkgs (avoids the i686 package-set error).
  # Libraries here are native ARM64 — box64 wraps the most common ones itself,
  # the rest it finds via BOX64_LD_LIBRARY_PATH or this FHS /lib tree.
  steamcmdFhs = pkgs.buildFHSEnv {
    name = "steamcmd-fhs";

    targetPkgs = p: with p; [
      box32       # box64 with BOX32 — the actual x86 interpreter
      curl
      glibc
      libgcc
      zlib
    ];

    # No multiPkgs — the i686 cross package set does not exist on aarch64.

    runScript = pkgs.writeShellScript "steamcmd-inner" ''
      exec "$@"
    '';
  };

  # Wrapper that mirrors what pkgs.x86.steamcmd's script does, minus the
  # call to x86_64 steam-run.
  steamcmdWrapper = pkgs.writeShellScriptBin "steamcmd" ''
    set -e

    STEAMROOT="$HOME/.local/share/Steam"
    PATH="$PATH''${PATH:+:}${pkgs.coreutils}/bin"

    # Reproduce the Steam root skeleton that steamcmd expects.
    if [ ! -e "$STEAMROOT" ]; then
      mkdir -p "$STEAMROOT"/{appcache,config,logs,Steamapps/common}
      mkdir -p ~/.steam
      ln -sf "$STEAMROOT" ~/.steam/root
      ln -sf "$STEAMROOT" ~/.steam/steam
    fi

    # Copy steamcmd files into the Steam root on first run (symlinks don't work).
    if [ ! -e "$STEAMROOT/steamcmd.sh" ]; then
      mkdir -p "$STEAMROOT/linux32"
      cd ${steamcmdPkg}/share/steamcmd
      find . -type f -exec install -Dm 755 "{}" "$STEAMROOT/{}" \;
    fi

    # Run steamcmd.sh inside the native FHS.
    # Box64 binfmt intercepts the x86_64 ELF transparently.
    exec ${steamcmdFhs}/bin/steamcmd-fhs "$STEAMROOT/steamcmd.sh" "$@"
  '';

in
{
  config = lib.mkIf cfg.enable {

    # bwrap needs setuid to create mount namespaces without user-namespace
    # support in the kernel (common on vendor aarch64 kernels).
    security.wrappers.bwrap = {
      owner  = "root";
      group  = "root";
      source = "${pkgs.bubblewrap}/bin/bwrap";
      setuid = true;
    };

    environment.systemPackages = [ steamcmdWrapper ];
  };
}