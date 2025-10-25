#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#+SYNOPSIS
#+    ${SCRIPT_NAME} --bucket <name> --key <name> --root_dir <path>
#+
#+DESCRIPTION
#+    Initialize terraform to use S3 backend
#+
#+OPTIONS
#+    --bucket <name>
#+          The name of the S3 bucket to hold TF state
#+    --key <name>
#+          The name of the S3 key to hold TF state
#+    --root_dir <path>
#+          Path of terraform dir to init
#+    -h, --help
#+          Print this help
#+
#+EXAMPLES
#+    ${SCRIPT_NAME} --bucket my-bucket
#+        --key management/root.tfstate --root_dir ./
#+
#================================================================
# END_OF_HEADER
#================================================================

set -euo pipefail

SCRIPT_HEADER_SIZE=$(head -200 "${0}" | grep -n "^#.*END_OF_HEADER" | cut -f1 -d:)
SCRIPT_NAME="$(basename "${0}")"

show_help() {
  head -"${SCRIPT_HEADER_SIZE:-200}" "${0}" |
    grep -e "^#[%+]" |
    sed -e "s/^#[%+-]//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"
}

echo_error() {
  echo "$1" 1>&2
}

parse_args() {
  if [ $# -le 0 ]; then
    show_help
    exit 0
  fi
  while [ $# -gt 0 ]; do
    case "$1" in
      --bucket)
        if [ -z "$2" ]; then
          echo_error "Option --bucket needs an argument!"
          exit 1
        fi
        BUCKET_NAME="$2"
        shift 2
        ;;
      --key)
        if [ -z "$2" ]; then
          echo_error "Option --key needs an argument!"
          exit 1
        fi
        STATE_KEY="$2"
        shift 2
        ;;
      --root_dir)
        if [ -z "$2" ]; then
          echo_error "Option --root_dir needs an argument!"
          exit 1
        fi
        TERRAFORM_DIR="$2"
        shift 2
        ;;
      -h | --help)
        show_help
        exit 0
        ;;
      *)
        echo_error "Unknown option!"
        show_help
        exit 1
        ;;
    esac
  done
}

validate_args() {
  SHOULD_EXIT='false'
  if [ -z "${BUCKET_NAME}" ]; then
    echo_error "Missing --bucket"
    SHOULD_EXIT='true'
  fi
  if [ -z "${STATE_KEY}" ]; then
    echo_error "Missing --key"
    SHOULD_EXIT='true'
  fi
  if [ -z "${TERRAFORM_DIR}" ]; then
    echo_error "Missing --root_dir"
    SHOULD_EXIT='true'
  fi
  if [ "${SHOULD_EXIT}" = 'true' ]; then
    exit 2
  fi
}

set_defaults() {
  AWS_REGION="${AWS_REGION:-us-east-1}"
}

print_args() {
  echo "==> Management state bootstrap"
  echo "Bucket:  ${BUCKET_NAME}"
  echo "Region:  ${AWS_REGION}"
}

terraform_init() {
  terraform -chdir="${TERRAFORM_DIR}" init \
    -reconfigure \
    -backend-config="bucket=${BUCKET_NAME}" \
    -backend-config="key=${STATE_KEY}" \
    -backend-config="region=${AWS_REGION}" \
    -backend-config="encrypt=true" \
    -backend-config="use_lockfile=true"
}

main() {
  parse_args "$@"
  validate_args
  set_defaults
  print_args
  terraform_init
}

main "$@"
