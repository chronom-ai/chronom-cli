echo "# Creating a new Certificate Request for ${args[--dns-record]} in the ${args[--region]} region"

## Parametrs normalization
dnsRecord=${args[--dns-record]}
region=${args[--region]}

create_certificate_request $dnsRecord $region

echo "# Certificate Request created successfully"

if [ ${args[--auto-validate]} ]; then
    
    echo "# Searching for Route53 Hosted Zone ID for $dnsRecord"
    find_create_compatible_dns_zone_cname $dnsRecord $validationName $validationValue
    echo "# Completed"
else
    echo
    echo "# To manually create the CNAME record, please use the following values:"
    echo "Name: $validationName"
    echo "Value: $validationValue"
    echo "TTL: 300"
    echo "Type: CNAME"
    echo
    
fi