#!/usr/bin/env bash

set -eu
umask 077

destroy_mode=false
dry_run=false
target_resource_address="google_compute_instance.zarina_instance[0]"
ignore_tag="ignore_instance_zarina"
expected_format_version="1.2"
plan_path=$(mktemp)
trap 'rm -f "$plan_path"' EXIT

show_help() {
  cat << EOF
Usage: ${0##*/} [-hrd] [-a <target_resource_address>] [-t <ignore_tag>]
Terraform wrapper that deploys or destroys a single server and checks for inconsistencies.

  -h  Display this help and exit.
  -r  Dry-run mode. Will not apply the terraform plan.
  -d  Destroy mode. Will destroy instead of deploy.
  -a  The terraform address of the targeted server. Default: "$target_resource_address"
  -t  The terraform variable tag used to specify whether the target will be ignored (destroyed) or not (deployed). Default: "$ignore_tag"
EOF
}

# Gets the index of the target resource address (e.g the server) in the terraform plan
get_target_resource_address_index_in() {
  target_resource_address_index=-1
  i=0
  while read -r resource_address; do
    if [ "$target_resource_address" == "$resource_address" ]; then
      target_resource_address_index=$i
      break
    fi
    i=$((i + 1))
  done < <(echo "$plan_json" | jq -r $1)
}

# Applies the terraform plan with an approximated live percentage
tf_apply() {
  local message=$1

  if $dry_run; then
    sleep 300 &
    echo "Warning: Dry-run mode is enabled, emulating a 300s long terraform apply command:" >&2
  else
    terraform apply -auto-approve -input=false -no-color "$plan_path" > /dev/null &
  fi
  local pid=$!

  local start_timestamp=$(date +%s)
  local expected_duration=27
  local refresh_rate=0.3
  while kill -0 $pid 2>/dev/null; do
    progress=$((($(date +%s) - $start_timestamp) * 100 / $expected_duration))
    if [ $progress -lt 100 ]; then
      echo -en "$message $progress%\r"
    else
      echo -en "$message Elapsed: $(($(date +%s) - $start_timestamp))s\r"
    fi
    sleep $refresh_rate
  done
  echo -e "$message 100%\r"
}

# Handles the destroy logic based on the actions
handle_destroy() {
  case "${actions[0]}" in
    "delete")
      if [ "${#actions[@]}" -eq 1 ]; then
        tf_apply "Destroying server..."
        exit 0
      else
        echo "Error: Unexpected terraform plan" >&2
        exit 1
      fi
    ;;
    "create")
      if [ "${#actions[@]}" -eq 1 ] && [ "${actions[1]}" == "delete" ]; then
        echo "Warning: Server will be created and then deleted." >&2
        tf_apply "Destroying server..."
        exit 0
      else
        echo "Error: Unexpected terraform plan" >&2
        exit 1
      fi
    ;;
    "no-op")
      get_target_resource_address_index_in '.prior_state.values.root_module.resources[].address'
      if [ $target_resource_address_index -eq -1 ]; then
        echo "Warning: Server with address '$target_resource_address' not found in prior state. It may already be destroyed." >&2
        exit 0
      else
        echo "Error: Unexpected terraform plan" >&2
        exit 1
      fi
    ;;
    *)
      echo "Error: Unexpected terraform plan" >&2
      exit 1
    ;;
  esac
}
# Handles the deploy logic based on the actions
handle_deploy() {
  case "${actions[0]}" in
    "create")
      if [ "${#actions[@]}" -eq 1 ]; then
        tf_apply "Deploying server..."
        exit 0
      else
        echo "Error: Unexpected terraform plan" >&2
        exit 1
      fi
    ;;
    "delete")
      if [ "${actions[1]}" == "create" ]; then
        echo "Warning: Server will be deleted and then created." >&2
        tf_apply "Deploying server..."
        exit 0
      else
        echo "Error: Unexpected terraform plan" >&2
        exit 1
      fi
    ;;
    "update"|"no-op")
      get_target_resource_address_index_in '.prior_state.values.root_module.resources[].address'
      if [ $target_resource_address_index -eq -1 ]; then
        echo "Error: Unexpected terraform plan" >&2
        exit 1
      else
        echo "Warning: Server with address '$target_resource_address' not found in prior state. It may already be deployed." >&2
        exit 0
      fi
    ;;
    *)
      echo "Error: Unexpected terraform plan"
      exit 1
    ;;
  esac
}

# Parse command-line options
while getopts hda:t:r opt; do
  case $opt in
    h) show_help; exit 0 ;;
    d) destroy_mode=true ;;
    a) target_resource_address=$OPTARG ;;
    t) ignore_tag=$OPTARG ;;
    r) dry_run=true ;;
    *) show_help; exit 1 ;;
  esac
done

# Initialize Terraform and create a plan
terraform init > /dev/null
terraform plan -out="$plan_path" -var="$ignore_tag"=$destroy_mode > /dev/null
plan_json=$(terraform show -json "$plan_path")

# Verify the format version of the plan
format_version=$(echo "$plan_json" | jq -r '.format_version')
if [ "$format_version" != "$expected_format_version" ]; then
  echo "Error: Format version mismatch. Expected $expected_format_version, but got $format_version" >&2
  exit 1
fi

# Get the index of the target resource address in the resource changes
get_target_resource_address_index_in '.resource_changes[].address'
if [ $target_resource_address_index -eq -1 ]; then
  if $destroy_mode; then
        echo "Warning: Server with address '$target_resource_address' not found in resource changes. It may already be destroyed." >&2
    exit 0
  fi
  echo "Error: Couldn't find $target_resource_address in resource changes" >&2
  exit 1
fi

# Extract actions for the target resource
actions=($(echo "$plan_json" | jq -r '.resource_changes['"$target_resource_address_index"'].change.actions[]'))
if [ ${#actions[@]} -eq 0 ] || [ ${#actions[@]} -gt 2 ]; then
  echo "Error: Unexpected number of actions for address '$target_resource_address'. It should never happen." >&2
  exit 1
fi

# Handle the deploy or destroy mode based on the actions
if $destroy_mode; then
  handle_destroy
else
  handle_deploy
fi
