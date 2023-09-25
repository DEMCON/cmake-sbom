# SPDX-FileCopyrightText: 2023 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

# This file only performs a few sanity checks on the repo. No building is required to use the
# cmake/*.cmake files.

cmake_minimum_required(VERSION 3.5)
cmake_policy(VERSION 3.5)

project(cmake-sbom)

include(sbom)

reuse_lint()

add_subdirectory(example)
