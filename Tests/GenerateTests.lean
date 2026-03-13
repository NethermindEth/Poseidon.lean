import Mathlib
import LSpec
import Poseidon.Hash
import Poseidon.Parameters.BabyBear

open Poseidon2
open LSpec
open SlimCheck

def generateRandomListHelper (listLength : Nat) (lowerBound upperBound : ℤ) : Gen (List ℤ) :=
  match listLength with
  | 0 => pure []
  | Nat.succ listLength' => do
    let h ← Gen.choose ℤ lowerBound upperBound
    let tl ← generateRandomListHelper listLength' lowerBound upperBound
    return h :: tl

def generateRandomList (lowerBound upperBound : ℤ) : Gen (List ℤ) := do
  generateRandomListHelper (← Gen.getSize) lowerBound upperBound

def generateRandomLists (listLength : Nat) (step upperBoundStart : ℤ) : Gen (List (List ℤ)) :=
  match listLength with
  | 0 => pure []
  | Nat.succ listLength' => do
    let h ← generateRandomList 0 upperBoundStart
    let tl ← (generateRandomLists listLength' step (upperBoundStart + step))
    return h :: tl

def generateTestCases : Gen (List (List ℤ)) := do
  let l₁ ← generateRandomLists 5 1 0
  let l₂ ← generateRandomLists 10 5 5
  let l₃ ← generateRandomLists 85 25 25
  let l₄ ← generateRandomLists 100 1000 1000
  return l₁ ++ l₂ ++ l₃ ++ l₄

-- Based on `#print Gen.run`
def runWith {α : Type} (seed : Nat) (x : Gen α) (size : ℕ) : BaseIO α :=
  SlimCheck.IO.runRandWith seed (ReaderT.run x { down := size })

def constructHorizenLabsRustTest (width : ℕ) (idx : ℕ) (l : List ℤ) : String :=
  let testNum := idx + 1
  s!"    let input{testNum}: Vec<Scalar> = vec!{l}.into_iter().map(|x: usize| FpBabyBear::from(x as u32)).collect();\n" ++
  s!"    let perm{testNum} = instance{width}.permutation(&input{testNum});\n" ++
  s!"    print_baby_bear_vec(perm{testNum});\n"

def rustHLBefore16 : String :=
   "use itertools::Itertools;
use zkhash::{fields::babybear::FpBabyBear, poseidon2::{poseidon2::Poseidon2, poseidon2_instance_babybear::{POSEIDON2_BABYBEAR_16_PARAMS, POSEIDON2_BABYBEAR_24_PARAMS}}};

type Scalar = FpBabyBear;

pub fn main() {
    println!(\"Width 16:\");
    tests16();
    println!(\"Width 24:\");
    tests24();
}

fn print_baby_bear_vec(l : Vec<Scalar>) {
    let l2 : Vec<String> = l.into_iter().map(|x| format!(\"{}\", x)).collect();
    println!(\"[{}]\", l2.iter().format(\", \"));
}

fn tests16() {
    let instance16 = Poseidon2::new(&POSEIDON2_BABYBEAR_16_PARAMS);"

def rustHLAfter16Before24 : String :=
  "}

fn tests24() {
    let instance24 = Poseidon2::new(&POSEIDON2_BABYBEAR_24_PARAMS);"

def rustHLAfter24 : String := "}"

def printHorizenLabsRustTests : IO Unit := do
  let seed := 42
  let g := generateTestCases
  let l16 ← runWith seed g 16
  let l24 ← runWith seed g 24
  
  IO.println rustHLBefore16
  IO.println ((l16.mapIdx (constructHorizenLabsRustTest 16)).foldl (fun x y => x ++ "\n" ++ y) "")
  IO.println rustHLAfter16Before24
  IO.println ((l24.mapIdx (constructHorizenLabsRustTest 24)).foldl (fun x y => x ++ "\n" ++ y) "")
  IO.println rustHLAfter24

-- #eval printHorizenLabsRustTests

def constructPlonky3NonAirRustTest  (width : ℕ) (idx : ℕ) (l : List ℤ) : String :=
  let testNum := idx + 1
  s!"    let input{testNum} = {l}.map(|x: u32| BabyBear::new(x as u32));\n" ++
  s!"    let perm{testNum} : Vec<u32> = poseidon2_width{width}.permute(input{testNum}).iter().map(|x| x.as_canonical_u32()).collect();\n" ++
  s!"    println!(\"{"{"}:?{"}"}\", perm{testNum});\n"

def rustP3Before16 : String :=
   "use p3_baby_bear::{BabyBear, default_babybear_poseidon2_16, default_babybear_poseidon2_24};
use p3_field::PrimeField32;
use p3_symmetric::Permutation;

fn main() {
    let poseidon2_width16 = default_babybear_poseidon2_16();
    let poseidon2_width24 = default_babybear_poseidon2_24();
    
    println!(\"Width 16:\");
"

def rustP3After16Before24 : String :=
  "    println!(\"Width 24:\");
"

def rustP3After24 : String := "}"

def printPlonky3NonAirRustTests : IO Unit := do
  let seed := 42
  let g := generateTestCases
  let l16 ← runWith seed g 16
  let l24 ← runWith seed g 24
  
  IO.println rustP3Before16
  IO.println ((l16.mapIdx (constructPlonky3NonAirRustTest 16)).foldl (fun x y => x ++ "\n" ++ y) "")
  IO.println rustP3After16Before24
  IO.println ((l24.mapIdx (constructPlonky3NonAirRustTest 24)).foldl (fun x y => x ++ "\n" ++ y) "")
  IO.println rustP3After24

-- #eval printPlonky3NonAirRustTests

def runLeanTestWidth16 (input16 : List ℤ) : List ℤ :=
  let input16' := (List.map (fun (x : ZMod BabyBear.p) ↦ x.cast) input16).toArray
  (Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext input16').toList.map (fun (x : ZMod BabyBear.p) ↦ x.cast)

def runLeanTestWidth24 (input24 : List ℤ) : List ℤ :=
  let input24' := (List.map (fun (x : ZMod BabyBear.p) ↦ x.cast) input24).toArray
  (Poseidon2.hashInputWithCtx BabyBear24.hashProfile BabyBear24.lurkContext input24').toList.map (fun (x : ZMod BabyBear.p) ↦ x.cast)

def printLeanOutputs : IO Unit := do
  let seed := 42
  let g := generateTestCases
  let l16 ← runWith seed g 16
  let l24 ← runWith seed g 24
  
  IO.print "Width 16:"
  IO.println ((l16.map (runLeanTestWidth16)).foldl (fun x y => s!"{x}\n{y}") "")
  IO.print "Width 24:"
  IO.println ((l24.map (runLeanTestWidth24)).foldl (fun x y => s!"{x}\n{y}") "")

-- #eval printLeanOutputs

def main (args : List String) : IO UInt32 := do
  let arg0Opt : Option String := if h : args.length = 0 then .none else .some args[0]
  match arg0Opt with
  | .some "HorizenLabsRust" => printHorizenLabsRustTests; pure 0
  | .some "Plonky3NonAirRust" => printPlonky3NonAirRustTests; pure 0
  | .some "LeanOutputs" => printLeanOutputs; pure 0
  | _ => IO.println "Provide one of 'HorizenLabsRust', 'Plonky3NonAirRust' or 'LeanOutputs' as a command line argument"; pure 1
