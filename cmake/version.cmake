# SPDX-FileCopyrightText: 2023-2025 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.10)

message(DEPRECATION "Include git_version.cmake instead")

include(${CMAKE_CURRENT_LIST_DIR}/git_version.cmake)

