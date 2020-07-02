#!/bin/bash


if [[ -z $(ps -ef | grep '[.]*minishift.pid$') ]]; then
  echo " minishift is not operational [start | install_vmd | install_minishift | install_both] to start"
  read -r input
  if [[ $input == 'start' ]]; then
    start='true'
  elif [[ $input == 'install_vmd' ]]; then
    if [[ -e /usr/local/bin/docker-machine-driver-xhyve ]]; then
      sudo rm /usr/local/bin/docker-machine-driver-xhyve
      start='true'
    fi
  elif [[ $input == 'install_minishift' ]]; then
    if [[ -d "$HOME"/.minishift ]]; then
      sudo rm -r "$HOME"/.minishift
      start='true'
    fi
  elif [[ $input == 'install_both' ]]; then
     if [[ -e /usr/local/bin/docker-machine-driver-xhyve ]]; then
      sudo rm /usr/local/bin/docker-machine-driver-xhyve
     fi
     if [[ -d "$HOME"/.minishift ]]; then
      sudo rm -r "$HOME"/.minishift
      start='true'
     fi
  else
    echo "permissible input is [start]"
    exit 1
  fi
else
  echo "minishift is operational [restart | continue ] to restart or continue"
  read -r input
  if [[ $input == 'restart' ]]; then
    minishift stop
    start='true'
  elif [[ $input == 'continue' ]]; then
    echo
  else
    echo "permissible input is [restart | continue]"
    exit 1
  fi
fi

if [[ -e /usr/local/bin/docker-machine-driver-xhyve ]]; then
  echo
else
  install_vmd='true'
fi

if [[ -d "$HOME"/.minishift  ]]; then
  echo
else
  install_minishift='true'
fi

source "$HOME"/.bash_profile
cd "$TOOL_HOME"
cat "./edx_rc_pre.sh" > "$HOME"/.bash_profile


# echo $input
# exit 0

if [[ -z $install_vmd ]]; then echo
else
  sudo curl -L  https://github.com/zchee/docker-machine-driver-xhyve/releases/download/v0.3.3/docker-machine-driver-xhyve -o /usr/local/bin/docker-machine-driver-xhyve
  sudo chown root:wheel /usr/local/bin/docker-machine-driver-xhyve
  sudo chmod u+s,+x /usr/local/bin/docker-machine-driver-xhyve
fi
if [[ -z $install_minishift ]]; then echo
else
  minishift delete
  minishift setup-cdk
  minishift config set memory 2048
fi

if [[ -z $start ]]; then echo
else
  minishift start --insecure-registry 172.30.0.0/16
fi

if [[ -z $(ps -ef | grep '[.]*minishift.pid$') ]]; then
  echo "error minishift is not operational"
  exit 1
else
  echo "# The contents of this file are auto generated using minishift" > "./edx_rc_post.sh"
  minishift docker-env | grep export >> "./edx_rc_post.sh"
  minishift oc-env | grep export >> "./edx_rc_post.sh"
  cat "./edx_rc_post.sh" >> "$HOME"/.bash_profile
  source "$HOME"/.bash_profile
  bash
fi
