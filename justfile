mod nix

[private]
default:
    just --list --list-submodules

run:
    cargo run --features bevy/dynamic_linking

build:
    cargo build --features bevy/dynamic_linking

check:
    pre-commit run --all-files

format:
    treefmt
