set working-directory := '../..'

[private]
default:
    @just --justfile nix/wasm/mod.just --list

build:
    nix build .#wasm --print-build-logs

run: build
    nix run .#wasm-server-runner result/bin/first-bevy-game.wasm
