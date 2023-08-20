echo "# Creating a new EKS Cluster in the ${args[--region]} region"
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
chronomReadOnlyUsername=${args[--chronom-readonly-username]}
chronomReadOnlyUserarn=${args[--chronom-readonly-userarn]}
accountId=$(aws sts get-caller-identity --query 'Account' --output text)

create_cluster_complete $clusterName $region $version $nodeType $minNodes $maxNodes $chronomReadOnlyUsername $chronomReadOnlyUserarn $accountId

