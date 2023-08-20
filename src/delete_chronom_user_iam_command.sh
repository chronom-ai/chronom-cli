echo "# Deleting user ${args[--name]} and role ${args[--name]}-role"

userName=${args[--name]}

roleName=$userName-role

accountId=$(aws sts get-caller-identity --query 'Account' --output text)

userPolicyArn=$(aws iam get-policy --policy-arn "arn:aws:iam::$accountId:policy/$userName-permissions-policy" --query 'Policy.Arn' --output text) || echo "User Policy not found"

rolePolicyArn=$(aws iam get-policy --policy-arn "arn:aws:iam::$accountId:policy/$roleName-permissions-policy" --query 'Policy.Arn' --output text) || echo "Role Policy not found"

echo "# Detaching User Policy"
aws iam detach-user-policy --user-name $userName --policy-arn $userPolicyArn || echo "User Policy not found"

echo "# Detaching Role Policy"
aws iam detach-role-policy --role-name $roleName --policy-arn $rolePolicyArn || echo "Role Policy not found"

echo "# Deleting User Policy"
aws iam delete-policy --policy-arn $userPolicyArn || echo "User Policy not found"

echo "# Deleting Role Policy"
aws iam delete-policy --policy-arn $rolePolicyArn || echo "Role Policy not found"

echo "# Deleting All User Access Key"
aws iam list-access-keys --user-name $userName --query 'AccessKeyMetadata[].AccessKeyId' --output text | while read key; do aws iam delete-access-key --access-key-id $key --user-name $userName; done

echo "# Deleting User"
aws iam delete-user --user-name $userName || echo "User not found"

echo "# Deleting Role"
aws iam delete-role --role-name $roleName || echo "Role not found"

echo "# Successfull deleted user $userName and role $roleName"