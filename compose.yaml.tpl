services:
  etcd:
    image: quay.io/coreos/etcd:v3.5.13
    hostname: etcd
    restart: unless-stopped
    entrypoint: /usr/local/bin/etcd
    command:
      - '--name=etcd'
      - '--initial-advertise-peer-urls=http://etcd:2380'
      - '--listen-peer-urls=http://0.0.0.0:2380'
      - '--listen-client-urls=http://0.0.0.0:2379'
      - '--advertise-client-urls=http://etcd:2379'
      - '--heartbeat-interval=250'
      - '--election-timeout=1250'
      - '--initial-cluster=etcd=http://etcd:2380'
      - '--initial-cluster-state=new'
      - '--initial-cluster-token=mys3cr3ttok3n'
    volumes:
      - ${ETCD_DATA_DIR}:/var/lib/etcd
    networks:
      - controlplane
    logging:
      driver: json-file
      options:
        max-size: "1m"
        max-file: "10"

  apiserver:
    image: registry.k8s.io/kube-apiserver:v1.30.3
    hostname: apiserver
    restart: unless-stopped
    command:
      - /usr/local/bin/kube-apiserver
      - --advertise-address=127.0.0.1
      - --secure-port=${KUBE_SECURE_PORT}
      - --etcd-servers=http://etcd:2380
      - --enable-admission-plugins=DefaultStorageClass,DefaultTolerationSeconds,LimitRanger,MutatingAdmissionWebhook,NamespaceLifecycle,NodeRestriction,Priority,ResourceQuota,ServiceAccount,ValidatingAdmissionWebhook
      - --admission-control-config-file=/kindof/etc/adm-control/admission-control.yaml
      - --authorization-mode=Node,RBAC
      - --external-hostname=localhost
      - --token-auth-file=/kindof/etc/tokens/tokens.csv
      - --enable-bootstrap-token-auth
      - --service-account-key-file=/kindof/pki/service-account/signer.key
      - --service-cluster-ip-range=10.240.16.0/20
      - --service-node-port-range=30000-32767
      - --allow-privileged
      - --tls-cert-file=/kindof/pki/apiserver/serving.crt
      - --tls-private-key-file=/kindof/pki/apiserver/serving.key
      - --proxy-client-cert-file=/kindof/pki/kubernetes/front-proxy/client/apiserver.crt
      - --proxy-client-key-file=/kindof/pki/kubernetes/front-proxy/client/apiserver.key
      - --client-ca-file=/kindof/pki/kubernetes/client/ca.crt
      - --kubelet-client-certificate=/kindof/pki/kubernetes/client/kubelet.crt
      - --kubelet-client-key=/kindof/pki/kubernetes/client/kubelet.key
      - --kubelet-certificate-authority=/kindof/pki/kubernetes/client/ca.crt
      - --requestheader-client-ca-file=/kindof/pki/kubernetes/front-proxy/ca.crt
      - --requestheader-allowed-names=apiserver-aggregator
      - --requestheader-extra-headers-prefix=X-Remote-Extra-
      - --requestheader-group-headers=X-Remote-Group
      - --requestheader-username-headers=X-Remote-User
      - --endpoint-reconciler-type=none
      - --profiling=false
      - --service-account-issuer=https://localhost:${KUBE_SECURE_PORT}
      - --service-account-signing-key-file=/kindof/pki/service-account/signer.key
      - --api-audiences=https://localhost:${KUBE_SECURE_PORT}
      - --kubelet-preferred-address-types=InternalIP,ExternalIP
    volumes:
      - "${KINDOF_PKI_DIR}:/kindof/pki:ro"
      - "${KINDOF_ETC_DIR}:/kindof/etc"
    ports:
      - ${KUBE_SECURE_PORT}:${KUBE_SECURE_PORT}
    networks:
      - controlplane
    logging:
      driver: json-file
      options:
        max-size: "1m"
        max-file: "10"

  controller-manager:
    image: registry.k8s.io/kube-controller-manager:v1.30.3
    hostname: controller-manager
    restart: unless-stopped
    command:
      - /usr/local/bin/kube-controller-manager
      - --kubeconfig=/kindof/etc/kube-controller-manager/kubeconfig
      - --service-account-private-key-file=/kindof/pki/service-account/signer.key
      - --root-ca-file=/kindof/pki/kubernetes/root-ca.crt
      - --cluster-signing-cert-file=/kindof/pki/kubernetes/root-ca.crt
      - --cluster-signing-key-file=/kindof/pki/kubernetes/root-ca.key
      - --controllers=*,bootstrapsigner,tokencleaner
      - --use-service-account-credentials
      - --profiling=false
      - --allocate-node-cidrs
      - --cluster-cidr=172.25.0.0/16
      - --service-cluster-ip-range=10.240.16.0/20
      - --node-cidr-mask-size=24
      - --configure-cloud-routes=false
      - --feature-gates=RotateKubeletServerCertificate=true
      - --authentication-kubeconfig=/kindof/etc/kube-controller-manager/kubeconfig
      - --client-ca-file=/kindof/pki/kubernetes/client/ca.crt
      - --authentication-kubeconfig=/kindof/etc/kube-controller-manager/kubeconfig
      - --authorization-kubeconfig=/kindof/etc/kube-controller-manager/kubeconfig
    volumes:
      - "${KINDOF_PKI_DIR}:/kindof/pki:ro"
      - "${KINDOF_ETC_DIR}:/kindof/etc"
    networks:
      - controlplane
    logging:
      driver: json-file
      options:
        max-size: "1m"
        max-file: "10"

networks:
  controlplane: ~
