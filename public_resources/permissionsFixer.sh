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

# Empty Policy JSON
emptyPolicyJson='{ "Version": "2012-10-17", "Statement": [ { "Sid": "ReadOnlyActions", "Effect": "Allow", "Action": [], "Resource": "*" } ] }'


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
    if [[ $action == *":Batch"* ]]
    then
      # If the action contains Batch, then split after the second capital letter (For example, BatchGetCollection => BatchGet)
      newAction=$(echo $action | sed -E 's/([A-Z][a-z]+)([A-Z][a-z]+)/\1\2 /g' | awk '{print $1}')
      newActions+=($newAction*)
    elif [[ $action == *":Admin"* ]]
    then
      # If the action contains Batch, then split after the second capital letter (For example, BatchGetCollection => BatchGet)
      newAction=$(echo $action | sed -E 's/([A-Z][a-z]+)([A-Z][a-z]+)/\1\2 /g' | awk '{print $1}')
      newActions+=($newAction*)
    elif [[ $action == *":PartiQLSelect"* ]]
    then
      newActions+=($action*)
    elif [[ $action == *":ESHttpGet"* ]]
    then
      newActions+=($action*)
    elif [[ $action == *":ESHttpHead"* ]]
    then
      newActions+=($action*)
    elif [[ $action == *":list"* ]]
    then
      # Replace :list with :List
      newAction=$(echo $action | sed -E 's/list/List/g')
      newAction=$(echo $newAction | sed -E 's/([A-Z][a-z]+)/\1 /g' | awk '{print $1}')
      newActions+=($newAction*)
    elif [[ $action == *":get"* ]]
    then
      # Replace :get with :Get
      newAction=$(echo $action | sed -E 's/get/Get/g')
      newAction=$(echo $newAction | sed -E 's/([A-Z][a-z]+)/\1 /g' | awk '{print $1}')
      newActions+=($newAction*)
    elif [[ $action == *":describe"* ]]
    then
      # Replace :describe with :Describe
      newAction=$(echo $action | sed -E 's/describe/Describe/g')
      newAction=$(echo $newAction | sed -E 's/([A-Z][a-z]+)/\1 /g' | awk '{print $1}')
      newActions+=($newAction*)
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

# The actions are structured as <service>:<action>
# We need to create a json object that looks like this:
# [
#   {
#     "service1": 56, # Number of chars in the actions array without whitespace
#     "actions": [
#       "service1:action1",
#       "service1:action2",
#       "service1:action3"
#     ]
#   },
#   {
#     "service2": 56, # Number of chars in the actions array without whitespace
#     "actions": [
#       "service2:action1",
#       "service2:action2",
#       "service2:action3"
#     ]
#   }
# ]

# Create an empty array to store the services in
services=()

# Loop through the actions
for newAction in "${newActions[@]}"
do
  # Split the action after the first colon
  service=$(echo $newAction | awk -F':' '{print $1}')
  # Add the service to the services array
  services+=($service)
done
# Remove duplicates from the services array
services=($(echo "${services[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

# Create an empty array to store the JSON objects in
jsonObjects=()

# Loop through the services
for service in "${services[@]}"
do
  # Create an empty array to store the actions in
  actions=()
  # Loop through the actions
  for newAction in "${newActions[@]}"
  do
    # Split the action after the first colon
    actionService=$(echo $newAction | awk -F':' '{print $1}')
    # Check if the action contains the service
    if [[ $actionService == $service ]]
    then
      # If it does, add it to the actions array
      actions+=($newAction)
    fi
  done
  # Count the number of characters in the actions array without whitespace
  actionsLength=$(echo "${actions[@]}" | tr -d '[:space:]' | wc -c)
  # Create a JSON object with the service and actions
  jsonObject=$(jq -n --arg service "$service" --arg count "$actionsLength" --argjson actions "$(printf '%s\n' "${actions[@]}" | jq -R . | jq -s .)" '{"service": $service, "count": $count, "actions": $actions}')

  echo $service

  # Add the JSON object to the jsonObjects array
  jsonObjects+=($jsonObject)
done

# create a new AWS IAM Policy with the new actions, with up to 6000 characters per policy actions (use the count property to determine the length of the actions array)
# do not break up the actions array for a single service into multiple policies
# each policy should have a maximum of 6000 characters in the actions array
# Do not change the order of the actions array, preffer to have less then 6000 characters in the actions array instead of changing the order of the actions array

# Convert the $jsonObjects array to a JSON object
convertedJsonObjects=$(printf '%s\n' "${jsonObjects[@]}" | jq -s .)

echo $convertedJsonObjects > convertedJsonObjects.json


tempCounter=0
countedActions=()
policyCounter=0
while [ "$tempCounter" -lt 5000 ] && [ "$convertedJsonObjects" != "[]" ]
do
  # Get the first JSON object from the $convertedJsonObjects array
  jsonObject=$(echo $convertedJsonObjects | jq -r '.[0]')
  # Get the service from the JSON object
  service=$(echo $jsonObject | jq -r '.service')
  # Get the actions from the JSON object
  actions=$(echo $jsonObject | jq -r '.actions[]')
  # Get the count from the JSON object
  count=$(echo $jsonObject | jq -r '.count')
  tempCounter=$((tempCounter + count))
  if [[ $tempCounter -lt 5000 ]]
  then
    # Add the actions to the countedActions array
    echo "Service: $service added to policy # $policyCounter"
    countedActions+=($actions)
    # if service equals eks then add"eks:AccessKubernetesApi" to the countedActions array
    if [[ $service == "eks" ]]
    then
      countedActions+=("eks:AccessKubernetesApi")
    fi

    # Remove the first JSON object from the $convertedJsonObjects array
    convertedJsonObjects=$(echo $convertedJsonObjects | jq -r '.[1:]')
  else
    echo "Service: $service not added to policy # $policyCounter"
    # Create a new JSON object with the countedActions array
    newJson=$(echo "$emptyPolicyJson" | jq --argjson countedActions "$(printf '%s\n' "${countedActions[@]}" | jq -R . | jq -s .)" '.Statement[].Action = $countedActions')
    # Print the new JSON object
    echo $newJson > readonly-policy-part$policyCounter.json

    echo "Created policy # $policyCounter"

    policyCounter=$((policyCounter + 1))
    # Empty the countedActions array
    countedActions=()
    # Empty the tempCounter
    tempCounter=0
  fi
done

# Check if there are remaining actions in countedActions
if [ ${#countedActions[@]} -ne 0 ]; then
  # Create a new JSON object with the countedActions array
  newJson=$(echo "$emptyPolicyJson" | jq --argjson countedActions "$(printf '%s\n' "${countedActions[@]}" | jq -R . | jq -s .)" '.Statement[].Action = $countedActions')
  # Print the new JSON object
  echo $newJson > readonly-policy-part$policyCounter.json

  echo "Created policy # $policyCounter"
fi