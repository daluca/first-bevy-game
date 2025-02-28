{
  rustPlatform,
  buildTimeDependencies,
  runTimeDependencies,
}:

rustPlatform.buildRustPackage {
  pname = "first-bevy-game";
  version = "0.0.1";

  src = ../.;

  cargoLock.lockFile = ../Cargo.lock;

  nativeBuildInputs = buildTimeDependencies;

  buildInputs = runTimeDependencies;
}
