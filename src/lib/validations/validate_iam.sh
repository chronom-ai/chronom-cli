validate_available_iam_user_role() {
    userName="$1"
    
    ## Validate UserName is not Taken
    
    aws iam get-user --user-name "$userName" &> /dev/null
    
    [ ! $? -eq 0 ] || echo "User $userName already exists, please choose another name"
    
    ## Validate RoleName is not Taken
    
    aws iam get-role --role-name "$userName-role" &> /dev/null
    
    [ ! $? -eq 0 ] || echo "Role $userName-role already exists, please use a different name or provide a role name with --role-name"
    
    ## Validate User PolicyName is not taken
    
    aws iam get-policy --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query 'Account' --output text):policy/$userName-permissions-policy" &> /dev/null
    
    [ ! $? -eq 0 ] || echo "Policy $userName-permissions-policy already exists, please use a different name"
    
    ## Validate Role PolicyName is not taken

    aws iam get-policy --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query 'Account' --output text):policy/$userName-role-permissions-policy" &> /dev/null
    
    [ ! $? -eq 0 ] || echo "Policy $userName-role-permissions-policy already exists, please use a different name"
}