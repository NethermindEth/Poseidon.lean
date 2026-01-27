import Poseidon.FFI

/-!
# FFI Tests for Poseidon2 BabyBear

This test verifies that the Rust FFI implementation produces correct results
for both supported widths (16 and 24).

The expected outputs can be verified by running:
```
cd Plonky3
cargo run --example poseidon2_helper
```
-/

open Poseidon2.FFI

/-- Helper to print an array in hex format -/
def printArrayHex (arr : Array Nat) : IO Unit := do
  IO.print "["
  for i in [:arr.size] do
    if i > 0 then IO.print ", "
    let val := arr[i]!
    let hexStr := String.ofList (Nat.toDigits 16 val)
    let padded := String.pushn "" '0' (8 - hexStr.length) ++ hexStr
    IO.print s!"0x{padded}"
  IO.println "]"

def main : IO Unit := do
  IO.println "Testing Poseidon2 BabyBear FFI (multiple widths)"
  IO.println "================================================="
  IO.println ""

  -- Test width 16
  IO.println "=== Width 16 (BabyBear16) ==="
  let input16 : Array Nat := Array.range 16
  IO.println s!"Input: {input16}"
  let output16 := poseidon2Permute16Nat input16
  IO.println s!"Output: {output16}"
  IO.print "Output (hex): "
  printArrayHex output16
  IO.println ""

  -- Test width 24
  IO.println "=== Width 24 (BabyBear24) ==="
  let input24 : Array Nat := Array.range 24
  IO.println s!"Input: {input24}"
  let output24 := poseidon2Permute24Nat input24
  IO.println s!"Output: {output24}"
  IO.print "Output (hex): "
  printArrayHex output24
  IO.println ""

  IO.println "Compare this output with the Rust implementation:"
  IO.println "  cd Plonky3 && cargo run --example poseidon2_helper"
