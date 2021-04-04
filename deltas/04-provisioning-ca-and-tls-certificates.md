# Provisioning a CA and Generating TLS Certificates

## The Kubelet Client Certificates

We can fetch each instance's private IP from their vNIC information and
their public IP from the Azure Public IP that was automatically created for them.

Use this command instead to do this.

```sh
for instance in worker-0 worker-1 worker-2
do
  EXTERNAL_IP=$(az network public-ip show -n "${instance}PublicIP" -g kubernetes --query 'ipAddress' -o tsv)
  INTERNAL_IP=$(az network nic show -g kubernetes -n "${instance}VMNic" -g kubernetes --query 'ipConfigurations.ipAddress' -o tsv)
  hostname=$(hostname); \
  cat >"${instance}-csr.json" <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem  \
    -config=ca-config.json \
    -hostname="$hostname,$EXTERNAL_IP,$INTERNAL_IP" \
    -profile=kubernetes \
    "${instance}-csr.json" | cfssljson -bare "${instance}"
done
```

## Distribute the Client and Server Certificates

Use these commands for the worker:

```sh
for idx in $(seq 0 2);
do
  ip=$(az network public-ip show -g kubernetes -n "worker-${idx}PublicIP" --query 'ipAddress' -o tsv)
  do
    for file in "ca.pem" "worker-$idx.pem" "worker-$idx-key.pem";
    do
      scp -i /secrets/kthw_ssh_key -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          "/secrets/$file" "ubuntu@$ip:/home/ubuntu/"
    done;
  done;
done
```

and use these commands for the controller:

```sh
for idx in $(seq 0 2);
do
  ip=$(az network public-ip show -g kubernetes -n "controller-{idx}PublicIP" --query 'ipAddress' -o tsv)
  do
    for file in "ca.pem" "controller-$idx.pem" "controller-$idx-key.pem";
    do
      scp -i /secrets/kthw_ssh_key -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          "/secrets/$file" "ubuntu@$ip:/home/ubuntu/"
    done;
  done;
done
```
