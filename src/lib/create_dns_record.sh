
create_cname_record() {
    validationName="$1"
    validationValue="$2"
    dnsZoneId="$3"
    
    route53BatchRecord=$(cat <<EOM
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$validationName",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$validationValue"
          }
        ]
      }
    }
  ]
}
EOM
)
    aws route53 change-resource-record-sets --hosted-zone-id "$dnsZoneId" --change-batch "$route53BatchRecord"
}

find_create_compatible_dns_zone_cname() {
    dnsZone="$1"
    validationName="$2"
    validationValue="$3"
    
    zonesFound=0
    
    while [[ $zonesFound == 0 ]]; do
        SUBDOMAIN="${dnsZone#*.}"
        ZONE_CHECK=$(aws route53 list-hosted-zones-by-name --dns-name "$SUBDOMAIN" --query 'HostedZones' 2>&1)
        if [[ $ZONE_CHECK != *"[]"* ]]; then
            zonesFound=1
        fi
        
        if [[ $SUBDOMAIN != *"."* ]]; then
            zonesFound=2
        fi
        
        dnsZone=$SUBDOMAIN
    done
    if [[ $zonesFound == 1 ]]; then
        dnsZoneId=$(aws route53 list-hosted-zones-by-name --dns-name "$dnsZone" --query "HostedZones[?Name=='$dnsZone.'].Id" --output text)
        dnsZoneId=${dnsZoneId##*/}
        echo "# Route53 Hosted Zone ID found: $dnsZoneId, Zone: $dnsZone, Creating CNAME record..."
        create_cname_record $validationName $validationValue $dnsZoneId
        echo "# CNAME record created successfully"
    else
        echo "# No Route53 Hosted Zone found for $dnsZone"
        echo
        echo "# To manually create the CNAME record, please use the following values:"
        echo "Name: $validationName"
        echo "Value: $validationValue"
        echo "TTL: 300"
        echo "Type: CNAME"
        echo
    fi
}
