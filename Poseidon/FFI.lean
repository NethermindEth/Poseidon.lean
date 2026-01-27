/-!
# FFI bindings for Poseidon2 via Rust/Plonky3

This module provides FFI bindings to call the Poseidon2 BabyBear permutation
implemented in Rust (Plonky3) from Lean.

Supported widths:
- **16 elements** (64 bytes): BabyBear16
- **24 elements** (96 bytes): BabyBear24

The Rust implementation is compiled as a shared library (libposeidon2_ffi_lean.so)
which exports C-compatible functions wrapped for Lean's object system.

## Building

1. Build the Rust library:
   ```
   cd Plonky3/poseidon2-ffi
   make
   make install
   ```

2. Build the Lean project (it will link against the library)

## Functions

### Width 16 (BabyBear16)
- `poseidon2Permute16Raw`: Low-level function taking ByteArray (64 bytes)
- `poseidon2Permute16UInt32`: Takes and returns Array UInt32 (16 elements)
- `poseidon2Permute16Nat`: Takes and returns Array Nat (16 elements)

### Width 24 (BabyBear24)
- `poseidon2Permute24Raw`: Low-level function taking ByteArray (96 bytes)
- `poseidon2Permute24UInt32`: Takes and returns Array UInt32 (24 elements)
- `poseidon2Permute24Nat`: Takes and returns Array Nat (24 elements)
-/

namespace Poseidon2.FFI

-- =============================================================================
-- Helper functions for byte conversion
-- =============================================================================

/-- Convert a UInt32 to 4 bytes in little-endian order -/
def uint32ToBytes (n : UInt32) : ByteArray :=
  ByteArray.mk #[
    (n &&& 0xFF).toUInt8,
    ((n >>> 8) &&& 0xFF).toUInt8,
    ((n >>> 16) &&& 0xFF).toUInt8,
    ((n >>> 24) &&& 0xFF).toUInt8
  ]

/-- Convert 4 bytes in little-endian order to a UInt32 -/
def bytesToUInt32 (bytes : ByteArray) (offset : Nat) : UInt32 :=
  let b0 := bytes.get! offset |>.toUInt32
  let b1 := bytes.get! (offset + 1) |>.toUInt32
  let b2 := bytes.get! (offset + 2) |>.toUInt32
  let b3 := bytes.get! (offset + 3) |>.toUInt32
  b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24)

/-- Convert an array of UInt32 to a ByteArray of packed values -/
def uint32ArrayToBytes (arr : Array UInt32) : ByteArray := Id.run do
  let mut result : ByteArray := .empty
  for elem in arr do
    result := result ++ uint32ToBytes elem
  return result

/-- Convert a ByteArray of packed values to an array of UInt32 -/
def bytesToUInt32Array (bytes : ByteArray) : Array UInt32 := Id.run do
  let numElements := bytes.size / 4
  let mut result : Array UInt32 := Array.mkEmpty numElements
  for i in [:numElements] do
    result := result.push (bytesToUInt32 bytes (i * 4))
  return result

-- =============================================================================
-- Width 16 (BabyBear16) - 64 bytes
-- =============================================================================

/--
Low-level FFI function that calls the Rust Poseidon2 BabyBear16 permutation.

Takes a ByteArray of 64 bytes (16 × 4-byte little-endian u32 values) as input
and returns a ByteArray of 64 bytes as output.

Note: This function is opaque - the actual implementation is in the Rust library.
When the library is not linked, calling this function will cause a runtime error.
-/
@[extern "lean_poseidon2_babybear16_permute_wrapper"]
opaque poseidon2Permute16Raw (input : @& ByteArray) : ByteArray

/--
Apply the Poseidon2 BabyBear16 permutation using the Rust FFI.

Takes an array of 16 UInt32 values and returns the permuted state as 16 UInt32 values.
Values should be canonical BabyBear field elements (< 2013265921).

Returns the input unchanged if the size is not exactly 16.
-/
def poseidon2Permute16UInt32 (input : Array UInt32) : Array UInt32 :=
  if input.size ≠ 16 then
    input  -- Return unchanged if wrong size
  else
    let inputBytes := uint32ArrayToBytes input
    let outputBytes := poseidon2Permute16Raw inputBytes
    bytesToUInt32Array outputBytes

/--
Apply the Poseidon2 BabyBear16 permutation using the Rust FFI.

Takes an array of 16 natural numbers and returns the permuted state.
Values should be canonical BabyBear field elements (< 2013265921).

This is a convenience wrapper around `poseidon2Permute16UInt32`.
-/
def poseidon2Permute16Nat (input : Array Nat) : Array Nat :=
  if input.size ≠ 16 then
    input
  else
    let inputU32 := input.map (·.toUInt32)
    let outputU32 := poseidon2Permute16UInt32 inputU32
    outputU32.map (·.toNat)

-- =============================================================================
-- Width 24 (BabyBear24) - 96 bytes
-- =============================================================================

/--
Low-level FFI function that calls the Rust Poseidon2 BabyBear24 permutation.

Takes a ByteArray of 96 bytes (24 × 4-byte little-endian u32 values) as input
and returns a ByteArray of 96 bytes as output.

Note: This function is opaque - the actual implementation is in the Rust library.
When the library is not linked, calling this function will cause a runtime error.
-/
@[extern "lean_poseidon2_babybear24_permute_wrapper"]
opaque poseidon2Permute24Raw (input : @& ByteArray) : ByteArray

/--
Apply the Poseidon2 BabyBear24 permutation using the Rust FFI.

Takes an array of 24 UInt32 values and returns the permuted state as 24 UInt32 values.
Values should be canonical BabyBear field elements (< 2013265921).

Returns the input unchanged if the size is not exactly 24.
-/
def poseidon2Permute24UInt32 (input : Array UInt32) : Array UInt32 :=
  if input.size ≠ 24 then
    input  -- Return unchanged if wrong size
  else
    let inputBytes := uint32ArrayToBytes input
    let outputBytes := poseidon2Permute24Raw inputBytes
    bytesToUInt32Array outputBytes

/--
Apply the Poseidon2 BabyBear24 permutation using the Rust FFI.

Takes an array of 24 natural numbers and returns the permuted state.
Values should be canonical BabyBear field elements (< 2013265921).

This is a convenience wrapper around `poseidon2Permute24UInt32`.
-/
def poseidon2Permute24Nat (input : Array Nat) : Array Nat :=
  if input.size ≠ 24 then
    input
  else
    let inputU32 := input.map (·.toUInt32)
    let outputU32 := poseidon2Permute24UInt32 inputU32
    outputU32.map (·.toNat)

end Poseidon2.FFI
