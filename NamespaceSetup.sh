#!/bin/bash -e

# Throw error if PROXY_IP not set by script
if [ -z "${PROXY_IP}" ]; then
	echo -e "\nError: Proxy IP is not set !!! Please enter it manually with the following usage pattern. \n"
    echo -e "Usage:\n\tTEAM_NUMBER=<number_of_teams> PREFIX=<chosen_prefix> PROXY_IP=<proxy_ip> ./Blockchain_Setup.sh"
    exit 1
fi

if [ -z ${TEAM_NUMBER} ]; then
	echo -e "\nError: Number of teams not set !!!\n"
	echo -e "Usage:\n\tTEAM_NUMBER=<number_of_teams> PREFIX=<chosen_prefix> ./Blockchain_Setup.sh"
	exit 1
fi

if [ -z "${PREFIX}" ]; then
	echo -e "\nError: Prefix name for deployment not set !!!\n"
	echo -e "Usage:\n\tTEAM_NUMBER=<number_of_teams> PREFIX=<chosen_prefix> ./Blockchain_Setup.sh"
	exit 1
fi

# If CERTS is byo check if TLS_CERT and TLS_KEY files exist or throw error
if [ "${CERTS}" = "byo" ]; then
    if [ ! -f "${TLS_CERT}" ]
    then
        echo "You specified CERTS = byo. This means you need to provide a relevant certificate and key file." 
        echo "The TLS certificate at the path specified in variable TLS_CERT (${TLS_CERT}) does not exist"
        exit 1
    fi
    if [ ! -f "${TLS_KEY}" ]
    then
        echo "You specified CERTS = byo. This means you need to provide a relevant certificate and key file." 
        echo "The TLS key at the path specified in variable TLS_KEY (${TLS_KEY}) does not exist"
        exit 1
    fi
fi

# Make an array of available ports for console deployment and name a file
# to hold oldPorts for the lab
declare -a available_ports
export oldPorts="oldPorts.txt"

# Create a list of all ports used so instructors can reference this later. 
# Overwrite existing file when First team details created.
if [ ${START_NUMBER} -eq 0 ]
then
    echo "List of ports for each team for quick reference" > portList.txt
    echo >> portList.txt
fi

# Create Namespace with all necessary resources to deploy the operator and console
for (( i=${START_NUMBER}; i < ${TEAM_NUMBER}; i++ ))
do
    if [ ${i} -lt 10 ]
    then
        export team="0${i}"
    else
        export team="${i}"
    fi
    
    # If admin email entered use this for all console deployments, else use individual team emails. 
    if [ -z "${ADMIN_EMAIL}" ]; then
        export EMAIL="team${team}@ibm.com"
    else
        export EMAIL="${ADMIN_EMAIL}"
    fi

    # If default password not entered, use random individual team passwords, else use default password for alll deployments.
    if [ -z "${DEFAULT_PASSWORD}" ]; then
        export INITIAL_PASSWORD="team${team}pw${RANDOM}"
    else
        export INITIAL_PASSWORD="${DEFAULT_PASSWORD}"
    fi

    export NAMESPACE="${PREFIX}-${team}"
    export DOCKER_SECRET="blockchain-docker-registry"
    # TLS_SECRET only used if CERTS=byo or CERTS=icp
    export TLS_SECRET="blockchain-tls"
    export BASE_NAME="${NAMESPACE}-ibp"
    
    echo "Setting up namespace ${NAMESPACE}"

    set -x
    kubectl create ns "${NAMESPACE}"
    kubectl config set-context --current --namespace="$NAMESPACE"
    if [ "${CERTS}" = "byo" ]; then
        kubectl create secret tls "${TLS_SECRET}" --cert="${TLS_CERT}" --key="${TLS_KEY}" 
    elif [ "${CERTS}" = "icp" ]; then
        ./create_icp_certificate.sh
    else
        # TLS_SECRET only used if CERTS=byo or CERTS=icp
        export TLS_SECRET=""
    fi
    kubectl create sa "${SERVICE_ACCOUNT_NAME}"
    kubectl create rolebinding ibp-admin --serviceaccount "${NAMESPACE}":"${SERVICE_ACCOUNT_NAME}" --clusterrole="${IBP_CLUSTERROLE}"
    kubectl create rolebinding ibp-psp --group system:serviceaccounts:"${NAMESPACE}" --clusterrole="${PSP_CLUSTERROLE}"
    kubectl create clusterrolebinding "${NAMESPACE}"-ibp-crd --serviceaccount "${NAMESPACE}":"${SERVICE_ACCOUNT_NAME}" --clusterrole="${CRD_CLUSTERROLE}"
    if [ -z ${CLUSTER_HOSTNAME} ]; then
        kubectl create secret docker-registry ${DOCKER_SECRET} --docker-server=${DOCKER_SERVER}/${DOCKER_NAMESPACE} --docker-username=${DOCKER_USERNAME} --docker-password=${API_KEY}
    else
        kubectl create secret generic blockchain-docker-registry --from-literal=.dockerconfigjson=$(kubectl get secret -n "${DOCKER_NAMESPACE}" sa-"${DOCKER_NAMESPACE}" -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode) --type=kubernetes.io/dockerconfigjson
    fi

    set +x
    # Get used ports. Run this every time ports are going to be given to prevent port collision 
    # if someone were to get a port while script was running. Store these ports in text file set in variable oldPorts. 

    # Use 30000 as starter and 32768 as stopper since nodePort range is 30000-32768.
    kubectl get svc --all-namespaces -o go-template='{{range .items}}{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}{{end}}' | sort > "${oldPorts}" && echo "32768" >> "${oldPorts}"
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
                break 2;
            fi
        done
    done < "$oldPorts" 

    console_number=$(( (${i}-${START_NUMBER}) * 2 ))
    proxy_number=$(( (${i}-${START_NUMBER}) * 2 + 1 ))

    export CONSOLE_PORT=${available_ports[$console_number]}
    export PROXY_PORT=${available_ports[$proxy_number]}
    # Deploy operator and console deployments by calling create_operator_console.sh script with variables set
    ./create_operator_console.sh
    
    if [ $? != 0 ]
    then
        echo "CONSOLE Deployment ${team} failed"
        exit 1
    fi

    SECONDS=0
    while (( $SECONDS < 600 ));
    do 
        SVC_NAME=$(kubectl get svc | grep "ibpconsole-service" | awk '{print $1}')
        if [ "${SVC_NAME}" == "ibpconsole-service" ]; then
            break;
        fi
        sleep 3
    done

    if [ $SECONDS -ge 600 ]
    then
        echo "Timed out waiting for service: ${SVC_NAME} to be create "
        exit 1
    fi

    echo "****************   ${BASE_NAME}  ****************" >> portList.txt
    echo "${BASE_NAME} console URL: https://${CONSOLE_HOSTNAME}:${CONSOLE_PORT}" >> portList.txt
    echo "${BASE_NAME} proxy URL: https://${CONSOLE_HOSTNAME}:${PROXY_PORT}" >> portList.txt
    echo "${BASE_NAME} USERNAME: ${EMAIL}" >> portList.txt
    echo "${BASE_NAME} PASSWORD: ${INITIAL_PASSWORD}" >> portList.txt
    echo >> portList.txt
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
        export team="0${i}"
    else
        export team="${i}"
    fi
    console_number=$(( ($i-${START_NUMBER}) * 2 ))
    proxy_number=$(( ($i-${START_NUMBER}) * 2 + 1 ))

    NAMESPACE="${PREFIX}-${team}"
    
    echo "Checking ibp-operator deploy in namespace: ${NAMESPACE}"

    while (( $SECONDS < 600 ));
    do 
        POD_NAME=$(kubectl get pod -n "${NAMESPACE}" | grep "ibp-operator" | awk '{print $1}')
        POD_STATUS=$(kubectl get pods -n "${NAMESPACE}" | grep "ibp-operator" | awk '{print $3}')
        TOTAL_CONTAINERS=$(kubectl get pod -n "${NAMESPACE}" | grep "ibp-operator" | awk '{print $2}' | awk '{print substr($0,length,1)}')
        IS_READY=$(kubectl get pods -n "${NAMESPACE}" | grep "ibp-operator" | awk '{print $2}')
        if [ "${IS_READY}" == "${TOTAL_CONTAINERS}/${TOTAL_CONTAINERS}" ]
        then
            break;
        fi
        echo "Waiting for pod ${POD_NAME} to start completion. Status = ${POD_STATUS}, Readiness = ${IS_READY}"
        sleep 3
    done

    if [ $SECONDS -ge 600 ]
    then
        echo "Timed out waiting for pod: ${POD_NAME} to start completion"
        exit 1
    fi
    SECONDS=0
    echo "Checking ibpconsole deploy in namespace: ${NAMESPACE}"

    while (( $SECONDS < 600 ));
    do 
        POD_NAME=$(kubectl get pod -n "${NAMESPACE}" | grep "ibpconsole" | awk '{print $1}')
        POD_STATUS=$(kubectl get pods -n "${NAMESPACE}" | grep "ibpconsole" | awk '{print $3}')
        TOTAL_CONTAINERS=$(kubectl get pod -n "${NAMESPACE}" | grep "ibpconsole" | awk '{print $2}' | awk '{print substr($0,length,1)}')
        IS_READY=$(kubectl get pods -n "${NAMESPACE}" | grep "ibpconsole" | awk '{print $2}')
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
rm "${oldPorts}"