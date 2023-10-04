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
    
    
    yellow "# Checking wether user has access to the cluster"
    canI=$(kubectl --server $endpoint --token $token --certificate-authority $pemFile auth can-i '*' '*' --all-namespaces || echo "no")
    if [ "$canI" == "no" ]; then
        red "# User does not have access to the cluster"
        red "# Please execute the command with a user that has access to the cluster"
        cloudTrail=$(aws cloudtrail lookup-events --region "$region" --lookup-attributes "AttributeKey=ResourceName,AttributeValue=$clusterName" --output json)
        possibleUsers=$(echo "$cloudTrail" | jq -r '.Events[].Username' | sort | uniq)
        if [[ -n $possibleUsers ]]; then
            red "# According to CloudTrail, the following users might have access to the cluster:"
            echo "$possibleUsers"
        fi
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