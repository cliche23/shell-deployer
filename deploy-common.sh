#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 DEPLOYMENT_SOURCE_PATH" >&2
  exit 1
fi

# The last argument is expected to be the option --with-build
WITH_BUILD=false
if [[ " ${@: -1} " == *" --with-build "* ]]; then
  WITH_BUILD=true
  # Remove the last argument which is --with-build
  set -- "${@:1:$(($#-1))}"
fi

REQUIRED_VARS=("DEPLOY_HOST DEPLOY_USER DEPLOY_PATH")

for variableName in $REQUIRED_VARS; do
  if [[ -z "${!variableName}" ]]; then
    echo "${variableName} env variable is undefined"
    exit 1
  fi
done

RELEASE=`date -u +%Y%m%d%H%M%S`
RELEASE_DIRECTORY=${DEPLOY_PATH}/releases/${RELEASE}

DEPLOY_SOURCE_PATH=$1

DEPLOY_PORT="${DEPLOY_PORT:-22}"
DEPLOY_SSH_PATH=$HOME/.ssh
DEPLOY_SSH_KNOWN_HOSTS_PATH=$DEPLOY_SSH_PATH/known_hosts
DEPLOY_KEY_PATH="${DEPLOY_KEY_PATH:-$DEPLOY_SSH_PATH/id_rsa}"

if [ -n "${DEPLOY_SSH_KNOWN_HOSTS}" ]; then
  # make sure that .ssh directory exists
  mkdir -p -m 700 ${DEPLOY_SSH_PATH}

  # append known hosts
  echo "${DEPLOY_SSH_KNOWN_HOSTS}" >> ${DEPLOY_SSH_KNOWN_HOSTS_PATH}
fi

if [ -n "${DEPLOY_SSH_KEY}" ]; then
  echo "${DEPLOY_SSH_KEY}" > ${DEPLOY_KEY_PATH}
  chmod 600 ${DEPLOY_KEY_PATH}
fi
