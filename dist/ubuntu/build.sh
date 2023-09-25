#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jochem Rutgers
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

cmake ../../.. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="`pwd`/deploy" \
	-DCMAKE_MODULE_PATH="`pwd`/../../../cmake" -DPython3_ROOT_DIR="`pwd`/../../venv"

cmake --build . --target install

popd > /dev/null
