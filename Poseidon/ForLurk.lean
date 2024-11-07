import Poseidon.HashImpl
import Poseidon.Parameters.BabyBear
import Poseidon.Parameters.Lurk4
import Poseidon.Parameters.Lurk3

/-!
# Parameters for Lurk Profile

This module contains the definitions necessary to use the exact profile,
context, and input formatting to mirror the Poseidon hashing used in Lurk.
-/

namespace Poseidon.Lurk

open Poseidon

/-- The pre-computed hashing context used by Lurk for commitments-/
def Context3 : Hash.Context Lurk3.hashProfile :=
  ⟨Lurk3.MDS, Lurk3.roundConstants⟩

/-- The pre-computed hashing context used by Lurk. -/
def Context4 : Hash.Context Lurk4.hashProfile :=
  ⟨Lurk4.MDS, Lurk4.roundConstants⟩

/--
The hashing function used by Lurk for commitments that uses pre-initialized Lurk parameters and
constants
-/
def hash3 (f₁ f₂ f₃ : Zmod p) : Zmod p :=
  Poseidon.hash Lurk3.hashProfile Context3 #[f₁, f₂, f₃] .merkleTree

/--
The hashing function used by Lurk that uses pre-initialized Lurk parameters and
constants.
-/
def hash4 (f₁ f₂ f₃ f₄ : Zmod p) : Zmod p :=
  Poseidon.hash Lurk4.hashProfile Context4 #[f₁, f₂, f₃, f₄] .merkleTree

end Poseidon.Lurk

namespace Poseidon2.Lurk

open BabyBear (p)

def hash24 (input : Array (Zmod p)) : Array (Zmod p) :=
  Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input

def hash32 (input : Array (Zmod p)) : Array (Zmod p) :=
  Poseidon2.hashInputWithCtx BabyBear32.hashProfile BabyBear32.lurkContext input

def hash40 (input : Array (Zmod p)) : Array (Zmod p) :=
  Poseidon2.hashInputWithCtx BabyBear40.hashProfile BabyBear40.lurkContext input

def hash48 (input : Array (Zmod p)) : Array (Zmod p) :=
  Poseidon2.hashInputWithCtx BabyBear48.hashProfile BabyBear48.lurkContext input

end Poseidon2.Lurk
