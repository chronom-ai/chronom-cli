yellow "# Adding ${args[--chronom-readonly-roleArn]} to ${args[--cluster-name]} in ${args[--region]} region"

## Parametrs normalization
clusterName=${args[--cluster-name]}
region=${args[--region]}
chronomReadonlyRoleArn=${args[--chronom-readonly-roleArn]}

configure_additional_cluster_eks "$clusterName" "$region" "$chronomReadonlyRoleArn"

green "# Done, You can now Scan the cluster with Chronom"