yellow "# Upgrading IAM Permissions"

accountId=$(aws sts get-caller-identity --query 'Account' --output text)

tags='[{"Key":"Application","Value":"Chronom A.I."},{"Key":"DeployedAt","Value":"UTC-'$(date --utc +%Y-%m-%d:%H:%M:%S)'"}]'

# If ${args[--user-name]} was provided, role arn will be: arn:aws:iam::${accountId}:role/${args[--user-name]}-role
# else if ${args[--role-arn]} was provided, role arn will be: ${args[--role-arn]}
# else throw error since one of the two is required
if [[ -n "${args[--user-name]}" ]]; then
  roleArn="arn:aws:iam::${accountId}:role/${args[--user-name]}-role"
  roleName="${args[--user-name]}-role"
elif [[ -n "${args[--role-arn]}" ]]; then
  roleArn="${args[--role-arn]}"
  roleName="${roleArn##*/}"
elif [[ -n "${args[--role-name]}" ]]; then
  roleArn="arn:aws:iam::${accountId}:role/${args[--role-name]}"
  roleName="${args[--role-name]}"
else
  red "Either --user-name , --role-arn or --role-name must be provided"
  exit 1
fi

curl -Os https://raw.githubusercontent.com/chronom-ai/chronom-cli/main/public_resources/chronom-readonly-additional-access-policy.json


currentAttachedPolicies=$(aws iam list-attached-role-policies --role-name "$roleName" --query 'AttachedPolicies[].PolicyArn' --output text)

# Check if the role has the ReadOnlyAccess policy attached
# If it doesn't, attach it
if [[ ! "$currentAttachedPolicies" =~ .*arn:aws:iam::aws:policy/ReadOnlyAccess.* ]]; then
  yellow "# Attaching ReadOnlyAccess policy to role"
  aws iam attach-role-policy --role-name "$roleName" --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess"
fi

# Check if the role has the chronom-readonly-additional-access-policy policy attached
# If it does, compare the policy document with ./chronom-readonly-additional-access-policy.json
# If they are different, update the policy document
# If it doesn't, attach it
if [[ "$currentAttachedPolicies" =~ .*arn:aws:iam::$accountId:policy/chronom-readonly-additional-access-policy.* ]]; then
# If the policy is attached, check if it is using the latest policy document
  currentPolicyDocument=$(aws iam get-policy --policy-arn "arn:aws:iam::$accountId:policy/chronom-readonly-additional-access-policy" --query 'Policy.DefaultVersionId' --output text)
  currentPolicyDocument=$(aws iam get-policy-version --policy-arn "arn:aws:iam::$accountId:policy/chronom-readonly-additional-access-policy" --version-id "$currentPolicyDocument" --query 'PolicyVersion.Document' --output json)
  newPolicyDocument=$(cat chronom-readonly-additional-access-policy.json)
  if ! diff -q <(jq --sort-keys . <<< "$currentPolicyDocument") <(jq --sort-keys . <<< "$newPolicyDocument") &>/dev/null ; then
    yellow "# Updating chronom-readonly-additional-access-policy policy document"
    aws iam create-policy-version --policy-arn "arn:aws:iam::$accountId:policy/chronom-readonly-additional-access-policy" --policy-document file://chronom-readonly-additional-access-policy.json --set-as-default
  fi
else
# If the policy is not attached, check if it exists
# If it doesn't, create it
# If it does, check if it is using the latest policy document
# If they are different, update the policy document
   roPolicyArn=$(aws iam list-policies --query "Policies[?PolicyName=='chronom-readonly-additional-access-policy'].Arn" --output text --scope Local)
   if [[ -z "$roPolicyArn" ]]; then
   # If the policy doesn't exist, create it
     roPolicyArn=$(aws iam create-policy --tags "$tags" --policy-name "chronom-readonly-additional-access-policy" --policy-document file://chronom-readonly-additional-access-policy.json  --query 'Policy.Arn' --output text)
   else
   # If the policy exists, check if it is using the latest policy document
     yellow "# chronom-readonly-additional-access-policy policy already exists, verifying it is using latest policy document"
      currentPolicyDocument=$(aws iam get-policy --policy-arn "$roPolicyArn" --query 'Policy.DefaultVersionId' --output text)
      newPolicyDocument=$(cat chronom-readonly-additional-access-policy.json)
      if ! diff -q <(jq --sort-keys . <<< "$currentPolicyDocument") <(jq --sort-keys . <<< "$newPolicyDocument") &>/dev/null ; then
        yellow "# Updating chronom-readonly-additional-access-policy policy document"
        aws iam create-policy-version --policy-arn "$roPolicyArn" --policy-document file://chronom-readonly-additional-access-policy.json --set-as-default
      fi
   fi
  yellow "# Attaching chronom-readonly-additional-access-policy policy to role"
  aws iam attach-role-policy --role-name "$roleName" --policy-arn "$roPolicyArn"
fi

rm chronom-readonly-additional-access-policy.json
green "# Successfully upgraded IAM permissions for role $roleArn"
