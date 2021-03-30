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
