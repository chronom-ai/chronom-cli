yellow "# Creating a new EKS Cluster in the ${args[--region]} region"
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
chronomReadOnlyUsername=${args[--chronom-readonly-username]}
chronomReadOnlyUserarn=${args[--chronom-readonly-userarn]}
accountId=$(aws sts get-caller-identity --query 'Account' --output text)

tags='[{"Key":"Application","Value":"Chronom A.I."},{"Key":"DeployedAt","Value":"UTC-'$(date --utc +%Y-%m-%d:%H:%M:%S)'"}]'
eksctlTags="Application=Chronom A.I.,DeployedAt=UTC-$(date --utc +%Y-%m-%d:%H:%M:%S)"

create_cluster_complete "$clusterName" "$region" "$version" "$nodeType" "$minNodes" "$maxNodes" "$accountId" "$nodeTypeLarge" "$maxNodesLarge"

