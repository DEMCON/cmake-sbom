# SPDX-FileCopyrightText: 2023-2026 Jochem Rutgers
#
# SPDX-License-Identifier: CC0-1.0

cmake_minimum_required(VERSION 3.10)
cmake_policy(VERSION 3.10)

project(module_C LANGUAGES C)

include(GNUInstallDirs)
include(sbom)

sbom_generate(
	SUPPLIER Demcon
	SUPPLIER_URL https://demcon.com
	OUTPUT "${PROJECT_BINARY_DIR}/module_C-sbom.spdx"
)

add_library(module_C_lib STATIC module_C.c)
install(TARGETS module_C_lib ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
sbom_add(TARGET module_C_lib)

sbom_finalize()
