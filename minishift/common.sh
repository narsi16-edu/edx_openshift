#!/bin/bash


function exit_okd
{
  export HISTFILE=$DEFAULT_HIST_FILE
  unset DEFAULT_HIST_FILE
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

  if set -o | grep '^posix[^a-zA-Z0-9]*on$'
  then
    set -o posix  || exit_okd "$?" "failed to set posix"
  fi
}

function minishift_close_case {
  return_val=0
  if [[ -z ${HOST_FOLDER_NAME} ]]; then
    :
  else
    expect <<HERE
                    spawn su -l  "$ADMINISTRATOR" --posix
                    expect "Password:"
                    send "$ADMINISTRATOR_PASSWORD\r"
                    expect "#"
                    send "source ${MINISHIFT_ROOT}/.bash_profile\r"
                    expect "#"
                    send "${MINISHIFT_ROOT}/minishift hostfolder remove\r"
                    expect "#"
HERE
    unset HOST_FOLDER_NAME
    echo "policy and profile  of shared folder unknown NOT...OK"
  fi || {   return_val=$?;
            printf "minishift shared folder remove sequence failed with error code %s" $return_val
        }

  if [[ $return_val -eq 0 && -e "${MINISHIFT_ROOT}"/minishift ]]; then
    # "${MINISHIFT_ROOT}"/minishift delete
    expect <<HERE
                spawn su -l  "$ADMINISTRATOR" --posix
                expect "Password:"
                send "$ADMINISTRATOR_PASSWORD\r"
                expect "#"
                send "source ${MINISHIFT_ROOT}/.bash_profile\r"
                expect "#"
                send "${MINISHIFT_ROOT}/minishift delete\r"
                expect "#"
HERE
  fi || {   return_val=$?;
            printf "minishift delete sequence failed with error code %s" $return_val

        }

  if [[ $return_val -eq 0 && -d "${MINISHIFT_HOME}" ]]; then
    #rm -rf "$MINISHIFT_ROOT"/.minishift
       expect <<HERE
                    spawn su -l  "$ADMINISTRATOR" --posix
                    expect "Password:"
                    send "$ADMINISTRATOR_PASSWORD\r"
                    expect "#"
                    send "source ${MINISHIFT_ROOT}/.bash_profile\r"
                    expect "#"
                    send "sudo rm -rf ${MINISHIFT_HOME}\r"
                    expect "Password:"
                    send "$ADMINISTRATOR_PASSWORD\r"
                    expect "#"
HERE
  fi || {   return_val=$?;
            printf  "%s directory deletion sequence failed with error code %s" "${MINISHIFT_HOME}", $return_val
        }
  if [[ $return_val -eq 0 ]]; then
    export commence='true'
  fi
}

function minishift_file_discovery_in_services {
  discovery_folder=$1
  shift
  discovery_list=$*
  printf "minishift_file_discovery_in_services with parameters %s %s" "${discovery_folder}" "${discovery_list[*]}"
  for discovery_item in ${discovery_list[*]}
  do
    discovery_file=$(echo "${discovery_item}" |sed s/'\(^[A-Za-z0-9!@_*-^%$#]*\)\/'//)
    echo "$discovery_file"
    if [[ ! -e ${discovery_folder}/${discovery_item} ]]; then
      echo "filed folder/item ${discovery_folder}/${discovery_item} for discovery not found NOT...OK"
      return_val=1
    else
      case ${discovery_file} in
          "cdk-3.0-2-minishift-darwin-amd64")
          echo "preceding discovery filing step missing..file discovery error NOT...OK"
          # "${MINISHIFT_ROOT}"/minishift setup-cdk
          return_val=1
          break
          ;;
          "minishift-v1.0.0")
          printf  "discovery file is %s " "${discovery_file}"
          printf "copying %s to %s" "${discovery_folder}"/"${discovery_item}"  "${MINISHIFT_ROOT}"/minishift
          cp -a "${discovery_folder}/${discovery_item}" "${MINISHIFT_ROOT}"/minishift
          expect <<HERE
            spawn su -l  "$ADMINISTRATOR" --posix
            expect "Password:"
            send "$ADMINISTRATOR_PASSWORD\r"
            expect "#"
            send "source $MINISHIFT_ROOT/.bash_profile\r"
            expect "#"
            send "sudo  chown root:wheel ${MINISHIFT_ROOT}/minishift\r"
            expect "Password:"
            send "$ADMINISTRATOR_PASSWORD\r"
            expect "#"
            send "sudo  chmod u+s,+x ${MINISHIFT_ROOT}/minishift\r"
            expect "#"
            send "${MINISHIFT_ROOT}/minishift delete\r"
            expect "#"
            send "${MINISHIFT_ROOT}/minishift config set memory 2048\r"
            expect "#"
HERE
          if [[ -z ${SAMBA_FOLDER_NAME} ]]; then
                echo "SAMBA shared folder services not included ..OK"
          else
                HOST_FOLDER_NAME=${SAMBA_FOLDER_NAME}
                "${TOOL_HOME}/minishift hostfolder add"
                return_val=$?
                if [[ $return_val -eq 0 ]]; then
                      export HOST_FOLDER_NAME
                else
                      unset HOST_FOLDER_NAME
                fi
          fi

          return_val=$?
          ;;
      esac
    fi
  done
  return $return_val
}

function minishift_file_discovery_out_services {
    return_val=0
    discovery_folder=$1
    shift
    discovery_list=$*
    printf "minishift_file_discovery_out_services with parameters %s %s" "${discovery_folder}" "${discovery_list[*]}"
    # shellcheck source="$VMD_HOME"/admin
    for discovery_item in ${discovery_list[*]}
    do
      discovery_path=${discovery_item%/*}
      discovery_file=$(echo "${discovery_item}" |sed s/'\(^[A-Za-z0-9!@_*-^%$#]*\)\/'//)
      # echo "######""${discovery_folder}/${discovery_file}"
      if [[ ! -e ${discovery_folder}/${discovery_item} ]]; then
        echo "filed folder/item ${discovery_folder}/${discovery_item} for discovery not found.NOT...OK"
        return_val=1
      else
        case ${discovery_file} in
            "docker-machine-driver-xhyve-v0.3.3")
            echo "copying ${discovery_folder}/${discovery_item} to ${VMD_ROOT}/docker-machine-driver-xhyve"

            if [[ ! -f $VMD_HOME/entitlements.plist ]]; then
            {
              echo '
              <?xml version="1.0" encoding="UTF-8"?>
              <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
             <plist version="1.0">
             <dict>
                 <key>com.apple.security.hypervisor</key>
                 <true/>
             </dict>
             </plist>'
             } > "$VMD_HOME"/entitlements.plist
             fi
            cp -a "${discovery_folder}"/"${discovery_item}" "${VMD_ROOT}"/docker-machine-driver-xhyve
            expect <<HERE
            spawn su -l  "$ADMINISTRATOR" --posix
            expect "Password:"
            send "$ADMINISTRATOR_PASSWORD\r"
            expect "#"
            send "source $MINISHIFT_ROOT/.bash_profile\r"
            expect "#"
            send "sudo  chown root:wheel ${VMD_ROOT}/docker-machine-driver-xhyve\r"
            expect "Password:"
            send "$ADMINISTRATOR_PASSWORD\r"
            expect "#"
            send "sudo  chmod u+s,+x ${VMD_ROOT}/docker-machine-driver-xhyve\r"
            expect "#"
HERE
#            send "sudo codesign --entitlements $VMD_HOME/entitlements.plist --force -s - ${VMD_ROOT}/docker-machine-driver-xhyve\r"
#            expect "#"
#HERE

            return_val=$?
            ;;
        esac
        fi
    done
    return $return_val
}

function minishift_file_discovery {
  #return_val=0
  discovery_restriction=$1
  shift
  discovery_list=$*
  discovery_folder=${MINISHIFT_ROOT}/discovery
  case $discovery_restriction in
        "in_services")
          minishift_file_discovery_in_services "${discovery_folder}" "${discovery_list[*]}" \
          || {  return_val=$? ;
                echo "minishift_file_discovery_in_services failed Not..OK"
              }
          ;;
        "out_services")
          minishift_file_discovery_out_services "${discovery_folder}" "${discovery_list[*]}" \
          || {
                return_val=$? ;
                echo "minishift_file_discovery_out_services failed Not...OK"
              }
          ;;
        "all_services")
          minishift_file_discovery_in_services "${discovery_folder}" "${discovery_list[*]}" \
          || {  return_val=$?;
                echo "all_services:minishift_file_discovery_in_services failed Not..OK"
              }
          if [[ $return_val == 0 ]]; then
            minishift_file_discovery_out_services "${discovery_folder}" "${discovery_list[*]}" \
            || {  return_val=$?;
                  echo "all_services:minishift_file_discovery_out_services failed Not...OK"
                }
          fi
          ;;
        *)
          echo "discovery restriction not defined NOT...OK"
          return_val=1
          ;;
  esac
  return $return_val
}

function minishift_process_discovery_in_services {
 echo "Please specify minishift : [ OKD | CDK ]"
 read -r input
 return_val=$?
 if [[ $input == "OKD" ]]; then
   discovery[0]=v1.0.0/minishift-v1.0.0
 elif [[ $input == "CDK" ]]; then
    discovery[0]=v3.0-2/cdk-3.0-2-minishift-darwin-amd64
 else
    echo " minishift distributions  need to be OKD or CDK"
    return_val=1
 fi
 return $return_val
}

function minishift_process_discovery_out_services {
  discovery[1]=v0.3.3/docker-machine-driver-xhyve-v0.3.3
  return $?
}

function minishift_process_discovery {
  discovery_restriction=$1
  return_val=0
  discovery_folder="${MINISHIFT_ROOT}"/discovery
  case $discovery_restriction in
    "in_services")
      minishift_process_discovery_in_services \
      || {  return_val=$?;
            echo "minishift_process_discovery_in_services failed NOT...OK"
          }
      ;;
    "out_services")
      minishift_process_discovery_out_services \
      || {  return_val=$?;
            echo "minishift_process_discovery_out_services failed NOT...OK"
          }
      ;;
    "all_services")
      minishift_process_discovery_in_services \
      || {  return_val=$?;
            echo "all_services:minishift_process_discovery_in_services failed NOT..OK"
          }
      if [[ $return_val -eq 0 ]]; then
        minishift_process_discovery_out_services \
        || {  return_val=$?;
              echo "all_services:minishift_process_discovery_out_services failed NOT..OK"
            }
      fi
      ;;
    *)
      echo "discovery restriction not defined NOT...OK"
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
          if [[ ! -d ${discovery_folder}/${discovery_path} ]]; then
            {
              mkdir -p "${discovery_folder}"/"${discovery_path}" \
              && pushd "${discovery_folder}"/"${discovery_path}"
            } || {  return_val=$?;
                  echo \
                  "make or switch to new working directory failed with error code %s NOT...OK" $return_val;
                  break
                }
          fi
          case ${discovery_file} in
            "cdk-3.0-2-minishift-darwin-amd64")
            receiving_url="https://developers.redhat.com/download-manager/file/cdk-3.0-2-minishift-darwin-amd64"
             # sudo curl -L https://developers.redhat.com/download-manager/file/cdk-3.0-2-minishift-darwin-amd64 -o "${TOOL_HOME}"/minishift
            printf "please manually download receiving file from %s into discovery folder %s as file %s" \
            ${receiving_url} "${discovery_folder}" "${discovery_file}"
            echo "automated discovery filing and CDK based minishift start/stop with register/unregister step missing NOT...OK"

            return_val=1
            break
            ;;
            "minishift-v1.0.0")
              printf "Receiving  %s for filing from %s" "${discovery_file}" \
              "https://github.com/minishift/minishift/releases/download/v1.0.0/minishift-1.0.0-darwin-amd64.tgz"
              {
                curl -L \
                https://github.com/minishift/minishift/releases/download/v1.0.0/minishift-1.0.0-darwin-amd64.tgz > minishift-1.0.0-darwin-amd64.tgz \
                && tar -zxvf minishift-1.0.0-darwin-amd64.tgz minishift \
                && mv minishift minishift-v1.0.0
              } || {  return_val=$?
                      printf "discovery filing step for $discovery_item failed with code %s, NOT...OK" \
                      $return_val
                      rm -r "${discovery_folder:?}"/"${discovery_item:?}" \
                      || {  return_val=$?
                            printf "directory removal failed with error code %s NOT...OK" $return_val;
                            break
                          }
                      break

              }
              ;;
            "docker-machine-driver-xhyve-v0.3.3")
              printf "Receiving  %s for filing from %s" "${discovery_file}" \
              "https://github.com/zchee/docker-machine-driver-xhyve/releases/download/v0.3.3/docker-machine-driver-xhyve"
              curl -L \
              https://github.com/zchee/docker-machine-driver-xhyve/releases/download/v0.3.3/docker-machine-driver-xhyve > docker-machine-driver-xhyve-v0.3.3
              return_val=$?
              if [[ $return_val -gt 0 ]]; then
                printf "discovery filing step for $discovery_item failed with code %s, NOT...OK" \
                $return_val
                rm -r "${discovery_folder:?}"/"${discovery_item:?}" \
                || {
                     return_val=$?;
                     echo "directory removal failed NOT...OK";
                     break
                   }
                break
              fi
              ;;
          esac
          if [[ -d ${discovery_folder}/${discovery_path} ]]; then
            popd \
            || {  return_val=$?;
                  echo "change to previous working directory failed NOT...OK";
                  break
                }
          fi
        fi
      done
    fi
    if [[ $return_val -eq 0 ]]; then
      minishift_file_discovery "${discovery_restriction}" "${discovery[*]}" \
      || {  return_val=1;
            echo "minishift_file_discovery failed NOT..OK"
         }
    fi
    return $return_val
}

function minishift_build_case {
  return_val=1
  discovery_restriction=$1
  
  if [[ -z $discovery_restriction ]]; then
    :
  else
    minishift_process_discovery "$discovery_restriction"
    return_val=$?
  fi
  
  if [[ $return_val -ne 0 ]]; then
    echo "discovery process failed NOT...OK"
  #else
  #  minishift_order_in_session
  #  return_val=$?
  fi
  return $return_val
}

function minishift_order_is_adjourned {

  {
    echo export MINISHIFT_USERNAME="${MINISHIFT_USERNAME}";
    echo export MINISHIFT_PASSWORD="${MINISHIFT_PASSWORD}";
  } > "${MINISHIFT_ROOT}"/.minishift_start_register
  if [[ -e "${MINISHIFT_ROOT}"/minishift ]]; then
    #"${MINISHIFT_ROOT}"/minishift stop # --skip-unregistration
    # export MINISHIFT_PATH=$PATH
    expect <<HERE
      spawn su -l  "$ADMINISTRATOR" --posix
      expect "Password:"
      send "$ADMINISTRATOR_PASSWORD\r"
      expect "#"
      send "source $MINISHIFT_ROOT/.bash_profile\r"
      expect "#"
      send "${MINISHIFT_ROOT}/minishift stop\r"
      expect "#"
HERE
#expect "Password:"
#      send "$ADMINISTRATOR_PASSWORD\r"
  fi
}

function minishift_order_in_session {
  if [[ -e "${MINISHIFT_ROOT}"/.minishift_start_register ]]; then
    # shellcheck source=${MINISHIFT_ROOT}/.minishift_start_register
    source "${MINISHIFT_ROOT}"/.minishift_start_register
  fi

  trap "minishift_order_is_adjourned ; exit " SIGINT SIGHUP QUIT EXIT
  # TODO start with username and password for cdk setup
  expect <<HERE
    spawn su -l  "$ADMINISTRATOR" --posix
    expect "Password:"
    send "$ADMINISTRATOR_PASSWORD\r"
    expect "#"
    send "source $MINISHIFT_ROOT/.bash_profile\r"
    expect "#"
    set timeout 250
    send "${MINISHIFT_ROOT}/minishift start --insecure-registry 172.30.0.0/16 --show-libmachine-logs --v=5\r"
    expect "#"
HERE

}


function minishift_in_session_ok {
  return_val=0
  if [[ -e ${MINISHIFT_ROOT}/minishift ]];then
    case $( "${MINISHIFT_ROOT}"/minishift status) in
    "Running")
    :
    ;;
    *)
    return_val=1
    ;;
    esac
  else
     echo 'minishift executable does not exist. Please select discover_minishift or discover_all'
     return_val=1
  fi
  return $return_val;
}

function admin_entry_processing {
  admin_user_entry='false'
  export HISTCONTROL=ignoreboth
  source "${HOME}"/.bash_profile
  if [[ ! -e  "$VMD_HOME/admin" ]]; then
        admin_user_entry='true'
  else
    source "$VMD_HOME/admin"
    if [[ -z $ADMINISTRATOR ]]; then
      admin_user_entry='true'
    fi
  fi
  if [[ 'true' == "$admin_user_entry" ]]; then
        echo "enter admin user name"
        read -r input
        if [[ ! -e $VMD_HOME ]]; then
          mkdir -p "$VMD_HOME"
        fi
        echo "export ADMINISTRATOR=$input" >> "${VMD_HOME}"/admin
  fi
  . "${VMD_HOME}"/admin

  echo "entry admin password (password used only during runtime)"
  read -r input
  export ADMINISTRATOR_PASSWORD=$input

}
function path_setter_pre {
  return_val=0
  if [[ ! -d ${MINISHIFT_ROOT} ]]; then
    mkdir -p "${MINISHIFT_ROOT}" \
    || {  return_val=$?;
        printf "path_setter_pre:failed with code %s" $return_val
        }
  fi
  if [[ $return_val -eq  0 ]]; then
    echo "# The contents of this section are auto generated " > "${MINISHIFT_ROOT}"/okd_ocs_rc_pre.sh
    {
        echo export TOOL_HOME="${TOOL_HOME}" ;
        echo export MINISHIFT_ROOT="${MINISHIFT_ROOT}";
        echo export MINISHIFT_HOME="${MINISHIFT_HOME}" ;
        echo export MINISHIFT_PATH="${MINISHIFT_PATH}" ;
        echo export PATH=\""${MINISHIFT_PATH}":\$PATH\" ;
    } | {   grep export >> "${MINISHIFT_ROOT}"/okd_ocs_rc_pre.sh \
    && cat "$MINISHIFT_ROOT"/okd_ocs_rc_pre.sh >> "$MINISHIFT_ROOT"/.bash_profile
    }
  else
      printf "generation of okd_ocs_rc_pre.sh failed with error code %s" $return_val
  fi
  return $return_val
}

function path_setter_post {
  return_val=0
  if [[ -d ${MINISHIFT_ROOT} ]]; then
    {
      echo "# The contents of this section are partially auto generated using minishift" > "${MINISHIFT_ROOT}"/okd_ocs_rc_post.sh
      {
        if [[ -e ${MINISHIFT_ROOT}/minishift ]]; then
          "${MINISHIFT_ROOT}"/minishift docker-env;
          "${MINISHIFT_ROOT}"/minishift oc-env;
        fi

      } | grep export >> "${MINISHIFT_ROOT}"/okd_ocs_rc_post.sh
      cat "$MINISHIFT_ROOT"/okd_ocs_rc_post.sh >> "$MINISHIFT_ROOT"/.bash_profile
    } || {  return_val=$?;
            printf "path_setter_post failed with code %s" $return_val
          }
  else
    return_val=1;
    printf "path_setter_post failed as %s directory does not exist" "${MINISHIFT_ROOT}"
  fi


}

function init_globals {
  DEFAULT_HIST_FILE=$HISTFILE
  export HISTFILE=/dev/null
  export MINISHIFT_TMP_ROOT=/Users/Shared/var/tmp
  export MINISHIFT_ROOT=${MINISHIFT_TMP_ROOT}/minishift
  export MINISHIFT_HOME=${MINISHIFT_ROOT}/.minishift
  export VMD_HOME=${MINISHIFT_ROOT}/vmd/.vmd
  export VMD_ROOT=$MINISHIFT_ROOT
  export MINISHIFT_PATH=${TOOL_HOME}:${MINISHIFT_ROOT}:${MINISHIFT_HOME}
  SAMBA_FOLDER_NAME=
  export ADMINISTRATOR=
  export ADMINISTRATOR_PASSWORD=
  #SSHFS_HOST_FOLDER_NAME=shared
  #MINISHIFT_SHARED_FOLDER_ROOT=${MINISHIFT_ROOT}
}

export -f init_globals
export -f exit_okd
export -f posix_setter
export -f minishift_build_case
export -f minishift_close_case
export -f minishift_order_in_session
export -f minishift_order_is_adjourned
export -f minishift_in_session_ok
export -f admin_entry_processing
export -f path_setter_pre
export -f path_setter_post


