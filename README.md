# Chronom-cli

Chronom-cli was originally created as an internal tool to allow Chronom A.I. customers to easily deploy their Chronom instances in the cloud.
It has since been expanded to allow for more general use cases.

## Installation

Chronom-cli is available as a single bash script. You can download it with the following command:

```bash
curl -o https://raw.githubusercontent.com/chronom-ai/chronom-cli/main/chronom-cli
chmod +x chronom-cli
```

### Prerequisites

Chronom-cli is built using [bashly](https://bashly.dannyb.co/), therefore you only need to have a bash shell installed on your system to get started.  
If you are using a Linux or Mac system, you should already have bash installed.  
If you are using Windows, you can install [Git Bash](https://git-scm.com/downloads) or [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10).  
In addition, you will need the following tools installed on your system to use all of the features of chronom-cli:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/)
- [jq](https://stedolan.github.io/jq/download/)
- [curl](https://curl.se/download.html)

More information about the installation of these tools can be found in the [Install chronom-cli dependencies](#install-chronom-cli-dependencies) section.

## Usage

Chronom-cli is a command line tool that allows you to easily deploy Chronom instances in the cloud.

To use the tool for general use cases, you don't need to have a Chronom account. However, if you want to deploy a Chronom instance, you will need to have a Chronom subscription. If you would like to register for a free trial, please visit [chronom.ai - register](https://chronom.ai/#contact).

### Chronom use cases

#### Create a complete deployment of Chronom on a new EKS cluster

The following command will create a new cluster in the given name and region, and then deploy a complete Chronom instance on it.  
The command will also create a new DNS record for the Chronom instance and a new certificate request in AWS Certificate Manager.  
After initial validation of the inputs, you will be prompted to enter the chronom registry password along with the chronom auth secret that were provided to you inside the registration email.

```bash
chronom-cli create chronom complete-deployment-eks --name <cluster_name> --region <cluster_region> --dns-record <chronom_dns_record> --chronom-registry-username <chronom_registry_username> --chronom-auth-id <chronom_auth_id>
```

##### Optional flags `create chronom complete-deployment-eks`

- `--create-rsa-key` - Recommended - Create a new RSA key pair and store it in the `~/.ssh` directory. The public key will be uploaded to AWS and used to access the EC2 instances in the cluster.
- `--key-pair-name` - The name of the RSA Key Pair to use (Only used if `--create-rsa-key` is not specified and the key pair already exists in AWS in the same region).
- `--node-type` - The type of EC2 instances to use for the nodes in the cluster (default: `t3.small`).
- `--min-nodes` - The minimum number of nodes in the cluster (default: `2`).
- `--max-nodes` - The maximum number of nodes in the cluster (default: `10`).
- `--version` - The Kubernetes version to use for the cluster (default: `1.27`).
- `--skip-gp3-setup` - Skip the setup of the GP3 storage class (Not recommended).
- `--skip-calico-setup` - Skip the setup of the Calico CNI (Not recommended).
- `--auto-validate` - Automatically attempt to locate a Route53 hosted zone and create a DNS record to validate the certificate request.
- `--chronom-readonly-username` - This will override the username that will be created for the Chronom readonly user (Default: `<cluster_name>-ro-user`).
- `--chronom-version` - The version of Chronom to deploy (Defaults to the latest version at time of release).
- `--skip-ingress-setup` - This will skip the creation of Ingress resources for Chronom. This is not recommended as it will prevent you from accessing Chronom from outside the cluster.
- `--skip-certificate-setup` - This will skip the creation of a certificate request in AWS Certificate Manager. This is not recommended as it will prevent you from accessing Chronom from outside the cluster.

#### Create a Chronom ReadOnly IAM user (For Advanced use cases)

This command will create a new IAM user with two permissions:

- `eks:AccessKubernetesApi` - This permission will allow the user to access the Kubernetes API.
- `sts:AssumeRole` - This permission will allow the user to assume the Chronom ReadOnly role.

The command will also create an IAM role with ReadOnly permissions for the entire AWS account (excluding RDS Database contents).

```bash
chronom-cli create chronom user-iam --name <user_name>
```

### General use cases

#### Setup Chronom-cli environment - Highly recommended

This will allow you to use tab completion for chronom-cli commands as well as run it as `chronom-cli` instead of `./chronom-cli`.

```bash
./chronom-cli setup auto-complete
```

##### Optional flags `setup auto-complete`

- `--update-bashrc` - Update the `~/.bashrc` file to automatically source the tab completion for chronom-cli. This will allow you to use tab completion for chronom-cli commands anywhere.

#### Install chronom-cli dependencies

```bash
chronom-cli setup install <dependency>
```

##### Available dependencies

- `awscli` - Install the AWS CLI.
- `eksctl` - Install eksctl.
- `kubectl` - Install kubectl.
- `helm` - Install helm.

#### Create a new EKS Cluster on AWS

```bash
chronom-cli create cluster-eks --name <cluster_name> --region <cluster_region>
```

##### Optional flags `create cluster-eks`

- `--create-rsa-key` - Recommended - Create a new RSA key pair and store it in the `~/.ssh` directory. The public key will be uploaded to AWS and used to access the EC2 instances in the cluster.
- `--key-pair-name` - The name of the RSA Key Pair to use (Only used if `--create-rsa-key` is not specified and the key pair already exists in AWS in the same region).
- `--node-type` - The type of EC2 instances to use for the nodes in the cluster (default: `t3.small`).
- `--min-nodes` - The minimum number of nodes in the cluster (default: `2`).
- `--max-nodes` - The maximum number of nodes in the cluster (default: `10`).
- `--version` - The Kubernetes version to use for the cluster (default: `1.27`).
- `--skip-gp3-setup` - Skip the setup of the GP3 storage class (Not recommended).
- `--skip-calico-setup` - Skip the setup of the Calico CNI (Not recommended).

#### List all EKS Clusters on AWS

```bash
chronom-cli list cluster-eks
```

##### Optional flags `list cluster-eks`

- `--region` - The AWS region to use (If not specified will query all regions).

#### Create Certificate Request in AWS Certificate Manager

```bash
chronom-cli create certificate-acm --dns-record <dns.record> --region <region>
```

##### Optional flags `create certificate-acm`

- `--auto-validate` - Automatically attempt to locate a Route53 hosted zone and create a DNS record to validate the certificate request.

### Sources / Acknowledgements

- [bashly](https://bashly.dannyb.co/) - A bash CLI framework.
- [eksctl](https://eksctl.io/) - A CLI for creating clusters on EKS.
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - A CLI for interacting with Kubernetes clusters.
- [helm](https://helm.sh/) - A package manager for Kubernetes.
- [AWS CLI](https://aws.amazon.com/cli/) - A CLI for interacting with AWS.
