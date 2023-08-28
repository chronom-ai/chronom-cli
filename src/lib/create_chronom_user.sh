create_chronom_user() {
    userName="$1"
    skip="$2"
    
    roleName=$userName-role
    
    tags='[{"Key":"Application","Value":"Chronom A.I."},{"Key":"DeployedAt","Value":"UTC-'$(date --utc +%Y-%m-%d:%H:%M:%S)'"}]'

    accountId=$(aws sts get-caller-identity --query 'Account' --output text)
    aws iam create-user --user-name "$userName" --tags "$tags" --query 'User.Arn' --output text
    roleArn=$(aws iam create-role --role-name "$roleName" --tags "$tags" --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"AWS\":\"$accountId\"},\"Condition\":{}}]}" --query 'Role.Arn' --output text)
    assumePolicyArn=$(aws iam create-policy --policy-name "$userName-permissions-policy" --tags "$tags" --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AssumeRole\",\"Effect\":\"Allow\",\"Action\":[\"sts:AssumeRole\"],\"Resource\":[\"$roleArn\"]},{\"Sid\":\"AllowEKSAccess\",\"Effect\":\"Allow\",\"Action\":[\"eks:AccessKubernetesApi\"],\"Resource\":[\"arn:aws:eks:*:*:cluster/*\"]}]}" --query 'Policy.Arn' --output text)
    aws iam attach-user-policy --user-name "$userName" --policy-arn "$assumePolicyArn"
    curl -Os https://raw.githubusercontent.com/chronom-ai/chronom-cli/main/public_resources/readonly-policy.json
    roPolicyArn=$(aws iam create-policy --tags "$tags" --policy-name "$roleName-permissions-policy" --policy-document file://readonly-policy.json  --query 'Policy.Arn' --output text)
    rm readonly-policy.json
    aws iam attach-role-policy --role-name "$roleName" --policy-arn "$roPolicyArn"
    accessKey=$(aws iam create-access-key --user-name "$userName" --query '{accessKeyId:AccessKey.AccessKeyId, secretAccessKey:AccessKey.SecretAccessKey}' --output json)
    
    green "# Successfull created user $userName and role $roleArn"
    green "# Please upload the data from $userName-details.yaml to Chronom's Multi Account Management page"
    
    if [ ! "$skip" ]; then
        echo -e "accountId: \n  $accountId" > "$userName-details.yaml"
        echo -e "roleArn: \n  $roleArn" >> "$userName-details.yaml"
        echo -e "accessKeyId: \n  $(echo "$accessKey" | jq -r '.accessKeyId')" >> "$userName-details.yaml"
        echo -e "accessKeySecret: \n  $(echo "$accessKey" | jq -r '.secretAccessKey')" >> "$userName-details.yaml"
    fi
}