# Generating the Data Encryption Config and Key

## The Encryption Config File

Use this command to send `encryption-config.yaml` to your controllers:

```sh
for idx in $(seq 0 2);
do
  ip=$(az network public-ip show -g kubernetes -n "controller-${idx}PublicIP" --query 'ipAddress' -o tsv)
  scp -i kthw_ssh_key -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      "encryption-config.yaml" "ubuntu@$ip:/home/ubuntu/"
done
```
