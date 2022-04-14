#!/bin/bash
set -o errexit
set -o pipefail
set -u

#######################################
# Ensure that a value is non-empty
# Arguments:
#   The description of the value
#   The value
# Returns:
#   None
#######################################
check_arg() {
  if [[ -z "$2" ]]; then
    echo "Required: $1"
    echo
    display_usage
    exit 1
  fi
}

endpoint=''
local_port=''
namespace="sym"
remote_port=''

display_usage() {
  cat <<EOM
    ##### tunnel #####
    SSH tunnel via AWS Session Manager and EC2 Instance Connect.

    Looks up the EC2 instance to use for tunneling by searching for an instance
    that is named "\${namespace}-bastion".

    More info: https://codelabs.transcend.io/codelabs/aws-ssh-ssm-rds/index.html

    Required arguments:
        -e | --endpoint         The endpoint to tunnel requests to
        -l | --local-port       The local port for tunnel requests
        -n | --namespace        The namespace to use for identifying the bastion
instance
        -r | --remote-port      The remote port the endpoint is listening on

    Optional arguments:
        -h | --help             Show this message

    Requirements:
        aws:        AWS Command Line Interface
EOM
  exit 2
}

while [[ $# -gt 0 ]]; do
  key="$1"

  case ${key} in
    -e|--endpoint)
      endpoint=$2
      shift
      ;;
    -l|--local-port)
      local_port=$2
      shift
      ;;
    -n|--namespace)
      namespace=$2
      shift
      ;;
    -r|--remote-port)
      remote_port=$2
      shift
      ;;
    -h|--help)
      display_usage
      exit 0
      ;;
    *)
      display_usage
      exit 1
      ;;
  esac
  shift
done

check_arg '-e or --endpoint' "${endpoint}"
check_arg '-l or --local-port' "${local_port}"
check_arg '-r or --remote-port' "${remote_port}"

bastion_name="${namespace}-bastion"

# Find an EC2 instance named \${namespace}-bastion
bastion_id=$(aws ec2 describe-instances \
  --filter Name=tag:Name,Values="${bastion_name}" Name=instance-state-name,Values=running \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)
if [[ -z "${bastion_id}" || "None" = "${bastion_id}" ]]; then
  echo "Unable to find bastion instance: ${bastion_name}"
  exit 1
fi

# The username to use for SSM sessions, this defaults to ssm-user
# unless you configure it differently in your AWS Session Manager settings
ssm_user=ssm-user

# Ensure SSM is set up on the instance before tunneling
aws ssm start-session \
  --target "${bastion_id}" \
  --document-name AWS-StartInteractiveCommand \
  --parameters command="exit" > /dev/null

# Generate a keypair and send the pubkey to our EC2 instance, so that we can use
# ssh port forwarding to our remote rds endpoint. If we were just using aws ssm
# start-session to connect we wouldn't need this step, but we can't configure
# the tunnel endpoint without using ssh.
echo -e 'y\n' | ssh-keygen -t rsa -f /tmp/temp -N '' >/dev/null 2>&1
aws ec2-instance-connect send-ssh-public-key \
  --instance-id "${bastion_id}" \
  --instance-os-user "${ssm_user}" \
  --ssh-public-key file:///tmp/temp.pub

ssh -i /tmp/temp \
  -Nf -M \
  -L "${local_port}":"${endpoint}":"${remote_port}" \
  -o "IdentitiesOnly=yes" \
  -o "UserKnownHostsFile=/dev/null" \
  -o "StrictHostKeyChecking=no" \
  -o ProxyCommand="aws ssm start-session --target %h --document AWS-StartSSHSession --parameters portNumber=%p" \
  "${ssm_user}"@"${bastion_id}"
