#!/bin/bash -e

# Throw error if PROXY_IP not set by script
if [ -z "${PROXY_IP}" ]; then
	echo -e "\nError: Proxy IP is not set !!! Please enter it manually with the following usage pattern. \n"
    echo -e "Usage:\n\tTEAM_NUMBER=<number_of_teams> PREFIX=<chosen_prefix> PROXY_IP=<proxy_ip> ./Redbook_Blockchain_Setup.sh"
    exit 1
fi

if [ -z ${TEAM_NUMBER} ]; then
	echo -e "\nError: Number of teams not set !!!\n"
	echo -e "Usage:\n\tTEAM_NUMBER=<number_of_teams> PREFIX=<chosen_prefix> ./Redbook_Blockchain_Setup.sh"
	exit 1
fi

if [ -z "${PREFIX}" ]; then
	echo -e "\nError: Prefix name for deployment not set !!!\n"
	echo -e "Usage:\n\tTEAM_NUMBER=<number_of_teams> PREFIX=<chosen_prefix> ./Redbook_Blockchain_Setup.sh"
	exit 1
fi

# Make an array of available ports for helm deploy and name a file
# to hold oldPorts for the lab
declare -a available_ports
export oldPorts="./oldPorts.txt"

# Create a list of all ports used so instructors can reference this later. 
# Overwrite existing file when First team details created.
if [ ${START_NUMBER} -eq 0 ]
then
    echo "List of ports for each team for quick reference" > portList.txt
    echo >> portList.txt
fi

# Create Namespace with all necessary resources to deploy the optools helm chart
for (( i=${START_NUMBER}; i < ${TEAM_NUMBER}; i++ ))
do
    if [ ${i} -lt 10 ]
    then
        export team="team0${i}"
    else
        export team="team${i}"
    fi

    echo "Setting up namespace for ${team}"
    export NAME="${PREFIX}-${team}-ibp-console"
    
    # If admin email entered use this for all console deployments, else use individual team emails. 
    if [ -z "${ADMIN_EMAIL}" ]; then
        export EMAIL="${team}@ibm.com"
    else
        export EMAIL="${ADMIN_EMAIL}"
    fi
    export NAMESPACE="${PREFIX}-${team}"
    export UI_SECRET="${team}-ibp-ui-secret"
    export INITIAL_PASSWORD="${team}pw"
    export DOCKER_SECRET="${team}-icp-docker-registry"
    
    set -x
    kubectl create ns "${NAMESPACE}"
    kubectl config set-context --current --namespace="$NAMESPACE"
    kubectl create secret generic "${UI_SECRET}" --from-literal=password="${INITIAL_PASSWORD}"
    kubectl create sa "${SERVICE_ACCOUNT_NAME}"
    kubectl create rolebinding ibp-admin --serviceaccount "${NAMESPACE}":"${SERVICE_ACCOUNT_NAME}" --clusterrole="${IBP_CLUSTERROLE}"
    kubectl create rolebinding ibp-psp --group system:serviceaccounts:"${NAMESPACE}" --clusterrole="${PSP_CLUSTERROLE}"
    kubectl create clusterrolebinding "${NAMESPACE}"-ibp-crd --serviceaccount "${NAMESPACE}":"${SERVICE_ACCOUNT_NAME}" --clusterrole="${CRD_CLUSTERROLE}"
    kubectl create secret generic blockchain-docker-registry --from-literal=.dockerconfigjson=$(kubectl get secret -n "${DOCKER_NAMESPACE}" sa-"${DOCKER_NAMESPACE}" -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode) --type=kubernetes.io/dockerconfigjson

    set +x
    # Get used ports. Run this every time ports are going to be given to prevent port collision 
    # if someone were to get a port while script was running. Store these ports in oldPorts.txt file.

    # Use 30000 as starter and 32768 as stopper since nodePort range is 30000-32768.
    kubectl get svc --all-namespaces -o go-template='{{range .items}}{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}{{end}}' | sort > oldPorts.txt && echo "32768" >> oldPorts.txt
    nextNodePort=30000
    counter=0
    while IFS= read -r port
    do
        while [[ $nextNodePort -le $port ]]
        do
            if [[ $nextNodePort -ne $port ]]
            then 
                available_ports+=($nextNodePort)
                counter=$(( counter + 1 ))
            fi
            nextNodePort=$(( nextNodePort + 1 ))
            if [[ ${counter} -ge 2 ]]
            then
                break;
            fi
        done
    done < "$oldPorts" 

    optools_number=$(( (${i}-${START_NUMBER}) * 2 ))
    proxy_number=$(( (${i}-${START_NUMBER}) * 2 + 1 ))

    export OPTOOLS_PORT=${available_ports[$optools_number]}
    export PROXY_PORT=${available_ports[$proxy_number]}

    # Deploy helm chart by calling create_optools.sh script with variables set
    ./create_optools.sh
    
    echo "****************   TEAM${i}  ****************" >> portList.txt
    echo "${team} optools URL: https://${PROXY_IP}:${OPTOOLS_PORT}" >> portList.txt
    echo "${team} proxy URL: https://${PROXY_IP}:${PROXY_PORT}" >> portList.txt
    echo "${team} USERNAME: ${team}@ibm.com" >> portList.txt
    echo "${team} PASSWORD: ${team}pw" >> portList.txt
    echo >> portList.txt
    
    if [ $? != 0 ]
    then
        echo "Optools Deployment $i failed"
        exit 1
    fi
    sleep 3
done

if [ ${START_NUMBER} -gt 0 ]
then
    echo "Cleanup Command for This Run: TEAM_NUMBER=${TEAM_NUMBER} START_NUMBER=${START_NUMBER} PREFIX=${PREFIX} ./cleanupNamespaces.sh" >> portList.txt
fi

echo "Full Cleanup Command: TEAM_NUMBER=${TEAM_NUMBER} PREFIX=${PREFIX} ./cleanupNamespaces.sh" >> portList.txt
echo >> portList.txt

for (( i=${START_NUMBER}; i < ${TEAM_NUMBER}; i++ ))
do
    SECONDS=0
    if [ ${i} -lt 10 ]
    then
        export team="team0${i}"
    else
        export team="team${i}"
    fi
    optools_number=$(( ($i-${START_NUMBER}) * 2 ))
    proxy_number=$(( ($i-${START_NUMBER}) * 2 + 1 ))

    echo "Checking deploy for ${team}"

    # Check for all pods to come up successfully in all namespaces and add each of their 
    # exposed ports to the list when they do.
    while (( $SECONDS < 600 ));
    do 
        HELM_NAME=${PREFIX}-${team}-ibp-console
        NAMESPACE="${PREFIX}-${team}"
        POD_NAME=$(kubectl get pod -n "${NAMESPACE}" | grep "${HELM_NAME}" | awk '{print $1}')
        POD_STATUS=$(kubectl get pods -n "${NAMESPACE}" | grep "${HELM_NAME}" | awk '{print $3}')
        TOTAL_CONTAINERS=$(kubectl get pod -n "${NAMESPACE}" | grep "${HELM_NAME}" | awk '{print $2}' | awk '{print substr($0,length,1)}')
        IS_READY=$(kubectl get pods -n "${NAMESPACE}" | grep "${HELM_NAME}" | awk '{print $2}')
        if [ "${IS_READY}" == "${TOTAL_CONTAINERS}/${TOTAL_CONTAINERS}" ]
        then
            break;
        fi
        echo "Waiting for pod ${POD_NAME} to start completion. Status = ${POD_STATUS}, Readiness = ${IS_READY}"
        sleep 3
    done

    if [ $SECONDS -ge 600 ]
    then
        echo "Timed out waiting for pod ${POD_NAME} to start completion"
        exit 1
    fi
done

# Remove oldPorts text file
rm ./oldPorts.txt