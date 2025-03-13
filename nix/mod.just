mod wasm

set working-directory := '..'

[private]
default:
    @just --justfile nix/mod.just --list --list-submodules

check:
    nix flake check

format:
    nix fmt

build:
    nix build --print-build-logs

run: build
    ./result/bin/first-bevy-game
