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

-- Generate exactly 16-element lists for Poseidon2 testing
def Gen.list16 [Repr α] (x : Gen α) : Gen (List α) := do
  let mut res := []
  for _ in [:16] do
    res := (← x) :: res
  let final := res.reverse
  dbg_trace s!"Testing with: {repr final}"
  return final
  
-- Generate exactly 24-element lists for Poseidon2 testing
def Gen.list24 [Repr α] (x : Gen α) : Gen (List α) := do
  let mut res := []
  for _ in [:24] do
    res := (← x) :: res
  let final := res.reverse
  dbg_trace s!"Testing with: {repr final}"
  return final

namespace width16

local instance List.sampleableExt [SampleableExt α] : SampleableExt (List α) where
  proxy := List (SampleableExt.proxy α)
  sample := Gen.list16 SampleableExt.sample -- Only generate lists of length 16
  interp := List.map SampleableExt.interp

/-
# End of section of code based on Mathlib v4.12.0
-/

def input₁ : Array Nat := Array.range 16

#eval List.map (λ ( x : ZMod BabyBear.p)  ↦ (x.cast : ℤ)) (Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext input₁).toList

-- Rust Poseidon2 Hash output on input [0..15]:
--   [1906786279, 1737026427, 1959749225, 700325316, 1638050605, 1021608788, 1726691001, 1761127344, 1552405120, 417318995, 36799261, 1215172152, 614923223, 1300746575, 957311597, 304856115]
--   [1906786279, 1737026427, 1959749225, 700325316, 1638050605, 1021608788, 1726691001, 1761127344, 1552405120, 417318995, 36799261, 1215172152, 614923223, 1300746575, 957311597, 304856115]
-- And above line is Lean output from #eval above

-- Last 4 from Rust: 614923223, 1300746575, 957311597, 304856115
-- Last 4 from Lean: 614923223, 1300746575, 957311597, 304856115

-- 916771791, 1584598824, 189674455, 1963929763 -- before copying over full round and partial round constants
-- 916771791, 1584598824, 189674455, 1963929763 -- after copying over full round and partial round constants


def tests : TestSeq := group "Poseidon2 Lean vs Rust tests" $
  test "input₁" ((
    (FFI.poseidon2Permute16Nat input₁).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext input₁).toList.map (fun x ↦ x.cast))) $
  test "input₁-reverse" ((
    (FFI.poseidon2Permute16Nat input₁).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext input₁).toList.map (fun x ↦ x.cast))) $
  check "PBT" (∀ (i : List Nat), ((
    (FFI.poseidon2Permute16Nat i.toArray).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext i.toArray).toList.map (fun x ↦ x.cast))))

end width16

namespace width24

local instance List.sampleableExt [SampleableExt α] : SampleableExt (List α) where
  proxy := List (SampleableExt.proxy α)
  sample := Gen.list24 SampleableExt.sample -- Only generate lists of length 24
  interp := List.map SampleableExt.interp

/-
# End of section of code based on Mathlib v4.12.0
-/

def input₁ : Array Nat := Array.range 24

#eval input₁
#eval List.map (λ ( x : ZMod BabyBear.p)  ↦ (x.cast : ℤ)) (Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input₁).toList

-- Rust Poseidon2 Hash output on input [0..23]:
--   [1771108703, 1707989511, 1600983599, 1040326054, 1894886368, 1111683018, 345926078, 1375535692, 867525720, 8311067, 1861712515, 1511177830, 1933967479, 1240935237, 552758551, 1534019729, 1277506434, 1879040535, 1361987653, 420733846, 117604165, 874383778, 91790175, 890256414]

def tests : TestSeq := group "Poseidon2 Lean vs Rust tests - width 24" $
  test "input₁" (
    [] -- TODO -- (FFI.poseidon2Permute24Nat input₁).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input₁).toList.map (fun x ↦ (x.cast : ℤ)))) $
  test "input₁-reverse" (
    [] -- TODO -- (FFI.poseidon2Permute24Nat input₁).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input₁).toList.map (fun x ↦ (x.cast : ℤ)))) $
  check "PBT" (∀ (i : List Nat), (
    [] -- TODO -- (FFI.poseidon2Permute24Nat i.toArray).toList.map (fun x ↦ Int.ofNat x))
    = 
    ((Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext i.toArray).toList.map (fun x ↦ (x.cast : ℤ)))))

end width24

def tests' :=
  @Std.HashMap.ofList String (List TestSeq) instBEqOfDecidableEq instHashableString
    [("width 16 tests", [width16.tests]), ("width 24 tests", [width24.tests])]

def main : IO UInt32 := lspecIO
  tests' []
