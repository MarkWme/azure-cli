#!/usr/bin/env bash

set -e

. $(cd $(dirname $0); pwd)/artifacts.sh

ls -la $share_folder/build

ALL_MODULES=`find $share_folder/build/ -name "*.whl"`

##############################################
# Define colored output func
function title {
    LGREEN='\033[1;32m'
    CLEAR='\033[0m'

    echo -e ${LGREEN}$1${CLEAR}
}

function error_msg {
    LRED='\033[1;31m'
    CLEAR='\033[0m'

    echo -e ${LRED}$1${CLEAR}
}

# title 'Install azdev'
# pip install -qqq -e ./tools

# title 'Install code coverage tools'
# pip install -qqq coverage codecov

title 'Install private packages (optional)'
[ -d privates ] && pip install -qqq privates/*.whl

title 'Install products'
pip install -qqq $ALL_MODULES

title 'Install pytest'
pip install -qqq pytest pytest-xdist

title 'Installed packages'
pip freeze

target_profile=${AZURE_CLI_TEST_TARGET_PROFILE:-latest}
if [ "$target_profile" != "latest" ]; then
    # example: 2017-03-09-profile
    target_profile=$target_profile-profile
fi

title 'Running tests'

PYTHON_DIR=`cd $(dirname $(which python)); cd ..; pwd`
SITE_PACKAGES_DIR=`find $PYTHON_DIR -name site-packages`

set +e
for TEST_DIR in `find $SITE_PACKAGES_DIR/azure/cli/command_modules -type d | grep -e 'tests/latest$'`; do
    echo ""
    MODULE_NAME=`basename $(dirname $(dirname $TEST_DIR))`
    title "Run automation in $MODULE_NAME"
    pytest -n 16 --no-print-logs $TEST_DIR || error_msg "Test failed in module $MODULE_NAME."
    echo ""
done
