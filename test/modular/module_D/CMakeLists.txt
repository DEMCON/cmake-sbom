# SPDX-FileCopyrightText: 2023-2026 Jochem Rutgers
#
# SPDX-License-Identifier: CC0-1.0

cmake_minimum_required(VERSION 3.10)
cmake_policy(VERSION 3.10)

project(module_D LANGUAGES C)

include(GNUInstallDirs)
include(sbom)

sbom_generate(
	SUPPLIER Demcon
	SUPPLIER_URL https://demcon.com
	OUTPUT "${PROJECT_BINARY_DIR}/module_D-sbom.spdx"
)

add_library(module_D_lib STATIC module_D.c)
install(TARGETS module_D_lib ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
sbom_add(TARGET module_D_lib)

add_executable(module_D_app module_D_main.c)
target_link_libraries(module_D_app PRIVATE module_D_lib)
install(TARGETS module_D_app RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
sbom_add(TARGET module_D_app)

sbom_finalize()
