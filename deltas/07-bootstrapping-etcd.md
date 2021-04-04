# Bootstrapping the etcd cluster
---
## Prerequisites

The Ubuntu image SKU made available to Azure VMs from Canonical does not contain `wget`.
You'll need to install it first by SSHing into each controller and using `apt`:

```sh
for idx in $(seq 0 2)
do
  ip=$(az network public-ip show -g kubernetes -n "controller-${idx}PublicIP" --query 'ipAddress' -o tsv)
  ssh -i kthw_ssh_key ubuntu@$ip 'sudo apt -y install wget'
done
```

⚠️  **NOTE**: The commands below must be run from each controller. ⚠️

# Bootstrapping an etcd Cluster Member
---

## Configure the etcd server

To get the host's internal IP address via [Azure IMDS](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/instance-metadata-service?tabs=windows),
you will first need to install `jq`, as IMDS provides this information as a JSON blob.

Run this to do that:

```sh
$: sudo apt -y install jq
```

Then run this to get the instance's IP address:

```sh
INTERNAL_IP=$(curl -H "Metadata: true" http://169.254.169.254/metadata/instance?api-version=2021-01-01 | \
  jq -r '.network.interface[0].ipv4.ipAddress[0].privateIpAddress')
```
