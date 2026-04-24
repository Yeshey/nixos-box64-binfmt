{ inputs, self }:
{ lib, pkgs, config, ... }:

let
  cfg   = config.box64-binfmt;
  box32 = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.box32;

  steamcmdPkg = pkgs.x86.steamcmd;
  steamPkg    = pkgs.x86.steam-unwrapped;

  steamFhs = pkgs.buildFHSEnv {
    name = "steam-box64-fhs";

    targetPkgs = p: with p; [
      box32       
      bash coreutils curl glibc libgcc zlib bzip2 xz gnutls udev
      xorg.libX11 xorg.libXext xorg.libXfixes xorg.libXcursor 
      xorg.libXrandr xorg.libXrender xorg.libxcb xorg.libXi xorg.libXinerama
      xorg.libXScrnSaver xorg.libSM xorg.libICE
      libGL libGLU vulkan-loader
      gtk2 gtk3 glib pango cairo freetype fontconfig dbus util-linux
      alsa-lib libpulseaudio
      libdrm libvdpau libvorbis libogg
    ];

    runScript = pkgs.writeShellScript "steam-fhs-inner" ''
      exec "$@"
    '';
  };

  steamcmdWrapper = pkgs.writeShellScriptBin "steamcmd" ''
    set -e
    STEAMROOT="$HOME/.local/share/Steam"
    PATH="$PATH''${PATH:+:}${pkgs.coreutils}/bin"

    if [ ! -e "$STEAMROOT" ]; then
      mkdir -p "$STEAMROOT"/{appcache,config,logs,Steamapps/common}
      mkdir -p ~/.steam
      ln -sf "$STEAMROOT" ~/.steam/root
      ln -sf "$STEAMROOT" ~/.steam/steam
    fi

    if [ ! -e "$STEAMROOT/steamcmd.sh" ]; then
      mkdir -p "$STEAMROOT/linux32"
      cd ${steamcmdPkg}/share/steamcmd
      find . -type f -exec install -Dm 755 "{}" "$STEAMROOT/{}" \;
    fi

    exec ${steamFhs}/bin/steam-box64-fhs "$STEAMROOT/steamcmd.sh" "$@"
  '';

  steamWrapper = pkgs.symlinkJoin {
    name = "steam-box64";
    paths = [ steamPkg ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f $out/bin/steam
      
      makeWrapper ${steamFhs}/bin/steam-box64-fhs $out/bin/steam \
        --add-flags "${steamPkg}/bin/steam -no-cef-sandbox -cef-disable-gpu -cef-disable-software-rasterizer" \
        --set STEAM_OS linux \
        --set STEAM_RUNTIME 1
    '';
  };

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