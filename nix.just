[private]
default:
    @just --justfile nix.just --list

check:
    nix flake check

format:
    nix fmt

build:
    nix build --print-build-logs

run: build
    ./result/bin/first-bevy-game

build-wasm:
    nix build .#wasm --print-build-logs

run-wasm: build-wasm
    nix run .#wasm-server-runner result/bin/first-bevy-game.wasm
