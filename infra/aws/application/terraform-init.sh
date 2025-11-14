#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#+SYNOPSIS
#+    ${SCRIPT_NAME} --bucket <name> --context <name>
#+
#+DESCRIPTION
#+    Initialize application terraform
#+
#+OPTIONS
#+    --bucket <name>
#+          The name of the S3 bucket to hold TF state
#+    --context <name>
#+          The context of the deployment
#+    -h, --help
#+          Print this help
#+
#+EXAMPLES
#+    ${SCRIPT_NAME} --bucket my-bucket --context dev
#+
#================================================================
# END_OF_HEADER
#================================================================

set -euo pipefail

SCRIPT_HEADER_SIZE=$(head -200 "${0}" | grep -n "^#.*END_OF_HEADER" | cut -f1 -d:)
SCRIPT_NAME="$(basename "${0}")"
SCRIPT_DIR="$(dirname "${0}")"

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
      --context)
        if [ -z "$2" ]; then
          echo_error "Option --context needs an argument!"
          exit 1
        fi
        CONTEXT="$2"
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
  if [ -z "${CONTEXT}" ]; then
    echo_error "Missing --context"
    SHOULD_EXIT='true'
  fi
  if [ "${SHOULD_EXIT}" = 'true' ]; then
    exit 2
  fi
}

terraform_init() {
  "${SCRIPT_DIR}/../../terraform-init.sh" \
    --bucket "${BUCKET_NAME}" \
    --key "deployment/application/${CONTEXT}" \
    --root_dir "${SCRIPT_DIR}"
}

main() {
  parse_args "$@"
  validate_args
  terraform_init
}

main "$@"
