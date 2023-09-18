## Parametrs normalization
clusterName=${args[--cluster-name]}
region=${args[--region]}
version=${args[--version]}
namespace=${args[--namespace]}

## If version is lower then 0.1.0 throw error
if [[ "$version" < "0.1.0" ]]; then
    red "Version $version is too low, please contact support at support@chronom.ai"
    exit 1
fi

yellow "# Upgrading Chronom to version ${args[--version]} in cluster ${args[--cluster-name]}"
yellow "# Updating kubeconfig to use the cluster ${args[--cluster-name]} in the region ${args[--region]}"

adminRoleArn=$(aws iam get-role --role-name "$clusterName-AdminRole" --query 'Role.Arn' --output text)
eksctl utils write-kubeconfig --cluster "$clusterName" --region "$region" --set-kubeconfig-context --authenticator-role-arn "$adminRoleArn"
kubectl config set-context --current --namespace "$namespace"

green "# Done! Proceeding to upgrade Chronom to version ${args[--version]} in cluster ${args[--cluster-name]}"

yellow "# Installing Latest version of Keda"
helm repo add kedacore https://kedacore.github.io/charts && helm repo update
helm upgrade -i keda kedacore/keda --namespace keda --create-namespace
green "# Done! Proceeding to upgrade Chronom to version ${args[--version]} in cluster ${args[--cluster-name]}"


yellow "# Extracting Chronom Helm registry credentials"
registryCredentials=$(kubectl get secret chronom-registry-key -n chronom -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode)

registryAddress=$(echo $registryCredentials | jq -r '.auths' | jq -r 'keys[0]')
registryUsername=$(echo $registryCredentials | jq -r '.auths' | jq -r '.[] | .username')
registryPassword=$(echo $registryCredentials | jq -r '.auths' | jq -r '.[] | .password')

helm registry login "$registryAddress" --username "$registryUsername" --password "$registryPassword"

helm get values -n "$namespace" chronom -o yaml > values.yaml

rabbitPass=$(kubectl get secret --namespace "$namespace" rabbitmq-chronom -o jsonpath="{.data.rabbitmq-password}" | base64 -d)

rabbitErlangCookie=$(kubectl get secret --namespace "$namespace" rabbitmq-chronom -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 -d)

helm upgrade -n "$namespace" chronom "oci://${registryAddress}/helm/chronom" --version "$version" -f ./values.yaml --set "rabbitmq.auth.password=$rabbitPass" --set "rabbitmq.auth.erlangCookie=$rabbitErlangCookie"

green "# Done! Chronom has been upgraded to version ${args[--version]} in cluster ${args[--cluster-name]}"
green "# Note that it might take a moment for the new version to completly replace the old one"

rm ./values.yaml