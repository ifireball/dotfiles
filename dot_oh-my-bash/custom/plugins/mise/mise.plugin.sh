#!/usr/bin/env bash

# Don't do anything of we don't have mise installed
type -t mise >> /dev/null && eval "$(mise activate bash)"
