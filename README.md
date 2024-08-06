# kind of

You heard of Kubernetes. But you want only a minimal distribution with no fuzz.

So you go out an search online and you find many solutions. You find minikube.
You find k3s. You find vcluster. You find kind.

And now you found _kindof_, yet another way of running Kubernetes, kind of.

## What?

_kindof_ is just a script and a Docker Compose file to run etcd, the kube
apiserver and the kube controller-manager. There is no kube scheduler, no
kube proxy, no DNS, no CNI, no CCM, no nodes.

## Why?

I needed to quickly and repeatedly setup a Kubernetes control plane _without
any nodes_. Even kind will always provision at least one control-plane node.

In this sense _kindof_ is similar to envtest, but I wanted to learn myself how
to bring up the Kubernetes control plane just using a Compose file :)

## How?

1. Clone the repository.
1. Have `envsubst`, certin and Docker installed.
1. Run the `bootstrap.sh` to generate the certificates and config files.
1. `docker-compose up` to bring everything up.

Finally, use the generated `etc/kubeconfig` file to communicate with the kube
apiserver.
