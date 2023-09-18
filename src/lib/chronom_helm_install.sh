chronom_helm_install() {
    clusterName="$1"
    region="$2"
    registry="$3"
    registryUsername="$4"
    registryPassword="$5"
    authClientId="$6"
    authClientSecret="$7"
    dnsRecord="$8"
    chronomVersion="$9"
    namespace="${10}"
    roAccessKey=${11}
    rwAccessKey=${12}
    ingressEnabled="${13}"
    yellow "# Installing Chronom A.I Helm Chart in the cluster $clusterName"

    ## If any of the 13 variable listed above is empty, exit with error saying that the variable is empty by printing the name of the variable
    
    
    token=$(aws eks get-token --cluster-name $clusterName --region $region --query "status.token" --output text)
    certificate=$(aws eks describe-cluster --name $clusterName --region $region --query "cluster.certificateAuthority.data" --output text)
    endpoint=$(aws eks describe-cluster --name $clusterName --region $region --query "cluster.endpoint" --output text)
    
    pemFile=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1).pem
    echo $certificate | base64 -d > $pemFile
    
    helm --kube-apiserver $endpoint --kube-token $token --kube-ca-file $pemFile registry login $registry --username $registryUsername --password $registryPassword || (echo -e "Failed to login to registry with command: \n |helm --kube-apiserver $endpoint --kube-token $token --kube-ca-file $pemFile registry login $registry --username $registryUsername --password $registryPassword|" && exit 1)
    
    imageCredentials='{"registry": "'$registry'","username": "'$registryUsername'","password": "'$registryPassword'"}'
    
    auth='{"clientId": "'$authClientId'", "clientSecret": "'$authClientSecret'"}'
    
    helm --kube-apiserver $endpoint --kube-token $token --kube-ca-file $pemFile install chronom oci://$registry/helm/chronom --version "$chronomVersion" --set "dnsRecord=$dnsRecord" --set "ingressEnabled=$ingressEnabled" --set "initRegion=$region" --set "secretRegion=$region" --set-json="auth=$auth" --set-json="imageCredentials=$imageCredentials" --set-json="backend=$rwAccessKey" --set-json "awsscanner=$roAccessKey" --namespace "$namespace" --create-namespace || (echo -e "Failed to install HelmChart with command: \n |helm --kube-apiserver $endpoint --kube-token $token --kube-ca-file $pemFile install chronom oci://$registry/helm/chronom --version \"$chronomVersion\" --set \"dnsRecord=$dnsRecord\" --set \"ingressEnabled=$ingressEnabled\" --set \"initRegion=$region\" --set \"secretRegion=$region\" --set-json=\"auth=$auth\" --set-json=\"imageCredentials=$imageCredentials\" --set-json=\"backend=$rwAccessKey\" --set-json \"awsscanner=$roAccessKey\" --namespace \"$namespace\" --create-namespace|" && exit 1)
    
    green "# Chronom A.I Helm Chart installed successfully"
    yellow "# Waiting for Ingress resource provisioning"
    sleep 10
    
    ingressCname=$(kubectl --server $endpoint --token $token --certificate-authority $pemFile get ingress -n $namespace -o jsonpath='{.items[].status.loadBalancer.ingress[0].hostname}')
    
    while [[ $ingressCname != *"$region.elb.amazonaws.com" ]]
    do
        sleep 15
        ingressCname=$(kubectl --server $endpoint --token $token --certificate-authority $pemFile get ingress -n $namespace -o jsonpath='{.items[].status.loadBalancer.ingress[0].hostname}')
    done
    green "# Ingress resource provisioned successfully"
    
    rm $pemFile
}
