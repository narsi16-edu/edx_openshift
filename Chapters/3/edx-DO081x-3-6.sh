#!/bin/bash

scriptpath3="$0"
CHAP3_HOME=$(cd "${scriptpath3%/*}" && pwd;)
export CHAP3_HOME
if [[ -z $CHAP3_HOME ]]; then
   echo "scriptpath not found for generating local or relative reference"
  echo "possible use as stream piped into shell via HERE file...NOT OK"
  exit 1
else
  # shellcheck source=${CHAP3_HOME}/../../edx-Do081x-common.sh
  source "${CHAP3_HOME}/../../edx-DO081x-common.sh"
fi

posix_setter


# CHAP3_HOME=$(dirname $scriptpath3)
pushd "$CHAP3_HOME" || exit_edx "$?" "changing directory to chapter 3 failed"
echo "running" "$scriptpath3"

TOOL_HOME_REL_CHAP3_HOME=$(cd "../../" && pwd);
pushd "$TOOL_HOME_REL_CHAP3_HOME" || exit_edx "$?" "changing directory to tools home"


# shellcheck disable=SC2143
if [[ -z $(minishift status | grep '^Running$') ]]; then
  export input='start'
else
  export input='continue'
fi

bash -c "edx-DO081x.sh "

popd || exit_edx "$?" "changing directory to chapter 3 failed"
# shellcheck source=${HOME}/.bash_profile
source "${HOME}/.bash_profile"
echo "now running" "$scriptpath3"

function remote_dockerfile_injector_for_5C_http {
        scp -i ~/.minishift/machines/minishift/id_rsa \
        -o 'StrictHostKeyChecking=no' \
        "${CHAP3_HOME}"/remote_5C_http_docker/Dockerfile \
        docker@"$(minishift ip)":
}

function remote_gen_and_invoke {
    echo "#!/bin/bash" > "$1"
    if [[ -z "$2" ]]; then
      echo "permissible values are '*http*' | '*sql*' "
      return  1
    fi
    function setting {
      echo "force=true" >> "$1"
      # echo "custom=true" >> "$1"
    }

    # shellcheck disable=SC2143
    if [[ -z $(echo "$2" | grep 'http') ]] ; then
      if [[ -z $(echo "$2" | grep 'sql') ]] ; then
         echo "permissible values are '*http*' | '*sql*' "
         return 1
      else
        setting "$1"
        cat >> "$1" <<HERE
        sqld1="$2"
        sqld2='mysqld-term'
HERE
        cat "${CHAP3_HOME}/remote_3C_sql.sh" >> "$1"
      fi
    else
      setting "$1"
      cat >> "$1" <<HERE
      httpd1="$2"
HERE
      cat "${CHAP3_HOME}/remote_3-4C_http.sh" >> "$1"
      remote_dockerfile_injector_for_5C_http
    fi
    chmod +x "$1"
    minishift ssh --  -t < "$1"
    return_value=$?
    if [[ return_value -gt 0 ]]; then
      echo "minishift invocation...NOT OK"
    fi
    return $return_value
}

echo "permissible choices are docker | oc"
read -r input
if [[ $input != "docker" ]]; then
  if [[  $input != "oc" ]]; then
    echo "permissble choice not provide"  &&  exit 1
  fi
fi

if [[ $input == "oc" ]]; then

  echo "permissble choices are image | s2i"
  read -r input
  # shellcheck source=${CHAP3_HOME}/openshift/local_oc_common.sh
  source "${CHAP3_HOME}/openshift/local_oc_common.sh"
  project="occ"

  if [[ $input == "image" ]]; then
    app="db-test-app"
  else
    app="do081x-lab-example"
  fi

  if [[ $input == "image" ]]; then
    oc_function="oc_mysql_gen_and_invoke"
  else
    oc_function="oc_http_gen_and_invoke"
  fi
  oc_gen_and_invoke "$oc_function" "$project" "$app"
  oc_gen_and_invoke_ret=$?
  if [[ $oc_gen_and_invoke_ret != 0 ]]; then
    echo "app creation using oc tool failed...NOT OK"
  fi
  return_value=$oc_gen_and_invoke_ret
else
  function choice_handler {
      #echo $$ > "$2"
      if [[ $1 == 'http' ]]; then
        echo "myhttpd-1" > "$2"
      elif [[ $1 == 'sql' ]]; then
        echo "mysqld-1" > "$2"
      else
        echo '1' > "$2"
        echo "permissible choice not provided"
        return 1
      fi
      return "$?"
  }

  remotes=remote_$$.sh

  remotes_state_fifo=choice$$
  # choice_sub_pid=''
  if [[ -z $(mkfifo "$remotes_state_fifo") ]]; then
    :
  else
    exit_edx "$?" "failed to create shared fifo pipe"
  fi

  echo "permissible choices are sql | http"
  read -r input

  choice_handler "$input" "$remotes_state_fifo" &
  remotes_state_var=$(cat < "$remotes_state_fifo")

  #while [  "$choice_sub_pid" == '' ]
  #do
  #   sleep 2
  #   choice_sub_pid=$(cat < "$remotes_state_fifo")
  #   echo "$choice_sub_pid"
  #done

  while [ "$remotes_state_var" == '' ]
  do
    sleep 2
    remotes_state_var=$(cat < "$remotes_state_fifo")
  done

  #kill "$choice_sub_pid"
  if [[ -e $remotes_state_fifo ]]; then
    rm "$remotes_state_fifo"
  fi

  echo "$remotes_state_var"

  remote_gen_and_invoke "$remotes" "$remotes_state_var"
  remote_gen_and_invoke_ret="$?"

  if [[ -e $remotes ]]; then
    rm "$remotes"
  fi
  echo "now running" "$scriptpath3"
  if [[ ($remote_gen_and_invoke_ret != 0) ]]; then
    echo "Local Launching with Non Zero Value Not...OK"
  fi
  return_value=$remote_gen_and_invoke_ret
fi

exit $return_value