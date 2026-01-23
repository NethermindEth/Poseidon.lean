#!/bin/bash
# Build script for Poseidon2 FFI library
#
# This script builds the Rust FFI library and prepares it for use with Lean.
#
# Prerequisites:
#   - Rust toolchain (cargo, rustc)
#   - GCC or Clang
#   - Lean 4 toolchain (for lean headers)
#
# Usage:
#   ./build-ffi.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLONKY3_DIR="$SCRIPT_DIR/../Plonky3"
FFI_DIR="$PLONKY3_DIR/poseidon2-ffi"

echo "=== Building Poseidon2 FFI Library ==="
echo ""

# Step 1: Build Rust library
echo "Step 1: Building Rust static library..."
cd "$PLONKY3_DIR"
cargo build --release -p poseidon2-ffi
echo "  ✓ Rust library built"

# Step 2: Build combined shared library
echo ""
echo "Step 2: Building combined shared library with C shim..."
cd "$FFI_DIR"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    LIB_EXT="dylib"
    SHARED_FLAG="-dynamiclib"
    LINK_FLAGS="-Wl,-force_load,$PLONKY3_DIR/target/release/libposeidon2_ffi.a"
else
    LIB_EXT="so"
    SHARED_FLAG="-shared"
    LINK_FLAGS="-Wl,--whole-archive $PLONKY3_DIR/target/release/libposeidon2_ffi.a -Wl,--no-whole-archive"
fi

# Find Lean include path
if command -v lean &> /dev/null; then
    LEAN_PREFIX=$(lean --print-prefix 2>/dev/null || echo "")
    if [ -n "$LEAN_PREFIX" ]; then
        LEAN_INCLUDE="$LEAN_PREFIX/include"
    fi
fi

# Fallback to elan paths
if [ ! -f "$LEAN_INCLUDE/lean/lean.h" ]; then
    LEAN_INCLUDE="$HOME/.elan/toolchains/leanprover-lean4-v4.12.0/include"
fi
if [ ! -f "$LEAN_INCLUDE/lean/lean.h" ]; then
    # Try current toolchain
    LEAN_INCLUDE="$HOME/.elan/toolchains/leanprover-lean4-v4.27.0-rc1/include"
fi
if [ ! -f "$LEAN_INCLUDE/lean/lean.h" ]; then
    echo "Error: Cannot find Lean headers. Please set LEAN_INCLUDE environment variable."
    echo "Expected location: \$LEAN_INCLUDE/lean/lean.h"
    exit 1
fi

echo "  Using Lean include path: $LEAN_INCLUDE"

# Compile
OUTPUT_LIB="libposeidon2_ffi_lean.$LIB_EXT"
gcc -fPIC -O2 -I"$LEAN_INCLUDE" $SHARED_FLAG -o "$OUTPUT_LIB" \
    src/lean_shim.c \
    $LINK_FLAGS \
    -lpthread -ldl -lm

echo "  ✓ Shared library built: $FFI_DIR/$OUTPUT_LIB"

# Step 3: Copy to feature-B
echo ""
echo "Step 3: Installing library to feature-B..."
cp "$OUTPUT_LIB" "$SCRIPT_DIR/"
echo "  ✓ Library installed to: $SCRIPT_DIR/$OUTPUT_LIB"

echo ""
echo "=== Build Complete ==="
echo ""
echo "You can now build the Lean project:"
echo "  cd $SCRIPT_DIR && lake build"
echo ""
echo "To test the FFI:"
echo "  lake exe Tests.FFI"
