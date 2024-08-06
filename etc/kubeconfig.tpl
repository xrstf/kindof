apiVersion: v1
clusters:
  - cluster:
      certificate-authority-data: "${KUBE_ROOT_CA}"
      server: "https://127.0.0.1:${KUBE_SECURE_PORT}"
    name: kindof
contexts:
  - context:
      cluster: kindof
      user: kindof
    name: kindof
current-context: kindof
kind: Config
preferences: {}
users:
  - name: kindof
    user:
      token: "${KUBE_ADMIN_TOKEN}"
