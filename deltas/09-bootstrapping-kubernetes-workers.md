# Bootstrap Kubernetes Workers
---

## Configure CNI Networking

Since we did not use a tag to store the CIDR for our `Pod`s, use this code block instead:

```sh
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "10.240.$(hostname -s | cut -f2 -d '-').0/24"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF
```

This should generate the following output for `worker-0`:

```json
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "10.240.0.0/24"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
```
