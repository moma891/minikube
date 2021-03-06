#!/bin/bash

# Copyright 2019 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# cleanup shared between Linux and macOS
function check_jenkins() {
  jenkins_pid="$(pidof java)"
  if [[ "${jenkins_pid}" = "" ]]; then
          return
  fi
  pstree "${jenkins_pid}" \
        | egrep -i 'bash|integration|e2e|minikube' \
        && echo "tests are is running on pid ${jenkins_pid} ..." \
        && exit 1
}

check_jenkins
logger "cleanup_and_reboot running - may shutdown in 60 seconds"
echo "cleanup_and_reboot running - may shutdown in 60 seconds" | wall
sleep 10
check_jenkins
logger "cleanup_and_reboot is happening!"

# kill jenkins to avoid an incoming request
killall java

# clean docker left overs
docker rm -f -v $(docker ps -aq) >/dev/null 2>&1 || true
docker volume prune -f || true
docker volume ls || true
docker system df || true

# Linux-specific cleanup

# disable localkube, kubelet
systemctl list-unit-files --state=enabled \
        | grep kube \
        | awk '{ print $1 }' \
        | xargs systemctl disable

# update and reboot
apt update -y && apt upgrade -y && reboot
