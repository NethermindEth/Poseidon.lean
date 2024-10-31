import Poseidon.Hash
import Poseidon.Parameters.BabyBear

open Poseidon2
open BabyBear (p)

def input24 : Array <| Zmod p := Array.iota 23 |>.map .mk

def input2 : Array <| Zmod p := #[886409618, 1327899896, 1902407911, 591953491, 648428576, 1844789031, 1198336108,
            355597330, 1799586834, 59617783, 790334801, 1968791836, 559272107, 31054313,
            1042221543, 474748436, 135686258, 263665994, 1962340735, 1741539604, 449439011,
            1131357108, 50869465, 1589724894]

#eval Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input24
