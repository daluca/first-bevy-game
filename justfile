[private]
default:
    just --list

run:
    cargo run -q

build:
    cargo build

check:
    nix flake check
