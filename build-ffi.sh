#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLONKY3_DIR="$SCRIPT_DIR/../Plonky3-review-A"
FFI_DIR="$PLONKY3_DIR/poseidon2-ffi"
LEAN_INCLUDE="$(lean --print-prefix)/include"

cd "$PLONKY3_DIR"
cargo build --release -p poseidon2-ffi

cd "$FFI_DIR"
gcc -fPIC -O2 -I"$LEAN_INCLUDE" -shared -o libposeidon2_ffi_lean.so \
    src/lean_shim.c \
    -Wl,--whole-archive "$PLONKY3_DIR/target/release/libposeidon2_ffi.a" -Wl,--no-whole-archive \
    -lpthread -ldl -lm

cp libposeidon2_ffi_lean.so "$SCRIPT_DIR/"
echo "Built: $SCRIPT_DIR/libposeidon2_ffi_lean.so"
