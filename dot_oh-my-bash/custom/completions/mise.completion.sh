#!/usr/bin/env bash

# Don't do anything of we don't have mise installed
if type -t mise >> /dev/null; then
    # We need to drop the oh-my-bash usage function because it collides with the
    # usage CLI (https://usage.jdx.dev/)
    unset -f usage

    type -t usage >> /dev/null && eval "$(mise completion bash)"
fi
