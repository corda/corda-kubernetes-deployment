# How to set up a corda k8s node on the corda testnet network

Azure steps :
- create an AKS cluster
- create a storage account with 3 file share:
  - node-storage (2Gb)
  - bridge-storage (1Gb)
  - float-storage (1Gb)
- create an ACR (docker registry)
- create 2 public IP adresses in the same RG as AKS (starts with MC_)
  - p2p-ip
  - rpc-ip
- fill `helm/values.yaml` with appropriate values from above

Repo steps :
- Do docker steps (docker directory)
- Register on corda marketplace : https://marketplace.r3.com/register
- Go to https://marketplace.r3.com/network/testnet/install-node
- Choose 
  - node version: "Enterprise"
  - Corda version : 4.0
- Click on "Create new node"
- Click on download corda node. It should download a `node.zip` file
- unzip the `node.zip` on a PC or a VM with internet access. (We are going to call it NODE_DIR)
- Edit `node.conf` and change `p2pAddress` 
- Run in a shell: `java -jar corda.jar` 
- Wait for node to start. That will enrich the certificate with the node legal entity key pair
- kill the node process
- Copy certificates `cp $NODE_DIR/certificates/*.jks ./helm/files/certificates/node`
- Fill variables  `keystorePassword` and `truststorePassword` from unzipped `node.conf` to `helm/values.yaml` `nodeKeystorePassword` and `nodeTruststorePassword`
- Fill variable `myLegalName` from node.conf to `helm/values.yaml` `corda.node.conf.legalName`
- `kubectl create namespace cordatest`
- `kubectl config set-context --current --namespace=cordatest`
- `deploy.sh`