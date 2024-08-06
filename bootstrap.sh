#!/usr/bin/env bash

set -euo pipefail

function render_template() {
  local filename="${1%%.tpl}"

  echo "Rendering $1..."
  envsubst < "$1" > "$filename"
}

TOKENS_FILE=etc/tokens/tokens.csv
if [ ! -f "$TOKENS_FILE" ]; then
  echo "Creating $TOKENS_FILE..."
  render_template "$TOKENS_FILE.tpl"
fi

function mkcert() {
  local dir="$(dirname $1)"
  local certName="$(basename $1)"

  shift

  mkdir -p "$dir"

  if [ ! -f "$dir/$certName.crt" ]; then
    (set -x; certin create "$dir/$certName.key" "$dir/$certName.crt" $@)
  else
    echo "$dir/$certName.crt exists already."
  fi
}

function mksigned() {
  local cert="$1"
  local signer="$2"

  shift
  shift

  mkcert "$cert" --signer-key "$signer.key" --signer-cert "$signer.crt" $@
}

PKI_DIR=pki

(
  mkdir -p "$PKI_DIR"
  cd "$PKI_DIR"

  # Kubernetes Root CA
  mkcert kubernetes/root-ca --cn kubernetes --is-ca

  # create service account signer keypair
  mksigned service-account/signer kubernetes/root-ca --cn service-account-signer

  # TLS serving cert for the kube apiserver
  mksigned apiserver/serving kubernetes/root-ca --cn apiserver --sans "apiserver,localhost,127.0.0.1"

  # TLS serving cert for the machine-controller webhook (for convenience this is signed by Kubernetes' root CA)
  mksigned machine-controller/serving kubernetes/root-ca --cn machine-controller-webhook --sans "machine-controller-webhook,localhost,127.0.0.1"
  chmod 644 machine-controller/*

  # TLS serving cert for the operating-system-manager webhook (for convenience this is signed by Kubernetes' root CA)
  mksigned operating-system-manager/tls kubernetes/root-ca --cn operating-system-manager-webhook --sans "operating-system-manager-webhook,localhost,127.0.0.1"
  chmod 644 operating-system-manager/*

  # CA for client certs in Kubernetes
  mksigned kubernetes/client/ca kubernetes/root-ca --cn kubernetes-client-ca --is-ca

  # kubelet client cert
  mksigned kubernetes/client/kubelet kubernetes/client/ca --cn kubelet-client

  # CA for the front proxy
  mksigned kubernetes/front-proxy/ca kubernetes/root-ca --cn kubernetes-front-proxy-ca --is-ca

  # front proxy client cert for the kube apiserver
  mksigned kubernetes/front-proxy/client/apiserver kubernetes/root-ca --cn apiserver
)

# render kubeconfig and other config file templates

export KUBE_ROOT_CA="$(base64 -w0 "$PKI_DIR/kubernetes/root-ca.crt")"
export KUBE_ADMIN_TOKEN="$(grep admin "$TOKENS_FILE" | cut -d, -f1)"
export KUBE_SECURE_PORT=${KUBE_SECURE_PORT:-32479}

export ETCD_DATA_DIR="${ETCD_DATA_DIR:-./data/etcd}"
export KINDOF_PKI_DIR="$(realpath "$PKI_DIR")"
export KINDOF_ETC_DIR="$(realpath etc)"

render_template compose.yaml.tpl

find etc -name '*.tpl' -print0 | while read -d $'\0' file; do
  render_template "$file"
done

# for convenience, allow to provide templates in kube/
# and we render them here

if [ -d kube ]; then
  find kube -name '*.tpl' -print0 | while read -d $'\0' file; do
    render_template "$file"
  done
fi
