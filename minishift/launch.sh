#!/bin/bash

function configure_input_discover_vmd {
  if [[ -e ${VMD_ROOT}/docker-machine-driver-xhyve ]]; then
      expect <<HERE
      spawn su -l "$ADMINISTRATOR" --posix
      expect "Password:"
      send "$ADMINISTRATOR_PASSWORD\r"
      expect "#"
      send "sudo rm -f ${VMD_ROOT}/docker-machine-driver-xhyve\r"
      expect "Password:"
      send "$ADMINISTRATOR_PASSWORD\r"
      expect "#"
HERE
      export commence='true'
 fi
}

script_path="$0"
it="$1"

if [[ -z $script_path ]]; then
  echo "script_path not found for generating local or relative reference"
  echo "possible use as stream piped into shell via HERE file...NOT OK"
  exit 1
else
  TOOL_HOME=$(cd "${script_path%/*}" && pwd;)
  export TOOL_HOME
  echo "${TOOL_HOME}"
  {
    . "${TOOL_HOME}"/common.sh\
    && init_globals
  } || {  return_val=$?;
          printf "common method inclusions or globals variables init failed with error code %s" $return_val;
          exit $return_val
        }
fi
echo "${MINISHIFT_PATH}"

pushd "$TOOL_HOME" || exit_okd "$?" "failed to  switch to tools home"

if [[ -z $script_path ]]; then
  echo "launch.sh"
else
  echo "running" "$script_path"
fi

posix_setter
path_setter_pre
# shellcheck source=${MINISHIFT_ROOT}/.bash_profile
source "${MINISHIFT_ROOT}"/.bash_profile
admin_entry_processing
minishift_in_session_ok
session_ok0=$?


if [[ $session_ok0 != 0 ]]; then
  # if [[ -z $input ]]; then
  echo " minishift is not in session [commence | discover_vmd | discover_minishift | discover_all ] to [commence] session"
  read -r input
  # fi
  if [[ $input == 'commence' ]]; then
    export commence='true'
  elif [[ $input == 'discover_vmd' ]]; then
    configure_input_discover_vmd
  elif [[ $input == 'discover_minishift' ]]; then
    minishift_close_case
  elif [[ $input == 'discover_all' ]]; then
    configure_input_discover_vmd
    minishift_close_case
  else
    echo "permissible input is [commence]"
    exit 1
  fi
else
  if [[ -z $input ]]; then
    echo "minishift is in session [new_session | join_session ] to withdraw/new or join"
    read -r input
  fi
  if [[ $input == 'new_session' ]]; then
    minishift_order_is_adjourned
    export commence='true'
  elif [[ $input == 'join_session' ]]; then
    :
  else
    echo "permissible input is [new_session | join_session]"
    exit 1
  fi
fi

if [[ -e ${VMD_ROOT}/docker-machine-driver-xhyve ]]; then
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
  cat "$MINISHIFT_ROOT"/.minishift_start_register >"$MINISHIFT_ROOT"/.bash_profile
fi
# shellcheck source=${MINISHIFT_ROOT}/.bash_profile
source "${MINISHIFT_ROOT}"/.bash_profile


if [[ -z $discover_vmd ]]; then
  :
else
    services="out_services"
fi
if [[ -z $discover_minishift ]]; then
  :
else
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
fi || {
  echo "minishift_build_case failed NOT...OK";
  exit 1
  }

printf "commence value is %s" $commence
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
else
  path_setter_post
  # shellcheck source=${MINISHIFT_ROOT}/.bash_profile
  source "${MINISHIFT_ROOT}"/.bash_profile
fi

if [[ -z $it ]]; then
  :
elif [[ $it == 'on' ]]; then
  if [[ -z $PS1 ]]; then
    # env -i env PS1='minishift'\# bash --posix -i
    bash --posix
  fi
else
  echo 'permissible parameters for it are [on]'
fi