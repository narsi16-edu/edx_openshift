#!/bin/bash

function oc_mysql_gen_and_invoke() {
  project=$1
  app=$2
  appwkrnd="wkrnd$$"
  oc login "$(minishift ip):8443" -u developer -p developer
  oc new-project "$project"
  oc new-app \
    MYSQL_USER=user \
    MYSQL_PASSWORD=password \
    MYSQL_DATABASE=database \
    MYSQL_ROOT_PASSWORD=rootpassword \
    --docker-image="registry.access.redhat.com/rhscl/mysql-56-rhel7" \
    --name="$app"

  oc run -t -i  \
  $appwkrnd \
  --image="registry.access.redhat.com/rhscl/mysql-56-rhel7" \
  --restart=Never \
  -- bash -c "while(true) do echo hello;sleep 300; done " &
  ocappwkrnd_run_pid=$!

  #db=mysql # Docker Hub MySQL
  sleep 20
  oc status
  ocwkpod=$(oc get pods | grep "$appwkrnd" | sed s/'\(^[A-Za-z0-9_-]*\).*$'/\\1/)
  ocpods=$(oc get pods | grep "$app" | sed s/'\(^[A-Za-z0-9_-]*\).*$'/\\1/)
  for ocpod in $ocpods; do
    oc describe pod "$ocpod"
    ocsvcport=$(oc describe pod "$ocpod" | grep Port |  sed s/'Port:'// | sed s/'\([0-9]*\)\/TCP$'/\\1/)
    # shellcheck disable=SC2086
    # shellcheck disable=SC2116
    ocsvsport=$(echo $ocsvcport)
    ocsvciaddr=$(oc describe pod "$ocpod"| grep IP | sed s/'IP:'//)
    # shellcheck disable=SC2086
    # shellcheck disable=SC2116
    ocsvciaddr=$(echo $ocsvciaddr)
    oc exec -it "$ocwkpod" /bin/bash <<HERE
    echo uname -a
    mysql -h$ocsvciaddr -P$ocsvsport -uuser -ppassword -D database --execute="show databases;"
HERE
    oc delete pod "$ocwkpod"
  done

  if [[ -z $ocappwkrnd_run_pid ]]; then
    echo "logic trap for practically unreachable code...NOT OK"
    return_val=1
  else
    kill -9 $ocappwkrnd_run_pid
    return_val=$?
  fi

  if [[ $return_val -eq 0 ]]; then
    # oc describe pod $app
    ocsvcs=$(oc get svc | grep "$app" | sed s/'\(^[A-Za-z0-9_-]*\).*$'/\\1/)
    for ocsvc in $ocsvcs; do
      oc describe svc "$ocsvc"
    done
    # oc describe svc $app
    oc describe dc "$app"
    if [[ ! -d ~/var/tmp/edx ]]; then
      mkdir -p ~/var/tmp/edx
      chown "$(whoami):wheel" ~/var/tmp/edx
    fi
    oc export svc "$app" >~/var/tmp/edx/"${app}-svc.yml"
    cat ~/var/tmp/edx/"${app}-svc.yml"
    rm -r ~/var/tmp/edx

    oc delete project "$project"
    oc logout
    return_val=$?
  fi
  return $return_val
}


