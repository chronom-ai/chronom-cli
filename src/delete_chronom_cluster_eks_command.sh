yellow "# Deleting cluster ${args[--name]} in region ${args[--region]}"
eksctl delete cluster --name ${args[--name]} --region ${args[--region]} || red "Cluster not found"
green "# Successfull deleted cluster ${args[--name]} in region ${args[--region]}"
yellow "# Deleting Admin Role ${args[--name]}-AdminRole"
clusterName="${args[--name]}"
roleName="${args[--name]}-AdminRole"
accountId=$(aws sts get-caller-identity --query 'Account' --output text)
rolePolicyArn=$(aws iam get-policy --policy-arn "arn:aws:iam::$accountId:policy/${roleName}Policy" --query 'Policy.Arn' --output text) || red "Role Policy not found"

lbControllerPolicyArn=$(aws iam get-policy --policy-arn "arn:aws:iam::$accountId:policy/$clusterName-AWSLoadBalancerControllerIAMPolicy" --query 'Policy.Arn' --output text) || red "Load Balancer Policy not found - skipping"

aws iam detach-role-policy --role-name "$roleName" --policy-arn "$rolePolicyArn" || red "Admin Role not found"

aws iam delete-policy --policy-arn "$rolePolicyArn" || red "Admin Role Policy not found"

aws iam delete-role --role-name "$roleName" || red "Admin Role not found"

aws iam delete-policy --policy-arn "$lbControllerPolicyArn" || red "Load Balancer Policy not found - skipping"

green "# Successfull deleted Admin Role ${args[--name]}-AdminRole"
green "# Deletion of cluster ${args[--name]} in region ${args[--region]} completed successfully"