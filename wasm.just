[private]
default:
    @just --justfile wasm.just --list

build:
    cargo build --target wasm32-unknown-unknown

run:
    cargo run --target wasm32-unknown-unknown
