# SPDX-FileCopyrightText: 2023 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

include(sbom)

sbom_generate(SUPPLIER Demcon SUPPLIER_URL https://demcon.com)

install(FILES ${CMAKE_CURRENT_LIST_FILE} DESTINATION .)

# Does not exist before installing.
sbom_file(FILENAME CMakeLists.txt FILETYPE OTHER)

# Twice the same file, should not conflict.
sbom_file(FILENAME CMakeLists.txt FILETYPE OTHER)

sbom_finalize()
