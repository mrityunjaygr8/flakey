#!/usr/bin/env bash

pushd ~/flakey/ || exit
sudo nixos-rebuild switch --max-jobs 4 --flake .#
popd || exit
