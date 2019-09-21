cat << EOF > ${NAME}-tls-cert.yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: ${NAMESPACE}-${TLS_SECRET}
  namespace: ${NAMESPACE}
spec:
  # name of the tls secret to store
  # the generated certificate/key pair
  secretName: ${TLS_SECRET}
  issuerRef:
    # ClusterIssuer Name
    name: icp-ca-issuer
    # Issuer can be referenced
    # by changing the kind here.
    # the default value is Issuer (i.e.
    # a locally namespaced Issuer)
    kind: ClusterIssuer
  commonName: wsc-ibp-icp-cluster.icp
  dnsNames:
   # one or more fully-qualified domain names
   # can be defined here
 # - wsc-ibp-icp-cluster.icp
EOF

kubectl apply -f ${NAME}-tls-cert.yaml