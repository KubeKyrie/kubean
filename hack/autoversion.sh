#!/usr/bin/env bash

# Copyright 2023 Authors of kubean-io
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o nounset
set -o pipefail

KUBEAN_VERSION=$(git describe --tags "$(git rev-list --tags --max-count=1)")
SUPPORTED_FILE_PATH="./docs/zh/usage/support_k8s_version.md"


# Now the runner's OS is is Centos7
if ! which yq; then
    echo "need yq (https://github.com/mikefarah/yq)."
    wget https://github.com/mikefarah/yq/releases/download/v4.30.8/yq_linux_amd64
    chmod 777 yq_linux_amd64
    mv yq_linux_amd64 /usr/bin/yq
fi

# get default k8s version from /charts/kubean/templates/manifest.cr.yaml
function get_k8s_default_version() {
  rm manifest.cr.yaml -rf
  curl https://raw.githubusercontent.com/kubean-io/kubean-helm-chart/kubean-${KUBEAN_VERSION}/charts/kubean/templates/manifest.cr.yaml -O
  range=$(cat manifest.cr.yaml| yq '.spec.components[] | select(.name=="kube")' | yq '.defaultVersion' | tr '"' "'")
  echo ${range//- / }
}

# get k8s version range from /charts/kubean/templates/manifest.cr.yaml
function get_k8s_version_range() {
  rm manifest.cr.yaml -rf
  curl https://raw.githubusercontent.com/kubean-io/kubean-helm-chart/kubean-${KUBEAN_VERSION}/charts/kubean/templates/manifest.cr.yaml -O
  # get versionRange string
  range=$(cat manifest.cr.yaml| yq '.spec.components[] | select(.name=="kube")' | yq '.versionRange' | tr '"' "'")
  # replace each - with <br\/>       -, divide into one line, remove \n and remove the first <br\/>
  echo "$range" | sed 's/-/<br\/>       -/g'|sed ':a;N;$!ba;s/\n/ /g'| sed 's/<br\/>       //'
}

# print tab content
function k8s_version_tab_render() {
  #printf -- "| %-13s | %-24s | %s |\n" 'kubean Version' 'Default Kubernetes Version' 'Supported Kubernetes Version Range'
  #printf -- "| %-13s| %-24s| %s|\n" '-----------' '----------------------' '------------------------------------------------------------'
  printf -- "| %-13s | %-24s| %s|\n" "$KUBEAN_VERSION" "$k8s_default_version" "$k8s_version_range"
}

#############################################################################

k8s_default_version=$(get_k8s_default_version)
echo "k8s_default_version: ${k8s_default_version}"

k8s_version_range=$(get_k8s_version_range)
echo "k8s_version_range: ${k8s_version_range}"

rm -rf manifest.cr.yaml

k8s_version_tab_render >> "$SUPPORTED_FILE_PATH"
