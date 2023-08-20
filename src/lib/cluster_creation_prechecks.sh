check_available_cluster_name() {
    clusterName="$1"
    region="$2"
    
    clustersInRegion=$(aws eks list-clusters --region $region --query "clusters" --output text) || { echo "Error: Unable to list clusters in region $region"; exit; }
    if [ "$(echo "$clustersInRegion" | grep -w "$clusterName")" ]; then
        echo "Error: Cluster name $clusterName already exists"
        echo "Please choose a different name or region"
        exit
    fi
}

check_available_key_pair_name() {
    
    keyPairName="$1"
    region="$2"
    keyPairsInRegion=$(aws ec2 describe-key-pairs --region $region --query "KeyPairs[].KeyName" --output text) || { echo "Error: Unable to list key pairs in region $region"; exit; }
    # [ ! $(echo "$keyPairsInRegion" | grep -w "$keyPairName") ] || { echo "Error: Key Pair $keyPairName already exists" ; exit; }
    if [ "$(echo "$keyPairsInRegion" | grep -w "$keyPairName")" ]; then
        echo "Error: Key Pair $keyPairName already exists"
        echo "If you would like to use and existing Key Pair please pass the name using the --key-pair-name flag"
        echo "The Key Pair MUST be in the same region as the cluster"
        exit
    fi
    
}