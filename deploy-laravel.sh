#!/usr/bin/env bash

# exit script on any failing command
set -e

DEPLOYER_FILE_PATH=$(realpath "${BASH_SOURCE[0]}")
DEPLOYER_DIR=$(dirname "${DEPLOYER_FILE_PATH}")
DEPLOY_TYPE=laravel

source ${DEPLOYER_DIR}/deploy-common.sh

# laravel specifics vars
DEPLOY_PHP_COMMAND="${DEPLOY_PHP_COMMAND:-php}"
DEPLOY_SHARED_FILES="${DEPLOY_SHARED_FILES:-.env}"
DEPLOY_SHARED_DIRECTORIES="${DEPLOY_SHARED_DIRECTORIES:-storage}"
DEPLOY_SHARED_STORAGE_DIRECTORIES="${DEPLOY_SHARED_STORAGE_DIRECTORIES:-app/public;framework/cache/data;framework/views;framework/sessions;logs}"
DEPLOY_ARTISAN_COMMANDS="${DEPLOY_ARTISAN_COMMANDS:-storage:link;config:cache;migrate --force;view:cache;queue:restart}"
DEPLOY_SOURCE_NAME=`basename ${DEPLOY_SOURCE_PATH}`

echo "Deploying release ${RELEASE}"
# create release directory
ssh ${SSH_ARGS} ${DEPLOY_USER}@${DEPLOY_HOST} /bin/bash << EOT
  # exit script on any failing command
  set -e

  # use ; as delimiter for list params
  export IFS=";"

  mkdir -p ${RELEASE_DIR}

  # create shared storage directories
  export LOCAL_DEPLOY_SHARED_STORAGE_DIRECTORIES="${DEPLOY_SHARED_STORAGE_DIRECTORIES}"
  for shared_storage_directory in \${LOCAL_DEPLOY_SHARED_STORAGE_DIRECTORIES}; do
    mkdir -p ${DEPLOY_PATH}/shared/storage/\${shared_storage_directory}
  done

  # do not go further as .env is not created yet
  export LOCAL_ENV_PATH="${DEPLOY_PATH}/shared/.env"
  if [ ! -f "\${LOCAL_ENV_PATH}" ]; then
    echo "${DEPLOY_PATH}/shared/.env does not exists"
    exit 1
  fi
EOT

# call upload method by specifying upload target
upload ${RELEASE_DIR}/${DEPLOY_SOURCE_NAME}

# extract archive to release directory and run all artisan commands
ssh ${SSH_ARGS} ${DEPLOY_USER}@${DEPLOY_HOST} /bin/bash << EOT
  # exit script on any failing command
  set -e

  # use ; as delimiter for list params
  export IFS=";"

  # change working directory
  cd ${RELEASE_DIR}

  # extract and remove archive
  tar xzf ${DEPLOY_SOURCE_NAME}
  rm ${DEPLOY_SOURCE_NAME}

  # symlink shared files
  export LOCAL_DEPLOY_SHARED_FILES="${DEPLOY_SHARED_FILES}"
  for shared_file in \${LOCAL_DEPLOY_SHARED_FILES}; do
    ln -sf ${DEPLOY_PATH}/shared/\${shared_file} \${shared_file}
  done

  # symlink shared directories
  export LOCAL_DEPLOY_SHARED_DIRECTORIES="${DEPLOY_SHARED_DIRECTORIES}"
  for shared_directory in \${LOCAL_DEPLOY_SHARED_DIRECTORIES}; do
    ln -sf ${DEPLOY_PATH}/shared/\${shared_directory} \${shared_directory}
  done

  # artisan post-deployment commands
  export LOCAL_DEPLOY_ARTISAN_COMMANDS="${DEPLOY_ARTISAN_COMMANDS}"
  for artisan_command in \${LOCAL_DEPLOY_ARTISAN_COMMANDS}; do
    bash -c "${DEPLOY_PHP_COMMAND} artisan \${artisan_command}"
  done

  # switch working directory
  echo "Switching to release ${RELEASE}"
  ln -sTf ${RELEASE_DIR} ${DEPLOY_PATH}/current

  # delete all release directories except 2 latest
  echo "Cleaning up old releases"
  ls -dr ${DEPLOY_PATH}/releases/* | tail -n +3 | xargs rm -fr
EOT
