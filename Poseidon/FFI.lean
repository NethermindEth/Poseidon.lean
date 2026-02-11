/-! FFI bindings for Poseidon2 BabyBear16 permutation via Rust/Plonky3 -/

namespace Poseidon2.FFI

def uint32ToBytes (n : UInt32) : ByteArray :=
  ByteArray.mk #[
    (n &&& 0xFF).toUInt8,
    ((n >>> 8) &&& 0xFF).toUInt8,
    ((n >>> 16) &&& 0xFF).toUInt8,
    ((n >>> 24) &&& 0xFF).toUInt8
  ]

def bytesToUInt32 (bytes : ByteArray) (offset : Nat) : UInt32 :=
  let b0 := bytes.get! offset |>.toUInt32
  let b1 := bytes.get! (offset + 1) |>.toUInt32
  let b2 := bytes.get! (offset + 2) |>.toUInt32
  let b3 := bytes.get! (offset + 3) |>.toUInt32
  b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24)

def uint32ArrayToBytes (arr : Array UInt32) : ByteArray := Id.run do
  let mut result : ByteArray := .empty
  for elem in arr do
    result := result ++ uint32ToBytes elem
  return result

def bytesToUInt32Array (bytes : ByteArray) : Array UInt32 := Id.run do
  let mut result : Array UInt32 := Array.mkEmpty (bytes.size / 4)
  for i in [:bytes.size / 4] do
    result := result.push (bytesToUInt32 bytes (i * 4))
  return result

@[extern "lean_poseidon2_babybear16_permute_wrapper"]
opaque poseidon2Permute16Raw (input : @& ByteArray) : ByteArray

def poseidon2Permute16UInt32 (input : Array UInt32) : Array UInt32 :=
  if input.size ≠ 16 then input
  else bytesToUInt32Array (poseidon2Permute16Raw (uint32ArrayToBytes input))

def poseidon2Permute16Nat (input : Array Nat) : Array Nat :=
  if input.size ≠ 16 then input
  else (poseidon2Permute16UInt32 (input.map (·.toUInt32))).map (·.toNat)

end Poseidon2.FFI
