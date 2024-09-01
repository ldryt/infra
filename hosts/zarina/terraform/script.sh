#!/usr/bin/env sh

set -eu

umask 077

destroy_mode=false
dry_run=false
target_resource_address="google_compute_instance.zarina_instance[0]"
terraform_directory="./."
ignore_tag="ignore_instance_zarina"
ip_tag="zarina_ipv4"
expected_format_version="1.2"
plan_path=$(mktemp)
trap 'rm -f "$plan_path"' EXIT

show_help() {
	cat <<EOF
Usage: ${0##*/} [-hnx] [-r <target_resource_address>] [-i <ignore_tag>] [-p <ip_tag>] [-d <terraform_directory>]

Description:
  Terraform wrapper script for deploying or destroying a single server and checking for inconsistencies.

Options:
  -h  Display this help message and exit.
  -n  Enable dry-run mode. This will not apply the Terraform plan.
  -x  Enable destroy mode. This will destroy the specified resource instead of deploying it.
  -r  Specify the Terraform address of the target resource. Default: "$target_resource_address"
  -i  Specify the Terraform variable name used to indicate whether the target will be skipped (destroyed) or included (deployed). Default: "$ignore_tag"
  -p  Specify the Terraform output name storing the IP address of the target resource. Default: "$ip_tag"
  -d  Specify the directory containing the Terraform configuration files. Default: "$terraform_directory"
EOF
}

# Gets the index of the target resource address (e.g the server) in the terraform plan
get_target_resource_index_in() {
	i=0
	echo "$plan_json" | jq -r "$1" | while IFS= read -r resource_address; do
		if [ "$target_resource_address" = "$resource_address" ]; then
			echo $i
			break
		fi
		i=$((i + 1))
	done
}

tfwrap() {
	export TF_IN_AUTOMATION=true
	export TF_INPUT=false
	terraform -chdir="$terraform_directory" "$@" "-no-color"
}

# Prints an approximated progress percentage
progress() {
	cmd=$1
	message=$2
	expected_duration=$3

	refresh_rate=2
	start_timestamp=$(date +%s)

	stderr_file=$(mktemp)
	$cmd >/dev/null 2>"$stderr_file" &
	pid=$!
	child_pid=$(ps --ppid $pid -o pid= || true)
	if [ -n "$child_pid" ]; then
		name=$(cat /proc/"$child_pid"/comm)
	else
		name=$(cat /proc/"$pid"/comm)
	fi

	while ps -p "$pid" >/dev/null; do
		printf "%s " "$message"
		progress=$((($(date +%s) - start_timestamp) * 100 / expected_duration))
		if [ $progress -le 100 ]; then
			printf "%d%%\n" $progress
		else
			printf "Elapsed: %ds\n" $(($(date +%s) - start_timestamp))
		fi
		sleep "$refresh_rate"
	done

	printf "%s " "$message"
	if wait "$pid"; then
		printf "Done.\n"
	else
		status=$?
		stderr_first_line=$(
			if [ "$name" = "terraform" ]; then
				head -n 2 "$stderr_file" | tail -n 1
			else
				head -n 1 "$stderr_file"
			fi
		)
		printf "Error: %s exited with status %s: %s\n" "$name" "$status" "$stderr_first_line" >&2
		exit 1
	fi

	rm -f "$stderr_file"
}

# Applies the terraform plan with an approximated live percentage
tf_apply() {
	msg=$1
	if $dry_run; then
		cmd="sleep 300"
		echo "Warning: Dry-run mode is enabled, emulating a 300s long terraform apply command:" >&2
	else
		cmd="tfwrap apply -auto-approve $plan_path"
	fi
	progress "$cmd" "$msg" 26
}

# Handles the destroy logic based on the actions
handle_destroy() {
	case "$action_0" in
	"delete")
		if [ "$action_1" = "null" ]; then
			tf_apply "Destroying server..."
			exit 0
		else
			echo "Error: Unexpected terraform plan" >&2
			exit 1
		fi
		;;
	"create")
		if [ "$action_1" = "delete" ]; then
			echo "Warning: Server will be created and then deleted." >&2
			tf_apply "Destroying server..."
			exit 0
		else
			echo "Error: Unexpected terraform plan" >&2
			exit 1
		fi
		;;
	"no-op")
		target_resource_index=$(get_target_resource_index_in '.prior_state.values.root_module.resources[].address')
		if [ "$target_resource_index" -eq -1 ]; then
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
	case "$action_0" in
	"create")
		if [ "$action_1" = "null" ]; then
			tf_apply "Deploying server..."
			exit 0
		else
			echo "Error: Unexpected terraform plan" >&2
			exit 1
		fi
		;;
	"delete")
		if [ "$action_1" = "create" ]; then
			echo "Warning: Server will be deleted and then created." >&2
			tf_apply "Deploying server..."
			exit 0
		else
			echo "Error: Unexpected terraform plan" >&2
			exit 1
		fi
		;;
	"update" | "no-op")
		target_resource_index=$(get_target_resource_index_in '.prior_state.values.root_module.resources[].address')
		if [ "$target_resource_index" -eq -1 ]; then
			echo "Error: Unexpected terraform plan" >&2
			exit 1
		else
			echo "Warning: Server with address '$target_resource_address' not found in prior state. It may already be deployed." >&2
			exit 0
		fi
		;;
	*)
		echo "Error: Unexpected terraform plan" >&2
		exit 1
		;;
	esac
}

# Parse command-line options
while getopts hxr:i:nd: opt; do
	case $opt in
	h)
		show_help
		exit 0
		;;
	x) destroy_mode=true ;;
	r) target_resource_address=$OPTARG ;;
	i) ignore_tag=$OPTARG ;;
	n) dry_run=true ;;
	d) terraform_directory=$OPTARG ;;
	*)
		show_help
		exit 1
		;;
	esac
done

# Check if necessary commands are available
for cmd in terraform jq; do
	if ! command -v $cmd >/dev/null 2>&1; then
		printf "Error: %s command is not available. Please install it.\n" "$cmd" >&2
		exit 1
	fi
done

# Initialize Terraform and create a plan
progress "tfwrap init" "Initializing environment..." 3

progress "tfwrap plan -out=$plan_path -var=$ignore_tag=$destroy_mode" "Preparing environment..." 13
plan_json=$(tfwrap show -json "$plan_path")

# Verify the format version of the plan
format_version=$(echo "$plan_json" | jq -r '.format_version')
if [ "$format_version" != "$expected_format_version" ]; then
	printf "Error: Format version mismatch. Expected %s, but got %s\n" "$expected_format_version" "$format_version" >&2
	exit 1
fi

# Get the index of the target resource address in the resource changes
target_resource_index=$(get_target_resource_index_in '.resource_changes[].address')
if [ "$target_resource_index" -eq -1 ]; then
	if $destroy_mode; then
		printf "Warning: Target resource address '%s' not found in resource changes. It may already be destroyed.\n" "$target_resource_address" >&2
		exit 0
	fi
	printf "Error: Target resource address %s not found in resource changes\n" "$target_resource_address" >&2
	exit 1
fi

# Extract actions for the target resource
action_0=$(echo "$plan_json" | jq -r '.resource_changes['"$target_resource_index"'].change.actions[0]')
action_1=$(echo "$plan_json" | jq -r '.resource_changes['"$target_resource_index"'].change.actions[1]')

# Handle the deploy or destroy mode based on the actions
if $destroy_mode; then
	handle_destroy
else
	handle_deploy
	tfwrap output -json | jq -r '.outputs.'"$ip_tag"'.value'
fi
