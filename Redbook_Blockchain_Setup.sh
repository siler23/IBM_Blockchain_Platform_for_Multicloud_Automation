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

# Set admin email if want one admin email (username) for all console deployments rather than different team usenames.
export ADMIN_EMAIL=${ADMIN_EMAIL:-""}

# Prefix to use automation for lab and non-lab purposes. 
# Make user enter prefix to prevent confusion
export PREFIX=${PREFIX:-""}

# Set architecture for deployment
export ARCH=${ARCH:-"s390x"}

# Set name of local helm repo used in helm install command
export HELM_REPO=${HELM_REPO:-"blockchain-charts"}

# Version of helm chart
export PROD_VERSION=${PROD_VERSION:-"2.0.0"}

# Proxy IP of Cluster
export PROXY_IP=${PROXY_IP:-"$(kubectl get nodes -l proxy -o jsonpath='{.items[0].metadata.labels.kubernetes\.io\/hostname}')"}

# Use multi-arch images
export MULTIARCH=${MULTIARCH:-"true"}

# Storage class for dynamic provisioning
export STORAGE_CLASS=${STORAGE_CLASS:-"managed-nfs-share"}

# Hostname for ICP Cluster
export CLUSTER_HOSTNAME=${CLUSTER_HOSTNAME:-"mycluster.icp"}

# Server address for docker registry where docker images are stored
export DOCKER_SERVER=${DOCKER_SERVER:-"$CLUSTER_HOSTNAME:8500"}

# Namespace where docker images were pushed for the helm chart (where helm chart archive chart was loaded).
export DOCKER_NAMESPACE=${DOCKER_NAMESPACE:-"blockchain-time"}

# Version of HLF, default to 1.4.1 for IBP for Multicloud v2
export HLF_VERSION=${HLF_VERSION:-"1.4.1"}

# Version of IBP
export IBP_VERSION=${IBP_VERSION:-"2.0.0"}

# Number of teams for the lab, make user enter number to prevent confusion
export TEAM_NUMBER=${TEAM_NUMBER:-""}

# Set START_NUMBER at 0. If necessary users can adjust this. For example, if a deploy gets stopped
# midway due to a timeout, they can rerun with number they want to start with.
export START_NUMBER=${START_NUMBER:-"0"}

# Clusterrole set that has necessary resource access for IBP optools helm chart. 
# In wsc cluster this is ibm-blockchain-platform-clusterrole. The service account will get these
#privileges scoped to its namespace in the form of a rolebinding
export IBP_CLUSTERROLE=${IBP_CLUSTERROLE:-"ibm-blockchain-platform-clusterrole"}

# Clusterrole to give cluster-wide access to create CRD, is bound via clusterrolebinding in script
export CRD_CLUSTERROLE=${CRD_CLUSTERROLE:-"crd-clusterrole"}

# Clusterrole to give access to privileged psp
export PSP_CLUSTERROLE=${PSP_CLUSTERROLE:-"ibm-blockchain-platform-psp-clusterrole"}

# Name of new service account to be created in each namespace to dole out extra permissions
export SERVICE_ACCOUNT_NAME=${SERVICE_ACCOUNT_NAME:-"ibp"}

# Launches namespace setup script
echo -e "\n\n ---- Creating $TEAM_NUMBER of Optools Instances ----\n"
./NamespaceSetup.sh

# Finish and give runtime as well as nice message
runtime=$(($(date +%s)-start_time))
FINISHED
echo
echo "It took $(( $runtime / 60 )) minutes and $(( $runtime % 60 )) seconds to setup $TEAM_NUMBER optools instances each in an unique namespace"
