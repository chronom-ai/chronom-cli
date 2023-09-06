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