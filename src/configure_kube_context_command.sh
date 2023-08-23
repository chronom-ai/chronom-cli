yellow "# Configuring Local Kubectl Context to use the Cluster ${args[--name]} in the region ${args[--region]}"

## Parametrs normalization
clusterName=${args[--name]}
region=${args[--region]}

if [ -z "${args[--use-admin-role]}" ]; then
    yellow "# Using the Admin role $clusterName-AdminRole"
    adminRoleArn=$(aws iam get-role --role-name $clusterName-AdminRole --query 'Role.Arn' --output text)
    adminRoleArnFlag="--authenticator-role-arn $adminRoleArn"
fi

yellow "# Updating kubeconfig"

eksctl utils write-kubeconfig --cluster $clusterName --region $region --set-kubeconfig-context $adminRoleArnFlag

green "# Done! You can now use kubectl / Helm to manage $clusterName"