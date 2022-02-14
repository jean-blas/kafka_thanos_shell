#!/bin/bash

# Main entry point: call the others scripts
# ex:
# ./switcher urp bkp15|bkps03
# ./switcher all bkp15|bkps03
# ./switcher urp erding|cloud
# ./switcher all erding|cloud
# ./switcher show erding|cloud

. $(dirname "$0")/utils.sh

usage() {
    printf "\n%s" \
    "usage : SHELL COMMAND PARAMS" \
    "where:" \
    "  SHELL   = $0" \
    "  COMMAND = urp, do, ums, bs, olp, all, show" \
    "     all  : run all commands (e.g. SHELL all bkp15)" \
    "     show : display brokers and clusters only (e.g. SHELL show erding)" \
    "  PARAMS  = the command parameters, usually the cluster name or:" \
    "   erding : to check all erding clusters (e.g. SHELL urp erding)" \
    "    cloud : to check all PaaS clusters (e.g. SHELL urp cloud)"
}

: ${1?"missing parameter... `usage`"}
COMMAND=$1
shift
ERDING=$([ ! -v $1 ] && [ ${1} = "erding" ] && echo "true" || echo "false")
CLOUD=$([ ! -v $1 ] && [ ${1} = "cloud" ] && echo "true" || echo "false")

declare -A files=(
    [bs]=brokerState.sh
    [do]=diskOccupancy.sh
    [olp]=offlinePartitions.sh
    [ums]=minInSync.sh
    [urp]=underRepPart.sh
)

if [ ${files[$COMMAND]+_} ]; then

    if [ $ERDING = 'false' ] && [ $CLOUD = 'false' ]; then
        # Run one command for one cluster
        bash $(dirname "$0")/${files[$COMMAND]} $@

    elif [ $ERDING = 'true' ]; then
        # Run one command for all ERDING clusters
        readarray -d " " -t BROKERS_ERDING <<< $(inv_premises)
        clusters_premises BROKERS_ERDING
        len=${#CLUSTERS_ERDING[*]}
        printf "Found %d brokers in %d Clusters\n" ${#BROKERS_ERDING[*]} $len
        for k in ${!CLUSTERS_ERDING[@]}; do
            printf "%s [%d]:\t" $k ${CLUSTERS_ERDING[$k]}
            bash $(dirname "$0")/${files[$COMMAND]} $k all
        done

    elif [ $CLOUD = 'true' ]; then
        # Run one command for all PaaS clusters
        readarray -d " " -t BROKERS_CLOUD <<< $(inv_cloud)
        clusters_cloud BROKERS_CLOUD
        len=${#CLUSTERS_CLOUD[*]}
        printf "Found %d brokers in %d Clusters\n" ${#BROKERS_CLOUD[*]} $len
        for k in ${!CLUSTERS_CLOUD[@]}; do
            printf "%s [%d]:\t" $k ${CLUSTERS_CLOUD[$k]}
            bash $(dirname "$0")/${files[$COMMAND]} $k all
        done

    else
        usage; exit 1
    fi

elif [ $COMMAND = "all" ]; then

    if [ $ERDING = 'false' ] && [ $CLOUD = 'false' ]; then
        # Run all commands for a given cluster
        for key in "${!files[@]}"; do
            printf "\n%s:\n" "${files[$key]}"
            bash $(dirname "$0")/${files[$key]} $@
        done

    elif [ $ERDING = 'true' ]; then
        # Compute the inventories and run all commands for all clusters
        readarray -d " " -t BROKERS_ERDING <<< $(inv_premises)
        # parr "BROKERS in ERDING:" BROKERS_ERDING
        clusters_premises BROKERS_ERDING
        # parr "CLUSTERS in ERDING:" CLUSTERS_ERDING
        len=${#CLUSTERS_ERDING[*]}
        printf "Found %d brokers in %d Clusters\n" ${#BROKERS_ERDING[*]} $len
        printf "name  [nb]:\tmis\turp\tolp\tbs\tdo(%%)\n"
        for k in ${!CLUSTERS_ERDING[@]}; do
            printf "%s [%d]:\t" $k ${CLUSTERS_ERDING[$k]}
            ums=$(bash $(dirname "$0")/${files["ums"]} $k all)
            urp=$(bash $(dirname "$0")/${files["urp"]} $k all)
            olp=$(bash $(dirname "$0")/${files["olp"]} $k all)
             bs=$(bash $(dirname "$0")/${files["bs"]}  $k all)
             do=$(bash $(dirname "$0")/${files["do"]}  $k all)
            prt0 $ums; prt0 $urp; prt0 $olp; prt3 $bs; prt70 "${do}"; echo ""
        done

    elif [ $CLOUD = 'true' ]; then
        readarray -d " " -t BROKERS_CLOUD <<< $(inv_cloud)
        clusters_cloud BROKERS_CLOUD
        len=${#CLUSTERS_CLOUD[*]}
        printf "Found %d brokers in %d Clusters \n" ${#BROKERS_CLOUD[*]} $len
        printf "name  [nb]:\tmis\turp\tolp\tbs\n"
        for k in ${!CLUSTERS_CLOUD[@]}; do
            printf "%s [%d]:\t" $k ${CLUSTERS_CLOUD[$k]}
            ums=$(bash $(dirname "$0")/${files["ums"]} $k all)
            urp=$(bash $(dirname "$0")/${files["urp"]} $k all)
            olp=$(bash $(dirname "$0")/${files["olp"]} $k all)
             bs=$(bash $(dirname "$0")/${files["bs"]}  $k all)
            prt0 $ums; prt0 $urp; prt0 $olp; prt3 $bs; echo ""
        done

    else
        usage; exit 1
    fi

elif [ $COMMAND = 'show' ]; then

    if [ $ERDING = 'true' ]; then
        readarray -d " " -t BROKERS_ERDING <<< $(inv_premises)
        parrcol "BROKERS in ERDING:" BROKERS_ERDING 5
        clusters_premises BROKERS_ERDING
        parrcol "CLUSTERS in ERDING:" CLUSTERS_ERDING 5
        len=${#CLUSTERS_ERDING[*]}
        printf "\nFound %d brokers in %d Clusters\n" ${#BROKERS_ERDING[*]} $len

    elif [ $CLOUD = 'true' ]; then
        readarray -d " " -t BROKERS_CLOUD <<< $(inv_cloud)
        parrcol "BROKERS in CLOUD:" BROKERS_CLOUD 3
        clusters_cloud BROKERS_CLOUD
        parrcol "CLUSTERS in CLOUD:" CLUSTERS_CLOUD 3
        len=${#CLUSTERS_CLOUD[*]}
        printf "\nFound %d brokers in %d Clusters \n" ${#BROKERS_CLOUD[*]} $len

    else
        usage; exit 1
    fi

elif [ $COMMAND = *"-h"* ]; then

    for key in "${!files[@]}"; do
        printf "\n%s:" "$key"
        bash $(dirname "$0")/${files[$key]} "-h"
    done

else
    usage; exit 1
fi
