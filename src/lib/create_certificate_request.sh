create_certificate_request() {
    dnsRecord="$1"
    region="$2"
    
    certReqArn=$(aws acm request-certificate --domain-name $dnsRecord --validation-method DNS --region $region --output text --query "CertificateArn")
    sleep 10
    validationName=$(aws acm describe-certificate --region $region --certificate-arn $certReqArn --region $region --query "Certificate.DomainValidationOptions[?DomainName=='$dnsRecord'].ResourceRecord.Name" --output text)
    validationValue=$(aws acm describe-certificate --region $region --certificate-arn $certReqArn --region $region --query "Certificate.DomainValidationOptions[?DomainName=='$dnsRecord'].ResourceRecord.Value" --output text)
}

