import Lake
open Lake DSL

package Poseidon where
  -- Link against the Poseidon2 FFI library
  -- The library should be in the same directory as the lakefile or in poseidon2-ffi
  moreLinkArgs := #[
    "-L.", 
    "-L../Plonky3/poseidon2-ffi",
    "-Wl,-rpath,.",
    "-Wl,-rpath,../Plonky3/poseidon2-ffi",
    "-lposeidon2_ffi_lean",
    "-lpthread",
    "-ldl",
    "-lm"
  ]

@[default_target]
lean_lib Poseidon where
  precompileModules := false

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.27.0"

require YatimaStdLib from git
  "https://github.com/NethermindEth/YatimaStdLib.lean" @ "v4.27.0"

require LSpec from git
  "https://github.com/NethermindEth/LSpec" @ "v4.27.0"

lean_exe Tests.RoundNumbers
lean_exe Tests.RoundConstants
lean_exe Tests.Hash
lean_exe Tests.Poseidon2
