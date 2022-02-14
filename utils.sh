#!/bin/bash

# Useful functions and variables

# set -o xtrace   #: debug the script
set -o errexit  # : to exit on error

THANOS_URL_PREMISES="https://thanos-world.tnz.amadeus.net/api/v1/query"

THANOS_URL_CLOUD="https://thanos-query-world-argos.muc8.paas.amadeus.net/api/v1/query"

CURL="curl -s "

declare -g BROKERS_ERDING
declare -A CLUSTERS_ERDING
declare -g BROKERS_CLOUD
declare -A CLUSTERS_CLOUD

BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
PINK="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
NORMAL="\033[0;39m"

# $1 = color and $2 = format and $3 = string to print
pcolor() {
    case $1 in
      GREEN)
         printf "\033[32m"$2"\033[0;39m" ${3} ;;
      YELLOW)
         printf "\033[33m"$2"\033[0;39m" ${3} ;;
      RED)
         printf "\033[31m"$2"\033[0;39m" ${3} ;;
      BLUE)
         printf "\033[34m"$2"\033[0;39m" ${3} ;;
      WHITE)
         printf "\033[37m"$2"\033[0;39m" ${3} ;;
      *)
         printf "$2" $3 ;;
    esac
}

# Print a string in color
#$1 = color and $2 = string to print
pscolor() {
    pcolor $1 "%s\t" "${2}"
}

# Println a string in color
#$1 = color and $2 = string to print
plcolor() {
    pcolor $1 "%s\n" "${2}"
}

prt0() {
    if [ $1 = "0" ]; then pscolor GREEN 0; else pscolor RED $1; fi
}

# Parse the args and write in RED if it is not only 3
prt3() {
    re='^[3]+$'
    if [[ $1 =~ $re ]]; then
        pscolor GREEN $1
    else
        pscolor RED $1
    fi
}

prt70() {
    readarray -d " " -t arr <<< "${1}"
    too70="false"
    too90="false"
    for k in "${arr[@]}"; do
        if [ $((k)) -ge 90 ]; then too90="true"; fi
        if [ $((k)) -ge 70 ]; then too70="true"; fi
    done
    if [ $too90 = "true" ]; then
        pcolor RED "%s|" "${1}"
    elif [ $too70 = "true" ]; then
        pcolor YELLOW "%s|" "${1}"
    else
        pcolor GREEN "%s|" "${1}"
    fi
}

# Print an array or map ($1=msg $2=array to print)
parr() {
    echo "$1"
    declare -n __p="$2"
    for k in "${!__p[@]}"; do
        printf "%3s=%s\n" "$k" "${__p[$k]}"
    done
}

# Print an array or map ($1=msg $2=array to print $3=nb of columns)
parrcol() {
    echo "$1"
    declare -n __p="$2"
    i=0
    for k in "${!__p[@]}"; do
        printf "%3s=%s\t" "$k" "${__p[$k]}"
        i="`expr $i + 1`"
        if [ $((i % $3)) = 0 ]; then
            printf "\n"
        fi
    done
    printf "\n"
}

# Create an inventory for ERDING
inv_premises() {
    # echo -n ${FUNCNAME}:
    __query="'kafka_server_KafkaServer_Value{name = \"BrokerState\"}'"
    __temp=$(eval "$CURL -d query=$__query $THANOS_URL_PREMISES | jq '[.data.result[] | .metric.nodename | values] | sort' | tr '[]\",' ' '")
    echo $__temp
}

# Create an inventory for the cloud
inv_cloud() {
  QUERY="'kafka_server_kafkaserver_brokerstate'"
  BROKERS_CLOUD=$(eval "$CURL -d query=$QUERY $THANOS_URL_CLOUD | jq '[.data.result[] | .metric.pod_name | values] | sort ' | tr '[]\",' ' '")
  echo $BROKERS_CLOUD
}

# Transform, for example, bkp15 into bkpv15
addV() {
    addv=$1
    re='^(bk)(\w)([0-9]{2})'
    if [[ $addv =~ $re ]]; then
      addv=${BASH_REMATCH[1]}${BASH_REMATCH[2]}v${BASH_REMATCH[3]}
    fi
    echo $addv
}

# Deduce the name of the cluster from a broker (bktv1503 -> bkt15)
# $1=broker (bktv1500)
toName() {
    tn=$1
    re='^(bk.)v([0-9]{2})[0-9]{2}'
    if [[ $tn =~ $re ]]; then
        tn=${BASH_REMATCH[1]}${BASH_REMATCH[2]}
    else
        tn=""
    fi
    echo $tn
}

# Create the map of (cluster name, nb of brokers) from ERDING inventory
# $1 : BROKERS_ERDING array
clusters_premises() {
    temp=$1[@]
    brokers=("${!temp}")
    for i in "${!brokers[@]}"; do
        brokers[$i]=$(toName ${brokers[$i]})
    done
    inv=$(printf '%s\n' "${brokers[@]}" | sort | uniq -c | tr '\n' ' ' | sed 's/  */ /g' )
    readarray -d " " -t ainv <<< "$inv"
    len=${#ainv[*]}
    for (( j=1; j<$len-1; j+=2 )); do
        CLUSTERS_ERDING[${ainv[$j+1]}]=${ainv[$j]}
    done
}

# Deduce the name of the cluster from a broker (bkts15-kafka-0 -> bkt15)
# $1=broker (bkts15-kafka-0)
toNameCloud() {
    tn=$1
    re='(.*)-kafka-[0-9]+'
    if [[ $tn =~ $re ]]; then
        tn=${BASH_REMATCH[1]}
    else
        tn=""
    fi
    echo $tn
}

# Create the map of (cluster name, nb of brokers) from CLOUD inventory
# $1 : BROKERS_CLOUD array
clusters_cloud() {
    temp=$1[@]
    brokers=("${!temp}")
    for i in "${!brokers[@]}"; do
        brokers[$i]=$(toNameCloud ${brokers[$i]})
    done
    inv=$(printf '%s\n' "${brokers[@]}" | sort | uniq -c | tr '\n' ' ' | sed 's/  */ /g' )
    readarray -d " " -t ainv <<< "$inv"
    len=${#ainv[*]}
    for (( j=1; j<$len-1; j+=2 )); do
        CLUSTERS_CLOUD[${ainv[$j+1]}]=${ainv[$j]}
    done
}

# Summation of array colums using jq ($1 = array to sum)
sum_jq() {
    echo $(echo "${1}" | jq '[.data.result[] | .value[1] | tonumber ] | add')
}

pl_sum_jq() {
    sum=$(sum_jq "${1}")
    if [ $sum == 0 ]; then plcolor GREEN 0; else plcolor RED $sum; fi
}
