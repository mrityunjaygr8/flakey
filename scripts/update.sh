#!/usr/bin/env bash

pushd ~/flakey || exit
nix flake update
popd || exit
