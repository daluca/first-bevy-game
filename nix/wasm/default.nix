{
  buildPackage,
  lld,
  version,
}:

buildPackage {
  inherit version;

  src = ../../.;

  release = false;

  CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
  CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_LINKER = "${lld}/bin/lld";

  cargoBuildOptions =
    defaultOptions:
    defaultOptions
    ++ [
      "--profile"
      "wasm-release"
    ];
}
