create_chronom_user() {
    userName="$1"
    skip="$2"
    
    roleName=$userName-role
    
    tags='[{"Key":"Application","Value":"Chronom A.I."},{"Key":"DeployedAt","Value":"UTC-'$(date --utc +%Y-%m-%d:%H:%M:%S)'"}]'

    accountId=$(aws sts get-caller-identity --query 'Account' --output text)
    externalId=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9_\-' | fold -w 32 | head -n 1)
    aws iam create-user --user-name "$userName" --tags "$tags" --query 'User.Arn' --output text
    roleArn=$(aws iam create-role --role-name "$roleName" --tags "$tags" --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"AWS\":\"$accountId\"},\"Condition\":{}},{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::882668277426:root\"},\"Action\":\"sts:AssumeRole\",\"Condition\":{\"StringEquals\":{\"sts:ExternalId\":\"$externalId\"}}}]}" --query 'Role.Arn' --output text)
    assumePolicyArn=$(aws iam create-policy --policy-name "$userName-permissions-policy" --tags "$tags" --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AssumeRole\",\"Effect\":\"Allow\",\"Action\":[\"sts:AssumeRole\"],\"Resource\":[\"$roleArn\"]}]}" --query 'Policy.Arn' --output text)
    aws iam attach-user-policy --user-name "$userName" --policy-arn "$assumePolicyArn"
    curl -Os https://raw.githubusercontent.com/chronom-ai/chronom-cli/main/public_resources/chronom-readonly-additional-access-policy.json
    roPolicyArn=$(aws iam create-policy --tags "$tags" --policy-name "chronom-readonly-additional-access-policy" --policy-document file://chronom-readonly-additional-access-policy.json  --query 'Policy.Arn' --output text) || roPolicyArn=$(aws iam list-policies --query "Policies[?PolicyName=='chronom-readonly-additional-access-policy'].Arn" --output text --scope Local)
    rm chronom-readonly-additional-access-policy.json
    aws iam attach-role-policy --role-name "$roleName" --policy-arn "$roPolicyArn"
    aws iam attach-role-policy --role-name "$roleName" --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess"
    accessKey=$(aws iam create-access-key --user-name "$userName" --query '{accessKeyId:AccessKey.AccessKeyId, secretAccessKey:AccessKey.SecretAccessKey}' --output json)
    
    green "# Successfull created user $userName and role $roleArn"
    green "# Please upload the data from $userName-details.yaml to Chronom's Multi Account Management page"
    
    if [ ! "$skip" ]; then
        echo -e "accountId: \n  $accountId" > "$userName-details.yaml"
        echo -e "accessKeyId: \n  $(echo "$accessKey" | jq -r '.accessKeyId')" >> "$userName-details.yaml"
        echo -e "accessKeySecret: \n  $(echo "$accessKey" | jq -r '.secretAccessKey')" >> "$userName-details.yaml"
        echo -e "roleArn: \n  $roleArn" >> "$userName-details.yaml"

        # using JQ Create a json file containing the account id, role arn and access key id and secret for the user
        ### Disabled until support from UI us enabled
        # jq --arg accountId "$accountId" --arg accessKeyId "$(echo "$accessKey" | jq -r '.accessKeyId')" --arg accessKeySecret "$(echo "$accessKey" | jq -r '.secretAccessKey')" --arg roleArn "$roleArn" --arg externalId "$externalId" '. + {accountId: $accountId, accessKeyId: $accessKeyId, accessKeySecret: $accessKeySecret, roleArn: $roleArn, externalId: $externalId}' <<<'{}' > "chronom-details.json"



    fi
}