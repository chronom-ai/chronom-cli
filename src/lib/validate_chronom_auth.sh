# Write curl to https://auth.chronom.ai/
validate_chronom_auth() {
  echo "Validating Chronom Auth credentials..."
  local id=$1
  status_code=0

  while [ "$status_code" -ne 200 ]; do
    yellow_bold "Please enter the Chronom Auth Secret that was provided to you: "
    read -s chronomAuthSecret
    while [ ${#chronomAuthSecret} -lt 127 ]; do
      echo
      red "Chronom Auth Secret must be 128 characters long"
      red "Please enter the Chronom Auth Secret that was provided to you: "
      read -s chronomAuthSecret
    done

    local url="https://auth.chronom.ai/organization/authenticate"
    status_code=$(
      curl --write-out %{http_code} --silent --output /dev/null -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "{\"clientId\": \"$id\", \"clientSecret\": \"$chronomAuthSecret\"}"
    )

    if [ "$status_code" = 200 ]; then
      green "Credentials were validated successfully"
    else
      red "Credentials were not validated successfully"
    fi
  done

  return $status_code
}
