#!/bin/bash


cat "./edx_rc_pre.sh" > "$HOME"/.bash_profile
source "$HOME"/.bash_profile
cd "$TOOL_HOME"


sudo curl -L  https://github.com/zchee/docker-machine-driver-xhyve/releases/download/v0.3.3/docker-machine-driver-xhyve -o /usr/local/bin/docker-machine-driver-xhyve
sudo chown root:wheel /usr/local/bin/docker-machine-driver-xhyve
sudo chmod u+s,+x /usr/local/bin/docker-machine-driver-xhyve
minishift setup-cdk


minishift config set memory 2048
minishift start --insecure-registry 172.30.0.0/16

echo "# The contents of this file are auto generated using minishift" > "./edx_rc_post.sh"
minishift docker-env | grep export >> "./edx_rc_post.sh"
minishift oc-env | grep export >> "./edx_rc_post.sh"
cat "./edx_rc_post.sh" >> "$HOME"/.bash_profile

source "$HOME"/.bash_profile
bash