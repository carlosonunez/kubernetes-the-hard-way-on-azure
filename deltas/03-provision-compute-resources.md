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
  name="$(echo "$rule" | awk '{ print $1 }')"; 
  priority="$(echo "$rule" | awk '{ print $2 }')"; 
  permission="$(echo "$rule" | awk '{ print $3 }')"; 
  protocol="$(echo "$rule" | awk '{ print $4 }')"; 
  if echo "$protocol" | grep -q ':'; 
  then 
    protocol=$(echo "$protocol" | cut -f1 -d ':');
    port=$(echo "$protocol" | cut -f2 -d ':'); 
  else port="*"; 
  fi; 
  from="$(echo "$rule" | awk '{ print $6 }')"; 
  to="$(echo "$rule" | awk '{ print $8 }')"; 
  az network nsg rule create -g kthw --nsg-name kthw-nsg
    --name $name 
    --priority $priority
    --access $permission
    --source-address-prefixes $from
    --source-port-ranges $port
    --destination-address-prefixes $to
done
```

## Compute Instances
---

We will use `Standard_D2s_v4` instances, as they are similar to `e2-standard-2` instances
in Google Cloud. We will also provision them from the
[Spot Market](https://docs.microsoft.com/en-us/azure/virtual-machines/spot-vms)
to reduce the amount of money you spend (or credits you burn) on this lab.

⚠️  **NOTE**: Deploying spot control plane nodes this way is not recommended for production use. ⚠️

First, let's create a keypair to log into our instances with:

```sh
ssh-keygen -t rsa -b 2048 -f kthw_ssh_key
```

Enter an optional passphrase when prompted.

Next, let's run `az vm create` to provision our control plane instances:

```sh
for i in $(seq 1 3)
do
  az vm create -g kthw \
    --name "kthw-control-plane-$i" \
    --computer-name "kthw-control-plane-$i" \
    --image "Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:20.04.202103230" \
    --priority "Spot" \
    --max-price "0.04" \
    --eviction-policy "Deallocate" \
    --size "Standard_D2s_v4" \
    --private-ip-address "10.240.0.1$i" \
    --subnet kthw-subnet \
    --vnet-name kthw \
    --os-disk-name "kthw-cp-disk-$i" \
    --os-disk-size-gb 200 \
    --admin-username ubuntu \
    --ssh-key-values kthw_ssh_key.pub
done
```

Then we'll do the same for our worker nodes:

```sh
for i in $(seq 1 3)
do
  az vm create -g kthw \
    --name "kthw-worker-$i" \
    --computer-name "kthw-control-plane-$i" \
    --image "Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:20.04.202103230" \
    --priority "Spot" \
    --max-price "0.04" \
    --eviction-policy "Deallocate" \
    --size "Standard_D2s_v4" \
    --private-ip-address "10.240.0.1$i" \
    --subnet kthw-subnet \
    --vnet-name kthw \
    --os-disk-name "kthw-cp-disk-$i" \
    --os-disk-size-gb 200 \
    --admin-username ubuntu \
    --ssh-key-values kthw_ssh_key.pub
done
```

Next, we will enable IP forwarding on all of the vNICs attached to all nodes in our cluster:

```sh
for node in control-plane worker
do
  for i in $(seq 1 3)
  do
    az network nic update -g kthw \
      --name "kthw-$node-$i" \
      --ip-forwarding true
  done
done
```

Then we will wrap up this lab by confirming that all nodes in our cluster can be SSHed into:

```sh
$ for ip in $(az network public-ip list -g kthw | jq -r .[].ipAddress | grep -v "null"); \
  do \
    ssh -i kthw_ssh_key -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "ubuntu@$ip" \
        echo '$(hostname): $(whoami)' 2>/dev/null; \
  done | grep "ubuntu"
kthw-control-plane-1: ubuntu
kthw-control-plane-2: ubuntu
kthw-control-plane-3: ubuntu
kthw-worker-1: ubuntu
kthw-worker-2: ubuntu
kthw-worker-3: ubuntu
```
