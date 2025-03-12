{
  pkgs,
  lib,
  version,
  buildPackage,
  buildTimeDependencies,
  runTimeDependencies,
}:

buildPackage {
  inherit version;

  src = ../../.;

  nativeBuildInputs =
    with pkgs;
    [
      makeWrapper
    ]
    ++ buildTimeDependencies;

  buildInputs = runTimeDependencies;

  postInstall = # bash
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
