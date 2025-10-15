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

if should_publish; then
  ./gradlew final --info
  ./gradlew -Prelease.useLastTag=true -q printVersion
  ./gradlew -Prelease.useLastTag=true publish --info
fi
