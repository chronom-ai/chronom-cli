yellow "# Upgrading Chronom to version ${args[--version]} in cluster ${args[--cluster-name]}"
yellow "# Updating kubeconfig to use the cluster ${args[--cluster-name]} in the region ${args[--region]}"

## Parametrs normalization
clusterName=${args[--cluster-name]}
region=${args[--region]}
version=${args[--version]}
namespace=${args[--namespace]}

currentUser=$(aws sts get-caller-identity --query Arn --output text)
if [[ ! $currentUser =~ ^arn:aws:iam::[0-9]{12}:root$ ]]; then
    adminRoleArn=$(aws iam get-role --role-name "$clusterName-AdminRole" --query 'Role.Arn' --output text)
    eksctl utils write-kubeconfig --cluster "$clusterName" --region "$region" --set-kubeconfig-context --authenticator-role-arn "$adminRoleArn"
    elif [[ -n "${args[--i-am-root]}" ]]; then
    red "# You are currently logged in as root, but you passed the --i-am-root flag, so we will proceed with the configuration"
    red "# We feel obligated to warn you that this is not the recommended way, and you should use a user with admin permissions"
    eksctl utils write-kubeconfig --cluster "$clusterName" --region "$region" --set-kubeconfig-context
else
    red_bold "# You are currently logged in as root, and will not be able to assume the cluster's admin role"
    red_bold "# Please login as a user with admin permissions and try again"
    red_bold "# If you would like to use the root user, please pass the --i-am-root flag"
    exit 1
fi

kubectl config set-context --current --namespace "$namespace"

green "# Done! Proceeding to upgrade Chronom to version ${args[--version]} in cluster ${args[--cluster-name]}"

yellow "# Extracting Chronom Helm registry credentials"
registryCredentials=$(kubectl get secret chronom-registry-key -n "$namespace" -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode)

registryAddress=$(echo $registryCredentials | jq -r '.auths' | jq -r 'keys[0]')
registryUsername=$(echo $registryCredentials | jq -r '.auths' | jq -r '.[] | .username')
registryPassword=$(echo $registryCredentials | jq -r '.auths' | jq -r '.[] | .password')

helm registry login "$registryAddress" --username "$registryUsername" --password "$registryPassword"

helm get values -n "$namespace" chronom -o yaml > values.yaml

rabbitPass=$(kubectl get secret --namespace "$namespace" rabbitmq-chronom -o jsonpath="{.data.rabbitmq-password}" | base64 -d)

rabbitErlangCookie=$(kubectl get secret --namespace "$namespace" rabbitmq-chronom -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 -d)

helm upgrade -n "$namespace" chronom "oci://${registryAddress}/helm/chronom" --version "$version" -f ./values.yaml --set "rabbitmq.auth.password=$rabbitPass" --set "rabbitmq.auth.erlangCookie=$rabbitErlangCookie" || (red_bold "# Failed to upgrade Chronom to version $version in cluster $clusterName" && rm ./values.yaml && exit 1)

green "# Done! Chronom has been upgraded to version ${args[--version]} in cluster ${args[--cluster-name]}"
green "# Note that it might take a moment for the new version to completly replace the old one"

rm ./values.yaml