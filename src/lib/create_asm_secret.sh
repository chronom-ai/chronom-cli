create_asm_secret() {
    clusterName="$1"
    region="$2"
    tags="$3"
    
    asmRoUserName="$clusterName-aws-credentials-$chronomAuthId-ro-user"
    asmRwUserName="$clusterName-aws-credentials-$chronomAuthId-rw-user"
    
    cleanAccessKey=$(echo $accessKey | awk '{gsub(/{|}/,"")}1')
    initialSecret="[{\"organizationId\":\"$chronomAuthId\",$cleanAccessKey,\"roleArn\":\"$roleArn\",\"accountId\":\"$accountId\",\"accountName\":\"Default Account\"}]"
    secretManagerArn=$(aws secretsmanager create-secret --name "aws-credentials-$chronomAuthId" --secret-string "$initialSecret" --region "$region" --tags "$tags" --query 'ARN' --output text)
    
    # Create ReadOnly ASM User
    aws iam create-user --user-name "$asmRoUserName" --tags "$tags"
    roAccessKey=$(aws iam create-access-key --user-name "$asmRoUserName" --query '{accessKeyId:AccessKey.AccessKeyId, secretAccessKey:AccessKey.SecretAccessKey}' --output json)
    roPolicyArn=$(aws iam create-policy --tags "$tags" --policy-name "$asmRoUserName-policy" --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"readonly\",\"Effect\":\"Allow\",\"Action\":[\"secretsmanager:GetSecretValue\"],\"Resource\":\"$secretManagerArn\"}]}" --query 'Policy.Arn' --output text)
    aws iam attach-user-policy --user-name "$asmRoUserName" --policy-arn "$roPolicyArn"
    
    # Create ReadWrite ASM User
    aws iam create-user --user-name "$asmRwUserName" --tags "$tags"
    rwAccessKey=$(aws iam create-access-key --user-name "$asmRwUserName" --query '{accessKeyId:AccessKey.AccessKeyId, secretAccessKey:AccessKey.SecretAccessKey}' --output json)
    rwPolicyArn=$(aws iam create-policy --policy-name "$asmRwUserName-policy" --tags "$tags" --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"readonly\",\"Effect\":\"Allow\",\"Action\":[\"secretsmanager:GetSecretValue\",\"secretsmanager:UpdateSecret\",\"secretsmanager:PutSecretValue\"],\"Resource\":\"$secretManagerArn\"}]}" --query 'Policy.Arn' --output text)
    aws iam attach-user-policy --user-name "$asmRwUserName" --policy-arn "$rwPolicyArn"
}




