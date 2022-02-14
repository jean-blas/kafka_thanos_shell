#!/bin/bash

# Query thanos to get the disk occupancy
# ex:
# ./diskOccupancy.sh bkp15

. $(dirname "$0")/utils.sh

ALL=$([ ! -v $2 ] && [ ${2} = "all" ] && echo "true" || echo "false")

usage() {
    printf "\n%s" \
    "disk occupancy :" \
    "  PARAMETER: the cluster name"
}

# Parse the args and create the map
_extractMem() {
    declare -n res="$1"
    re='.*(bk.v[0-9]{4}).*,"([0-9]*).*'
    for arg in $@; do
        if [[ $arg =~ $re ]]; then
          g1=${BASH_REMATCH[1]}
          res[$g1]=${BASH_REMATCH[2]}
        fi
    done
}

# Display the maps to screen
_displayMaps() {
    declare -n fmap="$1"
    declare -n smap="$2"
    res=""
    for key in "${!smap[@]}"; do
      fm=$((fmap[$key]))
      sm=$((smap[$key]))
      gfm="`expr $fm / 1024 / 1024 / 1024`"
      gsm="`expr $sm / 1024 / 1024 / 1024`"
      pct="`expr 100 - $fm \* 100 / $sm`"
      if [ $ALL = 'false' ]; then
        echo -e "$key => free : ${gfm} Gb \t size : ${gsm} Gb \t used : $pct %"
      else
        res="${res} $pct"
      fi
    done
    if [ $ALL = 'true' ]; then
      echo "${res}"
    fi
}

# Disk occupance in ERDING
do_premises() {
  BROKER_NAME=$(addV $1)
  QUERY1="'max by (instance) (node_filesystem_free_bytes{mountpoint=\"/opt/kafkadata\",application=\"KAFZOO\",componentname=\"KAF\"})'"
  freeMem=$(eval "$CURL -d query=$QUERY1 $THANOS_URL_PREMISES | jq -c '.data.result[] | [.metric.instance, .value[1]]' | grep $BROKER_NAME")
  declare -A aFreeMem=()
  _extractMem aFreeMem $freeMem
  QUERY2="'max by (instance) (node_filesystem_size_bytes{mountpoint=\"/opt/kafkadata\",application=\"KAFZOO\",componentname=\"KAF\"})'"
  sizeMem=$(eval "$CURL -d query=$QUERY2 $THANOS_URL_PREMISES | jq -c '.data.result[] | [.metric.instance, .value[1]]' | grep $BROKER_NAME")
  declare -A aSizeMem=()
  _extractMem aSizeMem $sizeMem
  _displayMaps aFreeMem aSizeMem
}

# Disk occupance in the CLOUD
do_cloud() {
    echo "not implemented"
}

: ${1?"missing parameter... `usage`"}

if [[ $1 == *"-h"* ]]; then
    usage
else
    CLUSTER=$1
    [[ $CLUSTER != *"s"* ]] && do_premises $CLUSTER || do_cloud
fi
