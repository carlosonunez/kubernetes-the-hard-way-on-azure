# Provisioning Pod Network Routes

## The Routing Table

First, create a route table:

```sh
az network route-table create -g kubernetes -n kthw-route-table
```

## Routes

Next, add routes for each worker instance:

```sh
for idx in $(seq 0 2)
do
  az network route-table route create -g kubernetes \
    --name "kubernetes-route-10-200-${idx}-0-24" \
    --route-table-name kthw-route-table \
    --next-hop-type VirtualAppliance \
    --next-hop-ip-address "10.240.0.2${idx}" \
    --address-prefix "10.200.${idx}.0/24" 
done
```

Next, add default routes for inter-vNet traffic and egress traffic out to the Internet:

```sh
az network route-table route create -g kubernetes \
  --name default-route-internet \
  --route-table-name kthw-route-table \
  --next-hop-type Internet \
  --address-prefix "0.0.0.0/0" ;
az network route-table route create -g kubernetes \
  --name default-route-vnet \
  --route-table-name kthw-route-table \
  --next-hop-type VnetLocal \
  --address-prefix "10.240.0.0/16";
```

Lastly, confirm your work:

```sh
az network route-table route list -g kubernetes --route-table-name kthw-route-table -o json | \
  jq -r '.[] | .name + "{{ ':' }} " + .addressPrefix + " --> " + (if .nextHopIpAddress then .nextHopIpAddress else "" end) + " " + .nextHopType'
```

This should produce:

```sh
default-route-VNetLocal: 10.240.0.0/16 -->  VnetLocal
kubernetes-route-10-200-0-0-24: 10.200.0.0/24 --> 10.240.0.20 VirtualAppliance
kubernetes-route-10-200-1-0-24: 10.200.1.0/24 --> 10.240.0.21 VirtualAppliance
```

