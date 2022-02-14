#!/bin/bash

#Query thanos to get the broker state for a given cluster
# ex:
# ./brokerState.sh bkp15

. $(dirname "$0")/utils.sh

ALL=$([ ! -v $2 ] && [ ${2} = "all" ] && echo "true" || echo "false")

usage() {
    printf "\n%s" \
    "broker state :" \
    "  PARAMETER: the cluster name"
}

# Broker state in ERDING
bs_premises() {
  QUERY="'kafka_server_KafkaServer_Value{technical_cluster = \"$1\", name = \"BrokerState\"}'"
  res=$(eval "$CURL -d query=$QUERY $THANOS_URL_PREMISES")
  if [ $ALL = 'false' ]; then
    echo "$res" | jq -c '.data.result[] | [.metric.nodename, .value[1]]'
  else
    echo "$res" | jq -c -r -j '.data.result[] | .value[1]'

  fi
}

# Broker state in the CLOUD
bs_cloud() {
  QUERY="'kafka_server_kafkaserver_brokerstate{app_instance = \"$1\"}'"
  res=$(eval "$CURL -d query=$QUERY $THANOS_URL_CLOUD")
  if [ $ALL = 'false' ]; then
    echo "$res" | jq -c '.data.result[] | [.metric.pod_name, .value[1]]'
  else
    echo "$res" | jq -c -r -j '.data.result[] | .value[1]'

  fi
}

: ${1?"missing parameter... `usage`"}

if [[ $1 == *"-h"* ]]; then
    usage
else
    CLUSTER=$1
    [[ $CLUSTER != *"s"* ]] && bs_premises $CLUSTER || bs_cloud $CLUSTER
fi
