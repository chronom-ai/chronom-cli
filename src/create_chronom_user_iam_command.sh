echo "# Creating a new Read Only AWS IAM user and Role for Chronom"
echo "# User name: ${args[--name]}"
echo "# Role name: ${args[--name]}-role"

## Parameters normalization
userName=${args[--name]}

create_chronom_user $userName