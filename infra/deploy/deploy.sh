#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <instance-id> <path-to-jar> [region]"
  exit 1
fi

INSTANCE_ID="$1"
LOCAL_JAR="$2"
KEY_PATH="$3"
REGION="${4:-us-east-1}"

SERVICE_NAME="spring-app-deploy"
REMOTE_USER="ec2-user"
REMOTE_DIR="/opt/spring-app-deploy"
REMOTE_JAR_NAME="$(basename "${LOCAL_JAR}")"
APP_CURRENT_JAR_PATH="${REMOTE_DIR}/current.jar"
REMOTE_JAR_PATH="${REMOTE_DIR}/${REMOTE_JAR_NAME}"
UPLOAD_JAR_PATH="${HOME}/${REMOTE_JAR_NAME}"

echo "[deploy] Copying JAR ${REMOTE_JAR_NAME} to instance via SSM Session Manager (scp + AWS-StartSSHSession)..."
scp \
  -i "${KEY_PATH}" \
  -o "ProxyCommand=aws ssm start-session --region ${REGION} --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'" \
  "${LOCAL_JAR}" \
  "${REMOTE_USER}@${INSTANCE_ID}:${UPLOAD_JAR_PATH}"

echo "[deploy] JAR copied to ${UPLOAD_JAR_PATH}"

echo "[deploy] Running remote deployment commands via SSH..."

# shellcheck disable=SC2087
ssh \
  -i "${KEY_PATH}" \
  -o "ProxyCommand=aws ssm start-session --region ${REGION} --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'" \
  "${REMOTE_USER}@${INSTANCE_ID}" <<EOF
set -euo pipefail

echo "[remote] Moving JAR into ${REMOTE_JAR_PATH}..."
sudo mv ${UPLOAD_JAR_PATH} "${REMOTE_JAR_PATH}"

echo "[remote] Fixing ownership and permissions..."
sudo chown spring-app-deploy:spring-app-deploy "${REMOTE_JAR_PATH}"
sudo chmod 640 "${REMOTE_JAR_PATH}"

echo "[remote] Updating symlink ${REMOTE_JAR_PATH} -> ${APP_CURRENT_JAR_PATH}..."
sudo ln -s "${REMOTE_JAR_PATH}" "${APP_CURRENT_JAR_PATH}"

echo "[remote] Restarting systemd service ${SERVICE_NAME}..."
sudo systemctl daemon-reload || true
sudo systemctl restart "${SERVICE_NAME}"

echo "[remote] Deployment complete. Current jar: ${REMOTE_JAR_NAME}"
EOF

gcho "[deploy] Done."
