yellow "# Creating a new Read Only AWS IAM user and Role for Chronom"
yellow "# User name: ${args[--name]}"
yellow "# Role name: ${args[--name]}-role"

## Parameters normalization
userName=${args[--name]}

create_chronom_user $userName