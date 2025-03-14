{
  pkgs,
  lib,
  version,
  buildPackage,
  buildTimeDependencies,
  runTimeDependencies,
}:
let
  projectRoot = ../../.;
in
buildPackage {
  inherit version;

  src = projectRoot;

  nativeBuildInputs =
    with pkgs;
    [
      makeWrapper
    ]
    ++ buildTimeDependencies;

  cargoconfig = lib.path.append projectRoot ".cargo/config.toml";

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

      mkdir -p $out/bin/assets/fonts/
      cp ${pkgs.fira-sans}/share/fonts/opentype/FiraSans-Bold.otf $out/bin/assets/fonts/
    '';
}
