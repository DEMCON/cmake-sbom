# SPDX-FileCopyrightText: 2023-2025 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

# This file only performs a few sanity checks on the repo. No building is required to use the
# cmake/*.cmake files.

cmake_minimum_required(VERSION 3.10)
cmake_policy(VERSION 3.10)

project(cmake-sbom)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(git_version)
include(sbom)

reuse_lint()

add_subdirectory(example)
add_subdirectory(test)
