#!/bin/bash

# Example input:
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "ReadOnlyActions",
#       "Effect": "Allow",
#       "Action": [
#         "a4b:Get*",
#         "a4b:List*",
#         "a4b:Search*",
#         "access-analyzer:GetAccessPreview",
#         "access-analyzer:GetAnalyzedResource",
#         "access-analyzer:GetAnalyzer",
#         "access-analyzer:GetArchiveRule",
#         "access-analyzer:GetFinding",
#         "access-analyzer:GetGeneratedPolicy",
#         "access-analyzer:ListAccessPreviewFindings",
#         "access-analyzer:ListAccessPreviews",
#         "access-analyzer:ListAnalyzedResources",
#         "access-analyzer:ListAnalyzers",
#         "access-analyzer:ListArchiveRules",
#         "access-analyzer:ListFindings",
#         "access-analyzer:ListPolicyGenerations",
#         "access-analyzer:ListTagsForResource",
#         "access-analyzer:ValidatePolicy",
#         "account:GetAccountInformation",
#         "account:GetAlternateContact",
#         "account:GetChallengeQuestions",
#         "account:GetContactInformation",
#         "account:GetRegionOptStatus",
#         "account:ListRegions",
#         "acm-pca:Describe*",
#         "acm-pca:Get*",
#         "acm-pca:List*",
#         "acm:Describe*",
#         "acm:Get*",
#         "acm:List*"
#       ],
#       "Resource": "*"
#     }
#   ]
# }

# Example output:
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "ReadOnlyActions",
#       "Effect": "Allow",
#       "Action": [
#         "a4b:Get*",
#         "a4b:List*",
#         "a4b:Search*",
#         "access-analyzer:Get*",
#         "access-analyzer:List*",
#         "access-analyzer:Validate*",
#         "account:Get*",
#         "account:List*",
#         "acm-pca:Describe*",
#         "acm-pca:Get*",
#         "acm-pca:List*",
#         "acm:Describe*",
#         "acm:Get*",
#         "acm:List*"
#       ],
#       "Resource": "*"
#     }
#   ]
# }

# This script will take a JSON file containing a policy and fix the permissions
# to use wildcards where possible. This is useful for when you want to use

json=$(cat readonly-policy-new.json)

# Get the actions from the JSON
actions=$(echo $json | jq -r '.Statement[].Action[]')

# Create an empty array to store the actions in
newActions=()

# Loop through the actions
for action in $actions
do
  # Check if the action contains a wildcard
  if [[ $action == *"*"* ]]
  then
    # If it does, add it to the newActions array
    newActions+=($action)
  else
    # If it doesn't, add the wildcard version of the action to the newActions array
    if [[ $action == *"Batch"* ]]
    then
      # If the action contains Batch, then split after the second capital letter (For example, BatchGetCollection => BatchGet)
      newAction=$(echo $action | sed -E 's/([A-Z][a-z]+)([A-Z][a-z]+)/\1\2 /g' | awk '{print $1}')
      newActions+=($newAction*)
    elif [[ $action == *":Admin"* ]]
    then
      # If the action contains Batch, then split after the second capital letter (For example, BatchGetCollection => BatchGet)
      newAction=$(echo $action | sed -E 's/([A-Z][a-z]+)([A-Z][a-z]+)/\1\2 /g' | awk '{print $1}')
      newActions+=($newAction*)
    elif [[ $action == *"PartiQLSelect"* ]]
    then
      # If the action contains Batch, then split after the second capital letter (For example, BatchGetCollection => BatchGet)
      # newAction=$(echo $action | sed -E 's/([A-Z][a-z]+)([A-Z][a-z]+)/\1\2 /g' | awk '{print $1}')
      newActions+=($action*)
    else
      # If the action doesn't contain Batch, then split after the first capital letter (For example, GetAccountSummary => Get)
      newAction=$(echo $action | sed -E 's/([A-Z][a-z]+)/\1 /g' | awk '{print $1}')
      newActions+=($newAction*)
    fi
  fi
done

# Remove duplicates from the newActions array
newActions=($(echo "${newActions[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
# Sort the newActions array
newActions=($(echo "${newActions[@]}" | tr ' ' '\n' | sort | tr '\n' ' '))

# Create a new JSON object with the newActions array
# # newJson=$(echo $json | jq --argjson newActions "${newActions[@]}" '.Statement[].Action = $newActions')
newJson=$(echo "$json" | jq --argjson newActions "$(printf '%s\n' "${newActions[@]}" | jq -R . | jq -s .)" '.Statement[].Action = $newActions')

# Print the new JSON object
echo $newJson >> readonly-policy-new-wildcard.json