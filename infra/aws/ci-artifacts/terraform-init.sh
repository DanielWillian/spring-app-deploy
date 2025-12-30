#!/bin/sh
SCRIPT_DIR="$(dirname "${0}")"

if [ -z "${ARTIFACT_BUCKET_NAME}" ]; then
  echo "Empty ARTIFACT_BUCKET_NAME env" >&2
  exit 1
fi

"${SCRIPT_DIR}/../../terraform-init.sh" \
  --bucket "${ARTIFACT_BUCKET_NAME}" \
  --key "management/ci-artifacts" \
  --root_dir "${SCRIPT_DIR}"
