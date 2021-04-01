# Generating Kubernetes Configuration Files for Authentication

## Kubernetes Public IP Address

Run this to get the public IP address of the Kubernetes API server:

```sh
KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g 'kthw' -n "kubernetes-the-hard-way" | jq -r .ipAddress);
```
