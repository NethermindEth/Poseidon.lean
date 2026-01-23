import Poseidon.Hash
import Poseidon.Parameters.BabyBear
import Poseidon.FFI
import LSpec

open Poseidon2
open BabyBear (p)
open LSpec
open SlimCheck

def shrinkByPadWithZero (l :  List Nat) : List Nat :=
  match l with
  | [] => []
  | h :: tl => if h = 0 then 0 :: shrinkByPadWithZero tl else 0 :: tl

-- instance : Shrinkable (List Nat) where
--   shrink := fun l => l.tails

instance : SampleableExt (List Nat) :=
  SampleableExt.mkSelfContained do
    let size ← Gen.getSize
    let len ← Gen.choose Nat 0 (min size 30)
    let mut result := []
    for _ in [:len] do
      let x ← Gen.choose Nat 0 (size * 100)
      result := x :: result
    let final := result.reverse
    dbg_trace s!"Testing with: {final}"
    return final

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
