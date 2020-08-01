#!/bin/bash

scriptpath3="$0"
export CHAP3_HOME=${scriptpath3%/*}
if [[ -z $CHAP3_HOME ]]; then
  source "${PWD}/../../edx-DO081x-common.sh"
  CHAP3_HOME=${PWD}
else
  source "${CHAP3_HOME}/../../edx-DO081x-common.sh"
fi

posix_setter


# CHAP3_HOME=$(dirname $scriptpath3)
pushd "$CHAP3_HOME" || exit_edx "$?" "changing directory to chapter 3 failed"
echo "running" "$scriptpath3"

TOOL_HOME_REL_CHAP3_HOME="../../"
pushd "$TOOL_HOME_REL_CHAP3_HOME" || exit_edx "$?" "changing directory to tools home"


if [[ -z $(minishift status | grep '^Running$') ]]; then
  export input='start'
else
  export input='continue'
fi

bash -c "edx-DO081x.sh "

popd || exit_edx "$?" "changing directory to chapter 3 failed"

source "${HOME}/.bash_profile"
echo "$PATH"
echo "now running" "$scriptpath3"
echo "$PWD"


function remote_gen_and_invoke {
    echo "#!/bin/bash" > "$1"
    if [[ -z "$2" ]]; then
      echo "permissible values are '*http*' | '*sql*' "
      return  1
    fi
    function force_setting {
      :
      # echo "force=true" >> "$1"
    }
    if [[ -z $(echo "$2" | grep 'http') ]]; then
      if [[ -z $(echo "$2" | grep 'sql') ]]; then
         echo "permissible values are '*http*' | '*sql*' "
         return 1
      else
        force_setting
        echo "sqld1=$2" >> "$1"
        echo "sqld2=mysqld-term" >> "$1"
        cat remote_3C_sql.sh >> "$1"
      fi
    else
      force_setting
      echo "httpd1=$2" >> "$1"
      cat remote_3-4C_http.sh >> "$1"
    fi
    chmod +x "$1"
    minishift ssh --  -t < "$1"
    return_value=$?
    if [[ return_value -gt 0 ]]; then
      echo "minishift invocation...NOT OK"
    fi
    return $return_value
}

#function remote_gen_and_invoke {
#  cat > "$1" <<'EOF'
#    #!/bin/bash
#EOF
#    if [[ -z "$2" ]]; then
#      echo "permissible values are '*http*' | '*sql*' "
#      return  1
#    fi
#
#    if [[ -z $(echo "$2" | grep 'http') ]]; then
#      cat > "$1" <<'EOF'
#      sqld1=$2
#EOF
#      cat remote_3C_sql.sh >> "$1"
#    elif [[ -z $(echo "$2" | grep 'sql') ]]; then
#      cat > "$1" <<'EOF'
#      httpd1=$2
#EOF
#      cat remote_3-4C_http.sh >> "$1"
#    fi
#    chmod +x "$1"
#   minishift ssh -- < "$1"
#    rm  "$1"
#
#}

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
  exit "$remote_gen_and_invoke_ret"
fi

