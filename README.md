# Kubernetes the Hard Way
## Azure Edition

Deploy Kubernetes from scratch on Azure based on
[Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way).

## How to Use

### Prereqs

- Docker
- An Azure account

### Instructions

`make env` to create a new environment dotfile. Follow the instructions.

`make test` to run integration tests on each step.

`make deploy` to deploy the thing.

`make clean` to destroy all traces of your lab.

## Having Trouble?

Check out [the troubleshooting guide](./99-troubleshooting.md).

## Here Be Dragons!

This codebase roughly describes the effort required to spin up Kubernetes from scratch on Azure
through automation. It is **not** meant for production use.

If you'd like to deploy Kubernetes "bare-metal" style, check out [Cluster API](https://cluster-api.sigs.k8s.io/)
or any of the various Kubernetes "flavors", such as [kops](https://kops.sigs.k8s.io/getting_started/azure/)
or [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/).

If you'd like to run Kubernetes on your local machine, try [k3s](https://k3s.io) or
[kind](https://kind.sigs.k8s.io/).

If you just want to use Kubernetes and not deal with any of this stuff, try a managed
Kubernetes offering, like [Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/)
or [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine).

## Deltas

The lab documentation from the [original codebase](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/)
have not been copied over here. You should have them open in a separate browser along with this
reference. To see Azure-specific differences, check out the "deltas" [here](./deltas).

- [Prerequisites](./deltas/01-prerequisites.md)
- [Provisioning Compute Resources](./deltas/03-provision-compute-resources.md)
- [Provisioning a CA and Generating TLS Certificates](./deltas/04-provisioning-ca-and-tls-certificates.md)
- [Generating Kubernetes Configuration Files for Authentication](./deltas/05-kubernetes-configuration-files.md)
- [Generating the Data Encryption Config and Key](./deltas/06-data-encryption-keys.md)
- [Bootstrapping the etcd cluster](./deltas/07-bootstrapping-etcd.md)
- [Bootstrapping the Kubernetes Control Plane](./deltas/08-bootstrapping-kubernetes.md)
- [Bootstrap Kubernetes Workers](./deltas/09-bootstrapping-kubernetes-workers.md)
- [Provisioning Pod Network Routes](./deltas/11-pod-network-routes.md)
- [Smoke Test](./deltas/13-smoke-test.md)
- [Cleaning Up](./deltas/14-cleanup.md)
