#!/usr/bin/env bash

# exit script on any failing command
set -e

DEPLOY_REVISION="${DEPLOY_REVISION:-dev}"

PROJECT_DIR=`pwd`
PROJECT_BUILDIGNORE_FILE="${PROJECT_DIR}/.buildignore"
PROJECT_REVISION_FILE="${PROJECT_DIR}/public/REVISION"
PROJECT_BUILD_FILE="${PROJECT_DIR}/app.tgz"

BUILDER_FILE_PATH=`realpath $0`
BUILDER_DIR=`dirname ${BUILDER_FILE_PATH}`
BUILDIGNORE_FILE="${BUILDER_DIR}/.buildignore"

if [ -f $PROJECT_BUILDIGNORE_FILE ]; then
  echo "Using custom .buildignore"
  BUILDIGNORE_FILE=${PROJECT_BUILDIGNORE_FILE}
fi

echo "building ${DEPLOY_REVISION} deployment archive"

# write revision information from CI (tag:git-commit-hash)
echo ${DEPLOY_REVISION} > ${PROJECT_REVISION_FILE}

composer install --prefer-dist --no-progress --no-interaction --optimize-autoloader
npm i
npm run build
composer install --prefer-dist --no-progress --no-interaction --no-dev --optimize-autoloader
touch ${PROJECT_BUILD_FILE}
tar -zc --no-xattrs --exclude-from=${BUILDIGNORE_FILE} -f ${PROJECT_BUILD_FILE} .
rm ${PROJECT_REVISION_FILE}
