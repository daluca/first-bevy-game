{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "wasm-server-runner";
  version = "0.6.3+b748636";

  src = fetchFromGitHub {
    owner = "jakobhellermann";
    repo = "wasm-server-runner";
    rev = "b748636d120535c75f79eb734aec08d07b77502a";
    hash = "sha256-E6ZW8+SHngI2Gy5S1UI943BmpJDLkz0bs3hUcbQjwak=";
  };

  useFetchCargoVendor = true;

  cargoHash = "sha256-NBkmVlMLgIJH3txvQLVFwlM2FXEhllCaN6hvqAa96OM=";

  meta = with lib; {
    description = "cargo run for the browser";
    homepage = "https://github.com/jakobhellermann/wasm-server-runner";
    license = licenses.mit;
  };
}
