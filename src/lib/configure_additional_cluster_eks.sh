configure_additional_cluster_eks() {
    clusterName="$1"
    region="$2"
    chronomReadonlyRoleArn="$3"
    
    
    chronomReadOnlyRoleName=$(echo "$chronomReadonlyRoleArn" | cut -d'/' -f2)
    
    yellow "# Generating Temporary Credentials for the EKS Cluster Kubernetes API Server"
    token=$(aws eks get-token --cluster-name "$clusterName" --region "$region" --query "status.token" --output text)
    certificate=$(aws eks describe-cluster --name "$clusterName" --region "$region" --query "cluster.certificateAuthority.data" --output text)
    endpoint=$(aws eks describe-cluster --name "$clusterName" --region "$region" --query "cluster.endpoint" --output text)
    
    pemFile=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1).pem
    echo $certificate | base64 -d > $pemFile
    green "# Temporary Credentials generated successfully"
    
    
    
    ## @TODO - Add check if cluster is private, then if fails display it as a warning as well
    
    yellow "# Checking wether user has access to the cluster"
    canI=$(kubectl --server $endpoint --token $token --certificate-authority $pemFile auth can-i '*' '*' --all-namespaces || echo "no")
    if [ "$canI" == "no" ]; then
        red "# Unfortunately chronom-cli failed to reach the cluster"
        red "# The most common reason for this is either the user does not have access to the cluster or the cluster is private (or both)"
        endpointIp=$(dig +short "$(echo $endpoint | sed 's/https:\/\///g')" | head -n1)
        if [[ $endpointIp =~ ^10\. || $endpointIp =~ ^172\.1[6-9]\. || $endpointIp =~ ^172\.2[0-9]\. || $endpointIp =~ ^172\.3[0-1]\. || $endpointIp =~ ^192\.168\. ]]; then
            red "# The cluster is private, please make sure you are connected to the cluster's VPC - This might not be the issue, but it's worth checking :)"
        fi
        red "# Please make sure you execute the command with a user that has access to the cluster"
        cloudTrail=$(aws cloudtrail lookup-events --region "$region" --lookup-attributes "AttributeKey=ResourceName,AttributeValue=$clusterName" --output json)
        possibleUsers=$(echo "$cloudTrail" | jq -r '.Events[].Username' | sort | uniq)
        if [[ -n $possibleUsers ]]; then
            red "# According to CloudTrail, the following users might have access to the cluster:"
            echo "$possibleUsers"
        fi
        red "# If you are sure you have access to the cluster, please contact Chronom Support and we will be happy to assist you"
        red "# You can contact us via email at support@chronom.ai"
        exit 1
    fi
    green "# User has access to the cluster, proceeding with the configuration"
    
    
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
    
    rm $pemFile
}