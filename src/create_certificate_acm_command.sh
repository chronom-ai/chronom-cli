yellow "# Creating a new Certificate Request for ${args[--dns-record]} in the ${args[--region]} region"

## Parametrs normalization
dnsRecord=${args[--dns-record]}
region=${args[--region]}

create_certificate_request $dnsRecord $region

green "# Certificate Request created successfully"

if [ ${args[--auto-validate]} ]; then
    
    yellow "# Searching for Route53 Hosted Zone ID for $dnsRecord"
    find_create_compatible_dns_zone_cname $dnsRecord $validationName $validationValue
    green "# Completed"
else
    echo
    green "# To manually create the CNAME record, please use the following values:"
    green "Name: $validationName"
    green "Value: $validationValue"
    green "TTL: 300"
    green "Type: CNAME"
    echo
    
fi