import Poseidon.Hash
import Poseidon.Parameters.BabyBear
import Poseidon.FFI
import LSpec

open Poseidon2
open BabyBear (p)
open LSpec
open SlimCheck

instance : Shrinkable (List Nat) where
  shrink := fun l => l.tails.tail

instance : SampleableExt (List Nat) :=
  SampleableExt.mkSelfContained do
    let size ← Gen.getSize
    let len ← Gen.choose Nat 0 (min size 30)
    let mut result := []
    for _ in [:len] do
      let x ← Gen.choose Nat 0 (size * 100)
      result := x :: result
    return result.reverse

def input₁ : Array Nat := Array.range 24

def tests : TestSeq := group "Poseidon2 Lean vs Rust tests" $
  test "input₁" ((
    (FFI.poseidon2Permute24Nat input₁).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input₁).toList.map (fun x ↦ x.rep))) $
  test "input₁-reverse" ((
    (FFI.poseidon2Permute24Nat input₁).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input₁).toList.map (fun x ↦ x.rep))) $
  check "PBT" (∀ (i : List Nat), ((
    (FFI.poseidon2Permute24Nat i.toArray).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext i.toArray).toList.map (fun x ↦ x.rep))))

def main : IO UInt32 := lspecIO
  tests
