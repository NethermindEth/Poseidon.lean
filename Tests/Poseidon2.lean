import Poseidon.Hash
import Poseidon.Parameters.BabyBear
import LSpec

open Poseidon2
open BabyBear (p)
open LSpec
open SlimCheck

def input16 : Array <| Zmod p := Array.iota 15 |>.map .mk
def input24 : Array <| Zmod p := Array.iota 23 |>.map .mk

#eval Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext input16
#eval Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input24

structure Poseidon2Width16Test where
  name : String
  input : Array <| Zmod p
  expectedOutput : Array Int

-- Expected outputs obtained by running the Poseidon2 hash from the `poseidon2-air` crate
--   in https://github.com/NethermindEth/Plonky3 on the same inputs (using width 16).
def testInputs : List Poseidon2Width16Test := [
  Poseidon2Width16Test.mk "[0..15]" input16 #[1906786279, 1737026427, 1959749225, 700325316, 1638050605, 1021608788, 1726691001, 1761127344, 1552405120, 417318995, 36799261, 1215172152, 614923223, 1300746575, 957311597, 304856115],
  Poseidon2Width16Test.mk "[15..0]" input16.reverse #[418935550, 290312109, 1582160462, 275840810, 1906565755, 735795622, 776338246, 1235177379, 57156665, 1005479998, 1802403830, 337698487, 1359812170, 1540291456, 1600525356, 615611719]
  ]

def constructTest (t : Poseidon2Width16Test) : IO TestSeq:=
  pure $ test t.name (t.expectedOutput.toList == (List.map (fun x ↦ x.rep) (Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext t.input).toList))

def main : IO UInt32 := lspecEachIO testInputs constructTest

-- To run the tests use:
-- #eval main
-- Or run `lake exe Tests.Poseidon2`
