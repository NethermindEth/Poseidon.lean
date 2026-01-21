import Lake
open Lake DSL

package Poseidon

@[default_target]
lean_lib Poseidon where
  precompileModules := true

require YatimaStdLib from git
  "https://github.com/NethermindEth/YatimaStdLib.lean" @ "v4.27.0-rc1"

require LSpec from git
  "https://github.com/NethermindEth/LSpec" @ "v4.27.0-rc1"

lean_exe Tests.RoundNumbers
lean_exe Tests.RoundConstants
lean_exe Tests.Hash
