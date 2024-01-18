# SPDX-FileCopyrightText: 2023-2024 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

include(sbom)

sbom_generate(SUPPLIER Demcon SUPPLIER_URL https://demcon.com)

sbom_add(PACKAGE foo)
sbom_add(PACKAGE foo DOWNLOAD_LOCATION http://foo.bar/baz)
sbom_add(
	PACKAGE bar
	DOWNLOAD_LOCATION http://somwhere.com/bar
	LICENSE CC0-1.0
	SUPPLIER "Person: me"
	VERSION 0.1
)

sbom_finalize(VERIFY)
