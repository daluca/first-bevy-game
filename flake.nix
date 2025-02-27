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
    pkgs = system: import nixpkgs {
      inherit system;
      overlays = [(import rust-overlay)];
    };
    rust = system: (pkgs system).rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
    bevyDependencies = system: with (pkgs system); [
      pkg-config
      alsa-lib
      udev
    ];
    rustPlatform = system: (pkgs system).makeRustPlatform {
      cargo = (rust system);
      rustc = (rust system);
    };
  in {
    checks = forEachSystem (system:
      let
        pkgs' = (pkgs system);
        rust' = (rust system);
        bevyDependencies' = (bevyDependencies system);
        rustPlatform' = (rustPlatform system);
      in {
        pre-commit = git-hooks.lib.${system}.run {
          src = ./.;
          settings.rust = {
            cargoManifestPath = "Cargo.toml";
            check.cargoDeps = rustPlatform'.importCargoLock { lockFile = ./Cargo.lock; };
          };
          hooks = rec {
            cargo-check = {
              enable = true;
              package = rust';
              extraPackages = bevyDependencies';
            };
            rustfmt = {
              enable = true;
              packageOverrides = {
                cargo = rust';
                rustfmt = rust';
              };
              extraPackages = bevyDependencies';
            };
            clippy = {
              enable = true;
              packageOverrides = {
                cargo = rust';
                clippy = rust';
              };
              extraPackages = bevyDependencies';
            };
            typos.enable = true;
            commitlint-rs = {
              enable = true;
              name = "commitlint-rs";
              description = "Asserts that Conventional Commits have been used for all commit messages according to the rules for this repo.";
              package = pkgs'.commitlint-rs;
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
        pkgs' = (pkgs system);
        rust' = (rust system);
        bevyDependencies' = (bevyDependencies system);
        pre-commit = self.checks.${system}.pre-commit;
      in {
        default = pkgs'.mkShell {
          inherit (pre-commit) shellHook;
          name = "first-bevy-game";
          buildInputs = [
            rust'
          ] ++ bevyDependencies' ++ pre-commit.enabledPackages;
          JUST_COMMAND_COLOR = "blue";
        };
      }
    );
  };
}
