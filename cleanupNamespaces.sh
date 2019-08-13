#!/bin/bash -e

function Cleanup(){
printf "
       \`..   \`..      \`........      \`.       \`...     \`..
 \`..   \`..\`..      \`..           \`. ..     \`. \`..   \`..
\`..       \`..      \`..          \`.  \`..    \`.. \`..  \`..
\`..       \`..      \`......     \`..   \`..   \`..  \`.. \`..
\`..       \`..      \`..        \`...... \`..  \`..   \`. \`..
 \`..   \`..\`..      \`..       \`..       \`.. \`..    \`. ..
   \`....  \`........\`........\`..         \`..\`..      \`..
"
}

TEAM_NUMBER=${TEAM_NUMBER:-${1}}
PREFIX=${PREFIX:-${1}}

if [ -z ${TEAM_NUMBER} ]; then
	echo -e "\nError: Number of teams not set !!!\n"
	echo -e "Usage:\n\tTEAM_NUMBER=<number_of_teams> PREFIX=<chosen_prefix> ./cleanup.sh"
	exit 1
fi

if [ -z ${PREFIX} ]; then
	echo -e "\nError: Prefix name for deployment not set !!!\n"
	echo -e "Usage:\n\tTEAM_NUMBER=<number_of_teams> PREFIX=<chosen_prefix> ./cleanup.sh"
	exit 1
fi

START_NUMBER=${START_NUMBER:-"0"}

start_time=$(date +%s)

for (( i = ${START_NUMBER}; i < ${TEAM_NUMBER}; i++ ))
do
    if [ ${i} -lt 10 ]
    then
        export team="team0${i}"
    else
        export team="team${i}"
    fi
    set -x
    HELM_NAME=${PREFIX}-${team}-ibp-console
    helm delete ${HELM_NAME} --purge --tls 
    kubectl delete clusterrolebinding ${PREFIX}-${team}-ibp-crd
    set +x
done 

for (( i = ${START_NUMBER}; i < ${TEAM_NUMBER}; i++ ))
do
    if [ ${i} -lt 10 ]
    then
        export team="team0${i}"
    else
        export team="team${i}"
    fi
    set -x
    NAMESPACE="${PREFIX}-${team}"
    kubectl delete ns ${NAMESPACE}
    set +x
done

echo
runtime=$(($(date +%s)-start_time))
Cleanup
echo
echo "It took $(( $runtime / 60 )) minutes and $(( $runtime % 60 )) seconds to cleanup $TEAM_NUMBER optools instances and their namespaces"
