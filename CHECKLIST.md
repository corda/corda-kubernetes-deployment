# Corda Kubernetes Deployment checklist

Tested with:

- Corda Enterprise version 4.0

---

## Prerequisites:

	- Clone the repository to any local folder
	- Installation requires the following tools:
		- Docker (tested with Docker 19.03.5, API 1.40, newer versions should be fine)
		- Kubectl (tested with kubectl v1.12.8, newer versions should be fine)
		- Helm (requires Helm version 2.x, tested with Helm v2.14.3, newer v2.x versions should be fine)
		- Cloud specific CLI:
			- Azure CLI (tested with az cli 2.1.0, newer versions should be fine) [az](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
			- AWS CLI (tested with aws cli 2, newer versions should be fine) [aws](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
			- Google CLI (tested with gcloud 290.0.1, newer versions should be fine) [gcloud](https://cloud.google.com/sdk/gcloud)

---

## Cloud setup, follow one of the following: Azure, AWS

### Microsoft Azure cloud setup checklist:

	- Azure Setup
		- Azure Account connected to a subscription with permissions to create resources
		- Azure Kubernetes Service
		- Azure Container Registry
		- Azure Service Principals
		- Azure Storage Account, create three new File shares for each of the following:
			- node, named for example node-<name>-storage, where name would match the nodes x500 name to some degree and should match values.yaml files "fileShareName" parameter as well
			- bridge, named for example bridge-<name>-storage, where name would match the nodes x500 name to some degree and should match values.yaml files "fileShareName" parameter as well
			- float, named for example float-<name>-storage, where name would match the nodes x500 name to some degree and should match values.yaml files "fileShareName" parameter as well
		- Public IP Addresses in the "KubernetesPlayground-NodePool" resource group
			- Node, to enable RPC connections from GUI, named for example node-<name>-ip
			- Float, to enable inbound connections from other nodes on the network, named for example float-<name>-ip
	- Azure Config
		- az login, make sure at this point that if you have many subscriptions, that the one you want to use has isDefault=true, if not use "az account list" and "az account set -s <subscription id>" to fix it
		- az aks get-credentials --resource-group KubernetesPlayground --name KubernetesPlaygroundAKS # KubernetesPlayground is just an example name, use your own resource names
		- kubectl create namespace <name> # name could be for example firstname-lastname in lowercase, if you are deploying many instances in a test environment
		- kubectl config set-context --current --namespace <name>

### Amazon Web Services (AWS) cloud setup checklist:

	- AWS Setup
		- AWS account with a subscription that has necessary permissions to create resources
		- AWS VPC for the Kubernetes cluster
		- AWS EKS (Elastic Kubernetes Service), with at least one VM (t3.medium or better recommended)
		- AWS ECR (Elastic Container Registry)
		- AWS EBS (Elastic Block System), with 3 dedicated volumes set up and mounted to the VM that the pods will be running on
			- node volume, size 2Gb
			- bridge volume, size 1Gb
			- float volume, size 1Gb
	- AWS Config
		- kubectl config, follow https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
		- kubectl create namespace <name> # name could be for example firstname-lastname in lowercase, if you are deploying many instances in a test environment
		- kubectl config set-context --current --namespace <name>

### Google Cloud Platform (GCP) cloud setup checklist:

	- GCP Setup
		- GCP account with a subscription that has necessary permissions to create resources
		- GCP GKE (Google Kubernetes Engine), with at least one VM (n1-standard-4 or better recommended)
		- GCP GCR (Google Container Registry)
		- GCP PD (Persistent Disk), with 3 dedicated volumes set up and mounted to the VM that the pods will be running on
			- node volume, size 10Gb
			- bridge volume, size 10Gb
			- float volume, size 10Gb
	- GCP Config
		- kubectl config, follow https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl
		- kubectl create namespace <name> # name could be for example firstname-lastname in lowercase, if you are deploying many instances in a test environment
		- kubectl config set-context --current --namespace <name>

---

## Deployment configuration:

	- Deployment folder (repository folder)
		- Binaries, jar files (the name of the jars should match the configuration)
			- Docker-images/bin
				- Corda Enterprise jar (eg. corda-ent-4.0.jar)
				- Health-survey-tool jar (eg. corda-tools-healthsurvey-4.0.jar)
				- Corda Firewall jar (eg. corda-firewall-4.0.jar)
			- Pki-firewall/bin
				- Optional step on windows: Copy Key tool jar + dll to bin folder (pki-firewall/bin)
		- Config
			- docker_config.sh
				- Define versions so that they match what is in the values.yaml file.
		- Values.yaml
			- Config containerRegistry section.
			- Config storage section.
			- Config fileShareName for node/bridge/float
			- Config identityManagerAddress and networkmapAddress (without http:// prefix)
				- You can use any network, but please note that if you want to use Testnet, we will have to skip the initial registration step and download the full Testnet node from the dashboard
				- Alternative config to above if using Corda Testnet, see Testnet configuration below
			- Config resourceName to reflect the x500 name of the node, please note to use lowercase letters and numbers only
			- Config legalName to define the x500 name of the node
		- Download network root truststore to ./helm/files/network with the name "networkRootTrustStore.jks"
		- Configure matching truststorePassword to the truststore.
	- Execution
		- Run one-time-setup.sh once, which does the following:
			- Creates and pushes Docker images to the container registry
			- Generates certificates for the Corda Firewall TLS tunnel
			- Performs initial registration of the node
			- Copies the generates certificates for the next step, which is the deployment
		- Deploy using deploy.sh or helm/helm_compile.sh, which does the following:
			- Compiles the Helm charts from templates to Kubernetes resource definition files
			- Applies the generated Kubernetes resources definition files to the Kubernetes cluster
			- Three pods should be at status ‘Runningʼ for node, bridge and float after a while
			- Please have a look at the logs files for the three pods to make sure they are running without errors (kubectl get pods + kubectl logs -f <pod name>)
			- Run delete_all.sh to remove all resources from the Kubernetes cluster if you need to start fresh

---

## Corda Testnet configuration:

	- Retrieve certificates and config:
		- Register on R3 Corda Marketplace: https://marketplace.r3.com/register
		- Go to https://marketplace.r3.com/network/testnet/dashboard
		- Click Create Node: https://marketplace.r3.com/network/testnet/install-node
		- Choose 
			- Node version: "Enterprise"
			- Corda version: 4.0
		- Click on "Create new node"
		- Click on "Download Corda Node". A "node.zip" file should be prepared and downloaded
	- Update certificates with legal entity keys ("identity-private-key" section in "nodekeystore.jks"):
		- Unzip the "node.zip" to a folder with JVM 1.8 installed and Internet access. (Let's call the full path to download folder NODE_DIR)
		- Edit "node.conf" and change "p2pAddress" from "0.0.0.0" to "localhost" 
		- Run in a shell: "java -jar corda.jar"
		- Wait for node to start. This will enrich "certificates/nodekeystore.jks" with the Nodes legal entity key pair
		- Kill the node process (ctrl+c)
		- Copy certificates from Testnet node folder to deployment folder: "cp NODE_DIR/certificates/*.jks ./helm/files/certificates/node"
	- In "helm/values.yaml":
		- Copy variables "keystorePassword" and "truststorePassword" from unzipped "node.conf" to sections matching paths ".Values.corda.node.conf.keystorePassword" and ".Values.corda.node.conf.truststorePassword" respectively
		- Fill variable "myLegalName" from "node.conf" to ".Values.corda.node.conf.legalName"
		- Fill variable "corda.node.conf.compatibilityZoneEnabled"  with "true"
		- Fill variable "corda.node.conf.compatibilityZoneURL" with "https://netmap.testnet.r3.com"

---

## Useful commands:

	- Check deployment status with: kubectl get pods, expect to see 'Running' if the pods are working normally
	- Check logs of running components with : kubectl logs -f <pod>
	- Investigate Corda Node log by gaining a shell into the running pod with: (winpty on windows) kubectl exec -it <pod> bash, then cd to folder /opt/corda/workspace/logs and look at most recent node log file

---
