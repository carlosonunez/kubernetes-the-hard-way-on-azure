# Bootstrapping the Kubernetes Control Plane
---

Run this to get the public IP address of the Kubernetes API server:

```sh
KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g 'kthw' -n "kubernetes-the-hard-way" --query 'ipAddress' -o tsv;
```

## Enable HTTP Health Checks

An [Azure Load Balancer](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-overview)
will be used to distribute traffic across the three API servers. Unlike
Google Network Load Balancers, HTTP headers cannot be set on Azure Load Balancer
health check probes. Consequently, while we will create `/healthz` as instructed
by the lab, we will use the NGINX test page at `/` to tell our load balancer
that our controllers are healthy.

## The Kubernetes Frontend Load Balancer

⚠️  **NOTE**: Ensure that you are running these commands on your local machine
and _not_ from within a controller. ⚠️

### Provision an Azure Load Balancer

First, create a load balancer with a `Standard` SKU:

```sh
az network lb create -g kubernetes -n kubernetes --sku Standard
```

Next, associate the public IP for our controllers with our new load balancers:

```sh
az network lb frontend-ip create -g kubernetes \
  --lb-name kubernetes \
  -n kubernetes-frontend-ip \
  --public-ip-address kubernetes-the-hard-way
```

Next, add the health check probe:

```sh
az network lb probe create -g kubernetes \
  --lb-name kubernetes \
  -n kubernetes \
  --protocol http \
  --port 80 \
  --path /
```

Next, we will add a rule to the NSG that we created when we
[provisioned our compute resources](./deltas/02-provision-compute-resources) to
allow the controllers to be probed from Azure. Azure has allocated a special IP
address for health check probes and other health checks: `168.63.129.16`.
We will configure our rule to allow controllers and workers to receive traffic
on port 80 from this address.

This IP address is the same regardless of region or type of cloud (i.e. GovCloud, China, etc.).

Learn more about this special IP address [here](https://docs.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16).

```sh
az network nsg rule create -g kubernetes \
  -n allow-msft-prober-into-controllers \
  --priority 110 \
  --access allow \
  --source-address-prefixes "168.63.129.16/32" \
  --source-port-ranges "*" \
  --protocol tcp \
  --destination-address-prefixes "10.240.0.0/24" \
  --destination-port-ranges "80"
```

Next, create the backend pool into which our controllers will be added:

```sh
az network lb address-pool create -g kubernetes \
  -n kubernetes-target-pool \
  --lb-name kubernetes \
  --vnet kthw \
  --backend-address name=controller-0 ip-address=10.240.0.10 \
  --backend-address name=controller-1 ip-address=10.240.0.11 \
  --backend-address name=controller-2 ip-address=10.240.0.12
```

Finally, create a forwarding rule to allow all traffic to the Kubernetes
API server port  from the Internet to be sent to our controllers in the target pool:

```sh
az network lb rule create -g kubernetes \
  --lb kubernetes \
  -n kubernetes-forwarding-rule \
  --protocol Tcp \
  --frontend-ip kubernetes-frontend-ip \
  --frontend-port 6443 \
  --backend-pool-name kubernetes-target-pool \
  --backend-port 6443
```

Verify that the controllers are reachable from your machine with `curl`:

```sh
KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g 'kthw' -n "kubernetes-the-hard-way" --query 'ipAddress' -o tsv;
curl --cacert ca.pem https://$KUBERNETES_PUBLIC_ADDRESS:6443/version
```

You should see the output below:

```
{
  "major": "1",
  "minor": "18",
  "gitVersion": "v1.18.6",
  "gitCommit": "dff82dc0de47299ab66c83c626e08b245ab19037",
  "gitTreeState": "clean",
  "buildDate": "2020-07-15T16:51:04Z",
  "goVersion": "go1.13.9",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```
