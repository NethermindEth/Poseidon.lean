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

/-
# Based on Mathlib v4.12.0 - Mathlib/Testing/SlimCheck/Sampleable.lean

The following code is based on Sampleable.lean from Mathlib v4.12.0,
Used under the Apache-2.0 license,
  See https://github.com/leanprover-community/mathlib4/blob/v4.12.0/LICENSE
-/

/-- `Nat.shrink' n` creates a list of smaller natural numbers by
successively dividing `n` by 2 . For example, `Nat.shrink 5 = [2, 1, 0]`. -/
def Nat.shrink (n : Nat) : List Nat :=
  if h : 0 < n then
    let m := n/2
    have : m < n := by
      apply Nat.div_lt_self h
      decide
    m :: shrink m
  else
    []

instance Nat.shrinkable : Shrinkable Nat where
  shrink := Nat.shrink
  
/-- Shrink a list of a shrinkable type, either by discarding an element or shrinking an element. -/
instance List.shrinkable [Shrinkable α] : Shrinkable (List α) where
  shrink := fun L =>
    (L.mapIdx fun i _ => L.eraseIdx i) ++
    (L.mapIdx fun i a => (Shrinkable.shrink a).map fun a' => L.set i a').flatten

instance Nat.sampleableExt : SampleableExt Nat :=
  SampleableExt.mkSelfContained (do Gen.choose Nat 0 (← Gen.getSize))

-- Generate exactly 24-element lists for Poseidon2 testing
def Gen.list24 [Repr α] (x : Gen α) : Gen (List α) := do
  let mut res := []
  for _ in [:24] do
    res := (← x) :: res
  let final := res.reverse
  dbg_trace s!"Testing with: {repr final}"
  return final

instance List.sampleableExt [SampleableExt α] : SampleableExt (List α) where
  proxy := List (SampleableExt.proxy α)
  -- sample := Gen.listOf SampleableExt.sample -- Do not constrain list length
  sample := Gen.list24 SampleableExt.sample -- Only generate lists of length 24
  interp := List.map SampleableExt.interp

/-
# End of section of code based on Mathlib v4.12.0
-/

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
