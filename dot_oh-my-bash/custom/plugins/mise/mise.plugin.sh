#!/usr/bin/env bash

# Don't do anything of we don't have mise installed
command -y mise || exit 0

eval "$(mise activate bash)"
