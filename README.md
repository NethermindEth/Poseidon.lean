# Lean 4 Poseidon and Poseidon 2 implementation

This repository contains an implementation of the Poseidon and Poseidon 2 hash functions in Lean 4.

This is a fork of [argumentcomputer/Poseidon.lean](https://github.com/argumentcomputer/Poseidon.lean) by the [Argument Computer Corporation](https://github.com/argumentcomputer) (used under the MIT license) with minor changes, in particular to the round constants and other parameters to the Poseidon 2 permutation as well as some additional tests of the Poseidon 2 permutation.

## Poseidon

For details about the implementation of the Poseidon hash, please see the [original README from upstream](https://github.com/argumentcomputer/Poseidon.lean/blob/main/README.md), copied here as [README-original](./README-original.md).

## Poseidon 2

### Usage

For the Poseidon 2 permutation, two widths (16 and 24) are supported.

To see examples of the usage of Poseidon 2, please see [Tests/Poseidon2.lean](./Tests/Poseidon2.lean).

For example, to calculate the hash of `[0..15]` we can run:

```
#eval Poseidon2.hashInputWithCtx BabyBear16.hashProfile BabyBear16.lurkContext #[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
```

### Tests

The Poseidon 2 tests compare the output of the hash with a version of [Poseidon 2 from the Plonky3 repo](https://github.com/NethermindEth/Plonky3/tree/Dom/extraction_deliverable/poseidon2) (that is different from the AIR version) and a slightly-modified version of the [HorizenLabs implementation of Poseidon 2](https://github.com/NethermindEth/HorizenLabs-poseidon2/). These tests can be run by:

  1. Running `nix-shell` or `nix develop` (ensure Nix is installed, with flakes support for `nix develop`, see https://nixos.org). Alternatively, ensure dependencies equivalent to `buildInputs` in `flake.nix` are installed.
  2. Optionally, run `lake exe cache get` to speed up the build using the precompiled files for the dependency Mathlib.
  3. Running `./poseidon2Tests.sh` (first check that `../TestingPoseidon2Spec` does not already exist).

The tests are defined in `Tests/GenerateTests.lean`.