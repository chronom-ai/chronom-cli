# Write curl to https://auth.chronom.ai/
validate_chronom_auth() {
    statusCode=$(curl --write-out %{http_code} --silent --output /dev/null -X POST "https://auth.chronom.ai/organization/authenticate" -H "Content-Type: application/json" -d "{\"clientId\": \"$chronomAuthId\", \"clientSecret\": \"$chronomAuthSecret\"}")
    echo $statusCode
}
