import Poseidon.Hash
import Poseidon.Parameters.BabyBear

open Poseidon2
open BabyBear (p)

def input16 : Array <| Zmod p := Array.iota 15 |>.map .mk
def input24 : Array <| Zmod p := Array.iota 23 |>.map .mk

#eval Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext input16
#eval Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input24
