# SPDX-FileCopyrightText: 2023 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

include(sbom)

set(SBOM_SUPPLIER Demcon)
set(SBOM_SUPPLIER_URL https://demcon.com)

sbom_generate()
sbom_finalize()
