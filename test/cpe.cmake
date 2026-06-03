# SPDX-FileCopyrightText: 2023-2026 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

include(sbom)

set(expected_cpe "cpe:2.3:o:vendor:custom_os:1.2.3:*:*:*:*:*:*:*")
set(output_file "${CMAKE_INSTALL_PREFIX}/cpe-test.spdx")

sbom_generate(
	OUTPUT "${output_file}" VERSION 1.2.3 CPE "${expected_cpe}"
	SUPPLIER Demcon
	SUPPLIER_URL https://demcon.com
)
sbom_finalize(NO_VERIFY)
