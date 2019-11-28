#!/bin/bash -e

export CA_IMAGE=${CA_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-ca"}
export CONFIGTXLATOR_IMAGE=${CONFIGTXLATOR_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-utilities"}
export COUCH_IMAGE=${COUCH_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-couchdb"}
export DEPLOYER_IMAGE=${DEPLOYER_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-deployer"}
export DIND_IMAGE=${DIND_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-dind"}
export FLUENTD_IMAGE=${FLUENTD_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-fluentd"}
export GRPC_IMAGE=${GRPC_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-grpcweb"}
export IBP_INIT_IMAGE=${IBP_INIT_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-init"}
export OPERATOR_IMAGE=${OPERATOR_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-operator"}
export CONSOLE_IMAGE=${CONSOLE_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-console"}
export ORDERER_IMAGE=${ORDERER_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-orderer"}
export PEER_IMAGE=${PEER_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-peer"}
export CA_INIT_IMAGE=${CA_INIT_IMAGE:-"${DOCKER_SERVER}/${DOCKER_NAMESPACE}/ibp-ca-init"}

export OPERATOR_DATE=${OPERATOR_DATE:-"${IMAGE_DATE}"}
export IBP_INIT_DATE=${IBP_INIT_DATE:-"${IMAGE_DATE}"}
export CONSOLE_DATE=${CONSOLE_DATE:-"${IMAGE_DATE}"}
export CONFIGTXLATOR_DATE=${CONFIGTXLATOR_DATE:-"${IMAGE_DATE}"}
export COUCH_DATE=${COUCH_DATE:-"${IMAGE_DATE}"}
export DEPLOYER_DATE=${DEPLOYER_DATE:-"${IMAGE_DATE}"}
export CA_INIT_DATE=${CA_INIT_DATE:-"${IMAGE_DATE}"}
export CA_DATE=${CA_DATE:-"${IMAGE_DATE}"}
export IBP_INIT_DATE=${IBP_INIT_DATE:-"${IMAGE_DATE}"}
export PEER_DATE=${PEER_DATE:-"${IMAGE_DATE}"}
export DIND_DATE=${DIND_DATE:-"${IMAGE_DATE}"}
export FLUENTD_DATE=${FLUENTD_DATE:-"${IMAGE_DATE}"}
export GRPC_DATE=${GRPC_DATE:-"${IMAGE_DATE}"}
export ORDERER_DATE=${ORDERER_DATE:-"${IMAGE_DATE}"}


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

    #CONSOLE
    CONSOLE_CPU_LIMITS=500m
    CONSOLE_MEMORY_LIMITS=1000Mi
    CONSOLE_CPU_REQUESTS=500m
    CONSOLE_MEMORY_REQUESTS=1000Mi
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

    #CONSOLE
    CONSOLE_CPU_LIMITS=250m
    CONSOLE_MEMORY_LIMITS=250Mi
    CONSOLE_CPU_REQUESTS=50m
    CONSOLE_MEMORY_REQUESTS=100Mi
fi

set -x
cat << EOF > ${BASE_NAME}-operator-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ibp-operator
  labels:
    release: "operator"
    helm.sh/chart: "ibm-ibp"
    app.kubernetes.io/name: "ibp"
    app.kubernetes.io/instance: "ibpoperator"
    app.kubernetes.io/managed-by: "ibp-operator"
spec:
  replicas: 1
  strategy:
    type: "Recreate"
  selector:
    matchLabels:
      name: ibp-operator
  template:
    metadata:
      labels:
        name: ibp-operator
        release: "operator"
        helm.sh/chart: "ibm-ibp"
        app.kubernetes.io/name: "ibp"
        app.kubernetes.io/instance: "ibpoperator"
        app.kubernetes.io/managed-by: "ibp-operator"
      annotations:
        productName: "IBM Blockchain Platform"
        productID: "${PRODUCT_ID}"
        productVersion: "${IBP_VERSION}"
    spec:
      hostIPC: false
      hostNetwork: false
      hostPID: false
      serviceAccountName: ${SERVICE_ACCOUNT_NAME}
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: beta.kubernetes.io/arch
                operator: In
                values:
                - ${ARCH}
      imagePullSecrets:
        - name: ${DOCKER_SECRET}
      containers:
        - name: ibp-operator
          image: ${OPERATOR_IMAGE}:${IBP_VERSION}-${OPERATOR_DATE}-${ARCH}
          command:
          - ibp-operator
          imagePullPolicy: Always
          securityContext:
            privileged: false
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: false
            runAsNonRoot: false
            runAsUser: 1001
            capabilities:
              drop:
              - ALL
              add:
              - CHOWN
              - FOWNER
          livenessProbe:
            tcpSocket:
              port: 8383
            initialDelaySeconds: 10
            timeoutSeconds: 5
            failureThreshold: 5
          readinessProbe:
            tcpSocket:
              port: 8383
            initialDelaySeconds: 10
            timeoutSeconds: 5
            periodSeconds: 5
          env:
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: OPERATOR_NAME
              value: "ibp-operator"
            - name: ISOPENSHIFT
              value: "false"
          resources:
            requests:
              cpu: ${OPERATOR_CPU_REQUESTS}
              memory: ${OPERATOR_MEMORY_REQUESTS}
            limits:
              cpu: ${OPERATOR_CPU_LIMITS}
              memory: ${OPERATOR_MEMORY_LIMITS}
EOF

kubectl apply -f ${BASE_NAME}-operator-deploy.yaml

RC=$?

set +x

if [ $RC != 0 ]; then
    echo "Operator ${BASE_NAME} Deployment Failed"
    exit 1
fi

# Cleanup after applying
rm "${BASE_NAME}"-operator-deploy.yaml

set -x
cat << EOF > ${BASE_NAME}-console-deploy.yaml
apiVersion: ibp.com/v1alpha1
kind: IBPConsole
metadata:
  name: ibpconsole
spec:
  license: accept
  serviceAccountName: ${SERVICE_ACCOUNT_NAME}
  email: "${EMAIL}"
  password: "${INITIAL_PASSWORD}"
  image:
    imagePullSecret: ${DOCKER_SECRET}
    consoleInitImage: ${IBP_INIT_IMAGE} 
    consoleInitTag: ${IBP_VERSION}-${IBP_INIT_DATE}-${ARCH}
    consoleImage: ${CONSOLE_IMAGE}
    consoleTag: ${IBP_VERSION}-${CONSOLE_DATE}-${ARCH}
    configtxlatorImage: ${CONFIGTXLATOR_IMAGE}
    configtxlatorTag: ${HLF_VERSION}-${CONFIGTXLATOR_DATE}-${ARCH}
    couchdbImage: ${COUCH_IMAGE} 
    couchdbTag: ${COUCH_VERSION}-${COUCH_DATE}-${ARCH}
    deployerImage: ${DEPLOYER_IMAGE} 
    deployerTag: ${IBP_VERSION}-${DEPLOYER_DATE}-${ARCH}
  versions:
    ca:
      ${HLF_VERSION_LONG}:
        default: true
        version: ${HLF_VERSION_LONG}
        image:
          caInitImage: ${CA_INIT_IMAGE} 
          caInitTag: ${IBP_VERSION}-${CA_INIT_DATE}-${ARCH}
          caImage: ${CA_IMAGE}
          caTag: ${HLF_VERSION}-${CA_DATE}-${ARCH}
    peer:
      ${HLF_VERSION_LONG}:
        default: true
        version: ${HLF_VERSION_LONG}
        image:
          peerInitImage: ${IBP_INIT_IMAGE}
          peerInitTag: ${IBP_VERSION}-${IBP_INIT_DATE}-${ARCH}
          peerImage: ${PEER_IMAGE}
          peerTag: ${HLF_VERSION}-${PEER_DATE}-${ARCH}
          dindImage: ${DIND_IMAGE}
          dindTag: ${HLF_VERSION}-${DIND_DATE}-${ARCH}
          fluentdImage: ${FLUENTD_IMAGE}
          fluentdTag: ${IBP_VERSION}-${FLUENTD_DATE}-${ARCH}
          grpcwebImage: ${GRPC_IMAGE}
          grpcwebTag: ${IBP_VERSION}-${GRPC_DATE}-${ARCH}
          couchdbImage: ${COUCH_IMAGE}
          couchdbTag: ${COUCH_VERSION}-${COUCH_DATE}-${ARCH}
    orderer:
      ${HLF_VERSION_LONG}:
        default: true
        version: ${HLF_VERSION_LONG}
        image:
          ordererInitImage: ${IBP_INIT_IMAGE}
          ordererInitTag: ${IBP_VERSION}-${IBP_INIT_DATE}-${ARCH}
          ordererImage: ${ORDERER_IMAGE}
          ordererTag: ${HLF_VERSION}-${ORDERER_DATE}-${ARCH}
          grpcwebImage: ${GRPC_IMAGE}
          grpcwebTag: ${IBP_VERSION}-${GRPC_DATE}-${ARCH}
  networkinfo:
    domain: ${CONSOLE_HOSTNAME}
    consolePort: ${CONSOLE_PORT} 
    proxyPort: ${PROXY_PORT}
  storage:
    console:
      class: ${STORAGE_CLASS}
      size: 10Gi
  tlsSecretName: ${TLS_SECRET}
  resources:
    console:
      requests:
        cpu: ${CONSOLE_CPU_REQUESTS}
        memory: ${CONSOLE_MEMORY_REQUESTS}
      limits:
        cpu: ${CONSOLE_CPU_LIMITS}
        memory: ${CONSOLE_MEMORY_LIMITS}
    configtxlator:
      limits:
        cpu: ${CONFIGTXLATOR_CPU_LIMITS}
        memory: ${CONFIGTXLATOR_MEMORY_LIMITS}
      requests:
        cpu: ${CONFIGTXLATOR_CPU_REQUESTS}
        memory: ${CONFIGTXLATOR_MEMORY_REQUESTS}
    couchdb:
      limits:
        cpu: ${COUCHDB_CPU_LIMITS}
        memory: ${COUCHDB_MEMORY_LIMITS}
      requests:
        cpu: ${COUCHDB_CPU_REQUESTS}
        memory: ${COUCHDB_MEMORY_REQUESTS}
    deployer:
      limits:
        cpu: ${DEPLOYER_CPU_LIMITS}
        memory: ${DEPLOYER_MEMORY_LIMITS}
      requests:
        cpu: ${DEPLOYER_CPU_REQUESTS}
        memory: ${DEPLOYER_MEMORY_REQUESTS}
EOF

kubectl apply -f ${BASE_NAME}-console-deploy.yaml
rm ${BASE_NAME}-console-deploy.yaml

RC=$?

set +x

if [ $RC != 0 ]; then
    echo "Console ${BASE_NAME} Deployment Failed"
    exit 1
fi