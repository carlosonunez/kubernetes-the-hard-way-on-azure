# Provisioning Compute Resources
---

## Networking
---

Google Cloud handles networking a little differently from Azure. Azure expects users to be
much more declarative in how their networking resources are created. This section will outline
how to create the flat Kubernetes network as instructed by Hard Way.

### Virtual Private Cloud Network

The [vNet](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) is
used to provide logical segmentation of compte resources in an Azure subscription. We will,
first, need to create a vNet into which our Kubernetes nodes will be provisioned. A subnet
for these nodes will need to be created thereafter.

Create the vNet and subnet in one shot with this command:

```sh
az network vnet create -g kthw -n kthw --address-prefix 10.128.0.0/9 \
  --subnet-name kthw-subnet --subnet-address-prefix 10.240.0.0/24
```

Verify that the network has been created afterwards:

```sh
az network vnet list -g kthw | \
  jq '.[] | \
select(.name == "kthw") | \
{\
  name: .name, \
  subnets: [ { name: .subnets[0].name, prefix: .subnets[0].addressPrefix \
}]}'
```

This should produce:

```
{
  "name": "kthw",
  "subnets": [
    {
      "name": "kthw-subnet",
      "prefix": "10.240.0.0/24"
    }
  ]
}
```

### Firewall Rules

Azure uses [Network Security Groups](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
to permission traffic within and out of vNets. We will use them to permission traffic between
compute in `kthw-subnet` and IPs with the CIDR that Kubernetes will use for containers running
in its cluster (`10.200.0.0/16`), or the "Service CIDR."
We need to do this because Kubernetes assumes a flat network by default, and because IPs within
the Service CIDR aren't actually a part of the vNet, packets originating from these IPs
will be dropped.

First, create the NSG object...

```sh
az network nsg create -g kthw -n kthw-nsg
```

...then provision the rules as described by Hard Way:

```sh
for rule in "prio 1 allow tcp from 10.200.0.0/16 to 10.240.0.0/24"
  "prio 2 allow tcp from 10.240.0.0/24 to 10.240.0.0/16"
  "prio 3 allow udp from 10.200.0.0/16 to 10.240.0.0/24"
  "prio 4 allow udp from 10.240.0.0/24 to 10.240.0.0/16"
  "prio 5 allow icmp from 10.200.0.0/16 to 10.240.0.0/24"
  "prio 6 allow icmp from 10.240.0.0/24 to 10.240.0.0/16"
  "prio 7 allow tcp:22 from 0.0.0.0/0 to 10.240.0.0/24"
  "prio 8 allow tcp:6443 from 0.0.0.0/0 to 10.240.0.0/24"
  "prio 9 allow icmp from 0.0.0.0/0 to 10.240.0.0/24";
do
  name="$(echo "$rule" | awk '{ print $1 }')"; \
  priority="$(echo "$rule" | awk '{ print $2 }')"; \
  permission="$(echo "$rule" | awk '{ print $3 }')"; \
  protocol="$(echo "$rule" | awk '{ print $4 }' | cut -f1 -d ':')"; \
  if echo "$protocol" | grep -q ':'; \
  then \
    port=$(echo "$protocol" | cut -f2 -d ':'); \
  else port="*"; \
  fi; \
  from="$(echo "$rule" | awk '{ print $6 }')"; \
  to="$(echo "$rule" | awk '{ print $8 }')"; \
  az network nsg rule create -g kthw --nsg-name kthw-nsg
    --name $name 
    --priority $priority
    --access $permission
    --source-address-prefixes $from
    --source-port-ranges $port
    --destination-address-prefixes $to
done
```
