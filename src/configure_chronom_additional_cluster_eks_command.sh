yellow "# Adding ${args[--chronom-readonly-username]} to ${args[--cluster-name]} in ${args[--region]} region"

## Parametrs normalization
clusterName=${args[--cluster-name]}
region=${args[--region]}
chronomReadonlyUsername=${args[--chronom-readonly-username]}

chronomReadonlyClusterRole $clusterName $region $chronomReadonlyUsername

green "# Done, You can now Scan the cluster with Chronom"