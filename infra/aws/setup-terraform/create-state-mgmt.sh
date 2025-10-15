#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#+SYNOPSIS
#+    ${SCRIPT_NAME} --bucket <name>
#+
#+DESCRIPTION
#+    Create resources for base terraform state
#+
#+OPTIONS
#+    --bucket <name>
#+          The name of the S3 bucket to hold TF state
#+    -h, --help
#+          Print this help
#+
#+EXAMPLES
#+    ${SCRIPT_NAME} --bucket my-bucket
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

bucket_policy() {
  cat <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"DenyInsecureTransport",
      "Effect":"Deny",
      "Principal":"*",
      "Action":"s3:*",
      "Resource":[
        "arn:aws:s3:::${BUCKET_NAME}",
        "arn:aws:s3:::${BUCKET_NAME}/*"
      ],
      "Condition":{ "Bool":{ "aws:SecureTransport":"false" } }
    }
  ]
}
EOF
}

create_bucket() {
  if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
    echo "S3 bucket already exists: s3://${BUCKET_NAME}"
    return
  fi

  echo "Creating S3 bucket: s3://${BUCKET_NAME}"
  if [ "${AWS_REGION}" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}"
  else
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --create-bucket-configuration LocationConstraint="${AWS_REGION}"
  fi

  echo "Blocking public access on bucket…"
  aws s3api put-public-access-block --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }'

  echo "Enabling versioning…"
  aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

  echo "Enforcing default encryption (AES256)…"
  aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" }
      }]
    }'

  echo "Adding TLS-only bucket policy…"
  aws s3api put-bucket-policy --bucket "${BUCKET_NAME}" --policy "$(bucket_policy)"

  echo "Setting lifecycle to expire noncurrent versions after 90 days…"
  aws s3api put-bucket-lifecycle-configuration \
    --bucket "${BUCKET_NAME}" \
    --lifecycle-configuration '{
      "Rules": [{
        "ID": "expire-old-versions",
        "Status": "Enabled",
        "Filter": { "Prefix": "" },
        "NoncurrentVersionExpiration": { "NoncurrentDays": 90 }
      }]
    }'
}

print_terraform_setup() {
  echo "==> Done. Backend values to use in Terraform:"
  cat <<EOF
backend "s3" {
  bucket         = "${BUCKET_NAME}"
  key            = "management/root.tfstate"
  region         = "${AWS_REGION}"
  encrypt        = true
  use_lockfile   = true
}
EOF
}

main() {
  parse_args "$@"
  validate_args
  set_defaults
  print_args
  create_bucket
  create_table
  print_terraform_setup
}

main "$@"
