# Generating Kubernetes Configuration Files for Authentication

## Kubernetes Public IP Address

Run this to get the public IP address of the Kubernetes API server:

```sh
KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g 'kthw' -n "kubernetes-the-hard-way" --query 'ipAddress' -o tsv;
```

## Distribute the Kubernetes Configuration Files

Use these commands for the worker:

```sh
for idx in $(seq 0 2);
do
  ip=$(az network public-ip show -g kubernetes -n "worker-${idx}PublicIP" --query 'ipAddress' -o tsv)
  do
    for file in "kube-proxy.kubeconfig" "worker-$idx.kubeconfig";
    do
      scp -i kthw_ssh_key -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          "$file" "ubuntu@$ip:/home/ubuntu/"
    done
  done
done
```

and use these commands for the controller:

```sh
for idx in $(seq 1 3);
do
  ip=$(az network public-ip show -g kubernetes -n "controller-${idx}PublicIP" --query 'ipAddress' -o tsv)
  do
    for file in admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig; \
    do
      scp -i kthw_ssh_key -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          "$file" "ubuntu@$ip:/home/ubuntu/"
    done;
  done;
done
```
