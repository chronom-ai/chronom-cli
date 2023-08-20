# Chronom-cli

Chronom-cli was originally created as an internal tool to allow Chronom A.I. customers to easily deploy their Chronom instances in the cloud.
It has since been expanded to allow for more general use cases.

## Installation

Chronom-cli is available as a single bash script. You can download it with the following command:

```bash
curl -O https://raw.githubusercontent.com/chronom-ai/chronom-cli/main/chronom-cli
chmod +x chronom-cli
```

## To Deploy

This will take care of everything needed to create a fully functional Chronom instance on a new EKS cluster.

```bash
./chronom-cli create chronom complete-deployment-eks --name <cluster_name> --region <cluster_region> --dns-record <chronom_dns_record> --chronom-registry-username <chronom_registry_username> --chronom-auth-id <chronom_auth_id> --create-rsa-key --auto-validate
```

The installation requires a password that is provided at registration.

## Prerequisites

Chronom-cli is built using [bashly](https://bashly.dannyb.co/), therefore you only need to have a bash shell with the following tools installed:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/)
- [jq](https://stedolan.github.io/jq/download/)
- [curl](https://curl.se/download.html)

More information about the installation of these tools can be found in the [advanced README](README_ADVANCED.md/#environment-setup-commands---highly-recommended).

---

### Required flags `create chronom complete-deployment-eks`

- `--name` - The name of the EKS cluster to create.
- `--region` - The AWS region to create the EKS cluster in.

### Optional flags `create chronom complete-deployment-eks`

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

#### Example

```bash
./chronom-cli create chronom complete-deployment-eks --name chronom-cluster --region us-east-1 --dns-record chronom.example.com --chronom-registry-username chronom-registry-username --chronom-auth-id chronom-auth-id --create-rsa-key --auto-validate
```

The example above will create a new EKS cluster in the `us-east-1` region with the name `chronom-cluster` and will create a new RSA key pair and store it in the `~/.ssh` directory as well as create a new DNS record in Route53 for `chronom.example.com` and validate the certificate request for the same record.

### Acknowledgements

- [bashly](https://bashly.dannyb.co/) - A bash CLI framework.
- [eksctl](https://eksctl.io/) - A CLI for creating clusters on EKS.
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - A CLI for interacting with Kubernetes clusters.
- [helm](https://helm.sh/) - A package manager for Kubernetes.
- [AWS CLI](https://aws.amazon.com/cli/) - A CLI for interacting with AWS.
