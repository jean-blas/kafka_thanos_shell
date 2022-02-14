#!/bin/bash

#Query thanos to get the offline partitions for a given cluster
# ex:
# ./offlinePartitions.sh bkp15

. $(dirname "$0")/utils.sh

ALL=$([ ! -v $2 ] && [ ${2} = "all" ] && echo "true" || echo "false")

usage() {
    printf "\n%s" \
    "offline partitions :" \
    "  PARAMETER: the cluster name"
}

# Offline partitions in ERDING
olp_premises() {
  QUERY="'kafka_controller_KafkaController_Value{technical_cluster = \"$1\", name = \"OfflinePartitionsCount\"}'"
  res=$(eval "$CURL -d query=$QUERY $THANOS_URL_PREMISES" | tr "\'" '\"')
  if [ $ALL = 'false' ]; then
    echo "${res}" | jq -c '.data.result[] | [.metric.nodename, .value[1]]'
    pl_sum_jq "${res}"
  else
    echo $(sum_jq "${res}")
  fi
}

# Offline partitions in the CLOUD
olp_cloud() {
  QUERY="'kafka_controller_kafkacontroller_offlinepartitionscount{app_instance = \"$1\"}'"
  res=$(eval "$CURL -d query=$QUERY $THANOS_URL_CLOUD")
  if [ $ALL = 'false' ]; then
    echo "${res}" | jq -c '.data.result[] | [.metric.pod_name, .value[1]]'
    pl_sum_jq "${res}"
  else
    echo $(sum_jq "${res}")
  fi
}

: ${1?"missing parameter... `usage`"}

if [[ $1 == *"-h"* ]]; then
    usage
else
    CLUSTER=$1
    [[ $CLUSTER != *"s"* ]] && olp_premises $CLUSTER || olp_cloud $CLUSTER
fi
