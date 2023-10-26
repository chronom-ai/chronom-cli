# # green_bold "# Thank you for choosing Chronom"
# # green_bold '# Please type "yes" to confirm your concent to Chronom`s Terms of Use and EULA'
# # read -r tmsEula
# # echo
# # if [ "${tmsEula,,}" != "yes" ]; then
# #     red_bold 'You must agree to Chronom`s Terms of Use and EULA to proceed'
# #     exit 1
# # fi
# # green '# Thank you for agreeing to Chronom`s Terms of Use and EULA'
yellow "# Creating a new EKS Cluster in the ${args[--region]} region for Chronom"
yellow "# Cluster Name: ${args[--name]}"
yellow "# Cluster Version: ${args[--version]}"
yellow "# Cluster Initial NodeGroup Type: ${args[--node-type]}, minimum nodes: ${args[--min-nodes]}, maximum nodes: ${args[--max-nodes]}"

## Parametrs normalization
clusterName=${args[--name]}
region=${args[--region]}
version=${args[--version]}
nodeType=${args[--node-type]}
minNodes=${args[--min-nodes]}
maxNodes=${args[--max-nodes]}
dnsRecord=${args[--dns-record]}
chronomAuthId=${args[--chronom-auth-id]}
chronomVersion=${args[--chronom-version]}
chronomRegistry=${args[--chronom-registry-name]}
chronomNamespace=${args[--chronom-namespace]}
nodeTypeLarge=${args[--node-type-large]}
maxNodesLarge=${args[--max-nodes-large]}

# If getting any of the following parameters, make sure that all of them are provided
# parameters:
#${args[--ro-role-arn]}
#${args[--ro-user-access-key]}
#${args[--ro-user-secret-key]}
#${args[--asm-ro-user-access-key]}
#${args[--asm-ro-user-secret-key]}
#${args[--asm-rw-user-access-key]}
#${args[--asm-rw-user-secret-key]}

accountId=$(aws sts get-caller-identity --query 'Account' --output text)

if [ ${args[--chronom-readonly-username]} ]; then
    chronomReadOnlyUsername=${args[--chronom-readonly-username]}
else
    chronomReadOnlyUsername=$clusterName-ro-user
fi

if [ ${args[--skip-ingress-setup]} ]; then
    ingressEnabled=false
else
    ingressEnabled=true
fi

if [ ${args[--chronom-registry-username]} ]; then
    chronomRegistryUsername=${args[--chronom-registry-username]}
else
    chronomRegistryUsername=org-$chronomAuthId
fi


tags='[{"Key":"Application","Value":"Chronom A.I."},{"Key":"DeployedAt","Value":"UTC-'$(date --utc +%Y-%m-%d:%H:%M:%S)'"}]'

eksctlTags="Application=Chronom A.I.,DeployedAt=UTC-$(date --utc +%Y-%m-%d:%H:%M:%S)"

# validate_chronom_auth $chronomAuthId

yellow_bold "Please enter the Chronom Registry Password that was provided to you: "
read -s chronomRegistryPassword
while [ ${#chronomRegistryPassword} -lt 51 ]
do
    echo
    red "Chronom Registry Password must be 52 characters long"
    red "Please enter the Chronom Registry Password that was provided to you: "
    read -s chronomRegistryPassword
done

if [ -z "${args[--ro-role-arn]}" ] && [ -z "${args[--ro-user-access-key]}" ] && [ -z "${args[--ro-user-secret-key]}" ]; then
    ## Create Chronom user
    yellow "# Creating Chronom user"
    create_chronom_user "$chronomReadOnlyUsername" true
    green "# Chronom user created successfully"
else
    roleArn=${args[--ro-role-arn]}
    accessKey='{"accessKeyId": "'${args[--ro-user-access-key]}'", "secretAccessKey": "'${args[--ro-user-secret-key]}'"}'
fi


if [ -z ${args[--asm-ro-user-access-key]} ] && [ -z ${args[--asm-ro-user-secret-key]} ] && [ -z ${args[--asm-rw-user-access-key]} ] && [ -z ${args[--asm-rw-user-secret-key]} ]; then
    ## Create a new AWS Secret Manager Secrect to Store the AWS Credentials for the Chronom readonly users
    yellow "# Creating AWS Secret Manager Secrect $clusterName-chronom-readonly-users"
    create_asm_secret "$clusterName" "$region" "$tags"
    green "# AWS Secret Manager Secrect $clusterName-chronom-readonly-users created successfully"
else
    yellow "# Creating AWS Secret Manager Secrect $clusterName-chronom-readonly-users"
    roAccessKey='{"accessKeyId": "'${args[--asm-ro-user-access-key]}'", "secretAccessKey": "'${args[--asm-ro-user-secret-key]}'"}'
    rwAccessKey='{"accessKeyId": "'${args[--asm-rw-user-access-key]}'", "secretAccessKey": "'${args[--asm-rw-user-secret-key]}'"}'
    cleanAccessKey=$(echo $accessKey | awk '{gsub(/{|}/,"")}1')
    initialSecret="[{\"organizationId\":\"$chronomAuthId\",$cleanAccessKey,\"roleArn\":\"$roleArn\",\"accountId\":\"$accountId\",\"accountName\":\"Default Account\"}]"
    secretManagerArn=$(aws secretsmanager create-secret --name "aws-credentials-$chronomAuthId" --secret-string "$initialSecret" --region "$region" --tags "$tags" --query 'ARN' --output text)
    green "# AWS Secret Manager Secrect $clusterName-chronom-readonly-users created successfully"
fi


## Create a fully functional cluster tailored for Chronom
create_cluster_complete "$clusterName" "$region" "$version" "$nodeType" "$minNodes" "$maxNodes" "$accountId" "$nodeTypeLarge" "$maxNodesLarge"


if [ -z ${args[--asm-ro-user-access-key]} ] && [ -z ${args[--asm-ro-user-secret-key]} ] && [ -z ${args[--asm-rw-user-access-key]} ] && [ -z ${args[--asm-rw-user-secret-key]} ] && [ -z "${args[--ro-role-arn]}" ] && [ -z "${args[--ro-user-access-key]}" ] && [ -z "${args[--ro-user-secret-key]}" ]; then
    ## Add Chronom user to the cluster
    yellow "# Adding $chronomReadOnlyUsername to the cluster"
    chronomReadonlyClusterRole $clusterName $region $chronomReadOnlyUsername
    green "# $chronomReadOnlyUsername added to the cluster successfully"
fi

if [ ! ${args[--skip-certificate-setup]} ]; then
    ## Create a new certificate request for the chronom Deployment that will be created later
    create_certificate_request $dnsRecord $region
    green "# Certificate Request created successfully"
    if [ ${args[--auto-validate]} ]; then
        yellow "# Searching for Route53 Hosted Zone ID for $dnsRecord"
        find_create_compatible_dns_zone_cname $dnsRecord $validationName $validationValue
        green "# Completed"
    else
        echo
        cyan_bold "# To manually create the CNAME record, please use the following values:"
        cyan_bold "Name: $validationName"
        cyan_bold "Value: $validationValue"
        cyan_bold "TTL: 300"
        cyan_bold "Type: CNAME"
        echo
    fi
fi


## Deploy Chronom Helm Chart
yellow "# Deploying Chronom Helm Chart in the cluster $clusterName"

flatRoAccessKey=$(echo $roAccessKey | jq -c . )
flatRwAccessKey=$(echo $rwAccessKey | jq -c . )

chronom_helm_install $clusterName $region $chronomRegistry $chronomRegistryUsername $chronomRegistryPassword $chronomAuthId $chronomAuthSecret $dnsRecord $chronomVersion $chronomNamespace $flatRoAccessKey $flatRwAccessKey $ingressEnabled
green "# Chronom Helm Chart deployed successfully"

if [ ! ${args[--skip-ingress-setup]} ]; then
    yellow "# Searching for Route53 Hosted Zone ID for $dnsRecord"
    yellow "# CNAME value will be: $ingressCname"
    find_create_compatible_dns_zone_cname $dnsRecord $dnsRecord $ingressCname
    green "# Completed"
fi

green "# Please stend by while Chronom is being deployed"
sleep 120

green_bold "# Congratulations! Your Chronom cluster is ready to use"
green_bold "# If ever needed, an IAM Role $clusterName-AdminRole was created with Administrator Access to the Cluster API Server"
green_bold "# You can access Chronom at https://$dnsRecord"
green_bold "# Cluster Name: $clusterName in region $region"
