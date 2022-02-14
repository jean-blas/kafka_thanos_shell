#!/bin/bash

#Query thanos to get the under replicated partitions for a given cluster
# ex:
# ./underRepPart.sh bkp15

. $(dirname "$0")/utils.sh

ALL=$([ ! -v $2 ] && [ ${2} = "all" ] && echo "true" || echo "false")

usage() {
    printf "\n%s" \
    "under replication partitions :" \
    "  PARAMETER: the cluster name"
}

# Under replicated partitions in ERDING
urp_premises() {
  QUERY="'sum by (nodename) (kafka_server_ReplicaManager_Value{technical_cluster = \"$1\", name = \"UnderReplicatedPartitions\"})'"
  res=$(eval "$CURL -d query=$QUERY $THANOS_URL_PREMISES")
  if [ $ALL = 'false' ]; then
    echo "${res}" | jq -c '.data.result[] | [.metric.nodename, .value[1]]'
    pl_sum_jq "${res}"
  else
    echo $(sum_jq "${res}")
  fi
}

# Under replicated partitions in the CLOUD
urp_cloud() {
  QUERY="'sum by (topic) (kafka_cluster_partition_underreplicated{app_instance = \"$1\"})'"
  res=$(eval "$CURL -d query=$QUERY $THANOS_URL_CLOUD")
  if [ $ALL = 'false' ]; then
    echo "${res}" | jq -c '.data.result[] | [.metric.topic, .value[1]]'
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
    [[ $CLUSTER != *"s"* ]] && urp_premises $CLUSTER || urp_cloud $CLUSTER
fi
