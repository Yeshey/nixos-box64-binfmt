{
  lib,
  stdenv,
  fetchFromGitHub,
  gitUpdater,
  cmake,
  python3,
  withDynarec ? (
    stdenv.hostPlatform.isAarch64 || stdenv.hostPlatform.isRiscV64 || stdenv.hostPlatform.isLoongArch64
  ),
  runCommand,
  hello-x86_64,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "box32";
  version = "7eeb5016493dab4e143d53da50dd47bfb44a9509";
  binaryName = "box64";
  doCheck = false;

  src = fetchFromGitHub {
    owner = "ptitSeb";
    repo = "box64";
    rev = finalAttrs.version;
    hash = "sha256-XESbBWXSj2vrwVaHsVIU+m/Ru/hOXcx9ywrA2WqXG/o=";
  };

  nativeBuildInputs = [
    cmake
    python3
  ];

  # Enable ARMv8.1-A extensions required by the ARM dynarec.
  env = lib.optionalAttrs stdenv.hostPlatform.isAarch64 {
    NIX_CFLAGS_COMPILE = "-march=armv8.1-a+crc";
  };

  cmakeFlags =
    [
      (lib.cmakeBool "NOGIT" true)

      # Architecture mega-options
      (lib.cmakeBool "ARM64" stdenv.hostPlatform.isAarch64)
      (lib.cmakeBool "RV64" stdenv.hostPlatform.isRiscV64)
      (lib.cmakeBool "PPC64LE" (stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian))
      (lib.cmakeBool "LARCH64" stdenv.hostPlatform.isLoongArch64)
    ]
    ++ lib.optionals stdenv.hostPlatform.isx86_64 [
      # x86_64 has no single mega-option; set the individual flags that apply.
      (lib.cmakeBool "LD80BITS" true)
      (lib.cmakeBool "NOALIGN" true)
    ]
    ++ [
      # DynaRec (JIT recompiler) per-arch flags.
      (lib.cmakeBool "ARM_DYNAREC" (withDynarec && stdenv.hostPlatform.isAarch64))
      (lib.cmakeBool "RV64_DYNAREC" (withDynarec && stdenv.hostPlatform.isRiscV64))
      (lib.cmakeBool "LARCH64_DYNAREC" (withDynarec && stdenv.hostPlatform.isLoongArch64))

      # Box32: run 32-bit x86 binaries through Box64.
      # BOX32_BINFMT registers the i386/i686 binfmt_misc entry automatically.
      (lib.cmakeBool "BOX32" true)
      (lib.cmakeBool "BOX32_BINFMT" true)
    ];

  installPhase = ''
    runHook preInstall
    install -Dm 0755 box64 "$out/bin/${finalAttrs.binaryName}"
    runHook postInstall
  '';

  doInstallCheck = false; # stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  installCheckPhase = ''
    runHook preInstallCheck

    echo "--- checking box64 runs ---"
    $out/bin/${finalAttrs.binaryName} -v

    echo "--- checking dynarec flag ---"
    $out/bin/${finalAttrs.binaryName} -v | grep ${lib.optionalString (!withDynarec) "-v"} Dynarec

    runHook postInstallCheck
  '';

  passthru = {
    updateScript = gitUpdater { rev-prefix = "v"; };
    tests.hello =
      runCommand "box32-test-hello" { nativeBuildInputs = [ finalAttrs.finalPackage ]; }
        ''
          BOX64_NOBANNER=0 BOX64_LOG=1 ${finalAttrs.binaryName} ${lib.getExe hello-x86_64} --version | tee $out
        '';
  };

  meta = {
    homepage = "https://box86.org/";
    description = "Run x86_64 (and i386 via Box32) Linux programs on non-x86 systems";
    changelog = "https://github.com/ptitSeb/box64/commits/${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      gador
      OPNA2608
    ];
    mainProgram = finalAttrs.binaryName;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "riscv64-linux"
      "powerpc64le-linux"
      "loongarch64-linux"
      "mips64el-linux"
    ];
  };
})