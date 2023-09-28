# SPDX-FileCopyrightText: 2023 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

include(sbom)

sbom_generate(SUPPLIER Demcon SUPPLIER_URL https://demcon.com)
sbom_finalize()
