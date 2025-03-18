{
  pname,
  lib,
  version,
  rustPlatform,
  buildTimeDependencies,
  runTimeDependencies,
  makeWrapper,
  fira-sans,
}:
let
  projectRoot = ../../.;
in
rustPlatform.buildRustPackage {
  inherit pname version;

  src = projectRoot;

  cargoLock.lockFile = lib.path.append projectRoot "Cargo.lock";

  nativeBuildInputs = [
    makeWrapper
  ] ++ buildTimeDependencies;

  buildInputs = runTimeDependencies;

  postInstall = # bash
    ''
      mkdir -p $out/bin/assets/fonts/
      cp ${fira-sans}/share/fonts/opentype/FiraSans-Bold.otf $out/bin/assets/fonts/
      wrapProgram $out/bin/${pname} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runTimeDependencies}
    '';
}
