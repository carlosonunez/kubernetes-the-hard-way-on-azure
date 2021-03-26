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

### Deltas

There will be several differences between these labs and the ones from KTHW. Browse over
to the [`deltas`](./deltas) folder to view them. If a delta does not exist for a KTHW lab,
then assume that the same steps from the original lab apply.
