{
  description = "First bevy game";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, rust-overlay, ... }:
  let
    supportedSystems = [ "x86_64-linux" ];
    forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
  in {
    devShells = forEachSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [(import rust-overlay)];
        };
        rust = pkgs.rust-bin.stable.latest.default;
        bevyDependencies = with pkgs; [
          pkg-config
          alsa-lib
          udev
        ];
      in {
        default = pkgs.mkShell {
          name = "first-bevy-game";
          buildInputs = [
            rust
          ] ++ bevyDependencies;
          JUST_COMMAND_COLOR = "blue";
        };
      }
    );
  };
}
