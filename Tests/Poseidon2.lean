import Poseidon.Hash
import Poseidon.Parameters.BabyBear
import LSpec

open Poseidon2
open LSpec
open SlimCheck

def input16 : Array <| ZMod p := Array.iota 15
def input24 : Array <| ZMod p := Array.iota 23

-- #eval Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext input16
-- #eval Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext input16.reverse
-- #eval Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input24
-- #eval Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input24.reverse

structure Poseidon2Test where
  name : String
  profile : Poseidon.HashProfile
  context : Hash.Context profile
  input : Array <| ZMod profile.p
  expectedOutput : Array Int

-- Expected outputs obtained by running the Poseidon2 hash from the HorizenLabs implementation of Poseidon 2
--   in https://github.com/NethermindEth/HorizenLabs-poseidon2/tree/Dan/PBT on the same inputs.
--   The relevant parameters and constants where altered first in the HorizenLabs implementation
--   before generating these expected outputs.
def testInputs : List Poseidon2Test := [
  Poseidon2Test.mk "[0..15]" BabyBear16.hashProfile BabyBear16.lurkContext input16 #[1906786279, 1737026427, 1959749225, 700325316, 1638050605, 1021608788, 1726691001, 1761127344, 1552405120, 417318995, 36799261, 1215172152, 614923223, 1300746575, 957311597, 304856115],
  Poseidon2Test.mk "[15..0]" BabyBear16.hashProfile BabyBear16.lurkContext input16.reverse #[418935550, 290312109, 1582160462, 275840810, 1906565755, 735795622, 776338246, 1235177379, 57156665, 1005479998, 1802403830, 337698487, 1359812170, 1540291456, 1600525356, 615611719],
  Poseidon2Test.mk "[0..23]" BabyBear24.hashProfile BabyBear24.lurkContext input24 #[1258400453, 1053111865, 110582201, 551951226, 757801152, 1050692695, 853215329, 1906090252, 638837033, 729997437, 1294096437, 1566504438, 893448705, 573091011, 1848151681, 1233526615, 1629091534, 260829253, 1776424712, 651265962, 1185497831, 844066758, 500223253, 438677666],
  Poseidon2Test.mk "[23..0]" BabyBear24.hashProfile BabyBear24.lurkContext input24.reverse #[1809440065, 1948276961, 682939406, 725662042, 645865437, 983860562, 1509721042, 746492143, 1447569852, 636032329, 1575366109, 396824076, 355809548, 1502830900, 1448500967, 1094454101, 293489965, 834880784, 812206571, 692524771, 273153538, 1324325644, 530472741, 294687150],
  ]

def constructTest (t : Poseidon2Test) : IO TestSeq:=
  pure $ test t.name (t.expectedOutput.toList == (List.map (fun (x : ZMod t.profile.p) ↦ x.cast) (Poseidon2.hashInputWithCtx t.profile t.context t.input).toList))

def main : IO UInt32 := lspecEachIO testInputs constructTest

-- To run the tests use:
-- #eval main
-- Or run `lake exe Tests.Poseidon2`
