{
  description = "First bevy game";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

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
    }:
    let
      inherit (nixpkgs) lib;
      supportedSystems = [ "x86_64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
      cargo = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package;
      version = cargo.version;
      edition = cargo.edition;
      pname = cargo.name;
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
      buildTimeDependencies =
        system: with (pkgs system); [
          pkg-config
        ];
      x11Dependencies =
        system: with (pkgs system); [
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr
        ];
      waylandDependencies =
        system: with (pkgs system); [
          libxkbcommon
          wayland
        ];
      runTimeDependencies =
        system:
        with (pkgs system);
        lib.flatten [
          udev
          alsa-lib
          vulkan-loader
        ]
        ++ (x11Dependencies system)
        ++ (waylandDependencies system);
      bevyDependencies =
        system: lib.flatten (buildTimeDependencies system) ++ (runTimeDependencies system);
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
              check-github-workflows = {
                enable = true;
                name = "check-github-workflows-jsonschema";
                description = "Validate GitHub Workflows against the schema provided by SchemaStore";
                package = pkgs'.check-jsonschema;
                entry = "${check-github-workflows.package}/bin/check-jsonschema --builtin-schema vendor.github-workflows";
                args = [ "--verbose" ];
                files = "^\\.github/workflows/[^/]+$";
                types = [ "yaml" ];
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
          runTimeDependencies' = (runTimeDependencies system);
          bevyDependencies' = (bevyDependencies system);
          pre-commit = self.checks.${system}.pre-commit;
        in
        {
          default = pkgs'.mkShell {
            name = "first-bevy-game";
            buildInputs =
              with pkgs';
              [
                just
                wasm-bindgen-cli_0_2_100
              ]
              ++ [
                rust'
                wasm-server-runner
              ]
              ++ bevyDependencies'
              ++ pre-commit.enabledPackages;
            shellHook = # bash
              ''
                mkdir -p assets/fonts/
                ln --symbolic --force ${pkgs'.fira-sans}/share/fonts/opentype/FiraSans-Bold.otf assets/fonts/
              ''
              + pre-commit.shellHook;
            LD_LIBRARY_PATH = lib.makeLibraryPath runTimeDependencies';
            RUST_BACKTRACE = 1;
            JUST_COMMAND_COLOR = "blue";
          };

          ci = pkgs'.mkShell {
            name = "ci";
            buildInputs = with pkgs'; [
              just
            ];
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
        in
        {
          default = self.packages.${system}.desktop;

          desktop = import ./nix/desktop {
            inherit pname version lib;
            rustPlatform = rustPlatform';
            buildTimeDependencies = buildTimeDependencies';
            runTimeDependencies = runTimeDependencies';
            makeWrapper = pkgs'.makeWrapper;
            fira-sans = pkgs'.fira-sans;
          };

          wasm = import ./nix/wasm {
            inherit lib;
            desktop = self.packages.${system}.desktop;
            wasm-bindgen-cli = pkgs'.wasm-bindgen-cli_0_2_100;
            fira-sans = pkgs'.fira-sans;
          };

          wasm-server-runner = pkgs'.callPackage ./nix/wasm-server-runner { rustPlatform = rustPlatform'; };
        }
      );
    };
}
