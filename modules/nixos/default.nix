{ inputs, self }:
{ lib, pkgs, config, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.box64-binfmt;
in

with lib;
let
  box32 = inputs.self.packages.${system}.box32;

  # ARM64 host libraries exposed to the FHS environment so that box64 can
  # satisfy shared-library lookups without a full x86 chroot.
  steamLibs = with pkgs; [
    unityhub
    harfbuzzFull
    glibc glib.out gtk2 gdk-pixbuf pango.out cairo.out fontconfig libdrm libvdpau expat util-linux at-spi2-core libnotify
    gnutls openalSoft udev xorg.libXinerama xorg.libXdamage xorg.libXScrnSaver xorg.libxcb libva gcc-unwrapped.lib libgccjit
    libpng libpulseaudio libjpeg libvorbis stdenv.cc.cc.lib xorg.libX11 xorg.libXext xorg.libXrandr xorg.libXrender xorg.libXfixes
    xorg.libXcursor xorg.libXi xorg.libXcomposite xorg.libXtst xorg.libSM xorg.libICE libGL libglvnd freetype
    openssl curl zlib dbus-glib ncurses
    libva mesa
    ncurses5 ncurses6 ncurses
    pkgs.curl.out
    cef-binary
    libdbusmenu
    xcbutilxrm
    xorg.xcbutilkeysyms
    sbclPackages.cl-cairo2-xlib
    pango
    gtk3-x11
    libmpg123
    libnma
    libnma-gtk4
    libappindicator libappindicator-gtk3 libappindicator-gtk2
    nss
    nspr
    libudev-zero
    libusb1 gtk3
    xdg-utils
    dotnet-sdk_8
    glfw
    freetype
    vulkan-headers
    vulkan-loader
    vulkan-validation-layers
    shaderc
    renderdoc
    tracy
    vulkan-tools-lunarg
    zenity dbus libnsl libunity pciutils openal
    passt
    cups
    alsa-lib
    libxslt
    zstd
    xorg.libxshmfence
    avahi
    xorg.libpciaccess
    elfutils
    lm_sensors
    libffi
    flac
    libogg
    libbsd
    libxml2
    llvmPackages.libllvm
    libllvm
    libdrm.out
    libgbm
    libgbm.out
    libcap libcap_ng libcaption
    gmp
    gmpxx
    libgmpris
    SDL2
    SDL2_image
    SDL2_mixer
    SDL2_ttf
    bzip2
    SDL sdl3 SDL2 sdlpop SDL_ttf SDL_net SDL_gfx sdlookup SDL2_ttf SDL2_net SDL2_gfx SDL_sound SDL_sixel
    SDL_mixer SDL_image SDL_Pango sdl-jstest SDL_compat SDL2_sound SDL2_mixer SDL2_image SDL2_Pango SDL_stretch
    SDL_audiolib
    libcdada
    libgcc
    swiftshader
    libGL
    xapp
    libunity
    libselinux
    python3 wayland wayland-protocols patchelf libGLU
    fribidi brotli
    fribidi.out brotli.out
  ];

  steamLibsI686 = with pkgs.pkgsCross.gnu32; [
    glibc
    glib.out
    gtk2
    gdk-pixbuf
    cairo.out
    fontconfig
    libdrm
    libvdpau
    expat
    util-linux
    at-spi2-core
    libnotify
    gnutls
    openalSoft
    udev
    xorg.libXinerama
    xorg.libXdamage
    xorg.libXScrnSaver
    xorg.libxcb
    libva
    libpng
    libpulseaudio
    libjpeg
    libvorbis
    stdenv.cc.cc.lib
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXfixes
    xorg.libXcursor
    xorg.libXi
    xorg.libXcomposite
    xorg.libXtst
    xorg.libSM
    xorg.libICE
    libGL
    libglvnd
    freetype
    openssl
    curl
    zlib
    dbus-glib
    ncurses
    vulkan-headers
    vulkan-loader
    ncurses5
    ncurses6
    pkgs.curl.out
    libdbusmenu
    xcbutilxrm
    xorg.xcbutilkeysyms
    gtk3-x11
    libmpg123
    libnma
    libnma-gtk4
    libappindicator
    libappindicator-gtk3
    libappindicator-gtk2
    nss
    nspr
    libudev-zero
    libusb1
    gtk3
    xdg-utils
    vulkan-validation-layers
    zenity
    xorg.libXrandr
    dbus
    libnsl
    pciutils
    openal
    passt
    cups
    alsa-lib
    libxslt
    zstd
    xorg.libxshmfence
    avahi
    xorg.libpciaccess
    elfutils
    lm_sensors
    libffi
    flac
    libogg
    libbsd
    libxml2
    llvmPackages.libllvm
    libdrm.out
    libgbm
    libgbm.out
    libcap
    libcap_ng
    libcaption
    gmp
    gmpxx
    libgmpris
    SDL2
    SDL2_image
    SDL2_ttf
    bzip2
    sdlookup
    SDL2_net
    SDL2_gfx
    SDL_sixel
    sdl-jstest
    SDL_compat
    SDL_audiolib
    libcdada
    libgcc
    libselinux
    python3
    wayland
    wayland-protocols
    patchelf
    libGLU
    fribidi brotli
    fribidi.out brotli.out
  ];

  steamLibsX86_64_GL = with pkgs.pkgsCross.gnu64; [
    libGL
  ];

  # x86_64 libraries symlinked into the box64 search path so that box64 can
  # find them at /usr/lib/box64-x86_64-linux-gnu (see COMPILE.md).
  steamLibsX86_64 = with pkgs.pkgsCross.gnu64; [
    glibc
    glib.out
    gdk-pixbuf
    cairo.out
    fontconfig
    libdrm
    libvdpau
    expat
    util-linux
    libnotify
    gnutls
    openalSoft
    udev
    xorg.libXinerama
    xorg.libXdamage
    xorg.libXScrnSaver
    xorg.libxcb
    libva
    libpng
    libpulseaudio
    libjpeg
    libvorbis
    stdenv.cc.cc.lib
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXfixes
    xorg.libXcursor
    xorg.libXi
    xorg.libXcomposite
    xorg.libXtst
    xorg.libSM
    xorg.libICE
    libGL
    libglvnd
    freetype
    openssl
    curl
    zlib
    dbus-glib
    ncurses
    vulkan-headers
    vulkan-loader
    ncurses5
    ncurses6
    pkgs.curl.out
    xcbutilxrm
    xorg.xcbutilkeysyms
    gtk3-x11
    libmpg123
    libnma
    libnma-gtk4
    libappindicator
    libappindicator-gtk3
    libappindicator-gtk2
    nss
    nspr
    libudev-zero
    libusb1
    gtk3
    xdg-utils
    vulkan-validation-layers
    zenity
    xorg.libXrandr
    dbus
    libnsl
    pciutils
    openal
    passt
    cups
    alsa-lib
    libxslt
    zstd
    xorg.libxshmfence
    avahi
    xorg.libpciaccess
    elfutils
    lm_sensors
    libffi
    flac
    libogg
    libbsd
    libxml2
    llvmPackages.libllvm
    libdrm.out
    libgbm
    libgbm.out
    libcap
    libcap_ng
    libcaption
    gmp
    gmpxx
    libgmpris
    SDL2
    SDL2_image
    SDL2_ttf
    bzip2
    sdlookup
    SDL2_net
    SDL2_gfx
    SDL_sixel
    sdl-jstest
    SDL_compat
    SDL_audiolib
    libcdada
    libgcc
    libselinux
    python3
    wayland
    wayland-protocols
    patchelf
    libGLU
    fribidi brotli
    fribidi.out brotli.out
  ];

  # Fetch the box64 source to copy its bundled stub libraries into the FHS.
  # x64lib / x86lib contain minimal ELF stubs for syscall-level compat.
  box64Source = pkgs.fetchFromGitHub {
    owner = "ptitSeb";
    repo = "box64";
    rev = "main";
    sha256 = "sha256-XESbBWXSj2vrwVaHsVIU+m/Ru/hOXcx9ywrA2WqXG/o=";
  };
in

let
  BOX64_LOG = "1";
  BOX64_DYNAREC_LOG = "0";
  STEAMOS = "1";
  STEAM_RUNTIME = "1";

  BOX64_VARS = ''
    export BOX64_DLSYM_ERROR=1;
    export BOX64_TRANSLATE_NOWAIT=1;
    export BOX64_NOBANNER=1;
    export STEAMOS=${STEAMOS}; # https://github.com/ptitSeb/box64/issues/91#issuecomment-898858125
    export BOX64_LOG=${BOX64_LOG};
    export BOX64_DYNAREC_LOG=${BOX64_DYNAREC_LOG};
    export DBUS_FATAL_WARNINGS=1;
    export STEAM_RUNTIME=${STEAM_RUNTIME};
    export SDL_VIDEODRIVER=x11;
    export BOX64_TRACE_FILE="stderr"; # apparantly prevents steam sniper not found error https://github.com/Botspot/pi-apps/issues/2614#issuecomment-2209629910
    export BOX86_TRACE_FILE=stderr;
    export BOX64_AVX=1;
    export VULKAN_SDK="${pkgs.vulkan-headers}";
    export VK_LAYER_PATH="${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
    export VK_ICD_FILENAMES=${pkgs.mesa}/share/vulkan/icd.d/lvp_icd.aarch64.json;
  '';

  # FHS environment that runs the given command (or drops to bash) with all
  # Steam/game libraries in scope.  box32 acts as the x86 interpreter inside.
  steamFHS = pkgs.buildFHSEnv {
    name = "steam-fhs";

    targetPkgs = pkgs: (with pkgs; [
      box32 box86 steam-run xdg-utils
      vulkan-validation-layers vulkan-headers
      libva-utils swiftshader
    ]) ++ steamLibs;

    multiPkgs = pkgs: steamLibs;

    # x86_64 and i386 stub libraries placed where box64 searches by default.
    # See: https://github.com/ptitSeb/box64/issues/476#issuecomment-2667068838
    extraBuildCommands = let
      steamLibPaths = builtins.map (pkg: "${pkg}") steamLibsX86_64;
    in ''
      mkdir -p $out/usr/lib64/box64-x86_64-linux-gnu
      cp -r ${box64Source}/x64lib/* $out/usr/lib64/box64-x86_64-linux-gnu/

      mkdir -p $out/usr/lib64/box64-i386-linux-gnu
      cp -r ${box64Source}/x86lib/* $out/usr/lib64/box64-i386-linux-gnu/

      ${lib.concatMapStringsSep "\n" (pkgPath: ''
        if [ -d "${pkgPath}/lib" ]; then
          find "${pkgPath}/lib" -maxdepth 1 -name '*.so*' -exec ln -svf -t $out/usr/lib64/box64-x86_64-linux-gnu {} \+
        fi
        if [ -d "${pkgPath}/lib64" ]; then
          find "${pkgPath}/lib64" -maxdepth 1 -name '*.so*' -exec ln -svf -t $out/usr/lib64/box64-x86_64-linux-gnu {} \+
        fi
      '') steamLibPaths}
    '';

    runScript = ''
      ${BOX64_VARS}
      if [ "$#" -eq 0 ]; then
        exec ${pkgs.bashInteractive}/bin/bash
      else
        exec "$@"
      fi
    '';
  };

  box64-fhs = pkgs.writeScriptBin "box64-wrapper" ''
    #!${pkgs.bash}/bin/sh
    ${BOX64_VARS}
    exec ${steamFHS}/bin/steam-fhs ${box32}/bin/box64 "$@"
  '';
in {

  options.box64-binfmt = {
    enable = mkEnableOption "box64-binfmt";
  };

  config = mkIf cfg.enable {

    # Override steam-related packages with genuine x86_64 builds so that
    # box32 can run them directly rather than through qemu-user.
    nixpkgs.overlays = [
      (self: super: let
        x86pkgs = import pkgs.path {
          system = "x86_64-linux";
          config.allowUnfree = true;
          config.allowUnsupportedSystem = true;
        };
      in {
        inherit (x86pkgs) steam-run steam-unwrapped;
      })
    ];

    # Prefer box32/box64 over the static qemu-user emulators registered by
    # boot.binfmt.emulatedSystems; static emulators cause segfaults here.
    boot.binfmt.preferStaticEmulators = false;

    environment.systemPackages = with pkgs; let

      steamx86Wrapper = pkgs.writeScriptBin "box64-bashx86-steamx86-wrapper" ''
        #!${pkgs.bash}/bin/sh
        ${BOX64_VARS}
        exec ${steamFHS}/bin/steam-fhs ${box32}/bin/box64 \
          ${pkgs.x86.bash}/bin/bash ${pkgs.x86.steam-unwrapped}/lib/steam/bin_steam.sh \
          -no-cef-sandbox \
          -cef-disable-gpu \
          -cef-disable-gpu-compositor \
          -system-composer \
          -srt-logger-opened \
          steam://open/minigameslist "$@"
      '';

      glmark2-x86 = pkgs.writeShellScriptBin "glmark2-x86" ''
        export LD_LIBRARY_PATH="${lib.makeLibraryPath steamLibsX86_64_GL}:$LD_LIBRARY_PATH"
        exec /nix/store/g741bnhdizvkpqfpqnmbz4dirai1ja7s-glmark2-2023.01/bin/.glmark2-wrapped -b :show-fps=true:title=#info#
      '';

    in [
      glmark2-x86
      box64-fhs
      steamx86Wrapper
      steamFHS
      box32
    ];
  };
}
