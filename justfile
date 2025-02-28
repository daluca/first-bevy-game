[private]
default:
    just --list

run:
    cargo run -q

build:
    cargo build

check:
    pre-commit run --all-files

format:
    treefmt
