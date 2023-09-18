yellow "# Adding ${args[--chronom-readonly-roleArn]} to ${args[--cluster-name]} in ${args[--region]} region"

## Parametrs normalization
clusterName=${args[--cluster-name]}
region=${args[--region]}
chronomReadonlyRoleArn=${args[--chronom-readonly-roleArn]}

## If --chronom-public-ip is provided, print a confirmation message and set the variable chronomPublicIp to the provided value
if [[ -n ${args[--chronom-public-ip]} ]]; then
    chronomPublicIp=${args[--chronom-public-ip]}/32
    yellow_bold "# You have provided a public IP for Chronom: $chronomPublicIp"
    red_bold "# NOTE! This will convert your cluster to be Public, but only accessible from Chronom's IP"
    red_bold "# If you have any other IP that should/already has access, please press CTRL+C and contact Chronom support for specific instructions"
    yellow_bold "# Please press enter to continue, or CTRL+C to cancel"
    read -r
fi

configure_additional_cluster_eks "$clusterName" "$region" "$chronomReadonlyRoleArn" "$chronomPublicIp"

green "# Done, You can now Scan the cluster with Chronom"