{
  pkgs,
  lib,
  version,
  buildPackage,
  wasm-bindgen,
  lld,
}:
let
  projectRoot = ../../.;
in
buildPackage {
  inherit version;

  src = projectRoot;

  release = false;

  nativeBuildInputs = [
    wasm-bindgen
  ];

  CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
  CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_LINKER = "${lld}/bin/lld";

  cargoconfig = lib.path.append projectRoot ".cargo/config.toml";

  cargoBuildOptions =
    defaultOptions:
    defaultOptions
    ++ [
      "--profile"
      "wasm-release"
    ];

  overrideMain = _: {
    postInstall = # bash
      ''
        mkdir -p $out/html $out/html/assets/fonts
        cp assets/index.html $out/html/
        cp "${pkgs.fira-sans}/share/fonts/opentype/FireSans-Bold.otf $out/html/assets/fonts/
        wasm-bindgen \
          --no-typescript \
          --out-name first-bevy-game \
          --out-dir $out/html \
          --target web \
          $out/bin/first-bevy-game.wasm
      '';
  };
}
