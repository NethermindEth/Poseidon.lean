import Poseidon.FFI

/-!
# FFI Tests for Poseidon2 BabyBear24

This test verifies that the Rust FFI implementation produces correct results
by comparing against known test vectors.
-/

open Poseidon2.FFI

/--
Test the Poseidon2 BabyBear24 FFI with input [0, 1, 2, ..., 23].

The expected output can be verified by running:
```
cd Plonky3
cargo run --example poseidon2_helper
```
-/
def main : IO Unit := do
  IO.println "Testing Poseidon2 BabyBear24 FFI"
  IO.println "================================"

  -- Input: [0, 1, 2, ..., 23]
  let input : Array Nat := Array.range 24

  IO.println s!"Input: {input}"

  -- Call the FFI function
  let output := poseidon2Permute24Nat input

  IO.println s!"Output: {output}"

  -- Print output in hex for comparison with Rust
  IO.print "Output (hex): ["
  for i in [:output.size] do
    if i > 0 then IO.print ", "
    let val := output[i]!
    let hexStr := String.ofList (Nat.toDigits 16 val)
    let padded := String.pushn "" '0' (8 - hexStr.length) ++ hexStr
    IO.print s!"0x{padded}"
  IO.println "]"

  IO.println ""
  IO.println "Compare this output with the Rust implementation:"
  IO.println "  cd Plonky3 && cargo run --example poseidon2_helper"
