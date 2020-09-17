#!/bin/bash

scriptpath="$0"
it="$1"

if [[ -z $scriptpath ]]; then
  echo "scriptpath not found for generating local or relative reference"
  echo "possible use as stream piped into shell via HERE file...NOT OK"
  exit 1
else
  export TOOL_HOME=$(cd "${scriptpath%/*}" && pwd;)
#  export TOOL_HOME="${scriptpath%/*}"
fi

cd "$TOOL_HOME" || exit_edx "$?" "failed to  switch to tools home"

if [[ -z $scriptpath ]]; then
  echo "edx-DO081x.sh"
else
  echo "running" "$scriptpath"
fi

source edx-DO081x-common.sh
posix_setter

if [[ -z $(ps -ef | grep '[.]*minishift.pid$') ]]; then
  if [[ -z $input ]]; then
    echo " minishift is not operational [start | install_vmd | install_minishift | install_both] to start"
    read -r input
  fi
  if [[ $input == 'start' ]]; then
    start='true'
  elif [[ $input == 'install_vmd' ]]; then
    if [[ -e /usr/local/bin/docker-machine-driver-xhyve ]]; then
      sudo rm /usr/local/bin/docker-machine-driver-xhyve
      start='true'
    fi
  elif [[ $input == 'install_minishift' ]]; then
    #if [[ -d "$HOME"/.minishift ]]; then
    #  sudo rm -r "$HOME"/.minishift
    #  start='true'
    #fi
    minishift_close_case
  elif [[ $input == 'install_both' ]]; then
    if [[ -e /usr/local/bin/docker-machine-driver-xhyve ]]; then
      sudo rm /usr/local/bin/docker-machine-driver-xhyve
    fi
    #if [[ -d "$HOME"/.minishift ]]; then
    #  sudo rm -r "$HOME"/.minishift
    #  start='true'
    #fi
    minishift_close_case
  else
    echo "permissible input is [start]"
    exit 1
  fi
else
  if [[ -z $input ]]; then
    echo "minishift is operational [restart | continue ] to restart or continue"
    read -r input
  fi
  if [[ $input == 'restart' ]]; then
    minishift_order_is_adjourned
    start='true'
  elif [[ $input == 'continue' ]]; then
    :
  else
    echo "permissible input is [restart | continue]"
    exit 1
  fi
fi

if [[ -e /usr/local/bin/docker-machine-driver-xhyve ]]; then
  :
else
  install_vmd='true'
fi

if [[ -d "${MINISHIFT_HOME}" ]]; then
  :
else
  install_minishift='true'
fi

cat "$TOOL_HOME"/edx_rc_pre.sh >"$HOME"/.bash_profile

source "$HOME"/.bash_profile

# echo $input
# exit 0

if [[ -z $install_vmd ]]; then
  :
else
  #sudo curl -L https://github.com/zchee/docker-machine-driver-xhyve/releases/download/v0.3.3/docker-machine-driver-xhyve -o /usr/local/bin/docker-machine-driver-xhyve
  minishift_build_case "out_services"
  #sudo chown root:wheel /usr/local/bin/docker-machine-driver-xhyve
  #sudo chmod u+s,+x /usr/local/bin/docker-machine-driver-xhyve
fi
if [[ -z $install_minishift ]]; then
  # sudo curl -L https://developers.redhat.com/download-manager/file/cdk-3.0-2-minishift-darwin-amd64 -o "${TOOL_HOME}"/minishift
  :
else
  #"${TOOL_HOME}"/minishift delete
  #"${TOOL_HOME}"/minishift setup-cdk
  #"${TOOL_HOME}"/minishift config set memory 2048
  minishift_build_case "in_services"
fi

if [[ -z $start ]]; then
  :
else
  #"${TOOL_HOME}"/minishift start --insecure-registry 172.30.0.0/16
  minishift_order_in_session
fi

if [[ -z $(ps -ef | grep '[.]*minishift.pid$') ]]; then
  echo "error minishift is not operational"
  exit 1
fi

echo "# The contents of this file are partially auto generated using minishift" > "${TOOL_HOME}"/edx_rc_post.sh
echo export TOOL_HOME="${TOOL_HOME}" >> "${TOOL_HOME}"/edx_rc_post.sh
echo export PATH=\""${TOOL_HOME}":\$PATH\" >> "${TOOL_HOME}"/edx_rc_post.sh

echo export MINISHIFT_ROOT="${MINISHIFT_ROOT}" >> "${TOOL_HOME}"/edx_rc_post.sh
echo export PATH=\""${MINISHIFT_ROOT}":\$PATH\" >> "${TOOL_HOME}"/edx_rc_post.sh

echo export MINISHIFT_HOME="${MINISHIFT_HOME}" >> "${TOOL_HOME}"/edx_rc_post.sh
echo export PATH=\""${MINISHIFT_HOME}":\$PATH\" >> "${TOOL_HOME}"/edx_rc_post.sh


"${MINISHIFT_ROOT}"/minishift docker-env | grep export >> "${TOOL_HOME}"/edx_rc_post.sh
"${MINISHIFT_ROOT}"/minishift oc-env | grep export >> "${TOOL_HOME}"/edx_rc_post.sh

cat "$TOOL_HOME"/edx_rc_post.sh >> "$HOME"/.bash_profile
source "$HOME"/.bash_profile
if [[ -z $it ]]; then
  :
elif [[ $it == 'on' ]]; then
  if [[ -z $PS1 ]]; then
    bash
  fi
else
  echo 'permissible parameters for it are [on]'
fi

