#!/usr/bin/bash

# 3rd party completion loader for commands emitting        -*- shell-script -*-
# their completion using "$cmd completion -s bash".

eval -- "$("$1" completion -s bash 2>/dev/null)"

# ex: filetype=sh
