# SUPPORT MATRIX

The Corda Kubernetes Deployment has been tested and verified to work with the following setup.

Please note that you may be able to work with other setups than the ones that have been tested, but for first time deployment you really should go with one of the tested ones.

## Database support

This deployment supports the following databases:

| Vendor        | Version | JDBC Driver                   |
| ------------- |:-------:|:------------------------------|
| MS SQL Server |  2017   | Microsoft JDBC                |
| PostgreSQL    |  9.6    | Oracle JDBC 8                 |
| Oracle        |  12cR2  | PostgreSQL JDBC Driver 42.1.4 |

Please note that the JDBC driver is downloaded automatically as part of the deployment and may end up downloading an unsupported version in the future.

## Operating system support

Operating systems supported in deployment:

| Platform      | Version |
| ------------- |:-------:|
| MS Windows    |   10    | 
| Linux Ubuntu  |  18.04  |
| Apple macOS   |  10.15  |

Great effort has been done to keep all 3 major OS supported.

## Cloud vendor support

This deployment has been tested and verified against the 3 major cloud providers.

| Vendor  | Complete vendor name    |
| ------- |:------------------------|
| Azure   |  Microsoft Azure        |
| AWS     |  Amazon Web Services    |
| GCP     |  Google Cloud Platform  |

Best effort to be cloud agnostic regarding the support for the different cloud providers.

## Software support

The deployment usually requires a minimum version of software and higher version numbers are usually fine, there are some exceptions though as listed below.

| Software   | Minimum recommended version          | Limitations |
| ---------- |:-------------------------------------|:-------------------------------------------------|
| Docker     | tested with Docker 19.03.5, API 1.40 | newer versions should be fine                    |
| kubectl    | tested with kubectl v1.12.8          | newer versions should be fine                    |
| Helm       | tested with Helm v2.14.3             | requires Helm version 2.x (3.x has known issues) |
| Azure CLI  | tested with az cli 2.1.0             | newer versions should be fine                    |
| AWS CLI    | tested with aws cli 2                | newer versions should be fine                    |
| Google CLI | tested with gcloud 290.0.1           | newer versions should be fine                    |

Should you try and use versions older than the tested ones, you are in uncharted waters and may run into issues, please consider updating the relevant software!

## Infrastructure minimum requirements

For the underlying infrastructure here are some minimum requirements that have been tested.

### Kubernetes Cluster

A node pool that has the following resources available:

- 2x Standard DS2 v2 (2 vcpus, 7 GiB memory)

### Storage account

3 file shares with the minimum storage requirements of:

- Node, 2GB
- Bridge, 1GB
- Float, 1GB

(please note that these are bare minimums to stand up the relevant components and should not be expected to last for years in production)

## Disclaimer

These are tested with versions, but that does not mean that there cannot be any issues arising later from using any of these combinations of systems.
Completing an end to end transaction between two nodes in a simple setup has different expectations compared to running a node in production for many years.
It is strongly recommended that you perform your own in-depth tests with the setup you deem most relevant to your deployment.
