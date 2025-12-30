#!/bin/sh

OWNER=DanielWillian
REPO=spring-app-deploy
GROUP=io.boot2prod
ARTIFACT=spring-app-deploy
BASE="https://maven.pkg.github.com/${OWNER}/${REPO}"

should_publish() {
  if VERSION="$(./gradlew -Prelease.useLastTag=true -q printVersion 2>/dev/null)"; then
    JAR_PATH="${GROUP}/${ARTIFACT}/${VERSION}/${ARTIFACT}-${VERSION}-spring.jar"
    CODE="$(curl -s -I -L -o /dev/null -w "%{http_code}\n" \
      -u "${GITHUB_ACTOR}:${GITHUB_TOKEN}" \
      "${BASE}/${JAR_PATH}")"
    if [ "$CODE" = "200" ]; then
      echo "Artifact already exists (${BASE}/${JAR_PATH}) -> $CODE! Skipping publish"
      return 1
    else
      echo "Artifact not found or not 200 (${BASE}/${JAR_PATH}) -> $CODE! We should publish"
      return 0
    fi
  else
    echo "There's no tag for the current commit, we should publish"
  fi
}

push_to_s3() {
  if [ -z "${ARTIFACT_BUCKET_NAME}" ]; then
    echo "Empty ARTIFACT_BUCKET_NAME env" >&2
    exit 3
  fi

  JAR_NAME="${ARTIFACT}-${VERSION}-spring.jar"
  JAR_PATH="build/${JAR_NAME}"
  S3_KEY="${ARTIFACT}/${VERSION}/${JAR_NAME}"
  S3_PATH="s3://${ARTIFACT_BUCKET_NAME}/${S3_KEY}"
  if [ -f "${JAR_PATH}" ]; then
    aws s3 cp "${JAR_PATH}" "${S3_PATH}" --only-show-errors
    echo "Copied jar to ${S3_KEY}"
  else
    echo "${JAR_PATH} does not exist! Could not upload to s3" >&2
    exit 5
  fi
}

if should_publish; then
  ./gradlew final --info
  VERSION="$(./gradlew -Prelease.useLastTag=true -q printVersion)"
  export VERSION
  ./gradlew -Prelease.useLastTag=true publish --info
  push_to_s3
fi
