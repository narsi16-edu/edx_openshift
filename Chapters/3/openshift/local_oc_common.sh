#!/bin/bash

function oc_gen_and_invoke() {
  # shellcheck source=${CHAP3_HOME}/openshift/local_oc_mysql.sh
  source "${CHAP3_HOME}/openshift/local_oc_mysql.sh"
  # shellcheck source=${CHAP3_HOME}/openshift/local_oc_http.sh
  source "${CHAP3_HOME}/openshift/local_oc_http.sh"
  # shellcheck disable=SC2068
  $@
}
