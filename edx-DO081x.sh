#!/bin/bash

scriptpath="$0"
it="$1"

if [[ -z $scriptpath ]]; then
  echo "scriptpath not found for generating local or relative reference"
  echo "possible use as stream piped into shell via HERE file...NOT OK"
  exit 1
else
  TOOL_HOME=$(cd "${scriptpath%/*}" && pwd;)
  export TOOL_HOME
fi

pushd "$TOOL_HOME" || exit_edx "$?" "failed to  switch to tools home"

if [[ -z $scriptpath ]]; then
  echo "edx-DO081x.sh"
else
  echo "running" "$scriptpath"
fi

source edx-DO081x-common.sh
posix_setter
minishift_in_session_ok
session_ok0=$?
if [[ $session_ok0 != 0 ]]; then
  if [[ -z $input ]]; then
    echo " minishift is not in session [commence | discover_vmd | discover_minishift | discover_all ] to [commence] session"
    read -r input
  fi
  if [[ $input == 'commence' ]]; then
    commence='true'
  elif [[ $input == 'discover_vmd' ]]; then
    if [[ -e /usr/local/bin/docker-machine-driver-xhyve ]]; then
      sudo rm /usr/local/bin/docker-machine-driver-xhyve
      commence='true'
    fi
  elif [[ $input == 'discover_minishift' ]]; then
    minishift_close_case
  elif [[ $input == 'discover_all' ]]; then
    if [[ -e /usr/local/bin/docker-machine-driver-xhyve ]]; then
      sudo rm /usr/local/bin/docker-machine-driver-xhyve
      commence='true'
    fi
    minishift_close_case
  else
    echo "permissible input is [commence]"
    exit 1
  fi
else
  if [[ -z $input ]]; then
    echo "minishift is in session [new_sesion | join_session ] to withdraw/new or join"
    read -r input
  fi
  if [[ $input == 'new_session' ]]; then
    minishift_order_is_adjourned
    commence='true'
  elif [[ $input == 'join_session' ]]; then
    :
  else
    echo "permissible input is [new_session | join_session]"
    exit 1
  fi
fi

if [[ -e /usr/local/bin/docker-machine-driver-xhyve ]]; then
  :
else
  discover_vmd='true'
fi

if [[ -d "${MINISHIFT_HOME}" ]]; then
  :
else
  discover_minishift='true'
fi
if [[ -e "$MINISHIFT_ROOT"/.minishift_start_register ]]; then
  cat "$MINISHIFT_ROOT"/.minishift_start_register >"$HOME"/.bash_profile
fi
# shellcheck source=${HOME}/.bash_profile
source "${HOME}"/.bash_profile


if [[ -z $discover_vmd ]]; then
  :
else
  #minishift_build_case "out_services"
  services="out_services"
fi
if [[ -z $discover_minishift ]]; then
  # sudo curl -L https://developers.redhat.com/download-manager/file/cdk-3.0-2-minishift-darwin-amd64 -o "${TOOL_HOME}"/minishift
  :
else
  #minishift_build_case "in_services"
  if [[ -z $services ]]; then
    services="in_services"
  else
    services="all_services"
  fi
fi

if [[ -z $services ]]; then
  :
else
  case $services in
    "in_services")
    minishift_build_case $services
    ;;
    "out_services")
    minishift_build_case $services
    ;;
    "all_services")
    minishift_build_case $services
    ;;
    *)
    echo "services not specified NOT...OK"; exit 1
    ;;
  esac
fi

if [[ -z $commence ]]; then
  :
else
  minishift_order_in_session
fi

minishift_in_session_ok
session_ok0=$?
if [[ $session_ok0 != 0 ]]; then
  echo "error minishift is not in session"
  exit 1
fi

echo "# The contents of this file are partially auto generated using minishift" > "${TOOL_HOME}"/edx_rc_post.sh
{
  echo export TOOL_HOME="${TOOL_HOME}";
  echo export MINISHIFT_ROOT="${MINISHIFT_ROOT}";
  echo export MINISHIFT_HOME="${MINISHIFT_HOME}";

  echo export PATH=\""${TOOL_HOME}":"${MINISHIFT_ROOT}":"${MINISHIFT_HOME}":\$PATH\";

  "${MINISHIFT_ROOT}"/minishift docker-env;
  "${MINISHIFT_ROOT}"/minishift oc-env;

} | grep export >> "${TOOL_HOME}"/edx_rc_post.sh

cat "$TOOL_HOME"/edx_rc_post.sh >> "$HOME"/.bash_profile
# shellcheck source=${HOME}/.bash_profile
source "${HOME}"/.bash_profile
if [[ -z $it ]]; then
  :
elif [[ $it == 'on' ]]; then
  if [[ -z $PS1 ]]; then
    bash --posix
  fi
else
  echo 'permissible parameters for it are [on]'
fi

