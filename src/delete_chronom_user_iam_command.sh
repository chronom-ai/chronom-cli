yellow "# Deleting user ${args[--name]} and role ${args[--name]}-role"

userName=${args[--name]}

roleName=$userName-role

accountId=$(aws sts get-caller-identity --query 'Account' --output text)

userPolicyArn=$(aws iam get-policy --policy-arn "arn:aws:iam::$accountId:policy/$userName-permissions-policy" --query 'Policy.Arn' --output text) || red "User Policy not found"

rolePolicyArn=$(aws iam get-policy --policy-arn "arn:aws:iam::$accountId:policy/chronom-readonly-additional-access-policy" --query 'Policy.Arn' --output text) || red "Role Policy not found"

yellow "# Detaching User Policy"
aws iam detach-user-policy --user-name $userName --policy-arn $userPolicyArn || red "User Policy not found"

yellow "# Detaching Role Policy"
aws iam detach-role-policy --role-name $roleName --policy-arn $rolePolicyArn || red "Role Policy not found"
aws iam detach-role-policy --role-name $roleName --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess" || red "Role Policy not found"

yellow "# Deleting User Policy"
aws iam delete-policy --policy-arn $userPolicyArn || red "User Policy not found"

yellow "# Deleting Role Policy"
aws iam delete-policy --policy-arn $rolePolicyArn || red "Role Policy not found"

yellow "# Deleting All User Access Key"
IFS=',' read -ra keys <<< "$(aws iam list-access-keys --user-name "$userName" --query 'AccessKeyMetadata[].AccessKeyId' --output text | awk '{$1=$1} 1' OFS=',')"
for key in "${keys[@]}"; do
  aws iam delete-access-key --access-key-id "$key" --user-name "$userName"
done

yellow "# Deleting User"
aws iam delete-user --user-name $userName || red "User not found"

yellow "# Deleting Role"
aws iam delete-role --role-name $roleName || red "Role not found"

# List all IAM users with '-aws-credentials-' in their username
possibleUsers=$(aws iam list-users --query "Users[?contains(UserName, '-aws-credentials-')].UserName" --output text)

# Check if any users were found
if [[ -n "$possibleUsers" ]]; then
  # Print numbered list of possible users
  listOutput=$(echo "$possibleUsers" | awk '{for(i=1;i<=NF;i++) print i". " $i}')
  yellow "# Possible users to delete (Will also delete <UserName>-policy):"
  yellow "0. Cancel"
  yellow "$listOutput"

  # Prompt user to enter numbers of users to delete
  red_bold "WARNING: This will delete the users and their policies permanently"
  red "Enter numbers of users to delete (comma-separated, 0 to cancel): "
  read userInput

  # Check if user entered 0 to cancel
  if [[ "$userInput" != "0" ]]; then
    # Split user input into array of numbers
    IFS=',' read -ra userNumbers <<< "$userInput"
    IFS="," read -a possibleUsersArray <<< "$(echo $possibleUsers | awk '{$1=$1} 1' OFS=',')"

    # Loop through user numbers and delete corresponding users
    for userNumber in "${userNumbers[@]}"; do
      # Subtract 1 from user number to get index in possibleUsers array
      index=$((userNumber-1))
      # Check if index is valid
      if [[ "$index" -lt 0 || "$index" -ge "${#possibleUsersArray[@]}" ]]; then
        red "# Invalid user number: $userNumber"
        continue
      fi
      # Get username from possibleUsers array
      userName="${possibleUsersArray[$index]}"
      # Detach User from policy, remove access keys, and delete user and policy
      yellow "# Deleting user $userName"
      aws iam detach-user-policy --user-name "$userName" --policy-arn "arn:aws:iam::$accountId:policy/$userName-policy" || red "User Policy not attached"
      IFS=',' read -ra keys <<< "$(aws iam list-access-keys --user-name "$userName" --query 'AccessKeyMetadata[].AccessKeyId' --output text | awk '{$1=$1} 1' OFS=',')"
      for key in "${keys[@]}"; do
        aws iam delete-access-key --access-key-id "$key" --user-name "$userName"
      done
      aws iam delete-user --user-name "$userName" || red "User not found"
      aws iam delete-policy --policy-arn "arn:aws:iam::$accountId:policy/$userName-policy" || red "User Policy not found"
    done
  else
    blue "No users will be deleted"
  fi
else
  blue "No users found with '-aws-credentials-' in their username"
fi
green "# Successfull deleted user $userName and role $roleName"