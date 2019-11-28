#!/bin/bash -e

function BlockchainSquad(){
printf '
______________ _____________________ _______________  ____________________   __
___  __ )__  / __  __ \_  ____/__  //_/_  ____/__  / / /__    |___  _/__  | / /
__  __  |_  /  _  / / /  /    __  ,<  _  /    __  /_/ /__  /| |__  / __   |/ / 
_  /_/ /_  /___/ /_/ // /___  _  /| | / /___  _  __  / _  ___ |_/ /  _  /|  /  
/_____/ /_____/\____/ \____/  /_/ |_| \____/  /_/ /_/  /_/  |_/___/  /_/ |_/   
                                                                               
___________________  ________________ 
__  ___/_  __ \_  / / /__    |__  __ \
_____ \_  / / /  / / /__  /| |_  / / /
____/ // /_/ // /_/ / _  ___ |  /_/ / 
/____/ \___\_\\____/  /_/  |_/_____/  
'

}

function FINISHED(){
printf '
@@@@@@@@  @@@  @@@  @@@  @@@   @@@@@@   @@@  @@@  @@@@@@@@  @@@@@@@   
@@@@@@@@  @@@  @@@@ @@@  @@@  @@@@@@@   @@@  @@@  @@@@@@@@  @@@@@@@@  
@@!       @@!  @@!@!@@@  @@!  !@@       @@!  @@@  @@!       @@!  @@@  
!@!       !@!  !@!!@!@!  !@!  !@!       !@!  @!@  !@!       !@!  @!@  
@!!!:!    !!@  @!@ !!@!  !!@  !!@@!!    @!@!@!@!  @!!!:!    @!@  !@!  
!!!!!:    !!!  !@!  !!!  !!!   !!@!!!   !!!@!!!!  !!!!!:    !@!  !!!  
!!:       !!:  !!:  !!!  !!:       !:!  !!:  !!!  !!:       !!:  !!!  
:!:       :!:  :!:  !:!  :!:      !:!   :!:  !:!  :!:       :!:  !:!  
 ::        ::   ::   ::   ::  :::: ::   ::   :::   :: ::::   :::: ::  
 :        :    ::    :   :    :: : :     :   : :  : :: ::   :: :  :   
'
}

# Begin script by taking start time and printing Blockchain Squad messsage
start_time=$(date +%s)
BlockchainSquad

# Prefix to use to group resources of one run of automation. 
# The prefix makes it so different users can coexist.
# Please check to make sure your prefix isn't being used by a namespace yet with:
# kubectl get ns | grep prefix where prefix is the name of your prefix. 
# Make user enter prefix to prevent confusion
export PREFIX=${PREFIX:-""}

# Number of consoles to have given prefix, make user enter number to prevent confusion
export TEAM_NUMBER=${TEAM_NUMBER:-""}

# Set START_NUMBER at 0. If necessary users can adjust this. For example, if a deploy gets stopped
# midway due to a timeout, they can rerun with number they want to start with.
export START_NUMBER=${START_NUMBER:-"0"}

# Set admin email if want one admin email (username) for all console deployments rather than different team usernames.
export ADMIN_EMAIL=${ADMIN_EMAIL:-""}

# Set default password if you want one default password for all console deployments rather than different random team passwords.
export DEFAULT_PASSWORD=${DEFAULT_PASSWORD:-""}

# Set architecture for deployment
export ARCH=${ARCH:-"s390x"}

# Proxy IP of Cluster
export PROXY_IP=${PROXY_IP:-"$(kubectl get nodes -l 'proxy=true' -o jsonpath='{.items[0].status.addresses[0].address}')"}

# Console Hostname (Defaults to same value as PROXY_IP)
export CONSOLE_HOSTNAME=${CONSOLE_HOSTNAME:-"${PROXY_IP}"}

# Set resources to prod limits if true (Default is false)
export PROD=${PROD:-"false"}

# 3 options 
# 1. leave blank for self-signed TLS CERTS. 
export CERTS=${CERTS:-""}
# 2. Set to icp to use icp-cert manager to create certs using icp ca as ca.
#export CERTS=${CERTS:-"icp"}
# 3. set to byo for bring your own certs and set TLS_CERT and TLS_KEY to your certs
#export CERTS=${CERTS:-"byo"}

# Path to TLS certificate for blockchain console (Only used if CERTS=byo)
# Default is file named cert.pem in directory of script (Only used if CERTS=byo)
export TLS_CERT=${TLS_CERT:-"cert.pem"}

# Path to TLS key for blockchain console (Only used if CERTS=byo)
# Default is file named key.pem in directory of script (Only used if CERTS=byo)
export TLS_KEY=${TLS_KEY:-"key.pem"}

# Use multi-arch images
export MULTIARCH=${MULTIARCH:-"true"}

# Kubernetes Storage class for dynamic provisioning
export STORAGE_CLASS=${STORAGE_CLASS:-"managed-nfs-storage"}

# Hostname for ICP Cluster if images stored locally 
export CLUSTER_HOSTNAME=${CLUSTER_HOSTNAME:-""}

# Server address for docker registry where docker images are stored. Use Cluster Hostname if supplied
if [ -z ${CLUSTER_HOSTNAME} ]; then
# Need to manually enter DOCKER_USERNAME and Password to create secret from API_KEY if not using local images
    export DOCKER_USERNAME=${DOCKER_USERNAME:-""}
    export API_KEY=${API_KEY:-""}
    export DOCKER_SERVER=${DOCKER_SERVER:-"ip-ibp-images-team-docker-remote.artifactory.swg-devops.com"}
else
# Using local images with local registry
    export DOCKER_SERVER=${DOCKER_SERVER:-"$CLUSTER_HOSTNAME:8500"}
fi

# Namespace where docker images were pushed for the helm chart (where helm chart archive chart was loaded).
export DOCKER_NAMESPACE=${DOCKER_NAMESPACE:-"cp"}

# Version of HLF, default to 1.4.1 for IBP for Multicloud v2
export HLF_VERSION=${HLF_VERSION:-"1.4.3"}

export HLF_VERSION_LONG=${HLF_VERSION_LONG:-"${HLF_VERSION}-0"}

# Version of IBP
export IBP_VERSION=${IBP_VERSION:-"2.1.1"}

# Product ID of IBP
export PRODUCT_ID=${PRODUCT_ID:-"54283fa24f1a4e8589964e6e92626ec4"}

# Version of CouchDB
export COUCH_VERSION=${COUCH_VERSION:-"2.3.1"}

# Date images cut
export IMAGE_DATE=${IMAGE_DATE:-"20191108"}

# Clusterrole set that has necessary resource access for IBM Blockchain Platform console and operator. 
# Following resources in directory, his is ibm-blockchain-platform-clusterrole. The service account will get these
#privileges scoped to its namespace in the form of a rolebinding
export IBP_CLUSTERROLE=${IBP_CLUSTERROLE:-"ibm-blockchain-platform-clusterrole-211"}

# Clusterrole to give cluster-wide access to create CRD, is bound via clusterrolebinding in script
export CRD_CLUSTERROLE=${CRD_CLUSTERROLE:-"ibm-blockchain-platform-crd-clusterrole-211"}

# Clusterrole to give access to privileged psp
export PSP_CLUSTERROLE=${PSP_CLUSTERROLE:-"ibm-blockchain-platform-psp-clusterrole-211"}

# Name of new service account to be created in each namespace to dole out extra permissions
export SERVICE_ACCOUNT_NAME=${SERVICE_ACCOUNT_NAME:-"ibp"}

# Launches namespace setup script
echo -e "\n\n ---- Creating $TEAM_NUMBER of Console Instances ----\n"
./NamespaceSetup.sh

# Finish and give runtime as well as nice message
runtime=$(($(date +%s)-start_time))
FINISHED
echo
echo "It took $(( $runtime / 60 )) minutes and $(( $runtime % 60 )) seconds to setup $TEAM_NUMBER Console instances each in an unique namespace"
