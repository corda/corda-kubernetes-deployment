Corda Kubernetes Depolyment checklist

Tested with:

- Corda Enterprise version 4.0

Pre-requisites:

	- Clone the repository to any local folder
	- Installation requires the following tools:
		- Docker (tested with Docker 19.03.5, API 1.40, newer versions should be fine)
		- Kubectl (tested with kubectl v1.12.8, newer versions should be fine)
		- Helm (requires Helm version 2.x, tested with Helm v2.14.3, newer v2.x versions should be fine)
		- Azure CLI (tested with az cli 2.1.0, newer versions should be fine)

Azure Cloud Setup:

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

AWS Cloud setup:

	- Coming soon

Configuration:

	- Deployment folder (repository folder)
		- Binaries, jar files (the name of the jars should match the configuration)
			- Docker-images/bin
				- Corda Enterprise jar (eg. corda-ent-4.0.jar)
				- Health-survey-tool jar (eg. corda-tools-healthsurvey-4.0.jar)
				- Corda Firewall jar (eg. corda-firewall-4.0.jar)
			- Pki-firewall/bin
				- Optional on windows: Copy Key tool jar + dll to bin folder (pki-firewall/bin)
		- Config
			- docker_config.sh
				- Define versions so that they match what is in the values.yaml file.
		- Values.yaml
			- Config containerRegistry section.
			- Config storage section.
			- Config fileShareName for node/bridge/float
			- Config identityManagerAddress and networkmapAddress (without http:// prefix)
				- You can use any network, but please note that if you want to use Testnet, we will have to skip the initial registration step and download the full Testnet node from the dashboard
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

Useful commands:

	- Check deployment status with: kubectl get pods, expect to see 'Running' if the pods are working normally
	- Check logs of running components with : kubectl logs -f <pod>
	- Investigate Corda Node log by gaining a shell into the running pod with: (winpty on windows) kubectl exec -it <pod> bash, then cd to folder /opt/corda/workspace/logs and look at most recent node log file
