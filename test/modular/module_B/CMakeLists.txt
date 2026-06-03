# SPDX-FileCopyrightText: 2023-2026 Jochem Rutgers
#
# SPDX-License-Identifier: CC0-1.0

add_library(module_B_lib STATIC module_B.c)
install(TARGETS module_B_lib ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
sbom_add(TARGET module_B_lib)

add_executable(module_B_app module_B_main.c)
target_link_libraries(module_B_app PRIVATE module_B_lib)
install(TARGETS module_B_app RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
sbom_add(TARGET module_B_app)
