# Smoke Tests
---

## Services

Add this NSG rule to reach the node port:

```sh
node_port=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}');
az network nsg rule create -g 'kubernetes' \
  --nsg-name kthw-nsg \
  --name "allow_into_node_port" \
  --priority 130 \
  --access Allow \
  --source-address-prefixes "*" \
  --protocol tcp \
  --destination-address-prefixes "*" \
  --destination-port-ranges "$node_port"
```

And run this command to confirm connectivity:

```sh
ip=$(az network public-ip show -g kubernetes -n 'worker-0PublicIP' --query 'ipAddress' -o tsv);
node_port=$(kubectl get svc nginx --output=jsonpath='{range .spec.ports[0]}{.nodePort}');
curl --head "http://${ip}:${node_port}"
```

> output

```
HTTP/1.1 200 OK
Server: nginx/1.19.9
Date: Tue, 06 Apr 2021 01:38:15 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 30 Mar 2021 14:47:11 GMT
Connection: keep-alive
ETag: "606339ef-264"
Accept-Ranges: bytes
```
