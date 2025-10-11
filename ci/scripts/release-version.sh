#!/bin/sh

OWNER=DanielWillian
REPO=spring-app-deploy
GROUP=io.boot2prod
ARTIFACT=spring-app-deploy
BASE="https://maven.pkg.github.com/${OWNER}/${REPO}"

should_release() {
  if VERSION="$(./gradlew -Prelease.useLastTag=true -q printVersion 2>/dev/null)"; then
    JAR_NAME="${ARTIFACT}-${VERSION}-spring.jar"
    JAR_PATH="${GROUP}/${ARTIFACT}/${VERSION}/${JAR_NAME}"
    LOCAL_JAR_PATH="build/${JAR_NAME}"
    CODE="$(curl -s -I -L -o "${LOCAL_JAR_PATH}" -w "%{http_code}\n" \
        -u "${GITHUB_ACTOR}:${GITHUB_TOKEN}" \
        "${BASE}/${JAR_PATH}")"
    if [ "${CODE}" != "200" ]; then
      echo "Artifact not found or not 200 (${BASE}/${JAR_PATH}) -> ${CODE}! Can't release!"
      return 1
    fi

    TAG="v${VERSION}"
    if gh release view "${TAG}" >/dev/null 2>&1; then
      echo "Release ${TAG} already exists!"
      return 3
    else
      echo "Release ${TAG} does not exist! Releasing..."
      return 0
    fi
  else
    echo "There's no tag for the current commit, we can't release!"
    return 2
  fi
}

if should_release; then
  gh release create "${TAG}" "${LOCAL_JAR_PATH}" \
        --title "${TAG}" \
        --generate-notes
fi
