# SPDX-FileCopyrightText: 2023-2026 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

include(sbom)

sbom_generate(
	OUTPUT "${CMAKE_INSTALL_PREFIX}/spdx22-test.spdx" SPDX_VERSION 2.2 VERSION 1.2.3
	SUPPLIER Demcon
	SUPPLIER_URL https://demcon.com
)
sbom_finalize(NO_VERIFY)
