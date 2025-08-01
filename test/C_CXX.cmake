# SPDX-FileCopyrightText: 2023-2025 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

include(sbom)

enable_language(C CXX)

sbom_generate(SUPPLIER Demcon SUPPLIER_URL https://demcon.com)
sbom_finalize()
