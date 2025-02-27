{
  description = "First bevy game";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, rust-overlay, git-hooks, ... }:
  let
    supportedSystems = [ "x86_64-linux" ];
    forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
  in {
    checks = forEachSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        pre-commit = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = rec {
            typos.enable = true;
            commitlint-rs = {
              enable = true;
              name = "commitlint-rs";
              description = "Asserts that Conventional Commits have been used for all commit messages according to the rules for this repo.";
              package = pkgs.commitlint-rs;
              entry = "${commitlint-rs.package}/bin/commitlint --edit .git/COMMIT_EDITMSG";
              stages = [ "prepare-commit-msg" ];
              pass_filenames = false;
              require_serial = true;
              verbose = true;
            };
          };
        };
      }
    );

    devShells = forEachSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [(import rust-overlay)];
        };
        rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        bevyDependencies = with pkgs; [
          pkg-config
          alsa-lib
          udev
        ];
        pre-commit = self.checks.${system}.pre-commit;
      in {
        default = pkgs.mkShell {
          inherit (pre-commit) shellHook;
          name = "first-bevy-game";
          buildInputs = [
            rust
          ] ++ bevyDependencies ++ pre-commit.enabledPackages;
          JUST_COMMAND_COLOR = "blue";
        };
      }
    );
  };
}
