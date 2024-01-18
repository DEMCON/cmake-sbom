# SPDX-FileCopyrightText: 2023-2024 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

include(sbom)
set(SBOM_SUPPLIER Demcon)
set(SBOM_SUPPLIER_URL https://demcon.com)

make_directory(${CMAKE_CURRENT_BINARY_DIR}/other)
file(
	WRITE ${CMAKE_CURRENT_BINARY_DIR}/other/CMakeLists.txt
	"
	project(other)
	sbom_generate(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/other-sbom.spdx)
	sbom_finalize()
	"
)
add_subdirectory(${CMAKE_CURRENT_BINARY_DIR}/other ${CMAKE_CURRENT_BINARY_DIR}/other-build)

# Last generated SBOM file. It's valid until the next sbom_generate().
get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)

sbom_generate()
sbom_add(EXTERNAL SPDXRef-other FILENAME "${_sbom}")

sbom_external(
	EXTERNAL SPDXRef-other
	FILENAME "${_sbom}"
	RELATIONSHIP "\@SBOM_LAST_SPDXID\@:SPDXRef-other VARIANT_OF ${SBOM_LAST_SPDXID}:SPDXRef-other"
)
sbom_finalize()
