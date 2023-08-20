if [ -z "${args[--region]}" ]; then
    regionFlag="--all-regions"
    echo "# Listing all clusters in all regions"
else
    regionFlag="--region ${args[--region]}"
    echo "# Listing all clusters in ${args[--region]} region"
    
fi

eksctl get cluster $regionFlag