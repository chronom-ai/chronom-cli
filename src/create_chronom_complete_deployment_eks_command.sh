echo "# Creating a new EKS Cluster in the ${args[--region]} region for Chronom"
echo "# Cluster Name: ${args[--name]}"
echo "# Cluster Version: ${args[--version]}"
echo "# Cluster Initial NodeGroup Type: ${args[--node-type]}, minimum nodes: ${args[--min-nodes]}, maximum nodes: ${args[--max-nodes]}"

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

echo -n "Please enter the Chronom Auth Secret that was provided to you: "
read -s chronomAuthSecret
while [ ${#chronomAuthSecret} -lt 120 ]
do
    echo
    echo "Chronom Auth Secret should be at least 120 characters long"
    echo -n "Please enter the Chronom Auth Secret that was provided to you: "
    read -s chronomAuthSecret
done

chronomAuthSecretLength=${#chronomAuthSecret}
chronomAuthMasked=$(printf '*%.0s' $(seq 1 $((chronomAuthSecretLength - 4))))
echo -e "\n Chronom Auth Secret: ${chronomAuthSecret:0:2}${chronomAuthMasked}${chronomAuthSecret: -2}"
echo "Chronom Auth Secret length: ${#chronomAuthSecret}"
echo "Is this correct? (y/n)"
read authAnswer
if [ "$authAnswer" != "${authAnswer#[Yy]}" ] ;then
    echo "Continuing..."
else
    echo "Exiting..."
    exit 1
fi

echo



echo -n "Please enter the Chronom Registry Password that was provided to you: "
read -s chronomRegistryPassword
while [ ${#chronomRegistryPassword} -lt 5 ]
do
    echo
    echo "Chronom Registry Password must be at least 5 characters long"
    echo -n "Please enter the Chronom Registry Password that was provided to you: "
    read -s chronomRegistryPassword
done

chronomRegistryPasswordLength=${#chronomRegistryPassword}
chronomRegistryMasked=$(printf '*%.0s' $(seq 1 $((chronomRegistryPasswordLength - 4))))

echo -e "\n Chronom Registry Password: ${chronomRegistryPassword:0:2}${chronomRegistryMasked}${chronomRegistryPassword: -2}"
echo "Chronom Registry Password length: ${#chronomRegistryPassword}"
echo "Is this correct? (y/n)"
read registryAnswer
if [ "$registryAnswer" != "${registryAnswer#[Yy]}" ] ;then
    echo "Continuing..."
else
    echo "Exiting..."
    exit 1
fi
echo

## Create a fully functional cluster tailored for Chronom
create_cluster_complete $clusterName $region $version $nodeType $minNodes $maxNodes $accountId

if [ ! ${args[--skip-certificate-setup]} ]; then
    ## Create a new certificate request for the chronom Deployment that will be created later
    create_certificate_request $dnsRecord $region
    echo "# Certificate Request created successfully"
    if [ ${args[--auto-validate]} ]; then
        echo "# Searching for Route53 Hosted Zone ID for $dnsRecord"
        find_create_compatible_dns_zone_cname $dnsRecord $validationName $validationValue
        echo "# Completed"
    else
        echo
        echo "# To manually create the CNAME record, please use the following values:"
        echo "Name: $validationName"
        echo "Value: $validationValue"
        echo "TTL: 300"
        echo "Type: CNAME"
        echo
    fi
fi

## Create Chronom user
echo "# Creating Chronom user"
create_chronom_user $chronomReadOnlyUsername true
echo "# Chronom user created successfully"


## Add Chronom user to the cluster
echo "# Adding $chronomReadOnlyUsername to the cluster"
chronomReadonlyClusterRole $clusterName $region $chronomReadOnlyUsername
echo "# $chronomReadOnlyUsername added to the cluster successfully"


## Deploy Chronom Helm Chart
echo "# Deploying Chronom Helm Chart in the cluster $clusterName"

flatAccessKey=$(echo $accessKey | jq -c . )

chronom_helm_install $clusterName $region $chronomRegistry $chronomRegistryUsername $chronomRegistryPassword $chronomAuthId $chronomAuthSecret $dnsRecord $chronomVersion $flatAccessKey $roleArn $chronomNamespace $ingressEnabled
echo "# Chronom Helm Chart deployed successfully"

if [ ! ${args[--skip-ingress-setup]} ]; then
    echo "# Searching for Route53 Hosted Zone ID for $dnsRecord"
    echo "# CNAME value will be: $ingressCname"
    find_create_compatible_dns_zone_cname $dnsRecord $dnsRecord $ingressCname
    echo "# Completed"
fi


echo "# Congratulations! Your Chronom cluster is ready to use"
echo "# You can access Chronom at https://$dnsRecord"