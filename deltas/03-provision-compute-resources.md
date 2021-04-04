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
az network vnet create -g kubernetes -n kthw --address-prefix 10.128.0.0/9 \
  --subnet-name kthw-subnet --subnet-address-prefix 10.240.0.0/24
```

Verify that the network has been created afterwards:

```sh
az network vnet list -g kubernetes --query '[].{Name: name, Subnets: (subnets[].{Name: name, Prefix: addressPrefix})}'
```

This should produce:

```
[
  {
    "Name": "kthw",
    "Subnets": [
      {
        "Name": "kthw-subnet",
        "Prefix": "10.240.0.0/24"
      }
    ]
  }
]
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
az network nsg create -g kubernetes -n kthw-nsg
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
  az network nsg rule create -g kubernetes --nsg-name kthw-nsg
    --name $name 
    --priority $priority
    --access $permission
    --source-address-prefixes $from
    --source-port-ranges "*"
    --destination-address-prefixes $to
    --destination-port-ranges $port
done
```

## Kubernetes Public IP Address

To allocate the static IP that we will use to front the Kubernetes API server with,
run this command:

```sh
az network public-ip create -g 'kthw' \
  --name "kubernetes-the-hard-way" \
  --allocation-method "Static" \
  --sku "Standard"
```

We need to use a `Standard` SKU so that the health check probes that we will
add when we [bootstrap Kubernetes](./deltas/08-bootstrapping-kubernetes) can be created.

## Compute Instances
---

We will use `Standard_D2s_v4` instances, as they are similar to `e2-standard-2` instances
in Google Cloud. We will also provision them from the
[Spot Market](https://docs.microsoft.com/en-us/azure/virtual-machines/spot-vms)
to reduce the amount of money you spend (or credits you burn) on this lab. Lastly,
we will use Ubuntu 20.04 to match the version of Ubuntu used by the original "Kubernetes
the Hard Way" guide.

⚠️  **NOTE**: Deploying spot control plane nodes this way is not recommended for
production use. ⚠️

First, let's create a keypair to log into our instances with:

```sh
ssh-keygen -t rsa -b 2048 -f kthw_ssh_key
```

Next, let's run `az vm create` to provision our control plane instances:

```sh
for i in $(seq 0 2)
do
  az vm create -g kubernetes \
    --admin-username "ubuntu" \
    --computer-name "controller-$i" \
    --image "Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:20.04.202103230" \
    --max-price "0.04" \
    --name "controller-$i" \
    --nsg-rule "NONE" \
    --os-disk-name "kthw-cp-disk-$i" \
    --os-disk-size-gb "200" \
    --priority "Spot" \
    --private-ip-address "10.240.0.1$i" \
    --public-ip-address-allocation static \
    --public-ip-sku Standard \
    --size "Standard_D2s_v4" \
    --ssh-key-values kthw_ssh_key.pub
    --subnet kthw-subnet \
    --vnet-name kthw \
done
```

Then we'll do the same for our worker nodes:

```sh
for i in $(seq 0 2)
do
  az vm create -g kubernetes \
    --admin-username "ubuntu" \
    --computer-name "worker-$i" \
    --image "Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:20.04.202103230" \
    --max-price "0.04" \
    --name "worker-$i" \
    --nsg-rule "NONE" \
    --os-disk-name "kthw-cp-disk-$i" \
    --os-disk-size-gb "200" \
    --priority "Spot" \
    --private-ip-address "10.240.0.1$i" \
    --public-ip-address-allocation static \
    --public-ip-sku Standard \
    --size "Standard_D2s_v4" \
    --ssh-key-values kthw_ssh_key.pub
    --subnet kthw-subnet \
    --vnet-name kthw \
done
```

Next, we will enable IP forwarding on all of the vNICs attached to all nodes in our cluster
and associate the NIC with the NSG that we created earlier:

```sh
for node in controller worker
do
  for i in $(seq 0 2)
  do
    az network nic update -g kubernetes \
      --name "controller-${i}VMNic" \
      --ip-forwarding true \
      --network-security-group kthw-nsg
  done
done
```

Next, we will create a public IP to front the controllers with through an Azure Load
Balancer:

```sh
az network public-ip create -g kubernetes \
  --name "kubernetes-the-hard-way" \
  --sku Standard \
  --allocation-method Static
```

Then we will wrap up this lab by confirming that all nodes in our cluster can be SSHed into:

```sh
EXTERNAL_IPS=$(az network public-ip list -g kubernetes --query '[].ipAddress' -o tsv)
for ip in $EXTERNAL_IPS
do
  ssh -i kthw_ssh_key "ubuntu$ip" 'echo: "$(hostname): $(whoami)"'
done
```

This should produce the below:

```
controller-0: ubuntu
controller-1: ubuntu
controller-2: ubuntu
worker-0: ubuntu
worker-1: ubuntu
worker-2: ubuntu
```
