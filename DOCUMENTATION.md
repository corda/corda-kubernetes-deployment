# DOCUMENTATION

## Overview

The main documentation section is currently hosted at https://solutions.corda.net/deployment/kubernetes/intro.html

The documentation may be migrated to GitHub, to this repository.

For now, the documentation contained here is limited to new topics that have not been added to the main documentation site yet.

## TOPICS

### Cost calculation of Kubernetes deployment versus a traditional bare-metal deployment

We have received many times the question of how much does it cost to deploy using Kubernetes versus a traditional bare-metal based installation.

Although the answer will be dependent on the use-case specific details, for example are we talking about high-frequency trading with high number of transactions per second or are we talking about high quality asset issuance which occurs much less frequently, we can still generate some rough estimates that hopefully will be useful as indications.

Let's start by looking at the costs of a traditional bare-metal installation.

#### Bare-metal installation cost

Let's use a typical server with 2 cores and 8 GB of memory as the base building block see the details in the specification section below.

The reason why we chose this type is that it should be sufficient to run most Corda applications without issues, but still it is considered one of the smallest sizes available, which means, if you wanted to increase performance, so would the cost increase.
For more information on sizing and performance please see [Corda Sizing & Performance](https://docs.corda.net/docs/corda-enterprise/4.4/node/sizing-and-performance.html#sizing-and-performance).

Let's add more detail to the deployment, let's look at a typical deployment of Corda, which is comprised of a Corda node, Corda firewall, a vault database, a webserver, loadbalancer and a cloud HSM.

We can also add the CENM setup to the list, just to have an overview of what it might mean if you were running your own private Corda network with the Corda Enterprise Network Manager.
A CENM setup is comprised of an Identity Manager, a Signing Service, a Network Map and a Notary cluster.

---

## Specification

VM spec (2 cores and 8 GB of memory):

- AWS: m4-large ($0.10/h, $73/month)
- Azure: Standard_D2s_v3 ($0.117/h, $85.41/month)
- GCP: n2-standard-2 ($0.0971/h, $70.883/month)

HDD spec:

- AWS: 100GB ($4.50/month)
- Azure: 100GB ($4.60/month)
- GCP: 100GB ($4.00/month)

Database (DB) spec (*):
4 vCores, 500GB storage (some discrepancy between the different cloud providers make comparison slightly uncertain, please be skeptical on GCP DB pricing in particular)

- AWS: db.m5.xlarge SQL Server ($1.224/h, $893.52/month) + storage SSD 500 GB ($112.50) = $1006.02 total/month (https://aws.amazon.com/rds/sqlserver/pricing/?nc=sn&loc=4)
- Azure: Microsoft.SQLDatabase 4vCore + data max size 500 GB ($925.66/month) (https://azure.microsoft.com/en-gb/pricing/calculator/)
- GCP: 4vCPU, 16 GB RAM,  4x$30.15+4x$5.11+500*$0.170/month = $120.6+$20.44+$85=$221+license $343.1 = $564.1 total/month (https://cloud.google.com/sql/pricing#sql-server)

## Cost calculation: CENM in traditional bare-metal setup

Keep in mind, that if you are using the Corda Network, this setup is hosted by the Corda Network Foundation and you should not have to consider this cost.

Please note that all costs are per month in this table and in USD. (only direct VM cost + HDD cost considered)
Cloud HSM is listed but not calculated, the pricing models will vary wildly depending on how you use them.


| Type              | VMs |  HDD   |       AWS |     Azure |       GCP |
| ----------------- |:---:|:------:| ---------:| ---------:| ---------:|
| Identity Manager  |  1  | 100 GB |    $77.50 |    $90.01 |    $74.88 |
| Signing Service   |  1  | 100 GB |    $77.50 |    $90.01 |    $74.88 |
| Network Map       |  1  | 100 GB |    $77.50 |    $90.01 |    $74.88 |
| CENM Database(HA) |  2* | 500 GB |  $2012.04 |  $1851.32 |  $1128.20 |
| Notary Cluster    |  3  | 100 GB |   $232.50 |   $270.03 |   $224.65 |
| Notary Cluster DB |  3* | 500 GB |  $3018.06 |  $2776.98 |  $1692.30 |
| Cloud HSM Keys x3 |  -  |   -    |         - |         - |         - |
|                   |     |        |           |           |           |
| **Total**         |  -  |   -    |  $5495.10 |  $5168.36 |  $3269.78 |

---

## Cost calculation: Corda Node in traditional bare-metal setup

Please note that all costs are per month in this table and in USD. (only direct VM cost + HDD cost considered)

Cloud HSM keys breakdown:
(1 Node CA per node + 1 Legal Identity per node + 1 TLS per node) x 2 (the reason for two nodes is we are using Hot-Cold HA (High availability))
(optionally 1 Artemis access token + 1 artemis root in HSM) (Artemis can be used as a standalone component, which is the recommendation for high throughput)
(optionally 1 tunnel root + 1 tunnel key  + 1 bridge key in HSM) (Corda firewall is an optional component which is recommended to achieve high security)


| Type              | VMs |  HDD   |       AWS |     Azure |       GCP |
| ----------------- |:---:|:------:| ---------:| ---------:| ---------:|
| Corda Node        |  2  | 100 GB |   $155.00 |   $180.02 |   $149.76 |
| Artemis MQ        |  2  | 100 GB |   $155.00 |   $180.02 |   $149.76 |
| Corda Bridge      |  2  | 100 GB |   $155.00 |   $180.02 |   $149.76 |
| Corda Float       |  2  | 100 GB |   $155.00 |   $180.02 |   $149.76 |
| Webserver         |  2  | 100 GB |   $155.00 |   $180.02 |   $149.76 |
| Loadbalancer      |  1  | 100 GB |    $77.50 |    $90.01 |    $74.88 |
| Cloud HSM Keys x6 |  -  |   -    |         - |         - |         - |
|                   |     |        |           |           |           |
| **Total**         | 11  |   -    |   $852.50 |   $990.11 |   $823.68 |

---

## Cost calculation: CENM using Kubernetes cluster

The main difference comes from the fact that we can pool together VMs to serve many components, based on load.
The storage requirements remain the same, as do the databases (the databases are expected to be provisioned outside of the cluster).

| Type              | VMs |  HDD   |       AWS |     Azure |       GCP |
| ----------------- |:---:|:------:| ---------:| ---------:| ---------:|
| Identity Manager  |  2  | 100 GB |   $150.50 |   $175.42 |   $145.76 |
| Signing Service   |  -  | 100 GB |     $4.50 |     $4.60 |     $4.00 |
| Network Map       |  -  | 100 GB |     $4.50 |     $4.60 |     $4.00 |
| CENM Database(HA) |  2* | 500 GB |  $2012.04 |  $1851.32 |  $1128.20 |
| Notary Cluster    |  3  | 100 GB |   $232.50 |   $270.03 |   $224.65 |
| Notary Cluster DB |  3* | 500 GB |  $3018.06 |  $2776.98 |  $1692.30 |
| Cloud HSM Keys x3 |  -  |   -    |         - |         - |         - |
|                   |     |        |           |           |           |
| **Total**         |  -  |   -    |  $5422.10 |  $5082.95 |  $3198.90 |

Cost saving of 1 VM for each column. The cost savings of running CENM inside a Kubernetes cluster are not huge, but they are measurable.
The big advantage of using Kubernetes for CENM comes from the uptime and availability of the system as a whole. 
Kubernetes will be auto-restarting failed components, while in a traditional setting, you might have to do manual investigation and remediation.

---

## Cost calculation: Corda Node using Kubernetes cluster

A large cost saving comes from the fact that Kubernetes maintains the HA. Which means we can drastically reduce the VMs required.

| Type              | VMs |  HDD   |       AWS |     Azure |       GCP |
| ----------------- |:---:|:------:| ---------:| ---------:| ---------:|
| Corda Node        |  1  | 100 GB |    $77.50 |    $90.01 |    $74.88 |
| Artemis MQ        |  1  | 100 GB |    $77.50 |    $90.01 |    $74.88 |
| Corda Bridge      |  1  | 100 GB |    $77.50 |    $90.01 |    $74.88 |
| Corda Float       |  1  | 100 GB |    $77.50 |    $90.01 |    $74.88 |
| Webserver         |  1  | 100 GB |    $77.50 |    $90.01 |    $74.88 |
| Loadbalancer      |  -  |   -    |    $22.42 |    $23.25 |    $18.25 |
| Cloud HSM Keys x6 |  -  |   -    |         - |         - |         - |
|                   |     |        |           |           |           |
| **Total**         |  5  |   -    |   $409.92 |    $473.3 |   $392.65 |

Cost saving of 6 VM for each column compared to traditional bare-metal installation. This equates to roughly 50% cost reduction.

---

## CONCLUSION

This cost calculation implies that there is a considerable amount of reduction of cost if using Kubernetes.
In addition Kubernetes provides many other benefits, such as self-healing (high-availability), portability and scalability.
Do take any calculations as a starting point and perform your own cost calculations, especially factoring in load scenarios you would be expecting.
As mentioned previously, a system that would be catering to high network throughput would surely have to be scaled up vertically by a big factor.
