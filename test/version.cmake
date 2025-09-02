# SPDX-FileCopyrightText: 2023-2025 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

project(version-project VERSION 1.2.3)

include(sbom)

sbom_generate(SUPPLIER Demcon SUPPLIER_URL https://demcon.com)
sbom_finalize()
