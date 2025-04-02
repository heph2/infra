#!/usr/bin/env bash

deploy() {
  nixos-rebuild --build-host $1 --target-host $1 --fast --impure --flake .#$1 switch
}

deploy $1
