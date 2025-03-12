{
  description = "First bevy game";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      git-hooks,
      treefmt-nix,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      supportedSystems = [ "x86_64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
      version = (fromTOML (builtins.readFile ./Cargo.toml)).package.version;
      edition = (fromTOML (builtins.readFile ./Cargo.toml)).package.edition;
      pkgs =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
      rust = system: (pkgs system).rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      rustPlatform =
        system:
        (pkgs system).makeRustPlatform {
          cargo = (rust system);
          rustc = (rust system);
        };
      naersk =
        system:
        (pkgs system).callPackage inputs.naersk {
          cargo = (rust system);
          rustc = (rust system);
        };
      buildTimeDependencies =
        system: with (pkgs system); [
          pkg-config
          vulkan-loader
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          libxkbcommon
        ];
      runTimeDependencies =
        system: with (pkgs system); [
          alsa-lib
          udev
        ];
      bevyDependencies =
        system:
        lib.flatten [
          (buildTimeDependencies system)
          (runTimeDependencies system)
        ];
      treefmt =
        system:
        treefmt-nix.lib.evalModule (pkgs system) (
          import ./treefmt.nix {
            inherit edition;
            rust = (rust system);
          }
        );
    in
    {
      checks = forEachSystem (
        system:
        let
          pkgs' = (pkgs system);
          rust' = (rust system);
          bevyDependencies' = (bevyDependencies system);
          rustPlatform' = (rustPlatform system);
          treefmt' = (treefmt system);
        in
        {
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
                settings.config-path = "rustfmt.toml";
              };
              clippy = {
                enable = true;
                packageOverrides = {
                  cargo = rust';
                  clippy = rust';
                };
                extraPackages = bevyDependencies';
              };
              treefmt = {
                enable = true;
                package = treefmt'.config.build.wrapper;
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
              };
            };
          };

          formatting = treefmt'.config.build.check self;
        }
      );

      devShells = forEachSystem (
        system:
        let
          inherit (self.packages.${system}) wasm-server-runner;
          pkgs' = (pkgs system);
          rust' = (rust system);
          bevyDependencies' = (bevyDependencies system);
          pre-commit = self.checks.${system}.pre-commit;
        in
        {
          default = pkgs'.mkShell {
            inherit (pre-commit) shellHook;
            name = "first-bevy-game";
            buildInputs =
              with pkgs';
              [
                just
              ]
              ++ [
                rust'
                wasm-server-runner
              ]
              ++ bevyDependencies'
              ++ pre-commit.enabledPackages;
            LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${
              with pkgs';
              lib.makeLibraryPath [
                vulkan-loader
                xorg.libX11
                xorg.libXcursor
                xorg.libXi
                libxkbcommon
              ]
            }";
            RUST_BACKTRACE = 1;
            JUST_COMMAND_COLOR = "blue";
          };
        }
      );

      formatter = forEachSystem (
        system:
        let
          treefmt' = (treefmt system);
        in
        treefmt'.config.build.wrapper
      );

      packages = forEachSystem (
        system:
        let
          pkgs' = (pkgs system);
          rustPlatform' = (rustPlatform system);
          buildTimeDependencies' = (buildTimeDependencies system);
          runTimeDependencies' = (runTimeDependencies system);
          naersk' = (naersk system);
        in
        {
          default = self.packages.${system}.first-bevy-game;

          first-bevy-game = import ./nix/game {
            inherit lib version;
            pkgs = pkgs';
            buildPackage = naersk'.buildPackage;
            buildTimeDependencies = buildTimeDependencies';
            runTimeDependencies = runTimeDependencies';
          };

          wasm = import ./nix/wasm {
            inherit version;
            buildPackage = naersk'.buildPackage;
            lld = pkgs'.llvmPackages_20.lld;
          };

          wasm-server-runner = pkgs'.callPackage ./nix/wasm-server-runner { rustPlatform = rustPlatform'; };
        }
      );
    };
}
