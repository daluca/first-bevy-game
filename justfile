mod nix
mod wasm

[private]
default:
    @just --list --list-submodules

build:
    cargo build --features bevy/dynamic_linking

run:
    cargo run --features bevy/dynamic_linking

check:
    pre-commit run --all-files

format:
    treefmt
