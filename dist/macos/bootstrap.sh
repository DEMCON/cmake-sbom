#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

set -exuo pipefail

function gotErr {
	echo -e "\nError occurred, stopping\n"
	exit 1
}

trap gotErr ERR

function get_brew {
	if ! which brew > /dev/null; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || gotErr
	fi
}

function do_install {
	for c in "$@"; do
		if ! which "${c}" > /dev/null; then
			# Command not found. We need brew to install it.
			get_brew || gotErr

			if ! brew ls --versions "${c}" > /dev/null; then
				HOMEBREW_NO_AUTO_UPDATE=1 brew install "${c}" || gotErr
			fi
		fi
	done
}

do_install python3 git cmake
