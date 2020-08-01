#!/bin/bash

function exit_edx
{
  if [[ -z $1 ]]; then
    echo "$2"
    exit 1
  elif [[ -z $2 ]]; then
    exit "$1"
  else
    echo "$2"
    exit "$1"
  fi
}

function posix_setter {
  if [[ -z $(set -o | grep '^posix[^a-zA-Z0-9]*on$') ]]; then
    set -o posix  || exit_edx "$?" "failed to set posix"
  fi
}

export -f exit_edx
export -f posix_setter
