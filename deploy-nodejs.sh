#!/usr/bin/env bash

# exit script on any failing command
set -e

DEPLOYER_FILE_PATH=$(realpath "${BASH_SOURCE[0]}")
DEPLOYER_DIR=$(dirname "${DEPLOYER_FILE_PATH}")
DEPLOY_TYPE=nodejs

source ${DEPLOYER_DIR}/deploy-common.sh

# silence file upload
SCP_ARGS="${SCP_ARGS} -q"

# create release directory
echo "Deploying release ${RELEASE}"
ssh ${SSH_ARGS} ${DEPLOY_USER}@${DEPLOY_HOST} /bin/bash << EOT
  mkdir -p ${DEPLOY_PATH}/releases
EOT

# call upload method by specifying upload target
upload ${RELEASE_DIR}

# extract archive to release directory and run all artisan commands
ssh ${SSH_ARGS} ${DEPLOY_USER}@${DEPLOY_HOST} /bin/bash << EOT
  # exit script on any failing command
  set -e

  # change working directory
  cd ${RELEASE_DIR}

  # switch working directory
  echo "Switching to release ${RELEASE}"
  ln -sTf ${RELEASE_DIR} ${DEPLOY_PATH}/current

  # custom post-deployment commands
  export LOCAL_DEPLOY_CUSTOM_COMMANDS="${DEPLOY_CUSTOM_COMMANDS}"
  for custom_command in \${LOCAL_DEPLOY_CUSTOM_COMMANDS}; do
    echo "\${custom_command}"
    bash -c "\${custom_command}"
  done

  # delete all release directories except 2 latest
  echo "Cleaning up old releases"
  ls -dr ${DEPLOY_PATH}/releases/* | tail -n +3 | xargs rm -fr
EOT
