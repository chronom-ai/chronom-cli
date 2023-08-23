yellow "# Upgrading Chronom to version ${args[--version]} in cluster ${args[--cluster-name]}"
yellow "# Updating kubeconfig to use the cluster ${args[--cluster-name]} in the region ${args[--region]}"

## Parametrs normalization
clusterName=${args[--cluster-name]}
region=${args[--region]}
version=${args[--version]}
namespace=${args[--namespace]}

adminRoleArn=$(aws iam get-role --role-name $clusterName-AdminRole --query 'Role.Arn' --output text)
eksctl utils write-kubeconfig --cluster $clusterName --region $region --set-kubeconfig-context --authenticator-role-arn $adminRoleArn

green "# Done! Proceeding to upgrade Chronom to version ${args[--version]} in cluster ${args[--cluster-name]}"

yellow "# Extracting Chronom Helm registry credentials"
registryCredentials=$(kubectl get secret chronom-registry-key -n chronom -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode)

registryAddress=$(echo $registryCredentials | jq -r '.auths' | jq -r 'keys[0]')
registryUsername=$(echo $registryCredentials | jq -r '.auths' | jq -r '.[] | .username')
registryPassword=$(echo $registryCredentials | jq -r '.auths' | jq -r '.[] | .password')

helm registry login "$registryAddress" --username "$registryUsername" --password "$registryPassword"

helm upgrade -n "$namespace" chronom "oci://${registryAddress}/helm/chronom" --version "$version"

green "# Done! Chronom has been upgraded to version ${args[--version]} in cluster ${args[--cluster-name]}"
green "# Note that it might take a moment for the new version to completly replace the old one"