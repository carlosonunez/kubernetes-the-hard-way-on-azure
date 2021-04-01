# Bootstrapping the etcd cluster
---
## Prerequisites

The Ubuntu image SKU made available to Azure VMs from Canonical does not contain `wget`. You'll
need to install it first by SSHing into each controller and using `apt`:

```sh
$: for ip_address in $(az network public-ip list -g '{{ azure_resource_group }}' | \
     jq -r '.[] | select(.name |contains("kthw-control-plane")) | .ipAddress'); \
   do sudo apt -y install wget; \
   done
```
