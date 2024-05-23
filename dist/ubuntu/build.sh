#!/bin/bash

# SPDX-FileCopyrightText: 2023-2024 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

set -euo pipefail

pushd "$( cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P )" > /dev/null

if [[ ! -e ../venv ]]; then
	python3 -m venv ../venv
	../venv/bin/python3 -m pip install -r ../common/requirements.txt
fi

mkdir -p build
cd build

cmake ../../.. --no-warn-unused-cli -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="`pwd`/deploy" \
	-DPython3_ROOT_DIR="`pwd`/../../venv" -DPython3_EXECUTABLE="`pwd`/../../venv/bin/python3" "$@"

cmake --build . --target install

popd > /dev/null
