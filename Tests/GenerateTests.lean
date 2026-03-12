import Mathlib
import LSpec

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

def constructRustTest (width : ℕ) (idx : ℕ) (l : List ℤ) : String :=
  let testNum := idx + 1
  s!"    let input{testNum}: Vec<Scalar> = vec!{l}.into_iter().map(|x: usize| FpBabyBear::from(x as u32)).collect();\n" ++
  s!"    let perm{testNum} = instance{width}.permutation(&input{testNum});\n" ++
  s!"    print_baby_bear_vec(perm{testNum});\n"

def rustBefore16 : String :=
   "use itertools::Itertools;
use zkhash::{fields::babybear::FpBabyBear, poseidon2::{poseidon2::Poseidon2, poseidon2_instance_babybear::{POSEIDON2_BABYBEAR_16_PARAMS, POSEIDON2_BABYBEAR_24_PARAMS}}};

type Scalar = FpBabyBear;

pub fn main() {
    tests16();
    tests24();
}

fn print_baby_bear_vec(l : Vec<Scalar>) {
    let l2 : Vec<String> = l.into_iter().map(|x| format!(\"{}\", x)).collect();
    println!(\"[{}]\", l2.iter().format(\", \"));
}

fn tests16() {
    let instance16 = Poseidon2::new(&POSEIDON2_BABYBEAR_16_PARAMS);"

def rustAfter16Before24 : String :=
  "}

fn tests24() {
    let instance24 = Poseidon2::new(&POSEIDON2_BABYBEAR_24_PARAMS);"

def rustAfter24 : String := "}"

def printHorizenLabsRustTests : IO Unit := do
  let seed := 42
  let g := generateTestCases
  let l16 ← runWith seed g 16
  let l24 ← runWith seed g 24
  
  IO.println rustBefore16
  IO.println ((l16.mapIdx (constructRustTest 16)).foldl (fun x y => x ++ "\n" ++ y) "")
  IO.println rustAfter16Before24
  IO.println ((l24.mapIdx (constructRustTest 24)).foldl (fun x y => x ++ "\n" ++ y) "")
  IO.println rustAfter24

-- #eval printHorizenLabsRustTests

def main : IO Unit :=
  printHorizenLabsRustTests
