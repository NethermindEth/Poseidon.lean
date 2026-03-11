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

def printTests : IO Unit := do
  let g := generateTestCases
  let l16 ← g.run 16
  IO.println l16
  let l24 ← g.run 24
  IO.println l24

#eval printTests
