{
  lib,
  clangStdenv,
  fetchFromGitHub,
  pkg-config,
  makeDesktopItem,
  copyDesktopItems,
  freetype,
  libGL,
  libx11,
  libxext,
  libxfixes,
  libxrandr,
}:

clangStdenv.mkDerivation {
  pname = "raddebugger";
  version = "0.9.30-unstable-2026-11-04";

  src = fetchFromGitHub {
    owner = "EpicGames";
    repo = "raddebugger";
    rev = "5b0d5f67a46af5fffa52322e95a116dabf393103";
    hash = "sha256-fmFGAI2MCvvWAJ1GgmQ3rZOw5ocU+FzRpYSQeUH/z0o=";
  };

  nativeBuildInputs = [
    pkg-config
    copyDesktopItems
  ];
  buildInputs = [
    freetype
    libGL
    libx11
    libxext
    libxfixes
    libxrandr
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    bash build.sh clang release raddbg
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 build/raddbg "$out/bin/raddbg"
    install -Dm644 data/logo.png "$out/share/icons/hicolor/256x256/apps/raddebugger.png"
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "raddebugger";
      desktopName = "RAD Debugger";
      comment = "Native graphical debugger";
      exec = "raddbg";
      icon = "raddebugger";
      categories = [
        "Development"
        "Debugger"
      ];
      startupWMClass = "RADDBG";
    })
  ];

  meta = with lib; {
    description = "Native, user-mode, multi-process graphical debugger";
    homepage = "https://github.com/EpicGames/raddebugger";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "raddbg";
    maintainers = with maintainers; [ GabrielMaguire ];
  };
}
