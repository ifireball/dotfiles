#!/usr/bin/env bash

_vscodium_shortcut_plugin() {
    # exit if we already have a "code" executable
    type -t code >> /dev/null && return 0

    # Exit if we don't hav flatpak
    type -t flatpak >> /dev/null || return 0

    # Exit is vscodium is not installed
    flatpak info com.vscodium.codium >> /dev/null || return 0

    alias code='flatpak run com.vscodium.codium'
}

_vscodium_shortcut_plugin
unset -f _vscodium_shortcut_plugin
