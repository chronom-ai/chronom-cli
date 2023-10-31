validate_chronom_auth() {
    statusCode=$(curl --write-out %{http_code} --silent --output /dev/null -X POST "https://auth.chronom.ai/organization/authenticate" -H "Content-Type: application/json" -d "{\"clientId\": \"$chronomAuthId\", \"clientSecret\": \"$chronomAuthSecret\"}")
    echo $statusCode
}

validate_aws_permissions() {
    callerArn=$(aws sts get-caller-identity --query 'Arn' --output text)
    iamPermissions=$(aws iam simulate-principal-policy --policy-source-arn $callerArn --action-names "iam:*" --query 'EvaluationResults[0].EvalDecision' --output text)
    eksPermissions=$(aws iam simulate-principal-policy --policy-source-arn $callerArn --action-names "eks:*" --query 'EvaluationResults[0].EvalDecision' --output text)
    ec2Permissions=$(aws iam simulate-principal-policy --policy-source-arn $callerArn --action-names "ec2:*" --query 'EvaluationResults[0].EvalDecision' --output text)
    route53Permissions=$(aws iam simulate-principal-policy --policy-source-arn $callerArn --action-names "route53:*" --query 'EvaluationResults[0].EvalDecision' --output text)
    acmPermissions=$(aws iam simulate-principal-policy --policy-source-arn $callerArn --action-names "acm:*" --query 'EvaluationResults[0].EvalDecision' --output text)
    secretsManagerPermissions=$(aws iam simulate-principal-policy --policy-source-arn $callerArn --action-names "secretsmanager:*" --query 'EvaluationResults[0].EvalDecision' --output text)

    ## If EKS, Ec2, Route53, Acm and SecretManager all are not equal to 'allowed' print error
    if [ "$eksPermissions" -ne 'allowed' ] && [ "$ec2Permissions" -ne 'allowed' ] && [ "$route53Permissions" -ne 'allowed' ] && [ "$acmPermissions" -ne 'allowed' ] && [ "$secretsManagerPermissions" -ne 'allowed' ]; then
        red_bold "Error: The Identity executing the command does not have the required permissions!"
        red_bold "Please make sure that the AWS Identity executing the command has the following permissions:"
        red_bold "EKS: eks:*"
        red_bold "EC2: ec2:*"
        red_bold "Route53: route53:*"
        red_bold "ACM: acm:*"
        red_bold "SecretsManager: secretsmanager:*"
        exit 1
    fi

    if [ -z "${args[--ro-user-access-key]}" ] && [ "$iamPermissions" -ne 'allowed' ]; then
        red_bold "Error: The Identity executing the command does not have the required permissions!"
        red_bold "Please make sure that the AWS Identity executing the command has the following permissions:"
        red_bold "IAM: iam:*"
        red_bold "Alternatively, you can manually create the users and provide the access keys using the --ro-user-access-key and --ro-user-secret-key flags"
        exit 1
    fi

}