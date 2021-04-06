# Troubleshooting
---

## Help! DNS isn't working in my containers, and my containers can't talk to the Internet.
---

### Confirm that `Pod`s from one node can reach `Pod`s in another node.

Create two pods:

```sh
for i in 0 1
do
  kubectl run test$i \
    --image=alpine \
    --overrides="{\"apiVersion\":\"v1\",\"spec\":{\"nodeSelector\":{\"kubernetes.io/hostname\": \"worker-$i\"}}}" \
    --command -- sleep 9000000000000
done
```

Confirm that the pods have been scheduled and are running in their respective nodes:

```sh
kubectl get pods -o wide
```

> output

```
NAME    READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
test0   1/1     Running   0          5s    10.200.0.34   worker-0   <none>           <none>
test1   1/1     Running   0          4s    10.200.1.25   worker-1   <none>           <none>
```

Use `kubectl exec` on each pod to confirm that it can reach the other pod:

```sh
kubectl exec test0 -- ping -c 3 10.200.1.25
```

Your output should be something like:

```
PING 10.200.1.25 (10.200.1.25): 56 data bytes
64 bytes from 10.200.1.25: seq=0 ttl=62 time=4.527 ms
64 bytes from 10.200.1.25: seq=1 ttl=62 time=0.927 ms
64 bytes from 10.200.1.25: seq=2 ttl=62 time=0.995 ms

--- 10.200.1.25 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.927/2.149/4.527 ms
```

#### If this is failing...

- [Confirm that you've created your route-table routes correctly](./deltas/11-pod-network-routes.md)
- [Confirm that you've configured the pod CIDR for your CNI correctly](./deltas/09-bootstrapping-kubernetes-workers.md)
- [Confirm that your network security group rules are configured correctly](./deltas/03-provision-compute.md)

### Patch CoreDNS to explicitly forward requests to /etc/resolv.conf

After deploying CoreDNS by following the instructions in the lab, try modifying the `ConfigMap`
that `coredns-1.7.yaml` uses to forward all DNS requests
to the kubelet's default nameservers.

First, open the configmap in `vi`:

```sh
kubectl edit configmap -n kube-system coredns
```

Add the line below above `prometheus :9153`:

```
forward . /etc/resolv.conf
```

then quit. Output:

```
configmap/coredns updated
```

Confirm that DNS is operational per the lab.

#### If this is failing...

- SSH into your workers and confirm that DNS queries work there.
- Confirm that `/run/systemd/resolve/resolv.conf` looks something like this:

```
# This file is managed by man:systemd-resolved(8). Do not edit.
#
# This is a dynamic resolv.conf file for connecting local clients directly to
# all known uplink DNS servers. This file lists all configured search domains.
#
# Third party programs must not access this file directly, but only through the
# symlink at /etc/resolv.conf. To manage man:resolv.conf(5) in a different way,
# replace this symlink by a static file or a different symlink.
#
# See man:systemd-resolved.service(8) for details about the supported modes of
# operation for /etc/resolv.conf.

nameserver 168.63.129.16

# The search domain will differ on your host. It might also be reddog.microsoft.com
# depending on your region.
search rf3ptkbhcxauhhna03kumx0p3d.gx.internal.cloudapp.net
```
