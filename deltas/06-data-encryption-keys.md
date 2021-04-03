# Generating the Data Encryption Config and Key

## The Encryption Config File

Use this command to send `encryption-config.yaml` to your controllers:

```sh
for idx in $(seq 1 3);
do
  for ip in $(az network public-ip list | \
    jq -r '.[] | select(.name | contains("controller-$idx")) | .ipAddress' \
    | grep -v "null");
  do
    scp -i kthw_ssh_key -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "encryption-config.yaml" "ubuntu@$ip:/home/ubuntu/"
  done;
done
```
