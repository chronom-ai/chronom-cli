validate_available_aws_region() {
  [[ ! "$1" == "il-central-1" ]] || echo "At the time there is an unmitigated issue with the AWS API in this region. Please choose a different region."
  [[ ! "$1" == "us-east-1" ]] || echo "At the time there is an Issue with the Availability Zones. please choose a different region."
}