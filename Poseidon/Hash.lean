import Poseidon.Profile
import Poseidon.MDS
import Poseidon.RoundConstants
import YatimaStdLib.Zmod
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
  mdsMatrix : YatimaMatrix (Zmod profile.p)
  roundConst : Array (Zmod profile.p)

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
  state : Vector' (Zmod profile.p)

def initialState {profile : HashProfile} (input : Vector' (Zmod profile.p)) : State profile := ⟨0, input⟩

end Hash

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
def hash (context : Context profile) (input : Vector' (Zmod profile.p)) : State profile :=
  Prod.snd <$> StateT.run (ReaderT.run (runRounds profile) context) (initialState input)

end HashM

open Hash

/--
Validates the input vector and context before feeding them to the Hash function to avoid runtime
panics.

TODO : Add more validation to reduce the junk values being returned for bad inputs
-/
def validateInputs (context : Context profile)  (input : Vector' (Zmod profile.p)) : Bool :=
  input.size == profile.t &&
  context.roundConst.size == profile.t * (profile.fullRounds + profile.partRounds) &&
  profile.t == context.mdsMatrix.size &&
  profile.t == context.mdsMatrix.transpose.size

/--
A wraper around `HashM.hash` which extracts only the final vector of outputs.

If the input is invalid according to `validateInputs` then a junk empty array is returned.
-/
def hashInputWithCtx (context : Context profile) (input : Vector' (Zmod profile.p)) : Vector' (Zmod profile.p) :=
  if validateInputs profile context input then (HashM.hash profile context input).state else #[]

/--
Hashes the input where the context is taken to be generated from the Profile.

Note: This will be slower than `hashInputWithCtx` as the context has to be generated every time,
so it is advised to use pre-computed contexts available in the `Poseidon.Parameters` folder.
-/
def hashInput (input : Vector' (Zmod profile.p)) : Vector' (Zmod profile.p) :=
  let context := profile.genericCtx
  hashInputWithCtx profile context input

end Poseidon

namespace Poseidon2

open Poseidon (HashProfile Hash.State)

structure Hash.Context (profile : HashProfile) where
  internalMatrixDiag : Array (Zmod profile.p)
  fullRoundConstants : Array $ Array (Zmod profile.p)
  partialRoundConstants : Array (Zmod profile.p)

abbrev HashM (profile : HashProfile) := ReaderT (Hash.Context profile) $ StateM (Hash.State profile)

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
  modify fun ⟨r, vec⟩ => ⟨r, vec + const⟩

def addPartialConst : HashM profile PUnit := do
  let partialRound := getPartialRound (← get).round profile
  let const := (← read).partialRoundConstants[partialRound]!
  modify fun ⟨r, vec⟩ => ⟨r, vec.modify 0 (· + const)⟩

def internalMatrixAction (diag : Array (Zmod p)) (vec : Vector' (Zmod p)) : Vector' (Zmod p) :=
  let sum := vec.foldl (· + ·) 0
  vec.mapIdx fun idx a => sum + a * diag[idx]!

open YatimaMatrix in
def internalLinearLayer : HashM profile PUnit := do
  let diag := (← read).internalMatrixDiag
  modify (fun ⟨r, vec⟩ => ⟨r, internalMatrixAction diag vec⟩)

-- depends on `vec` having size 4
def smallMatrixAction (vec : Vector' (Zmod p)) : Vector' (Zmod p) :=
  let smallMatrix : YatimaMatrix (Zmod p) :=
    #[#[2, 1, 1, 3],
      #[3, 2, 1, 1],
      #[1, 3, 2, 1],
      #[1, 1, 3, 2]]
  smallMatrix.action vec

-- depends on `vec` having size 4 * t
def externalMatrixAction (vec : Vector' (Zmod p)) : Vector' (Zmod p) := Id.run do
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

def hash (context : Hash.Context profile) (input : Vector' (Zmod profile.p)) : Hash.State profile :=
  Prod.snd <$> StateT.run (ReaderT.run (runRounds profile) context) (Poseidon.Hash.initialState input)

def validateInputs (context : Hash.Context profile)  (input : Vector' (Zmod profile.p)) : Bool :=
  input.size == profile.t &&
  profile.t % 4 == 0 &&
  true && -- TODO: At some point we should check the sizes of the partial round and full round constants
  profile.t == context.internalMatrixDiag.size

def hashInputWithCtx (context : Hash.Context profile) (input : Vector' (Zmod profile.p)) : Vector' (Zmod profile.p) :=
  if Poseidon2.validateInputs profile context input then (hash profile context input).state else #[]

end Poseidon2
