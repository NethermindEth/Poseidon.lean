#!/usr/bin/env bash

# Run `nix develop` before running this script

TESTDIRECTORY=$(realpath "../TestingPoseidon2Spec")
if [ -d "$TESTDIRECTORY" ]; then
  echo "$TESTDIRECTORY already exists, aborting. Delete this directory to run this script."
  exit 1
fi

mkdir "$TESTDIRECTORY"
pushd "$TESTDIRECTORY"
git clone -b main https://github.com/NethermindEth/HorizenLabs-poseidon2.git
popd
mkdir "$TESTDIRECTORY/HorizenLabs-poseidon2/plain_implementations/examples"
lake exe Tests.GenerateTests HorizenLabsRust > "$TESTDIRECTORY/HorizenLabs-poseidon2/plain_implementations/examples/poseidon2_tests.rs"
pushd "$TESTDIRECTORY/HorizenLabs-poseidon2/plain_implementations/"
cargo run --example poseidon2_tests > "$TESTDIRECTORY/rustHLOut.txt"
popd

pushd "$TESTDIRECTORY"
git clone -b Dom/extraction_deliverable https://github.com/NethermindEth/Plonky3.git
popd
mkdir "$TESTDIRECTORY/Plonky3/poseidon2/examples"
lake exe Tests.GenerateTests Plonky3NonAirRust > "$TESTDIRECTORY/Plonky3/poseidon2/examples/poseidon2_tests.rs"
pushd "$TESTDIRECTORY/Plonky3/"
cargo run --package p3-poseidon2 --example poseidon2_tests > "$TESTDIRECTORY/rustP3Out.txt"
popd

lake exe Tests.GenerateTests LeanOutputs > "$TESTDIRECTORY/leanOut.txt"

diff3 "$TESTDIRECTORY/rustHLOut.txt" "$TESTDIRECTORY/rustP3Out.txt" "$TESTDIRECTORY/leanOut.txt"
COMPARISON_RESULT=$?

if [ $COMPARISON_RESULT -eq 1 ]
then
  echo "Test output differ - FAILURE"
  exit 1
else
  echo "Test outputs match - SUCCESS"
  exit 0
fi