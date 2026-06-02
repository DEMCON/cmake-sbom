# SPDX-FileCopyrightText: 2023-2026 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

enable_language(C)
include(GNUInstallDirs)

include(sbom)

sbom_generate(SUPPLIER Demcon SUPPLIER_URL https://demcon.com)

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/foo.c "int main() { return 0; }\n")

add_library(foo SHARED ${CMAKE_CURRENT_BINARY_DIR}/foo.c)
install(TARGETS foo LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}")
sbom_add(TARGET foo)

sbom_finalize()
