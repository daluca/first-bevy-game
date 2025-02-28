[private]
default:
    just --justfile nix.just --list

check:
    nix flake check

format:
    nix fmt

build:
    nix build --print-build-logs
