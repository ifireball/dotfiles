#!/usr/bin/bash

# 3rd party completion loader for commands emitting        -*- shell-script -*-
# their completion using "$cmd gen-completion --shell bash".

eval -- "$("$1" gen-completion --shell bash 2>/dev/null)"

# ex: filetype=sh
