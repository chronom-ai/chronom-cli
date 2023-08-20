yellow "# Deleting user ${args[--name]} and role ${args[--name]}-role"

userName=${args[--name]}

roleName=$userName-role

accountId=$(aws sts get-caller-identity --query 'Account' --output text)

userPolicyArn=$(aws iam get-policy --policy-arn "arn:aws:iam::$accountId:policy/$userName-permissions-policy" --query 'Policy.Arn' --output text) || red "User Policy not found"

rolePolicyArn=$(aws iam get-policy --policy-arn "arn:aws:iam::$accountId:policy/$roleName-permissions-policy" --query 'Policy.Arn' --output text) || red "Role Policy not found"

yellow "# Detaching User Policy"
aws iam detach-user-policy --user-name $userName --policy-arn $userPolicyArn || red "User Policy not found"

yellow "# Detaching Role Policy"
aws iam detach-role-policy --role-name $roleName --policy-arn $rolePolicyArn || red "Role Policy not found"

yellow "# Deleting User Policy"
aws iam delete-policy --policy-arn $userPolicyArn || red "User Policy not found"

yellow "# Deleting Role Policy"
aws iam delete-policy --policy-arn $rolePolicyArn || red "Role Policy not found"

yellow "# Deleting All User Access Key"
aws iam list-access-keys --user-name $userName --query 'AccessKeyMetadata[].AccessKeyId' --output text | while read key; do aws iam delete-access-key --access-key-id $key --user-name $userName; done

yellow "# Deleting User"
aws iam delete-user --user-name $userName || red "User not found"

yellow "# Deleting Role"
aws iam delete-role --role-name $roleName || red "Role not found"

green "# Successfull deleted user $userName and role $roleName"