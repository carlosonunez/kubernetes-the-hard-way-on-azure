[Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
uses Google Cloud for its labs. Since we're using Azure in this repository,
there will be some differences. These differences are detailed in this delta.

## Create a new service principal

You'll need to create a new Azure service principal before you can run the commands below.
To do that, run this `az` command:

```sh
az login -t $YOUR_TENANT_ID # Log in through the web browser when prompted.
az ad sp create-for-rbac -n "tthw-sp" --role Owner
```

**NOTE**: If your subscription's management group does not allow service principals with
`Owner` roles, try creating a service principal as a contributor instead:

```sh
az ad sp create-for-rbac -n "kthw-sp" --role Contributor
```

You'll get a blob like the one shown below:

```sh
{
  "appId": "your_appId",
  "displayName": "khtw-sp",
  "name": "http://kthw-sp",
  "password": "your_password",
  "tenant": "your_tenant"
}
```

Copy and save into a new file called `$HOME/.azure_credentials`.

**Treat this file like the key to your house (or some other possession you deeply
care about). Don't distribute it with anyone!**

Once done, you can log into Azure using this service principal with the command
below:

```sh
az login --service-principal -u $(jq -r .appId ~/.azure_credentials) \
  -p $(jq -r .password ~/.azure_credentials) \
  -t $(jq -r .tenant ~/.azure_credentials)
```

## Create a resource group for our labs

We'll also need a resource group to hold all of the resources we'll be creating
for our labs. Run the command below to create that:

```sh
az group create --name kubernetes
```
