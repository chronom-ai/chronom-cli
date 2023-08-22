create_rsa_key_pair() {
    
    clusterName="$1"
    region="$2"
    
    ## Check if key pair name is available
    check_available_key_pair_name $clusterName-KeyPair $region
    mkdir -p ~/.ssh
    aws ec2 create-key-pair --key-name $clusterName-KeyPair --region $region --query "KeyMaterial" --output text > ~/.ssh/$clusterName-KeyPair.pem
    sshKeysFlags="--ssh-access --ssh-public-key $clusterName-KeyPair"
}

create_vpc_cni_addon() {
    clusterName="$1"
    region="$2"
    
    eksctl create addon --name vpc-cni --cluster $clusterName --version latest --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy --region $region --force
    green "# VPC-CNI addon created successfully"
    yellow "# Configuring VPC-CNI addon to support prefix delegation"
    kubectl --server $endpoint --token $token --certificate-authority $pemFile set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true
    kubectl --server $endpoint --token $token --certificate-authority $pemFile set env ds aws-node -n kube-system WARM_PREFIX_TARGET=1
}


create_cluster_addons_bundle() {
    clusterName="$1"
    region="$2"
    
    yellow "# Deploying Metrics Server"
    kubectl --server $endpoint --token $token --certificate-authority $pemFile apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    green "# Metrics Server deployed successfully"
    
    yellow "# Deploying Cluster Autoscaler"
    kubectl --server $endpoint --token $token --certificate-authority $pemFile apply -f <(curl -s https://chronompublicresources.s3.eu-north-1.amazonaws.com/k8sYamls/autoscaler.yaml | sed "s/<YOUR CLUSTER NAME>/$clusterName/g" )
    green "# Cluster Autoscaler deployed successfully"
    
    
    yellow "# Deploying KUBE-PROXY & COREDNS addons"
    eksctl create addon --name kube-proxy --cluster $clusterName --version latest --region $region --force
    eksctl create addon --name coredns --cluster $clusterName --version latest --region $region --force
    green "# KUBE-PROXY & COREDNS addons deployed successfully"
}

create_cluster_elb_addon() {
    
    clusterName="$1"
    region="$2"
    accountId="$3"
    
    curl -Os https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
    elbIamPolicyArn=$(aws iam create-policy --policy-name $clusterName"-AWSLoadBalancerControllerIAMPolicy" --policy-document file://iam_policy.json --query "Policy.Arn" --output text )
    rm iam_policy.json
    sleep 10
    green "# Completed creation of IAM Policy with ARN: $elbIamPolicyArn"
    yellow "# Creating iam service account for AWS Load Balancer Controller"
    eksctl create iamserviceaccount --cluster $clusterName --namespace kube-system --name aws-load-balancer-controller --region $region --role-name $clusterName"-AmazonEKSLoadBalancerControllerRole" --attach-policy-arn $elbIamPolicyArn --approve
    green "# Completed creation of iam service account for AWS Load Balancer Controller"
    yellow "# Deploying AWS Load Balancer Controller"
    helm --kube-apiserver $endpoint --kube-token $token --kube-ca-file $pemFile repo add eks https://aws.github.io/eks-charts && helm repo update eks
    helm --kube-apiserver $endpoint --kube-token $token --kube-ca-file $pemFile install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$clusterName --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=$region
}

gp3StorageClass() {
    kubectl --server $endpoint --token $token --certificate-authority $pemFile annotate sc gp2 storageclass.kubernetes.io/is-default-class-
  kubectl --server $endpoint --token $token --certificate-authority $pemFile apply -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
allowVolumeExpansion: true
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
EOF
}

calicoClusterRole() {
    kubectl --server $endpoint --token $token --certificate-authority $pemFile create namespace tigera-operator
    helm --kube-apiserver $endpoint --kube-token $token --kube-ca-file $pemFile repo add projectcalico https://docs.tigera.io/calico/charts
    helm --kube-apiserver $endpoint --kube-token $token --kube-ca-file $pemFile install calico projectcalico/tigera-operator --version v3.25.1 --namespace tigera-operator
  cat << EOF > append.yaml
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - patch
EOF
    kubectl --server $endpoint --token $token --certificate-authority $pemFile apply -f <(cat <(kubectl get clusterrole aws-node -o yaml) append.yaml)
    rm append.yaml
    kubectl --server $endpoint --token $token --certificate-authority $pemFile set env daemonset aws-node -n kube-system ANNOTATE_POD_IP=true
    kubectl --server $endpoint --token $token --certificate-authority $pemFile delete pods -n calico-system -l app.kubernetes.io/name=calico-kube-controllers
}

chronomReadonlyClusterRole() {
    clusterName="$1"
    region="$2"
    chronomReadOnlyUsername="$3"
    userArn=$(aws iam get-user --user-name $chronomReadOnlyUsername --query 'User.Arn' --output text)
    
    yellow "# Generating Temporary Credentials for the EKS Cluster Kubernetes API Server"
    token=$(aws eks get-token --cluster-name $clusterName --region $region --query "status.token" --output text)
    certificate=$(aws eks describe-cluster --name $clusterName --region $region --query "cluster.certificateAuthority.data" --output text)
    endpoint=$(aws eks describe-cluster --name $clusterName --region $region --query "cluster.endpoint" --output text)
    
    pemFile=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1).pem
    echo $certificate | base64 -d > $pemFile
    green "# Temporary Credentials generated successfully"
    
  kubectl --server $endpoint --token $token --certificate-authority $pemFile apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: chronomReadOnlyRole
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: chronomReadOnlyRoleBinding
subjects:
- kind: Group
  name: chronomReadOnlyGroup
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: chronomReadOnlyRole
  apiGroup: rbac.authorization.k8s.io
EOF
    eksctl create iamidentitymapping --cluster $clusterName --region $region --arn $userArn --group chronomReadOnlyGroup --username $chronomReadOnlyUsername
    
    rm $pemFile
}


create_cluster_complete(){
    clusterName="$1"
    region="$2"
    version="$3"
    nodeType="$4"
    minNodes="$5"
    maxNodes="$6"
    accountId="$7"
    
    ## Check if cluster name is available
    check_available_cluster_name $clusterName $region
    
    
    if [ ${args[--key-pair-name]} ]; then
        keyPairName=${args[--key-pair-name]}
        yellow "# Using existing RSA Key Pair: $keyPairName"
        sshKeysFlags="--ssh-access --ssh-public-key $keyPairName"
        
        elif [ ${args[--create-rsa-key]} ]; then
        yellow "# Creating a new RSA Key Pair"
        create_rsa_key_pair $clusterName $region
        green "# RSA Key Pair created successfully"
        green "# You can find the PEM file in $(pwd)/$clusterName-KeyPair.pem"
    fi
    
    yellow "# Creating a new EKS Cluster in the $region region"
    eksctl create cluster --name $clusterName --region $region --version $version --without-nodegroup --managed --with-oidc --alb-ingress-access --asg-access --node-private-networking --external-dns-access $sshKeysFlags
    green "# EKS Cluster created successfully"

    yellow "# Creating a new IAM Role with Admin Access for the Kubernetes API Server"
    accountId=$(aws sts get-caller-identity --query 'Account' --output text)
    adminRoleArn=$(aws iam create-role --role-name $clusterName"-AdminRole" --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"AWS\":\"$accountId\"},\"Condition\":{}}]}"  --query "Role.Arn" --output text)
    adminRolePolicyArn=$(aws iam create-policy --policy-name $clusterName"-AdminRolePolicy" --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AllowEKSAccess\",\"Effect\":\"Allow\",\"Action\":[\"eks:AccessKubernetesApi\",\"eks:DescribeCluster\"],\"Resource\":[\"arn:aws:eks:$region:$accountId:cluster/$clusterName\"]}]}" --query 'Policy.Arn' --output text)
    aws iam attach-role-policy --role-name $clusterName"-AdminRole" --policy-arn $adminRolePolicyArn
    eksctl create iamidentitymapping --cluster $clusterName --region $region --arn $adminRoleArn --group system:masters --username admin
    green "# IAM Role with Admin Access for the Kubernetes API Server created successfully"
    
    yellow "# Generating Temporary Credentials for the EKS Cluster Kubernetes API Server"
    token=$(aws eks get-token --cluster-name $clusterName --region $region --query "status.token" --output text)
    certificate=$(aws eks describe-cluster --name $clusterName --region $region --query "cluster.certificateAuthority.data" --output text)
    endpoint=$(aws eks describe-cluster --name $clusterName --region $region --query "cluster.endpoint" --output text)
    
    pemFile=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1).pem
    echo $certificate | base64 -d > $pemFile
    green "# Temporary Credentials generated successfully"
    
    yellow "# Creating VPC-CNI addon"
    create_vpc_cni_addon $clusterName $region
    green "# VPC-CNI addon configured successfully"
    
    yellow "# Creating a new EKS NodeGroup in the $region region with $nodeType instance type, minimum nodes: $minNodes, maximum nodes: $maxNodes"
    
    eksctl create nodegroup --cluster $clusterName --node-type $nodeType --nodes-min $minNodes --nodes-max $maxNodes $sshKeysFlags --managed --max-pods-per-node 110 --asg-access --node-private-networking --external-dns-access --region $region --alb-ingress-access --name $clusterName"-NodeGroup"
    green "# EKS NodeGroup created successfully"
    
    create_cluster_addons_bundle $clusterName $region
    
    yellow "# Deploying AWS Load Balancer Controller"
    create_cluster_elb_addon $clusterName $region $accountId
    green "# AWS Load Balancer Controller deployed successfully"
    
    yellow "# Deploying EBS CSI Driver"
    eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --region $region --cluster $clusterName --role-name $clusterName"-AmazonEKSEBSCSIDriverRole" --role-only --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve || red "# Warning:"
    eksctl create addon --name aws-ebs-csi-driver --cluster $clusterName --region $region --service-account-role-arn arn:aws:iam::$accountId:role/$clusterName"-AmazonEKSEBSCSIDriverRole" --force
    if [ ! ${args[--skip-gp3-setup]} ]; then
        gp3StorageClass
    fi
    green "# EBS CSI Driver deployed successfully"
    
    if [ ! ${args[--skip-calico-setup]} ]; then
        yellow "# Deploying Calico CNI"
        calicoClusterRole
        green "# Calico CNI deployed successfully"
    fi
    
    rm $pemFile
}