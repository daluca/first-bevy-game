mod nix

[private]
default:
    just --list --list-submodules

run:
    cargo run -q

build:
    cargo build

check:
    pre-commit run --all-files

format:
    treefmt
