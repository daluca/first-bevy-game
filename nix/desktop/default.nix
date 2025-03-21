{
  pname,
  lib,
  version,
  rustPlatform,
  buildTimeDependencies,
  runtimeDependencies,
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

  buildInputs = runtimeDependencies;

  postInstall = # bash
    ''
      mkdir -p $out/bin/assets/fonts/
      cp ${fira-sans}/share/fonts/opentype/FiraSans-Bold.otf $out/bin/assets/fonts/
      wrapProgram $out/bin/${pname} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDependencies} \
    '';
}
