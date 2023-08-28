check_available_cluster_name() {
    clusterName="$1"
    region="$2"
    
    clustersInRegion=$(aws eks list-clusters --region $region --query "clusters" --output text) || { echo "Error: Unable to list clusters in region $region"; exit; }
    if [ "$(echo "$clustersInRegion" | grep -w "$clusterName")" ]; then
        red_bold "Error: Cluster name $clusterName already exists"
        red_bold "Please choose a different name or region"
        exit
    fi
}

check_available_key_pair_name() {
    
    keyPairName="$1"
    region="$2"
    keyPairsInRegion=$(aws ec2 describe-key-pairs --region $region --query "KeyPairs[].KeyName" --output text) || { echo "Error: Unable to list key pairs in region $region"; exit; }
    if [ "$(echo "$keyPairsInRegion" | grep -w "$keyPairName")" ]; then
        red_bold "Error: Key Pair $keyPairName already exists"
        red_bold "If you would like to use and existing Key Pair please pass the name using the --key-pair-name flag"
        red_bold "The Key Pair MUST be in the same region as the cluster"
        exit
    fi
    
}