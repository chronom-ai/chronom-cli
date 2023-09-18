configure_additional_cluster_eks() {
    clusterName="$1"
    region="$2"
    chronomReadonlyRoleArn="$3"
    chronomPublicIp="$4"
    currentIp="$5"
    
    chronomReadOnlyRoleName=$(echo "$chronomReadonlyRoleArn" | cut -d'/' -f2)
    
    yellow "# Generating Temporary Credentials for the EKS Cluster Kubernetes API Server"
    token=$(aws eks get-token --cluster-name "$clusterName" --region "$region" --query "status.token" --output text)
    certificate=$(aws eks describe-cluster --name "$clusterName" --region "$region" --query "cluster.certificateAuthority.data" --output text)
    endpoint=$(aws eks describe-cluster --name "$clusterName" --region "$region" --query "cluster.endpoint" --output text)
    
    pemFile=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1).pem
    echo $certificate | base64 -d > $pemFile
    green "# Temporary Credentials generated successfully"
    
    if [[ -z $chronomPublicIp ]]; then
        
        yellow "# Checking wether the cluster is private or public"
        endpointIp=$(dig +short "$(echo $endpoint | sed 's/https:\/\///g')" | head -n1)
        if [[ $endpointIp =~ ^10\. || $endpointIp =~ ^172\.1[6-9]\. || $endpointIp =~ ^172\.2[0-9]\. || $endpointIp =~ ^172\.3[0-1]\. || $endpointIp =~ ^192\.168\. ]]; then
            red "# Cluster is private"
            red "# Unfortunately, we do not support private clusters at the moment"
            red "# Please add --chronom-public-ip and the public IP of Chronom to the command and try again"
            exit 1
        else
            green "# Cluster is reachable from the internet"
            green "# Proceeding with the configuration"
        fi
    fi
    
    
    if [[ -n $chronomPublicIp ]]; then
        permittedAddresses="${chronomPublicIp},${currentIp}/32"
        yellow "# Configuring the cluster to be accessible only from Chronom's IP"
        yellow "# This will take a few minutes, please stand by"
        eksctl utils set-public-access-cidrs --cluster "$clusterName" --region "$region" "$permittedAddresses" --approve
        eksctl utils update-cluster-endpoints --cluster "$clusterName" --region "$region" --public-access=true --private-access=true --approve
        green "# Cluster configured to be accessible only from Chronom's IP"
        yellow "# Checking wether user has access to the cluster"
        canI=$(kubectl --server $endpoint --token $token --certificate-authority $pemFile auth can-i '*' '*' --all-namespaces || echo "no")
        if [ "$canI" == "no" ]; then
            red "# User does not have access to the cluster"
            red "# Please execute the command with a user that has access to the cluster"
            red "# You may locate that information by going trough your Account's CloudTrail Event History - CreateCluster API calls"
            red "# For more information please go to - https://www.doit.com/resolving-the-your-current-user-or-role-does-not-have-access-to-kubernetes-objects-problem-on-aws-eks/"
            exit 1
        fi
        green "# User has access to the cluster, proceeding with the configuration"
    else
        yellow "# Checking wether user has access to the cluster"
        canI=$(kubectl --server $endpoint --token $token --certificate-authority $pemFile auth can-i '*' '*' --all-namespaces || echo "no")
        if [ "$canI" == "no" ]; then
            red "# User does not have access to the cluster"
            red "# Please execute the command with a user that has access to the cluster"
            exit 1
        fi
        green "# User has access to the cluster, proceeding with the configuration"
    fi
    
    
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
    eksctl create iamidentitymapping --cluster "$clusterName" --region "$region" --arn "$chronomReadonlyRoleArn" --group chronomReadOnlyGroup --username "$chronomReadOnlyRoleName"
    
    
    if [[ -n $chronomPublicIp ]]; then
        yellow "# Removing CloudShell Public IP from allowed CIDRs, please stand by"
        eksctl utils set-public-access-cidrs --cluster "$clusterName" --region "$region" "$chronomPublicIp" --approve
        green "# CloudShell Public IP removed from allowed CIDRs"
        green "# Process completed, you can now scan the cluster with Chronom"
    fi
    
    rm $pemFile
}