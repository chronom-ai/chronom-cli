yellow "# Upgrading Chronom to version 0.0.3 in cluster ${args[--cluster-name]}"
yellow "# Updating kubeconfig to use the cluster ${args[--cluster-name]} in the region ${args[--region]}"

## Parametrs normalization
clusterName=${args[--cluster-name]}
region=${args[--region]}
version="0.0.3"
namespace=${args[--namespace]}

tags='[{"Key":"Application","Value":"Chronom A.I."},{"Key":"DeployedAt","Value":"UTC-'$(date --utc +%Y-%m-%d:%H:%M:%S)'"}]'

adminRoleArn=$(aws iam get-role --role-name $clusterName-AdminRole --query 'Role.Arn' --output text)
eksctl utils write-kubeconfig --cluster $clusterName --region $region --set-kubeconfig-context --authenticator-role-arn $adminRoleArn

kubectl config set-context --current --namespace $namespace

green "# Done! Proceeding to upgrade Chronom to version ${args[--version]} in cluster ${args[--cluster-name]}"

yellow "# Extracting relevant parameters from existing version"
chronomAuthId=$(kubectl get secrets auth-chronom-chronom-secret -o jsonpath='{.data.AUTH_CLIENT_ID}' | base64 -d)
green "# Organization ID: $chronomAuthId"

accountId=$(aws sts get-caller-identity --query 'Account' --output text)

secretContent=$(kubectl get secrets awsscanner-chronom-chronom-secret -o jsonpath='{.data}' | jq --arg organizationId "$chronomAuthId" --arg accountId "$accountId" -c '[{accessKeyId: (.AWS_ACCESS_KEY_ID | @base64d),  secretAccessKey: (.AWS_SECRET_ACCESS_KEY | @base64d),  roleArn: (.ROLE_ARN | @base64d),organizationId: $organizationId,accountId: $accountId}]')

green "# Successfuly constructed secret content"
yellow "# Creating Secret"
secretManagerArn=$(aws secretsmanager create-secret --name "aws-credentials-$chronomAuthId" --secret-string "$secretContent" --region "$region" --tags "$tags" --query 'ARN' --output text)
aws iam create-user --user-name "$clusterName-asm-ro-user" --tags "$tags"
roAccessKey=$(aws iam create-access-key --user-name "aws-credentials-$chronomAuthId-ro-user" --query '{accessKeyId:AccessKey.AccessKeyId, secretAccessKey:AccessKey.SecretAccessKey}' --output json)
roPolicyArn=$(aws iam create-policy --tags "$tags" --policy-name "aws-credentials-$chronomAuthId-ro-user-policy" --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"readonly\",\"Effect\":\"Allow\",\"Action\":[\"secretsmanager:GetSecretValue\"],\"Resource\":\"$secretManagerArn\"}]}" --query 'Policy.Arn' --output text)
aws iam attach-user-policy --user-name "aws-credentials-$chronomAuthId-ro-user" --policy-arn "$roPolicyArn"
aws iam create-user --user-name "aws-credentials-$chronomAuthId-rw-user" --tags "$tags"
rwAccessKey=$(aws iam create-access-key --user-name "aws-credentials-$chronomAuthId-rw-user" --query '{accessKeyId:AccessKey.AccessKeyId, secretAccessKey:AccessKey.SecretAccessKey}' --output json)
rwPolicyArn=$(aws iam create-policy --policy-name "aws-credentials-$chronomAuthId-rw-user-policy" --tags "$tags" --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"readonly\",\"Effect\":\"Allow\",\"Action\":[\"secretsmanager:GetSecretValue\",\"secretsmanager:UpdateSecret\",\"secretsmanager:PutSecretValue\"],\"Resource\":\"$secretManagerArn\"}]}" --query 'Policy.Arn' --output text)
aws iam attach-user-policy --user-name "aws-credentials-$chronomAuthId-rw-user" --policy-arn "$rwPolicyArn"
green "# Successfully created Secret Manager"

yellow "# Updating role IAM Policy"
curl -Os https://raw.githubusercontent.com/chronom-ai/chronom-cli/main/public_resources/readonly-policy.json

aws iam create-policy-version --policy-arn "arn:aws:iam::${accountId}:policy/${clusterName}-role-permissions-policy" --policy-document file://readonly-policy.json --set-as-default

rm readonly-policy.json

green "# Successfully updated role IAM Policy"

yellow "# Updating role permission over the cluster"
eksctl create iamidentitymapping --cluster "$clusterName" --arn "arn:aws:iam::${accountId}:role/${clusterName}-role" --group chronomReadOnlyGroup --username "${clusterName}-role"

yellow "# Extracting Chronom Helm registry credentials"
registryCredentials=$(kubectl get secret chronom-registry-key -n chronom -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode)

registryAddress=$(echo $registryCredentials | jq -r '.auths' | jq -r 'keys[0]')
registryUsername=$(echo $registryCredentials | jq -r '.auths' | jq -r '.[] | .username')
registryPassword=$(echo $registryCredentials | jq -r '.auths' | jq -r '.[] | .password')

helm registry login "$registryAddress" --username "$registryUsername" --password "$registryPassword"

helm upgrade -n "$namespace" chronom "oci://${registryAddress}/helm/chronom" --version "$version"  --set secretRegion=$region --set-json="backend=$rwAccessKey" --set-json "awsscanner=$roAccessKey" 