import Mathlib
import Poseidon.Profile
import Poseidon.MDS
import Poseidon.RoundConstants
import YatimaStdLib.YatimaMatrix
import YatimaStdLib.Monad

/-!
# The Poseidon hashing algorithm

This module contains the core hashing logic used to produce Poseidon hashes.

A hash is done in the context of a `HashProfile` which has the information of the basefield prime,
security level, width, and other constants. See `Poseidon.Profile` for a full description.

The main function is `hashInput`, but most users will find the `Poseidon.hash` in `Poseidon.HashImpl`
to be the more useful method.
-/

namespace Poseidon

/--
A context in which to perform the Poseidon Hash. A hashing context requires an MDS matrix for the
linear layers, and an array of round constants `roundConst` for the ARC layer.

The context can be generated from a HashProfile with some choices, but is not determined by it so
they are separated to allow for alternate implementations.
-/
structure Hash.Context (profile : HashProfile) where
  mdsMatrix : Array $ Array (ZMod profile.p)
  roundConst : Array (ZMod profile.p)

open Hash in
/--
This function generates a context from a Hash profile according to the Filecoin specifications for
the MDS matrix and round constants
-/
def HashProfile.genericCtx (profile : HashProfile) : Context profile where
  mdsMatrix := generatePoseidonMDS profile.p profile.t
  roundConst := generateRConstants false profile

namespace Hash

/--
The internal state for the hashing algorithm
-/
structure State (profile : HashProfile) where
  round : Nat
  state : Array (ZMod profile.p)

def initialState {profile : HashProfile} (input : Array (ZMod profile.p)) : State profile := ⟨0, input⟩

end Hash

instance : YatimaRing (ZMod P) where
  zero := 0
  one := 1
  coe := λ x => (x: ZMod P)

open Hash in
/--
The Monad in which the hashing is performed
-/
abbrev HashM (profile : HashProfile) := ReaderT (Context profile) $ StateM (State profile)

variable (profile : HashProfile)

namespace HashM

open YatimaMatrix in
def linearLayer : HashM profile PUnit := do
  let mds := (← read).mdsMatrix
  modify (fun ⟨r, vec⟩ => ⟨r, action mds vec⟩)

def addConst : HashM profile PUnit := do
  let t := profile.t
  let round := (← get).round
  let const := (← read).roundConst.extract (t * round) (t * round + t)
  modify fun ⟨r, vec⟩ => ⟨r, vec + const⟩

def fullRound : HashM profile PUnit :=
  addConst profile *>
  (modify fun ⟨r, vec⟩ => ⟨r.succ, vec.map profile.sBox⟩) *>
  linearLayer profile

def partialRound : HashM profile PUnit :=
  addConst profile *>
  (modify fun ⟨r, vec⟩ => ⟨r.succ, vec.set! 0 (profile.sBox vec[0]!)⟩) *>
  linearLayer profile

open Monad in
def runRounds : HashM profile PUnit :=
  repeatM (fullRound profile) (profile.fullRounds / 2) *>
  repeatM (partialRound profile) (profile.partRounds) *>
  repeatM (fullRound profile) (profile.fullRounds / 2)

open Hash in
/--
Runs all the rounds needed for the hashing algorithm and extracts the final state.
-/
def hash (context : Context profile) (input : Array (ZMod profile.p)) : State profile :=
  Prod.snd <$> StateT.run (ReaderT.run (runRounds profile) context) (initialState input)

end HashM

open Hash

/--
Validates the input vector and context before feeding them to the Hash function to avoid runtime
panics.

TODO : Add more validation to reduce the junk values being returned for bad inputs
-/
def validateInputs (context : Context profile)  (input : Array (ZMod profile.p)) : Bool :=
  input.size == profile.t &&
  context.roundConst.size == profile.t * (profile.fullRounds + profile.partRounds) &&
  profile.t == context.mdsMatrix.size
  -- && profile.t == context.mdsMatrix.transpose.size --  TODO: add this check back, for Array $ Array

/--
A wraper around `HashM.hash` which extracts only the final vector of outputs.

If the input is invalid according to `validateInputs` then a junk empty array is returned.
-/
def hashInputWithCtx (context : Context profile) (input : Array (ZMod profile.p)) : Array (ZMod profile.p) :=
  if validateInputs profile context input then (HashM.hash profile context input).state else #[]

/--
Hashes the input where the context is taken to be generated from the Profile.

Note: This will be slower than `hashInputWithCtx` as the context has to be generated every time,
so it is advised to use pre-computed contexts available in the `Poseidon.Parameters` folder.
-/
def hashInput (input : Array (ZMod profile.p)) : Array (ZMod profile.p) :=
  let context := profile.genericCtx
  hashInputWithCtx profile context input

end Poseidon

namespace Poseidon2

open Poseidon

def add_array [Add α] (v w: Array α) := v.zip w |>.map fun (x, y) => x + y

structure Hash.Context (profile : HashProfile) where
  internalMatrixDiag : Array (ZMod profile.p)
  fullRoundConstants : Array $ Array (ZMod profile.p)
  partialRoundConstants : Array (ZMod profile.p)

abbrev HashM (profile : HashProfile) := ReaderT (Poseidon2.Hash.Context profile) $ StateM (Hash.State profile)

def getPartialRound (round : Nat) (profile : HashProfile) : Nat :=
  let halfFullRound := profile.fullRounds / 2
  round - halfFullRound

def getFullRound (round : Nat) (profile : HashProfile) : Nat :=
  let halfFullRound := profile.fullRounds / 2
  if round <= halfFullRound then round else round - profile.partRounds

variable (profile : HashProfile)

def addFullConst : HashM profile PUnit := do
  let fullRound := getFullRound (← get).round profile
  let const := (← read).fullRoundConstants[fullRound]!
  modify fun ⟨r, vec⟩ => ⟨r, add_array vec const⟩

def addPartialConst : HashM profile PUnit := do
  let partialRound := getPartialRound (← get).round profile
  let const := (← read).partialRoundConstants[partialRound]!
  modify fun ⟨r, vec⟩ => ⟨r, vec.modify 0 (· + const)⟩

def internalMatrixAction (diag : Array (ZMod p)) (vec : Array (ZMod p)) : Array (ZMod p) :=
  let sum := vec.foldl (· + ·) 0
  vec.mapIdx fun idx a => sum + a * diag[idx]!

open YatimaMatrix in
def internalLinearLayer : HashM profile PUnit := do
  let diag := (← read).internalMatrixDiag
  modify (fun ⟨r, vec⟩ => ⟨r, internalMatrixAction diag vec⟩)

def matrix_action{R} [OfNat R (nat_lit 0)] [Add R] [Mul R] (M : Array (Array R)) (v : Array R) : Array R :=
  M.zip v |>.foldl (fun v (col, r) => add_array v (col.map (λ x => x * r))) (Array.replicate v.size 0)

-- depends on `vec` having size 4
def smallMatrixAction (vec : Array (ZMod p)) : Array (ZMod p) :=
  let smallMatrix : Array (Array (ZMod p)) :=
    #[#[2, 1, 1, 3],
      #[3, 2, 1, 1],
      #[1, 3, 2, 1],
      #[1, 1, 3, 2]]
  matrix_action smallMatrix vec

-- depends on `vec` having size 4 * t
def externalMatrixAction (vec : Array (ZMod p)) : Array (ZMod p) := Id.run do
  let t := vec.size / 4
  let mut result := #[]
  for idx in [:t] do
    result := result ++ smallMatrixAction (vec.extract (4 * idx) (4 * (idx + 1)))

  let sums := Array.iota 3 |>.map (fun k =>
                Array.iota (t - 1) |>.map (fun j => result[4 * j + k]!)
                             |>.foldl (· + ·) 0)

  for i in [:vec.size] do
    result := result.modify i (· + sums[i % 4]!)

  return result

open YatimaMatrix in
def externalLinearLayer : HashM profile PUnit := do
  modify (fun ⟨r, vec⟩ => ⟨r, externalMatrixAction vec⟩)

def fullRound : HashM profile PUnit :=
  addFullConst profile *>
  (modify fun ⟨r, vec⟩ => ⟨r.succ, vec.map profile.sBox⟩) *>
  externalLinearLayer profile

def partialRound : HashM profile PUnit :=
  addPartialConst profile *>
  (modify fun ⟨r, vec⟩ => ⟨r.succ, vec.modify 0 profile.sBox⟩) *>
  internalLinearLayer profile

open Monad in
def runRounds : HashM profile PUnit :=
  externalLinearLayer profile *>
  repeatM (fullRound profile) (profile.fullRounds / 2) *>
  repeatM (partialRound profile) (profile.partRounds) *>
  repeatM (fullRound profile) (profile.fullRounds / 2)

def initialState {profile : HashProfile} (input : Array (ZMod profile.p)) : Hash.State profile := ⟨0, input⟩

def hash (context : Poseidon2.Hash.Context profile) (input : Array (ZMod profile.p)) : Hash.State profile :=
  Prod.snd <$> StateT.run (ReaderT.run (runRounds profile) context) (initialState input)

def validateInputs (context : Poseidon2.Hash.Context profile) (input : Array (ZMod profile.p)) : Bool :=
  input.size == profile.t &&
  profile.t % 4 == 0 &&
  true && -- TODO: At some point we should check the sizes of the partial round and full round constants
  profile.t == context.internalMatrixDiag.size

def hashInputWithCtx (context : Poseidon2.Hash.Context profile) (input : Array (ZMod profile.p)) : Array (ZMod profile.p) :=
  if validateInputs profile context input then (hash profile context input).state else #[]

end Poseidon2
