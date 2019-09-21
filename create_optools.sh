#!/bin/bash -e

export CA_IMAGE=${CA_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp2/hlfabric-ca"}
export CONFIGTXLATOR_IMAGE=${CONFIGTXLATOR_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp2/hlfabric-configtxlator"}
export COUCH_IMAGE=${COUCH_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp2/hlfabric-couchdb"}
export DEPLOYER_IMAGE=${DEPLOYER_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp2/deployer-to-go"}
export DIND_IMAGE=${DIND_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp2/hlfabric-dind"}
export FLUENTD_IMAGE=${FLUENTD_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/fluentd"}
export FLUENTD_TAG=${FLUENTD_TAG:-"v1.4-2"}
export GRPC_IMAGE=${GRPC_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp2/hlfabric-grpcweb"}
export INIT_IMAGE=${INIT_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp2/hlfabric-init"}
export OPERATOR_IMAGE=${OPERATOR_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp2/ibp-operator"}
export OPTOOLS_IMAGE=${OPTOOLS_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/op-tools/op-tools"}
export ORDERER_IMAGE=${ORDERER_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp2/hlfabric-orderer"}
export PEER_IMAGE=${PEER_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp2/hlfabric-peer"}


# Memory and CPU Configuration
if [ "${PROD}" = true ]
then
    #Configtxlator
    CONFIGTXLATOR_CPU_LIMITS=25m
    CONFIGTXLATOR_MEMORY_LIMITS=100Mi
    CONFIGTXLATOR_CPU_REQUESTS=25m
    CONFIGTXLATOR_MEMORY_REQUESTS=50Mi

    #CouchDB
    COUCHDB_CPU_LIMITS=500m
    COUCHDB_MEMORY_LIMITS=1000Mi
    COUCHDB_CPU_REQUESTS=500m
    COUCHDB_MEMORY_REQUESTS=1000Mi

    #Deployer
    DEPLOYER_CPU_LIMITS=100m
    DEPLOYER_MEMORY_LIMITS=200Mi
    DEPLOYER_CPU_REQUESTS=100m
    DEPLOYER_MEMORY_REQUESTS=200Mi

    #Operator
    OPERATOR_CPU_LIMITS=100m
    OPERATOR_MEMORY_LIMITS=200Mi
    OPERATOR_CPU_REQUESTS=100m
    OPERATOR_MEMORY_REQUESTS=200Mi

    #Optools
    OPTOOLS_CPU_LIMITS=500m
    OPTOOLS_MEMORY_LIMITS=1000Mi
    OPTOOLS_CPU_REQUESTS=500m
    OPTOOLS_MEMORY_REQUESTS=1000Mi
else
    #Configtxlator
    CONFIGTXLATOR_CPU_LIMITS=25m
    CONFIGTXLATOR_MEMORY_LIMITS=100Mi
    CONFIGTXLATOR_CPU_REQUESTS=25m
    CONFIGTXLATOR_MEMORY_REQUESTS=10Mi

    #CouchDB
    COUCHDB_CPU_LIMITS=250m
    COUCHDB_MEMORY_LIMITS=250Mi
    COUCHDB_CPU_REQUESTS=50m
    COUCHDB_MEMORY_REQUESTS=100Mi

    #Deployer
    DEPLOYER_CPU_LIMITS=100m
    DEPLOYER_MEMORY_LIMITS=100Mi
    DEPLOYER_CPU_REQUESTS=25m
    DEPLOYER_MEMORY_REQUESTS=10Mi

    #Operator
    OPERATOR_CPU_LIMITS=100m
    OPERATOR_MEMORY_LIMITS=100Mi
    OPERATOR_CPU_REQUESTS=25m
    OPERATOR_MEMORY_REQUESTS=20Mi

    #Optools
    OPTOOLS_CPU_LIMITS=250m
    OPTOOLS_MEMORY_LIMITS=250Mi
    OPTOOLS_CPU_REQUESTS=50m
    OPTOOLS_MEMORY_REQUESTS=100Mi
fi

# Helm install using local repo added from cluster repo with the IBP optools helm chart
set -x
helm install --tls --namespace ${NAMESPACE} ${HELM_REPO}/ibm-blockchain-platform-prod --version ${PROD_VERSION} -n ${HELM_NAME} \
--set app.email="${EMAIL}" \
--set app.multiArch=${MULTIARCH} \
--set app.passwordSecretName="${UI_SECRET}" \
--set app.proxyIP="${PROXY_IP}" \
--set app.serviceAccountName="${SERVICE_ACCOUNT_NAME}" \
--set arch="${ARCH}" \
--set dataPVC.storageClassName="${STORAGE_CLASS}" \
--set image.caImage="${CA_IMAGE}" \
--set image.caTag="${HLF_VERSION}" \
--set image.configtxlatorImage="${CONFIGTXLATOR_IMAGE}" \
--set image.configtxlatorTag="${HLF_VERSION}" \
--set image.couchdbImage="${COUCH_IMAGE}" \
--set image.couchdbTag="${HLF_VERSION}" \
--set image.deployerImage="${DEPLOYER_IMAGE}" \
--set image.deployerTag="${IBP_VERSION}" \
--set image.dindImage="${DIND_IMAGE}" \
--set image.dindTag="${HLF_VERSION}" \
--set image.fluentdImage="${FLUENTD_IMAGE}" \
--set image.fluentdTag="${FLUENTD_TAG}" \
--set image.grpcwebImage="${GRPC_IMAGE}" \
--set image.grpcwebTag="${HLF_VERSION}" \
--set image.imagePullSecret="${DOCKER_SECRET}" \
--set image.initImage="${INIT_IMAGE}" \
--set image.initTag="${HLF_VERSION}" \
--set image.operatorImage="${OPERATOR_IMAGE}" \
--set image.operatorTag="${IBP_VERSION}" \
--set image.optoolsImage="${OPTOOLS_IMAGE}" \
--set image.optoolsTag="${IBP_VERSION}" \
--set image.ordererImage="${ORDERER_IMAGE}" \
--set image.ordererTag="${HLF_VERSION}" \
--set image.peerImage="${PEER_IMAGE}" \
--set image.peerTag="${HLF_VERSION}" \
--set ingress.optools.hostname="${CONSOLE_HOSTNAME}" \
--set ingress.optools.port=${OPTOOLS_PORT} \
--set ingress.proxy.hostname="${CONSOLE_HOSTNAME}" \
--set ingress.proxy.port=${PROXY_PORT} \
--set ingress.tls.secret="${TLS_SECRET}" \
--set license="accept" \
--set resources.configtxlator.limits.cpu="${CONFIGTXLATOR_CPU_LIMITS}" \
--set resources.configtxlator.limits.memory="${CONFIGTXLATOR_MEMORY_LIMITS}" \
--set resources.configtxlator.requests.cpu="${CONFIGTXLATOR_CPU_REQUESTS}" \
--set resources.configtxlator.requests.memory="${CONFIGTXLATOR_MEMORY_REQUESTS}" \
--set resources.couchdb.limits.cpu="${COUCHDB_CPU_LIMITS}" \
--set resources.couchdb.limits.memory="${COUCHDB_MEMORY_LIMITS}" \
--set resources.couchdb.requests.cpu="${COUCHDB_CPU_REQUESTS}" \
--set resources.couchdb.requests.memory="${COUCHDB_MEMORY_REQUESTS}" \
--set resources.deployer.limits.cpu="${DEPLOYER_CPU_LIMITS}" \
--set resources.deployer.limits.memory="${DEPLOYER_MEMORY_LIMITS}" \
--set resources.deployer.requests.cpu="${DEPLOYER_CPU_REQUESTS}" \
--set resources.deployer.requests.memory="${DEPLOYER_MEMORY_REQUESTS}" \
--set resources.operator.limits.cpu="${OPERATOR_CPU_LIMITS}" \
--set resources.operator.limits.memory="${OPERATOR_MEMORY_LIMITS}" \
--set resources.operator.requests.cpu="${OPERATOR_CPU_REQUESTS}" \
--set resources.operator.requests.memory="${OPERATOR_MEMORY_REQUESTS}" \
--set resources.optools.limits.cpu="${OPTOOLS_CPU_LIMITS}" \
--set resources.optools.limits.memory="${OPTOOLS_MEMORY_LIMITS}" \
--set resources.optools.requests.cpu="${OPTOOLS_CPU_REQUESTS}" \
--set resources.optools.requests.memory="${OPTOOLS_MEMORY_REQUESTS}"

RC=$?

set +x

if [ $RC != 0 ]; then
    echo "Optools/operator ${HELM_NAME} Deployment Failed"
    exit 1
fi