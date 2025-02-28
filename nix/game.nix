{
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

  nativeBuildInputs = buildTimeDependencies;

  buildInputs = runTimeDependencies;
}
