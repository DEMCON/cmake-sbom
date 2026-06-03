# SPDX-FileCopyrightText: 2023-2026 Jochem Rutgers
#
# SPDX-License-Identifier: CC0-1.0

add_library(module_A_lib STATIC module_A.c)
install(TARGETS module_A_lib ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
sbom_add(TARGET module_A_lib)
