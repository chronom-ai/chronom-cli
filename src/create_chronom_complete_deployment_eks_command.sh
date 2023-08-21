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
chronomRegistryUsername=${args[--chronom-registry-username]}
chronomAuthId=${args[--chronom-auth-id]}
chronomVersion=${args[--chronom-version]}
chronomRegistry=${args[--chronom-registry-name]}
chronomNamespace=${args[--chronom-namespace]}

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

yellow_bold "Please enter the Chronom Auth Secret that was provided to you: "
read -s chronomAuthSecret
while [ ${#chronomAuthSecret} -lt 127 ]
do
    echo
    red "Chronom Auth Secret must be 128 characters long"
    red "Please enter the Chronom Auth Secret that was provided to you: "
    read -s chronomAuthSecret
done

# # chronomAuthSecretLength=${#chronomAuthSecret}
# # chronomAuthMasked=$(printf '*%.0s' $(seq 1 $((chronomAuthSecretLength - 4))))
# # cyan_underlined "\n Chronom Auth Secret: ${chronomAuthSecret:0:2}${chronomAuthMasked}${chronomAuthSecret: -2}"
# # cyan_underlined "Chronom Auth Secret length: ${#chronomAuthSecret}"
# # cyan_underlined "Is this correct? (y/n)"
# # read authAnswer
# # if [ "$authAnswer" != "${authAnswer#[Yy]}" ] ;then
# #     green "Continuing..."
# # else
# #     red_bold "Exiting..."
# #     exit 1
# # fi

echo



yellow_bold "Please enter the Chronom Registry Password that was provided to you: "
read -s chronomRegistryPassword
while [ ${#chronomRegistryPassword} -lt 51 ]
do
    echo
    red "Chronom Registry Password must be 52 characters long"
    red "Please enter the Chronom Registry Password that was provided to you: "
    read -s chronomRegistryPassword
done

# # chronomRegistryPasswordLength=${#chronomRegistryPassword}
# # chronomRegistryMasked=$(printf '*%.0s' $(seq 1 $((chronomRegistryPasswordLength - 4))))

# # cyan_underlined "\n Chronom Registry Password: ${chronomRegistryPassword:0:2}${chronomRegistryMasked}${chronomRegistryPassword: -2}"
# # cyan_underlined "Chronom Registry Password length: ${#chronomRegistryPassword}"
# # cyan_underlined "Is this correct? (y/n)"
# # read registryAnswer
# # if [ "$registryAnswer" != "${registryAnswer#[Yy]}" ] ;then
# #     green "Continuing..."
# # else
# #     red_bold "Exiting..."
# #     exit 1
# # fi
# # echo

## Create a fully functional cluster tailored for Chronom
create_cluster_complete $clusterName $region $version $nodeType $minNodes $maxNodes $accountId

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

## Create Chronom user
yellow "# Creating Chronom user"
create_chronom_user $chronomReadOnlyUsername true
green "# Chronom user created successfully"


## Add Chronom user to the cluster
yellow "# Adding $chronomReadOnlyUsername to the cluster"
chronomReadonlyClusterRole $clusterName $region $chronomReadOnlyUsername
green "# $chronomReadOnlyUsername added to the cluster successfully"


## Deploy Chronom Helm Chart
yellow "# Deploying Chronom Helm Chart in the cluster $clusterName"

flatAccessKey=$(echo $accessKey | jq -c . )

chronom_helm_install $clusterName $region $chronomRegistry $chronomRegistryUsername $chronomRegistryPassword $chronomAuthId $chronomAuthSecret $dnsRecord $chronomVersion $flatAccessKey $roleArn $chronomNamespace $ingressEnabled
green "# Chronom Helm Chart deployed successfully"

if [ ! ${args[--skip-ingress-setup]} ]; then
    yellow "# Searching for Route53 Hosted Zone ID for $dnsRecord"
    yellow "# CNAME value will be: $ingressCname"
    find_create_compatible_dns_zone_cname $dnsRecord $dnsRecord $ingressCname
    green "# Completed"
fi


green_bold "# Congratulations! Your Chronom cluster is ready to use"
green_bold "# You can access Chronom at https://$dnsRecord"