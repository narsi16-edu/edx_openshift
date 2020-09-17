#!/bin/bash

function oc_http_gen_and_invoke {
  return_val=0
  project=$1
  app=$2
  oc login "$(minishift ip):8443" -u developer -p developer
  oc new-project "$project"

  oc new-app \
  --name="$app"  \
  php:7.0~https://github.com/RedHatTraining/DO081x-lab-php-helloworld.git

  sleep 20
  oc log -f bc/"$app"
  oc describe bc/"$app"
  ocsvcs=$(oc get svc | grep "$app" | sed s/'\(^[A-Za-z0-9_-]*\).*$'/\\1/)

  for ocsvc in $ocsvcs
    do
      ocsvciaddr=$(oc describe svc "$ocsvc" | \
                  grep IP: | \
                  sed s/"[A-Za-z:\']*[[:space:]][[:space:]]*"//)
      sleep 5
      minishift ssh -- "curl ${ocsvciaddr}:8080"
    done
  oc expose service "$app" --name "${app}"route

  rou=$(oc get route | \
        grep "$app" |  \
        sed s/'^[A-Za-z0-9-]*[[:space:]]*'//  | \
        sed s/'[[:space:]][[:space:]]*[A-Za-z0-9-]*.*$'//)

  curl "$rou"

   oc delete project  "$project"
   oc logout



  return_val=$?
  return  $return_val
}
