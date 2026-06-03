# SPDX-FileCopyrightText: 2023-2026 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

enable_language(C)

include(GNUInstallDirs)
include(sbom)

set(_modules_dir "@CMAKE_CURRENT_SOURCE_DIR@/modular")

sbom_generate(SUPPLIER Demcon SUPPLIER_URL https://demcon.com)

# Modules A and B are part of the top-level project and top-level SBOM.
add_subdirectory("${_modules_dir}/module_A" "${CMAKE_CURRENT_BINARY_DIR}/module_A")
add_subdirectory("${_modules_dir}/module_B" "${CMAKE_CURRENT_BINARY_DIR}/module_B")

# Modules C and D are separate CMake projects that produce their own SBOMs.
add_subdirectory("${_modules_dir}/module_C" "${CMAKE_CURRENT_BINARY_DIR}/module_C")
sbom_add(EXTERNAL SPDXRef-module-C
	 FILENAME "${CMAKE_CURRENT_BINARY_DIR}/module_C/module_C-sbom.spdx"
)

add_subdirectory("${_modules_dir}/module_D" "${CMAKE_CURRENT_BINARY_DIR}/module_D")
get_property(_sbom_D GLOBAL PROPERTY SBOM_FILENAME)
sbom_add(EXTERNAL SPDXRef-module-D FILENAME "${_sbom_D}")

sbom_finalize()
