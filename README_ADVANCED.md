# Chronom CLI - Advanced

This document contains advanced use cases and more detailed information about the Chronom CLI.

## Environment Setup Commands - Highly recommended

### Setup Chronom-cli environment - Highly recommended

This will allow you to use tab completion for chronom-cli commands as well as run it as `chronom-cli` instead of `./chronom-cli`.

```bash
./chronom-cli setup auto-complete
```

#### Optional flags `setup auto-complete`

- `--update-bashrc` - Update the `~/.bashrc` file to automatically source the tab completion for chronom-cli. This will allow you to use tab completion for chronom-cli commands anywhere.

### Install chronom-cli dependencies

The command will install the selected dependency on the local machine.  
:warning: Note that currently the command does not check if the dependency is already installed.

```bash
chronom-cli setup install <dependency>
```

#### Available dependencies

- `awscli` - Install the AWS CLI.
- `eksctl` - Install eksctl.
- `kubectl` - Install kubectl.
- `helm` - Install helm.

## Chronom Commands

### Create a Chronom ReadOnly IAM user (For Advanced use cases)

The command is designed for when you want to create a new IAM user for Chronom outside the context of the `create chronom complete-deployment-eks` command.  
example use cases are mainly:

- rollout of IAM User - If instructed by Chronom support to create a new IAM user for Chronom.
- Manual deployment of Chronom - If you want to deploy Chronom manually using the Helm chart.

```bash
chronom-cli create chronom user-iam --name <user_name>
```

#### Details

The command will create a new IAM user with two permissions:

- `eks:AccessKubernetesApi` - This permission will allow the user to access the Kubernetes API.
- `sts:AssumeRole` - This permission will allow the user to assume the Chronom ReadOnly role.

The command will also create an IAM role with ReadOnly permissions for the entire AWS account (excluding RDS Database contents).  
To achieve this the command will create new IAM policies for the role and the user.  
Finally the command will create a new IAM User Access Key and Secret Key for the user (Those values are then used in the helm installation).

### Delete a Chronom ReadOnly IAM user (For Advanced use cases)

The command will delete the IAM user created by the `create chronom user-iam` command along with all the resources created by the command.

```bash
chronom-cli delete chronom user-iam --name <user_name>
```

## General commands

### Create a new EKS Cluster on AWS

This command will create a new EKS cluster on AWS following most of the best practices for EKS clusters.

```bash
chronom-cli create cluster-eks --name <cluster_name> --region <cluster_region> --create-rsa-key
```

#### Optional flags `create cluster-eks`

- `--create-rsa-key` - Recommended - Create a new RSA key pair and store it in the `~/.ssh` directory. The public key will be uploaded to AWS and used to access the EC2 instances in the cluster.
- `--key-pair-name` - The name of the RSA Key Pair to use (Only used if `--create-rsa-key` is not specified and the key pair already exists in AWS in the same region).
- `--node-type` - The type of EC2 instances to use for the nodes in the cluster (default: `t3.small`).
- `--min-nodes` - The minimum number of nodes in the cluster (default: `2`).
- `--max-nodes` - The maximum number of nodes in the cluster (default: `10`).
- `--version` - The Kubernetes version to use for the cluster (default: `1.27`).
- `--skip-gp3-setup` - Skip the setup of the GP3 storage class (Not recommended).
- `--skip-calico-setup` - Skip the setup of the Calico CNI (Not recommended).

#### Example

```bash
chronom-cli create cluster-eks --name chronom-cluster --region us-east-1 --create-rsa-key
```

#### Details

The command will create a new EKS cluster in the specified region with the specified name.  
The command will also create a new RSA key pair and store it in the `~/.ssh` directory.

The cluster will be created with the following configurations:

- Kubernetes version: `1.27`
- Node type: `t3.small`
- Minimum nodes: `2`
- Maximum nodes: `10`
- Default storage class: `gp3`
- CNI: `Calico`
- SSH access: `Enabled`
- Metrics server: `Enabled`
- Cluster autoscaler: `Enabled & Configured`
- Prefix Delegation: `Enabled`
- Public access: `Enabled`
- Node Private Networking: `Enabled`

---

### List all EKS Clusters on AWS

This command will list all EKS clusters in the specified region.  
If no region is specified the command will list all EKS clusters in all regions.

```bash
chronom-cli list cluster-eks
```

#### Optional flags `list cluster-eks`

- `--region` - The AWS region to use (If not specified will query all regions).

---

### Create Certificate Request in AWS Certificate Manager

This command will create a new certificate request in AWS Certificate Manager.  
If the `--auto-validate` flag is specified the command will also attempt to locate a Route53 hosted zone and create a DNS record to validate the certificate request by creating a new CNAME record.

```bash
chronom-cli create certificate-acm --dns-record <dns.record> --region <region>
```

#### Optional flags `create certificate-acm`

- `--auto-validate` - Automatically attempt to locate a Route53 hosted zone and create a DNS record to validate the certificate request.
