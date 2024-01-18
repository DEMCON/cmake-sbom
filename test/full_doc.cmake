# SPDX-FileCopyrightText: 2023-2024 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

include(sbom)

sbom_generate(
	OUTPUT "${CMAKE_INSTALL_PREFIX}/full-sbom.spdx"
	COPYRIGHT "2023 me"
	LICENSE "CC0-1.0"
	NAMESPACE "https://test.com/spdxdoc/me"
	PROJECT "test-full_doc"
	SUPPLIER Demcon
	SUPPLIER_URL https://demcon.com
)

sbom_finalize()
