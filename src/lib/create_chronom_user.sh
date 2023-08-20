create_chronom_user() {
    userName="$1"
    skip="$2"
    
    roleName=$userName-role
    
    accountId=$(aws sts get-caller-identity --query 'Account' --output text)
    userArn=$(aws iam create-user --user-name $userName --query 'User.Arn' --output text)
    roleArn=$(aws iam create-role --role-name $roleName --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"AWS\":\"$accountId\"},\"Condition\":{}}]}" --query 'Role.Arn' --output text)
    assumePolicyArn=$(aws iam create-policy --policy-name $userName-permissions-policy --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AssumeRole\",\"Effect\":\"Allow\",\"Action\":[\"sts:AssumeRole\"],\"Resource\":[\"$roleArn\"]},{\"Sid\":\"AllowEKSAccess\",\"Effect\":\"Allow\",\"Action\":[\"eks:AccessKubernetesApi\"],\"Resource\":[\"arn:aws:eks:*:*:cluster/*\"]}]}" --query 'Policy.Arn' --output text)
    aws iam attach-user-policy --user-name $userName --policy-arn $assumePolicyArn
    curl -Os https://chronompublicresources.s3.eu-north-1.amazonaws.com/IAMPolicies/readonly-policy.json
    roPolicyArn=$(aws iam create-policy --policy-name $roleName-permissions-policy --policy-document file://readonly-policy.json  --query 'Policy.Arn' --output text)
    rm readonly-policy.json
    aws iam attach-role-policy --role-name $roleName --policy-arn $roPolicyArn
    accessKey=$(aws iam create-access-key --user-name $userName --query '{accessKey:AccessKey.AccessKeyId, secretKey:AccessKey.SecretAccessKey}' --output json)
    
    green "# Successfull created user $userName and role $roleName"
    green "# Role ARN: $roleArn"
    
    if [ ! "$skip" ]; then
        echo "awsscanner:" > $userName-info.yaml
        echo "  roleArn: $userArn" >> $userName-info.yaml
        echo
        green_underlined "Access Key Created Successfully!"
        green_underlined "1. Print Access Key to console"
        green_underlined "2. Save Access Key to file $userName-access-key.txt"
        green_underlined "3. Print Access Key to console And Save to file $userName-access-key.txt"
        green_underlined "4. NOT RECOMMENDED - Do Nothing"
        green_underlined "Enter your choice (1/2/3/4):"
        echo
        read choice
        case "$choice" in
            1 ) echo $accessKey;;
            2 ) echo $accessKey > $userName-access-key.txt;;
            3 ) echo $accessKey; echo $accessKey > $userName-access-key.txt;;
            4 ) echo "Skipping Access Key";;
            * ) echo "Invalid choice";;
        esac
        echo
    fi
    
    
}