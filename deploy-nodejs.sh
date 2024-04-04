#!/usr/bin/env bash

# exit script on any failing command
set -e

DEPLOYER_FILE_PATH=$(realpath "${BASH_SOURCE[0]}")
DEPLOYER_DIR=$(dirname "${DEPLOYER_FILE_PATH}")

source ${DEPLOYER_DIR}/deploy-common.sh

# create release directory
echo "Deploying release ${RELEASE}"
ssh -i ${DEPLOY_KEY_PATH} ${DEPLOY_USER}@${DEPLOY_HOST} -p ${DEPLOY_PORT} /bin/bash << EOT
  mkdir -p ${DEPLOY_PATH}/releases
EOT

# upload deployment to actual server
echo "Uploading deploy source"
scp -q -i ${DEPLOY_KEY_PATH} -P ${DEPLOY_PORT} -r ${DEPLOY_SOURCE_PATH} ${DEPLOY_USER}@${DEPLOY_HOST}:${RELEASE_DIRECTORY}

# extract archive to release directory and run all artisan commands
ssh -i ${DEPLOY_KEY_PATH} ${DEPLOY_USER}@${DEPLOY_HOST} -p ${DEPLOY_PORT} /bin/bash << EOT
  # exit script on any failing command
  set -e

  # change working directory
  cd ${RELEASE_DIRECTORY}

  # switch working directory
  echo "Switch to release ${RELEASE}"
  ln -sTf ${RELEASE_DIRECTORY} ${DEPLOY_PATH}/current

  # delete all release directories except 2 latest
  echo "Cleaning up old releases"
  ls -dr ${DEPLOY_PATH}/releases/* | tail -n +3 | xargs rm -fr
EOT