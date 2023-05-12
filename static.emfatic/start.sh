#!/bin/bash

set -e

########################
# Wait for service to be ready
# Globals: none
# Arguments: name host port
# Returns: none
#########################
wait_for_service() {
    local service_name="$1"
    local service_host="$2"
    local service_port="$3"
    local service_address=$(getent hosts "$service_host" | awk '{ print $1 }')
    counter=0
    echo "Connecting to $service_name at $service_address"
    while ! nc -z "$service_address" "$service_port" >/dev/null; do
        counter=$((counter+1))
        if [ $counter == 30 ]; then
            echo "Error: Couldn't connect to $service_name at $service_address."
            exit 1
        fi
        echo "Trying to connect to $service_name at $service_address. Attempt $counter."
        sleep 5
    done
}

#TODO dockerize the build of eclipse based tools
# Functions for running Emfatic 
#cd com.mde-network.ep.toolfunctions.emfaticfunction
#mvn -B -o function:run -Drun.functionTarget=com.mdenetnetwork.ep.toolfunctions.emfaticfunction.RunConversionEcoreToEmfatic -Drun.port=8001 &
#wait_for_service EcoreToEmfatic 127.0.0.1 8001
#cd ..

#mvn -B -o function:run -Drun.functionTarget=org.eclipse.epsilon.live.FlexmiToPlantUMLFunction -Drun.port=8002 &
#wait_for_service Flexmi  127.0.0.1 8002

# nginx as frontend + reverse proxy
envsubst < /etc/nginx.conf.template > /etc/nginx/conf.d/default.conf
nginx -g "daemon off;" &

# wait for them all
wait -n
