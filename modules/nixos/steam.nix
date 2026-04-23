# steam.nix — Steam workarounds for box64-binfmt on aarch64
#
# Import this in modules/nixos/default.nix with:
#   imports = [ (import ./steam.nix { inherit inputs self; }) ];
#
{ inputs, self }:
{ lib, pkgs, config, ... }:

let
  cfg   = config.box64-binfmt;
  box32 = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.box32;

  # Raw x86_64 packages
  steamcmdPkg = pkgs.x86.steamcmd;
  steamPkg    = pkgs.x86.steam-unwrapped;

  # Unified Native aarch64 FHS environment for Steam, SteamCMD, and steam-run.
  # Libraries here are native ARM64 — box64 wraps the most common ones itself,
  # the rest it finds via our binfmt LD_LIBRARY_PATH wrapper or this FHS tree.
  steamFhs = pkgs.buildFHSEnv {
    name = "steam-box64-fhs";

    targetPkgs = p: with p; [
      box32       # box64 with BOX32 — the actual x86 interpreter
      
      # Core utilities expected by Steam
      bash coreutils curl glibc libgcc zlib bzip2 xz gnutls udev
      
      # Native Graphics & UI Boundaries
      xorg.libX11 xorg.libXext xorg.libXfixes xorg.libXcursor 
      xorg.libXrandr xorg.libXrender xorg.libxcb xorg.libXi
      libGL libGLU vulkan-loader
      gtk3 glib pango cairo freetype fontconfig dbus
      
      # Native Audio Boundaries
      alsa-lib libpulseaudio
    ];

    # No multiPkgs — the i686 cross package set does not exist on aarch64.

    runScript = pkgs.writeShellScript "steam-fhs-inner" ''
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
    exec ${steamFhs}/bin/steam-box64-fhs "$STEAMROOT/steamcmd.sh" "$@"
  '';

  # Proper GUI Steam Wrapper
  # We use symlinkJoin so the .desktop file and icons are preserved in your app launcher
  steamWrapper = pkgs.symlinkJoin {
    name = "steam-box64";
    paths = [ steamPkg ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Remove the broken x86 executable
      rm -f $out/bin/steam
      
      # Replace it with our native FHS wrapper
      makeWrapper ${steamFhs}/bin/steam-box64-fhs $out/bin/steam \
        --add-flags "${steamPkg}/bin/steam" \
        --set STEAM_OS linux \
        --set STEAM_RUNTIME 1
    '';
  };

  # steam-run wrapper (Useful for executing arbitrary x86 AppImages or generic binaries)
  steamRunWrapper = pkgs.writeShellScriptBin "steam-run" ''
    set -e
    exec ${steamFhs}/bin/steam-box64-fhs "$@"
  '';

in
{
  options.box64-binfmt.steam = {
    enable = lib.mkEnableOption "Steam, SteamCMD, and steam-run wrappers for Box64";
  };

  config = lib.mkIf (cfg.enable && cfg.steam.enable) {

    # bwrap needs setuid to create mount namespaces without user-namespace
    # support in the kernel (common on vendor aarch64 kernels).
    security.wrappers.bwrap = {
      owner  = "root";
      group  = "root";
      source = "${pkgs.bubblewrap}/bin/bwrap";
      setuid = true;
    };

    environment.systemPackages = [
      steamcmdWrapper
      steamWrapper
      steamRunWrapper
    ];
  };
}