#!/bin/bash

[ "$DEBUG" == 'true' ] && set -x
set -e

# CONSULT_HOST is mandatory
if [[ -z ${CONSUL_HOST} ]]; then
  echo >&2 'error: CONSUL_HOST is not specified '
  exit 1
fi

# GALERA_SERVICE_NAME is mandatory
if [[ -z ${GALERA_SERVICE_NAME} ]]; then
  echo >&2 'error: SERVICE_NAME is not specified '
  exit 1
fi

# Save IPs to BACKEND_SERVER_LIST_IP
BACKEND_SERVER_LIST_IP="`./docker-entrypoint-initdb.d/discovery-tool-linux -h=${CONSUL_HOST} -servicename=${GALERA_SERVICE_NAME}-3306`"

# Give the registrator some time to register the container
for i in {1..0}; do
    echo "Discovery in progress... $i"

    VAR2="`./docker-entrypoint-initdb.d/discovery-tool-linux -h=${CONSUL_HOST} -servicename=${GALERA_SERVICE_NAME}-3306`"
    if [ "$BACKEND_SERVER_LIST_IP" = "$VAR2" ]; then 
        sleep 1
    else
        echo "New registered containers found!"  
        BACKEND_SERVER_LIST_IP="`./docker-entrypoint-initdb.d/discovery-tool-linux -h=${CONSUL_HOST} -servicename=${GALERA_SERVICE_NAME}-3306`"
    fi;
done

# Mandatory
if [[ -z $BACKEND_SERVER_LIST_IP ]]; then
    echo "No service is online or registered"
    exit 1
fi

# Make array with IPs
IFS=',' read -r -a backend_servers <<< "$BACKEND_SERVER_LIST_IP"

# Make array with names
ARRAY=()
for i in ${!backend_servers[@]}; do
    ARRAY+=($SERVER"server"$(($i + 1)))
done

# list alle server names in comma seperated string
function join_by { local IFS="$1"; shift; echo "$*"; }
BACKEND_SERVER_LIST_STRING=$(join_by , ${ARRAY[@]})

config_file="/etc/maxscale.cnf"

# We start config file creation
cat <<EOF > $config_file
[maxscale]
threads=4
 
[Galera Monitor]
type=monitor
module=galeramon
servers=$BACKEND_SERVER_LIST_STRING
user=maxscale
passwd=password
monitor_interval=10000
disable_master_failback=1
 
[qla]
type=filter
module=qlafilter
options=/tmp/QueryLog
 
[fetch]
type=filter
module=regexfilter
match=fetch
replace=select
 
[RW]
type=service
router=readwritesplit
servers=$BACKEND_SERVER_LIST_STRING
user=root
passwd=password
max_slave_connections=100%
router_options=slave_selection_criteria=LEAST_CURRENT_OPERATIONS
 
[RR]
type=service
router=readconnroute
router_options=synced
servers=$BACKEND_SERVER_LIST_STRING
user=root
passwd=password
 
[Debug Interface]
type=service
router=debugcli
 
[CLI]
type=service
router=cli
 
[RWlistener]
type=listener
service=RW
protocol=MySQLClient
port=3307
 
[RRlistener]
type=listener
service=RR
protocol=MySQLClient
port=3308
 
[Debug Listener]
type=listener
service=Debug Interface
protocol=telnetd
address=127.0.0.1
port=4442
 
[CLI Listener]
type=listener
service=CLI
protocol=maxscaled
address=127.0.0.1
port=6603

# Start the Server block
EOF

# add the [server] block
for i in ${!backend_servers[@]}; do
cat <<EOF >> $config_file
[${ARRAY[$i]}]
type=server
address=${backend_servers[$i]}
port=3306
protocol=MySQLBackend

EOF

done

exec "$@"