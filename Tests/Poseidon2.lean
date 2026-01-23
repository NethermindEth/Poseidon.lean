import Poseidon.Hash
import Poseidon.Parameters.BabyBear
import Poseidon.FFI
import LSpec

open Poseidon2
open BabyBear (p)
open LSpec

def input₁ : Array Nat := Array.range 24

def tests : TestSeq := group "Poseidon2 Lean vs Rust tests" $
  test "input₁" ((
    (FFI.poseidon2Permute24Nat input₁).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input₁).toList.map (fun x ↦ x.rep))) $
  test "input₁-reverse" ((
    (FFI.poseidon2Permute24Nat input₁).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input₁).toList.map (fun x ↦ x.rep))) -- $
  -- check "PBT" (∀ (i : List Nat), ((
  --   (FFI.poseidon2Permute24Nat i.toArray).toList.map (fun x ↦ Int.ofNat x))
  --   = 
  --   ((Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext i.toArray).toList.map (fun x ↦ x.rep))))

def main : IO UInt32 := lspecIO
  tests
