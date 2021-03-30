# Provisioning a CA and Generating TLS Certificates

## The Kubelet Client Certificates

We can fetch each instance's private IP from their vNIC information and
their public IP from the Azure Public IP that was automatically created for them.

Use this command instead to do this.

```sh
for instance in kthw-worker-1 kthw-worker-2 kthw-worker-3
do
  internal_ip=$(\
    az network nic show -n "${instance}VMNic" -g '{{ azure_resource_group }}' | \
    jq -r .ipConfigurations.privateIpAddress); \
  external_ip=$(\
    az network nic show -n "${instance}PublicIP" -g '{{ azure_resource_group }}' | \
    jq -r .ipAddress); \
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
    -hostname="$hostname,$external_ip,$internal_ip" \
    -profile=kubernetes \
    "${instance}-csr.json" | cfssljson -bare "${instance}"
done
```

## Distribute the Client and Server Certificates

Use these commands for the worker:

```sh
for idx in $(seq 1 3);
do
  for ip in $(az network public-ip list | \
    jq -r '.[] | select(.name | contains("kthw-worker-$idx")) | .ipAddress' \
    | grep -v "null");
  do
    for file in "ca.pem" "kthw-worker-$idx.pem" "kthw-worker-$idx-key.pem";
    do
      scp -i /secrets/kthw_ssh_key -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          "/secrets/$file" "ubuntu@$ip:/home/ubuntu/" && touch "$cache_key";
    done;
  done;
done
```

and use these commands for the controller:

```sh
for idx in $(seq 1 3);
do
  for ip in $(az network public-ip list | \
    jq -r '.[] | select(.name | contains("kthw-control-plane-$idx")) | .ipAddress' \
    | grep -v "null");
  do
    for file in "ca.pem" "ca-key.pem" "kubernetes.pem" "kubernetes-key.pem" \
      "service-account.pem" "service-account-key.pem"
    do
      scp -i /secrets/kthw_ssh_key -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          "/secrets/$file" "ubuntu@$ip:/home/ubuntu/" && touch "$cache_key";
    done;
  done;
done
```

