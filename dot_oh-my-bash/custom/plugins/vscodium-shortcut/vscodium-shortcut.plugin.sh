#!/usr/bin/env bash

# exit if we already have a "code" executable
type -t code >> /dev/null && exit 0

# Exit if we don't hav flatpak
type -t flatpak >> /dev/null || exit 0

# Exit is vscodium is not installed
flatpak info com.vscodium.codium >> /dev/null || exit 0

alias code='flatpak run com.vscodium.codium'
