{
  lib,
  desktop,
  wasm-bindgen-cli,
  fira-sans,
}:

desktop.overrideAttrs (oldAttrs: {
  buildPhase = # bash
    ''
      cargo build --profile wasm-release --target wasm32-unknown-unknown
    '';

  installPhase = # bash
    ''
      mkdir -p $out/bin/ $out/html/assets/fonts/
      cp target/wasm32-unknown-unknown/wasm-release/${oldAttrs.pname}.wasm $out/bin
      cp assets/index.html $out/html/
      cp ${fira-sans}/share/fonts/opentype/FiraSans-Bold.otf $out/html/assets/fonts/
      wasm-bindgen \
        --no-typescript \
        --out-name ${oldAttrs.pname} \
        --out-dir $out/html \
        --target web \
        $out/bin/${oldAttrs.pname}.wasm
    '';

  doCheck = false;

  nativeBuildInputs = [
    wasm-bindgen-cli
  ] ++ (lib.ifilter0 (i: _: i != 0) oldAttrs.nativeBuildInputs);
})
