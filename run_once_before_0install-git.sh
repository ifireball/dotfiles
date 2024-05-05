#!/usr/bin/env bash

type -t git >> /dev/null && exit 0

for install_tool in dnf yum __none__; do
  type -t $install_tool >> /dev/null && break
done

if [[ $install_tool == __none__ ]]; then
  echo "Cant find a supported install tool" 1>&2
  exit 1
fi

$install_tool install -qy git

