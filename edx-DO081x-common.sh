#!/bin/bash
export MINISHIFT_TMP_ROOT=${HOME}/var/tmp
#export MINISHIFT_TMP_ROOT
export MINISHIFT_ROOT=${MINISHIFT_TMP_ROOT}/minishift
export MINISHIFT_HOME=${MINISHIFT_ROOT}/.minishift
SAMBA_HOSTFOLDER_NAME=
#SSHFS_HOSTFOLDER_NAME=shared
#MINISHIFT_SHARED_FOLDER_ROOT=${MINISHIFT_ROOT}

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

function minishift_close_case {

  if [[ -z ${HOSTFOLDER_NAME} ]]; then
    :
  else
    "${MINISHIFT_ROOT}"/minshift hostfolder remove
    unset HOSTFOLDER_NAME
    echo "policy and profile  of shared folder unknown Not...OK"
  fi


  if [[ -e "${MINISHIFT_ROOT}"/.minishift_start_register ]]; then
    rm "${MINISHIFT_ROOT}"/.minishift_start_register
    "${MINISHIFT_ROOT}"/minishift delete
  fi
  if [[ -d "$MINISHIFT_ROOT"/.minishift ]]; then
    rm -r "$MINISHIFT_ROOT"/.minishift
    export start='true'
  fi
}

function minishift_file_discovery {
  return_val=0
      case $DISCOVERY_RESTRICTION in
        "in_services")
        cp -a "${DISCOVERY_FOLDER}"/"${DISCOVERY_LIST[0]}" "${MINISHIFT_ROOT}"/minishift
        # shellcheck disable=SC2046
        chown $(whoami):staff "${MINISHIFT_ROOT}"/minishift
        chmod u+s,+x "${MINISHIFT_ROOT}"/minishift
        return_val=$?
        ;;
        "out_services")
        cp -a "${DISCOVERY_FOLDER}"/"${DISCOVERY_LIST[1]}" /usr/local/bin/docker-machine-driver-xhyve
        sudo chown root:wheel /usr/local/bin/docker-machine-driver-xhyve
        sudo  chmod u+s,+x /usr/local/bin/docker-machine-driver-xhyve
        return_val=$?
        ;;
        "all_services")
        cp -a "${DISCOVERY_FOLDER}"/"${DISCOVERY_LIST[0]}" "${MINISHIFT_ROOT}"/minishift
        cp -a "${DISCOVERY_FOLDER}"/"${DISCOVERY_LIST[1]}" /usr/local/bin/docker-machine-driver-xhyve
        sudo chown root:wheel /usr/local/bin/docker-machine-driver-xhyve
        sudo  chmod u+s,+x /usr/local/bin/docker-machine-driver-xhyve
        return_val=$?
        ;;
      esac

  unset DISCOVERY_FOLDER
  unset DISCOVERY_RESTRICTION
  unset DISCOVERY_LIST
  return $return_val
}

function minishift_process_discovery {
  discovery_restriction=$1
  return_val=0
  discovery_folder=${MINISHIFT_ROOT}/discovery
  case $discovery_restriction in
    "in_services")
      discovery[0]=v3.0-2/cdk-3.0-2-minishift-darwin-amd64
      ;;
    "out_services")
      discovery[0]=v0.3.3/docker-machine-driver-xhyve
      ;;
    "all_services")
      discovery[0]=v3.0-2/cdk-3.0-2-minishift-darwin-amd64
      discovery[1]=v0.3.3/docker-machine-driver-xhyve
      ;;
    *)
    echo "discovery restriction not defined Not...OK"
    return_val=1
    ;;
  esac

  if [[ $return_val -eq 0 ]]; then
    for discovery_item in ${discovery[*]}
      do
        discovery_path=${discovery_item%/*}
        discovery_file=$(echo "${discovery_item}" |sed s/'\(^[A-Za-z0-9!@_*-^%$#]*\)\/'//)

        if [[ -e ${discovery_folder}/${discovery_item} ]]; then
          :
        else
          case ${discovery_file} in
            "cdk-3.0-2-minishift-darwin-amd64")
              echo "discovery filing step missing Not...OK"
              return_val=1
              break
              ;;
            "docker-machine-driver-xhyve")
              mkdir -p "${discovery_folder}"/"${discovery_path}"
              pushd "${discovery_folder}"/"${discovery_path}"
               sudo curl -L \
               https://github.com/zchee/docker-machine-driver-xhyve/releases/download/v0.3.3/docker-machine-driver-xhyve
              return_val=$?
              if [[ $return_val -gt 0 ]]; then
                echo "discovery filing step for $discovery_item failed Not...OK"
                rm -r "${discovery_folder}"/"${discovery_item}"
                break
              fi
              popd
              ;;
          esac
        fi
      done
    fi
    if [[ $return_val -eq 0 ]]; then
      count=${#discovery[*]}
      index=0
      while ((index < count))
        do
          DISCOVERY_LIST[$index]=${discovery[$index]}
          ((index++))
        done
        export DISCOVERY_LIST
        export DISCOVERY_RESTRICTION=$discovery_restriction
        export DISCOVERY_FOLDER=$discovery_folder
        minishift_file_discovery
        return_val=$?
    else
      unset DISCOVERY_LIST
      unset DISCOVERY_RESTRICTION
      unset DISCOVERY_FOLDER
    fi
    return $return_val
}

function minishift_build_case {
  return_val=0
  discovery_restriction=$1

  if [[ -z $discovery_restriction ]]; then
    :
  else
    minishift_process_discovery "$discovery_restriction"
    return_val=$?
  fi

  if [[ $return_val -eq 0 ]]; then
    #"${MINISHIFT_ROOT}"/minishift delete
    "${MINISHIFT_ROOT}"/minishift setup-cdk
    "${MINISHIFT_ROOT}"/minishift config set memory 2048

    if [[ -z ${SAMBA_HOSTFOLDER_NAME} ]]; then
      echo "SAMBA shared folder services not included ..OK"
    else
      HOSTFOLDER_NAME=${SAMBA_HOSTFOLDER_NAME}
      "${TOOL_HOME}"/minishift hostfolder add
    fi
    return_val=$?
    if [[ $return_val -eq 0 ]]; then
      export HOSTFOLDER_NAME
    else
      unset HOSTFOLDER_NAME
    fi
  else
    echo "discovery process failed Not...OK"
  fi
  minishift_order_in_session
  return $return_val
}

function minishift_order_in_session {
  cli_parms=
  if [[ -e "${MINISHIFT_ROOT}"/.minishift_start_register ]]; then
    cli_parms="$cli_parms --skip-registration"
  fi
   "${MINISHIFT_ROOT}"/minishift start --insecure-registry 172.30.0.0/16  "$cli_parms"
}

function minishift_order_is_adjourned {
  echo 'true' > "${MINISHIFT_ROOT}"/.minishift_start_register
  "${MINISHIFT_ROOT}"/minishift stop --skip-unregistration

}

export -f exit_edx
export -f posix_setter
export -f minishift_build_case
export -f minishift_close_case
export -f minishift_order_in_session
export -f minishift_order_is_adjourned
#export -f minishift_process_discovery
#export -f minishift_file_discovery


