red_bold "# This command is not supported yet, please contact Chronom support if you have any issues"
# # yellow "# Adding ${args[--chronom-readonly-roleArn]} to ${args[--cluster-name]} in ${args[--region]} region"

# # ## Parametrs normalization
# # clusterName=${args[--cluster-name]}
# # region=${args[--region]}
# # chronomReadonlyRoleArn=${args[--chronom-readonly-roleArn]}

# # ## If --chronom-public-ip is provided, print a confirmation message and set the variable chronomPublicIp to the provided value
# # if [[ -n ${args[--chronom-public-ip]} ]]; then
# #     currentIp=$(curl -s https://ifconfig.me/ip)
# #     chronomPublicIp="${args[--chronom-public-ip]}/32"
# #     yellow_bold "# You have provided a public IP for Chronom: $chronomPublicIp"
# #     red_bold "# NOTE! This will convert your cluster to be Public, but only accessible from Chronom's IP"
# #     red_bold "# The action is an OVERWRITE - If you have any other IP that should/already has access, please press CTRL+C and contact Chronom support for specific instructions"
# #     yellow_bold "# Please press enter to continue, or CTRL+C to cancel"
# #     read -r
# # fi

# # configure_additional_cluster_eks "$clusterName" "$region" "$chronomReadonlyRoleArn" "$chronomPublicIp" "$currentIp"

# # green "# Done, You can now Scan the cluster with Chronom"