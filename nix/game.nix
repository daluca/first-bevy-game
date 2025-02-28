{
  pkgs,
  lib,
  version,
  rustPlatform,
  buildTimeDependencies,
  runTimeDependencies,
}:

rustPlatform.buildRustPackage {
  inherit version;

  pname = "first-bevy-game";

  src = ../.;

  cargoLock.lockFile = ../Cargo.lock;

  nativeBuildInputs =
    with pkgs;
    [
      makeWrapper
    ]
    ++ buildTimeDependencies;

  buildInputs = runTimeDependencies;

  postFixup = # bash
    ''
      wrapProgram $out/bin/first-bevy-game \
        --prefix LD_LIBRARY_PATH : "${
          with pkgs;
          lib.makeLibraryPath [
            vulkan-loader
            xorg.libX11
            xorg.libXcursor
            xorg.libXi
            libxkbcommon
          ]
        }"
    '';
}
