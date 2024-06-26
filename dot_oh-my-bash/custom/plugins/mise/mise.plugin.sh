#!/usr/bin/env bash

# Don't do anything of we don't have mise installed
if type -t mise >> /dev/null; then
    eval "$(mise activate bash)"
    # Enable other scripts that follow to use stuff that mise provides
    eval "$(mise hook-env -s bash)"
fi
