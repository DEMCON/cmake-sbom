# SPDX-FileCopyrightText: 2023 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

include(sbom)

sbom_generate(SUPPLIER Demcon SUPPLIER_URL https://demcon.com)

install(FILES ${CMAKE_CURRENT_LIST_FILE} DESTINATION dir)
install(FILES ${CMAKE_CURRENT_LIST_FILE} DESTINATION dir RENAME file.txt)

sbom_add(DIRECTORY dir FILETYPE OTHER)
sbom_add(DIRECTORY dir FILETYPE DOCUMENTATION)

sbom_finalize()
