# Corda Kubernetes Deployment checklist

Tested with:

Corda Enterprise versions 4.0, 4.1, 4.2, 4.3, 4.4, 4.5

---

## Prerequisites:

- Clone the repository to any local folder
- Installation requires the following tools:
	- **Docker** (tested with Docker 19.03.5, API 1.40, newer versions should be fine)
	- **kubectl** (tested with kubectl v1.12.8, newer versions should be fine)
	- **Helm** (requires Helm version 2.x, tested with Helm v2.14.3, newer v2.x versions should be fine)
	- Cloud specific **CLI**:
		- Azure CLI (tested with az cli 2.1.0, newer versions should be fine) [az](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
		- AWS CLI (tested with aws cli 2, newer versions should be fine) [aws](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
		- Google CLI (tested with gcloud 290.0.1, newer versions should be fine) [gcloud](https://cloud.google.com/sdk/gcloud)

---

## Cloud setup, follow one of the following: Azure, AWS, GCP

Note, that if you already have your Kubernetes cluster with attached Container Registry and Persistent storage, you can skip this whole cloud setup section and skip straight to [Deployment configuration](#deployment-configuration).

See [CLOUD_SETUP.md](CLOUD_SETUP.md) for more information on setup steps.

### Microsoft Azure cloud setup checklist:

#### Azure Setup

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
	- NOTE! SKU type for the Public IP must match the Load Balancer for the Kubernetes cluster (or you will get an error while the LoadBalancer is trying to set up the external IP connection)

#### Azure Config

- az login, make sure at this point that if you have many subscriptions, that the one you want to use has isDefault=true, if not use "az account list" and "az account set -s <subscription id>" to fix it
- az aks get-credentials --resource-group KubernetesPlayground --name KubernetesPlaygroundAKS # KubernetesPlayground is just an example name, use your own resource names
- kubectl create namespace <name> # name could be for example firstname-lastname in lowercase, if you are deploying many instances in a test environment
- kubectl config set-context --current --namespace <name>

---

### Amazon Web Services (AWS) cloud setup checklist:

#### AWS Setup

- AWS account with a subscription that has necessary permissions to create resources
- AWS VPC for the Kubernetes cluster
- AWS EKS (Elastic Kubernetes Service), with at least one VM (t3.medium or better recommended)
- AWS ECR (Elastic Container Registry)
- AWS EBS (Elastic Block System), with 3 dedicated volumes set up and mounted to the VM that the pods will be running on
	- node volume, size 2Gb
	- bridge volume, size 1Gb
	- float volume, size 1Gb

#### AWS Config

- kubectl config, follow https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
- kubectl create namespace <name> # name could be for example firstname-lastname in lowercase, if you are deploying many instances in a test environment
- kubectl config set-context --current --namespace <name>

---

### Google Cloud Platform (GCP) cloud setup checklist:

#### GCP Setup

- GCP account with a subscription that has necessary permissions to create resources
- GCP GKE (Google Kubernetes Engine), with at least one VM (n1-standard-4 or better recommended)
- GCP GCR (Google Container Registry)
- GCP PD (Persistent Disk), with 3 dedicated volumes set up and mounted to the VM that the pods will be running on
	- node volume, size 10Gb
	- bridge volume, size 10Gb
	- float volume, size 10Gb

#### GCP Config

- kubectl config, follow https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl
- kubectl create namespace <name> # name could be for example firstname-lastname in lowercase, if you are deploying many instances in a test environment
- kubectl config set-context --current --namespace <name>

---

## Deployment configuration:

### Deployment folder (repository folder)

#### MAIN CONFIG in ``values.yaml``:

- Define cordaVersion, which Corda Enterprise version to use, for example 4.0, 4.1 or 4.5-SNAPSHOT. (any releases that are tagged are fine)
- Configure the containerRegistry section in its entirety, you'll find the details from your Container Registry you created in the Cloud setup
- Configure the storage section in its entirety, you'll find the details from your Persistent Storage you created in the Cloud setup
- Set the fileShareName for node/bridge/float to match the volumes you created in your Persistent Storage
- Set the identityManagerAddress and networkmapAddress (with the http:// protocol prefix and the port number, eg. http://my-idman:1000)
	- You can use any network, but for Testnet see next line
	- Testnet - if you want to use Corda Testnet, follow the [Corda Testnet configuration](#corda-testnet-configuration) section
- Set the resourceName to reflect the x500 name of the node, please note to use lowercase letters and numbers only
- Set the legalName to define the x500 name of the node and a matching emailAddress as contact information
- Define the p2pAddress where the Node will be reached by other nodes on the network (if deploying a Float, it should be the Floats DNS name)
- Define the nodeLoadBalancerIP (it should map the Public STATIC IP address NUMBER of the Node, do not use a DNS name here)
- Define the floatLoadBalancerIP (it should map the Public STATIC IP address NUMBER of the Float, do not use a DNS name here)

#### Network setup

- Download network root truststore to ./helm/files/network with the name ``networkRootTrustStore.jks`` (must match spelling exactly)
- Configure matching truststorePassword to the truststore.

#### Binaries, jar files (the name of the jars should match the configuration)

Use ``docker-images/download_binaries.sh`` to automatically download the binaries for the cordaVersion specified in ``values.yaml``.

``docker-images/bin`` should contain the following:

- Corda Enterprise jar (eg. corda-ent-4.0.jar)
- Health-survey-tool jar (eg. corda-tools-healthsurvey-4.0.jar)
- Corda Firewall jar (eg. corda-firewall-4.0.jar)

``pki-firewall/bin`` Optional step on Windows (normally this step can be skipped as long as keytool.exe is in PATH):

- Copy Key tool binary + dll to bin folder (pki-firewall/bin)

### Execution

#### Run ``one-time-setup.sh`` once, which does the following:

- Creates and pushes Docker images to the container registry
- Generates certificates for the Corda Firewall TLS tunnel
- Performs initial registration of the node
- Copies the generates certificates for the next step, which is the deployment
- Copies the network-parameters file to /helm/files/network/network_parameters.file

#### Deploy using ``deploy.sh`` or ``helm/helm_compile.sh``, which does the following:

- Compiles the Helm charts from templates to Kubernetes resource definition files
- Applies the generated Kubernetes resources definition files to the Kubernetes cluster
- Three pods should be at status ‘Runningʼ for node, bridge and float after a while
- Please have a look at the logs files for the three pods to make sure they are running without errors (kubectl get pods + kubectl logs -f <pod name>)
- Run delete_all.sh to remove all resources from the Kubernetes cluster if you need to start fresh

---

## Corda Testnet configuration:

This section is only relevant should you choose to deploy your node to Corda Testnet. For more information on Corda Testnet see [Joining Corda Testnet](https://docs.corda.net/docs/corda-os/4.4/corda-testnet-intro.html).

### Retrieve certificates and config:

- Register on R3 Corda Marketplace: https://marketplace.r3.com/register
- Go to https://marketplace.r3.com/network/testnet/dashboard
- Click Create Node: https://marketplace.r3.com/network/testnet/install-node
- Choose: Node version: "Enterprise"
- Choose: Corda version: 4.0 (or whichever matches your version you are deploying)
- Click on "Create new node"
- Click on "Download Corda Node". A "node.zip" file should be prepared and downloaded

### Update certificates with legal entity keys ("identity-private-key" section in "nodekeystore.jks"):

- Unzip the "node.zip" to a folder with JVM 1.8 installed and Internet access. (Let's call the full path to download folder NODE_DIR)
- Edit "node.conf" and change "p2pAddress" from "0.0.0.0" to "localhost" 
- Run in a shell: "java -jar corda.jar"
- Wait for node to start. This will enrich "certificates/nodekeystore.jks" with the Nodes legal entity key pair
- Kill the node process (ctrl+c)
- Copy certificates from Testnet node folder to deployment folder: "cp NODE_DIR/certificates/*.jks ./helm/files/certificates/node"
- Copy network-parameters from Testnet node folder to deployment folder `cp NODE_DIR/network_parameters ./helm/files/network/network_parameters.file` 

### In "helm/values.yaml":

- Copy variables "keystorePassword" and "truststorePassword" from unzipped "node.conf" to sections matching paths ".Values.corda.node.conf.keystorePassword" and ".Values.corda.node.conf.truststorePassword" respectively
- Fill variable "myLegalName" from "node.conf" to ".Values.corda.node.conf.legalName"
- Fill variable "corda.node.conf.compatibilityZoneEnabled"  with "true"
- Fill variable "corda.node.conf.compatibilityZoneURL" with "https://netmap.testnet.r3.com"

---

## Useful commands:

- Check deployment status with: ``kubectl get pods``, expect to see 'Running' if the pods are working normally
- Check logs of running components with: ``kubectl logs -f <pod>``
- If the pods are not running correctly, investigate why with command: ``kubectl decribe <pod>``
- Investigate Corda Node log by gaining a shell into the running pod with: ``(prefix with 'winpty' on Windows) kubectl exec -it <pod> bash``, then cd to folder /opt/corda/workspace/logs and look at most recent node log file

---
