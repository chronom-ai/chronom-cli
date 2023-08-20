create_rsa_key_pair() {
    
    clusterName="$1"
    region="$2"
    
    ## Check if key pair name is available
    check_available_key_pair_name $clusterName-KeyPair $region
    aws ec2 create-key-pair --key-name $clusterName-KeyPair --region $region --query "KeyMaterial" --output text > ~/.ssh/$clusterName-KeyPair.pem
    sshKeysFlags="--ssh-access --ssh-public-key $clusterName-KeyPair"
}

create_vpc_cni_addon() {
    clusterName="$1"
    region="$2"
    
    
    eksctl create addon --name vpc-cni --cluster $clusterName --version latest --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy --region $region --force
    echo "# VPC-CNI addon created successfully"
    echo "# Configuring VPC-CNI addon to support prefix delegation"
    kubectl set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true
    kubectl set env ds aws-node -n kube-system WARM_PREFIX_TARGET=1
}


create_cluster_addons_bundle() {
    
    clusterName="$1"
    region="$2"
    
    echo "# Deploying Metrics Server"
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    echo "# Metrics Server deployed successfully"
    
    echo "# Deploying Cluster Autoscaler"
    kubectl apply -f <(curl -s https://chronompublicresources.s3.eu-north-1.amazonaws.com/k8sYamls/autoscaler.yaml | sed "s/<YOUR CLUSTER NAME>/$clusterName/g" )
    echo "# Cluster Autoscaler deployed successfully"
    
    
    echo "# Deploying KUBE-PROXY & COREDNS addons"
    eksctl create addon --name kube-proxy --cluster $clusterName --version latest --region $region --force
    eksctl create addon --name coredns --cluster $clusterName --version latest --region $region --force
    echo "# KUBE-PROXY & COREDNS addons deployed successfully"
}

create_cluster_elb_addon() {
    
    clusterName="$1"
    region="$2"
    accountId="$3"
    
    
    curl -Os https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
    elbIamPolicyArn=$(aws iam create-policy --policy-name $clusterName"-AWSLoadBalancerControllerIAMPolicy" --policy-document file://iam_policy.json --query "Policy.Arn" --output text ) 
    rm iam_policy.json
    sleep 10
    echo "# Completed creation of IAM Policy with ARN: $elbIamPolicyArn"
    echo "# Creating iam service account for AWS Load Balancer Controller"
    eksctl create iamserviceaccount --cluster $clusterName --namespace kube-system --name aws-load-balancer-controller --region $region --role-name $clusterName"-AmazonEKSLoadBalancerControllerRole" --attach-policy-arn $elbIamPolicyArn --approve
    echo "# Completed creation of iam service account for AWS Load Balancer Controller"
    eksctl get iamserviceaccount --cluster $clusterName --region $region
    echo "# Deploying AWS Load Balancer Controller"
    helm repo add eks https://aws.github.io/eks-charts && helm repo update eks
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$clusterName --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=$region
}

gp3StorageClass() {
    kubectl annotate sc gp2 storageclass.kubernetes.io/is-default-class-
  kubectl apply -f - <<EOF
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
    kubectl create namespace tigera-operator
    helm install calico projectcalico/tigera-operator --version v3.25.1 --namespace tigera-operator
  cat << EOF > append.yaml
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - patch
EOF
    kubectl apply -f <(cat <(kubectl get clusterrole aws-node -o yaml) append.yaml)
    rm append.yaml
    kubectl set env daemonset aws-node -n kube-system ANNOTATE_POD_IP=true
    kubectl delete pods -n calico-system -l app.kubernetes.io/name=calico-kube-controllers
}

chronomReadonlyClusterRole() {
    clusterName="$1"
    region="$2"
    chronomReadOnlyUsername="$3"
    userArn=$(aws iam get-user --user-name $chronomReadOnlyUsername --query 'User.Arn' --output text)
    
  kubectl apply -f - <<EOF
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
        echo "# Using existing RSA Key Pair: $keyPairName"
        sshKeysFlags="--ssh-access --ssh-public-key $keyPairName"
        
        elif [ ${args[--create-rsa-key]} ]; then
        echo "# Creating a new RSA Key Pair"
        create_rsa_key_pair $clusterName $region
        echo "# RSA Key Pair created successfully"
        echo "# You can find the PEM file in $(pwd)/$clusterName-KeyPair.pem"
    fi
    
    echo "# Creating a new EKS Cluster in the $region region"
    eksctl create cluster --name $clusterName --region $region --version $version --without-nodegroup --managed --with-oidc --alb-ingress-access --asg-access --node-private-networking --external-dns-access $sshKeysFlags
    echo "# EKS Cluster created successfully"
    
    echo "# Creating VPC-CNI addon"
    create_vpc_cni_addon $clusterName $region
    echo "# VPC-CNI addon configured successfully"
    
    echo "# Creating a new EKS NodeGroup in the $region region with $nodeType instance type, minimum nodes: $minNodes, maximum nodes: $maxNodes"
    
    eksctl create nodegroup --cluster $clusterName --node-type $nodeType --nodes-min $minNodes --nodes-max $maxNodes $sshKeysFlags --managed --max-pods-per-node 110 --asg-access --node-private-networking --external-dns-access --region $region --alb-ingress-access
    echo "# EKS NodeGroup created successfully"
    
    create_cluster_addons_bundle $clusterName $region
    
    echo "# Deploying AWS Load Balancer Controller"
    create_cluster_elb_addon $clusterName $region $accountId
    echo "# AWS Load Balancer Controller deployed successfully"
    
    echo "# Deploying EBS CSI Driver"
    eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --region $region --cluster $clusterName --role-name $clusterName"-AmazonEKSEBSCSIDriverRole" --role-only --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve || echo "# Warning:"
    eksctl create addon --name aws-ebs-csi-driver --cluster $clusterName --region $region --service-account-role-arn arn:aws:iam::$accountId:role/$clusterName"-AmazonEKSEBSCSIDriverRole" --force
    if [ ! ${args[--skip-gp3-setup]} ]; then
        gp3StorageClass
    fi
    echo "# EBS CSI Driver deployed successfully"
    
    if [ ! ${args[--skip-calico-setup]} ]; then
        echo "# Deploying Calico CNI"
        calicoClusterRole
        echo "# Calico CNI deployed successfully"
    fi
}