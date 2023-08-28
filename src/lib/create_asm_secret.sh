create_asm_secret() {
    clusterName="$1"
    region="$2"
    tags="$3"

    cleanAccessKey=$(echo $accessKey | awk '{gsub(/{|}/,"")}1')
    initialSecret="[{\"organizationId\":\"$chronomAuthId\",$cleanAccessKey,\"roleArn\":\"$roleArn\",\"accountId\":\"$accountId\"}]"
    secretManagerArn=$(aws secretsmanager create-secret --name "aws-credentials-$chronomAuthId" --secret-string "$initialSecret" --region "$region" --tags "$tags" --query 'ARN' --output text)
    aws iam create-user --user-name "$clusterName-asm-ro-user" --tags "$tags"
    roAccessKey=$(aws iam create-access-key --user-name "aws-credentials-$chronomAuthId-ro-user" --query '{accessKeyId:AccessKey.AccessKeyId, secretAccessKey:AccessKey.SecretAccessKey}' --output json)
    roPolicyArn=$(aws iam create-policy --tags "$tags" --policy-name "aws-credentials-$chronomAuthId-ro-user-policy" --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"readonly\",\"Effect\":\"Allow\",\"Action\":[\"secretsmanager:GetSecretValue\"],\"Resource\":\"$secretManagerArn\"}]}" --query 'Policy.Arn' --output text)
    aws iam attach-user-policy --user-name "aws-credentials-$chronomAuthId-ro-user" --policy-arn "$roPolicyArn"
    aws iam create-user --user-name "aws-credentials-$chronomAuthId-rw-user" --tags "$tags"
    rwAccessKey=$(aws iam create-access-key --user-name "aws-credentials-$chronomAuthId-rw-user" --query '{accessKeyId:AccessKey.AccessKeyId, secretAccessKey:AccessKey.SecretAccessKey}' --output json)
    rwPolicyArn=$(aws iam create-policy --policy-name "aws-credentials-$chronomAuthId-rw-user-policy" --tags "$tags" --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"readonly\",\"Effect\":\"Allow\",\"Action\":[\"secretsmanager:GetSecretValue\",\"secretsmanager:UpdateSecret\",\"secretsmanager:PutSecretValue\"],\"Resource\":\"$secretManagerArn\"}]}" --query 'Policy.Arn' --output text)
    aws iam attach-user-policy --user-name "aws-credentials-$chronomAuthId-rw-user" --policy-arn "$rwPolicyArn"
}




