if [ -z "${args[--region]}" ]; then
    regionFlag="--all-regions"
    yellow "# Listing all clusters in all regions"
else
    regionFlag="--region ${args[--region]}"
    yellow "# Listing all clusters in ${args[--region]} region"
    
fi

eksctl get cluster $regionFlag