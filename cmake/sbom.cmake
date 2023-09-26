# SPDX-FileCopyrightText: 2023 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

if(COMMAND sbom_generate)
	return()
endif()

include(GNUInstallDirs)
include(${CMAKE_CURRENT_LIST_DIR}/version.cmake)

find_package(
	Python3
	COMPONENTS Interpreter
	REQUIRED
)

# Common Platform Enumeration: https://nvd.nist.gov/products/cpe
if(WIN32)
	if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "AMD64")
		set(_arch "x64")
	elseif("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "IA64")
		set(_arch "x64")
	elseif("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "ARM64")
		set(_arch "arm64")
	elseif("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "X86")
		set(_arch "x86")
	elseif(CMAKE_CXX_COMPILER MATCHES "64")
		set(_arch "x64")
	elseif(CMAKE_CXX_COMPILER MATCHES "86")
		set(_arch "x86")
	else()
		set(_arch "*")
	endif()

	if("${CMAKE_SYSTEM_VERSION}" STREQUAL "6.1")
		set(SBOM_CPE "cpe:2.3:o:microsoft:windows_7:-:*:*:*:*:*:${_arch}:*")
	elseif("${CMAKE_SYSTEM_VERSION}" STREQUAL "6.2")
		set(SBOM_CPE "cpe:2.3:o:microsoft:windows_8:-:*:*:*:*:*:${_arch}:*")
	elseif("${CMAKE_SYSTEM_VERSION}" STREQUAL "6.3")
		set(SBOM_CPE "cpe:2.3:o:microsoft:windows_8.1:-:*:*:*:*:*:${_arch}:*")
	elseif("${CMAKE_SYSTEM_VERSION}" VERSION_GREATER_EQUAL 10)
		set(SBOM_CPE "cpe:2.3:o:microsoft:windows_10:-:*:*:*:*:*:${_arch}:*")
	else()
		set(SBOM_CPE "cpe:2.3:o:microsoft:windows:-:*:*:*:*:*:${_arch}:*")
	endif()
elseif(APPLE)
	set(SBOM_CPE "cpe:2.3:o:apple:mac_os:*:*:*:*:*:*:${CMAKE_SYSTEM_PROCESSOR}:*")
elseif(UNIX)
	set(SBOM_CPE "cpe:2.3:o:canonical:ubuntu_linux:-:*:*:*:*:*:${CMAKE_SYSTEM_PROCESSOR}:*")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
	set(SBOM_CPE "cpe:2.3:h:arm:arm:-:*:*:*:*:*:*:*")
else()
	message(FATAL_ERROR "Unsupported platform")
endif()

# Sets the given variable to a unique SPDIXID-compatible value.
#
# Usage: sbom_spdxid VARIABLE <variable_name> [HINTS <hint>...])
function(sbom_spdxid)
	set(options)
	set(oneValueArgs VARIABLE)
	set(multiValueArgs HINTS)

	cmake_parse_arguments(
		SBOM_SPDXID "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)

	if("${SBOM_SPDXID_VARIABLE}" STREQUAL "")
		message(FATAL_ERROR "Missing VARIABLE")
	endif()

	get_property(_spdxids GLOBAL PROPERTY sbom_spdxids)
	set(_suffix "-${_spdxids}")
	math(EXPR _spdxids "${_spdxids} + 1")
	set_property(GLOBAL PROPERTY sbom_spdxids "${_spdxids}")

	foreach(_hint IN LISTS SBOM_SPDXID_HINTS)
		string(REGEX REPLACE "[^a-zA-Z0-9]+" "-" _id "${_hint}")
		string(REGEX REPLACE "-+$" "" _id "${_id}")
		if(NOT "${_id}" STREQUAL "")
			set(_id "${_id}${_suffix}")
			break()
		endif()
	endforeach()

	if("${_id}" STREQUAL "")
		set(_id "SPDXRef${_suffix}")
	endif()

	if(NOT "${_id}" MATCHES "^SPDXRef-[-a-zA-Z0-9]+$")
		message(FATAL_ERROR "Invalid SPDXID \"${_id}\"")
	endif()

	set(${SBOM_SPDXID_VARIABLE}
	    "${_id}"
	    PARENT_SCOPE
	)
endfunction()

# Starts SBOM generation. Call sbom_add() and friends afterwards. End with sbom_finalize(). Input
# files allow having variables and generator expressions.
#
# Usage: sbom_generate(OUTPUT <filename> [PROJECT <name>] [INPUT <filename>... | [LICENSE <license>]
# [COPYRIGHT <copyright>]])
#
# If no INPUTs are given, a standard SPDX header is produced.
function(sbom_generate)
	set(options)
	set(oneValueArgs OUTPUT LICENSE COPYRIGHT PROJECT)
	set(multiValueArgs INPUT)
	cmake_parse_arguments(
		SBOM_GENERATE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)

	string(TIMESTAMP NOW_UTC UTC)

	if("${SBOM_GENERATE_OUTPUT}" STREQUAL "")
		message(FATAL_ERROR "Missing OUTPUT")
	endif()

	if("${SBOM_GENERATE_LICENSE}" STREQUAL "")
		set(SBOM_GENERATE_LICENSE "NOASSERTION")
	endif()

	if("${SBOM_GENERATE_COPYRIGHT}" STREQUAL "")
		# There is a race when building at New Year's Eve...
		string(TIMESTAMP NOW_YEAR "%Y" UTC)
		set(SBOM_GENERATE_COPYRIGHT "${NOW_YEAR} Demcon")
	endif()

	if("${SBOM_GENERATE_PROJECT}" STREQUAL "")
		set(SBOM_GENERATE_PROJECT "${PROJECT_NAME}")
	endif()

	string(REGEX REPLACE "[^-A_Za-z.]+" "-" SBOM_GENERATE_PROJECT "${SBOM_GENERATE_PROJECT}")

	install(
		CODE "
		message(STATUS \"Installing: ${SBOM_GENERATE_OUTPUT}\")
		file(WRITE \"${SBOM_GENERATE_OUTPUT}\" \"\")
		"
	)

	if("${SBOM_GENERATE_INPUT}" STREQUAL "")
		set(_f "${CMAKE_CURRENT_BINARY_DIR}/SPDXRef-DOCUMENT.cmake")

		get_filename_component(doc_name "${SBOM_GENERATE_OUTPUT}" NAME_WE)

		file(
			GENERATE
			OUTPUT "${_f}"
			CONTENT
				"SPDXVersion: SPDX-2.3
DataLicense: CC0-1.0
SPDXID: SPDXRef-DOCUMENT
DocumentName: ${doc_name}
DocumentNamespace: https://demcon.com/spdxdocs/${PROJECT_NAME}-${GIT_VERSION}
Creator: Organization: Demcon ()
Creator: Tool: cmake-sbom
CreatorComment: <text>This SPDX document was created from CMake ${CMAKE_VERSION}, using cmake-sbom
from https://github.com/DEMCON/cmake-sbom</text>
Created: ${NOW_UTC}

PackageName: ${CMAKE_CXX_COMPILER_ID}
SPDXID: SPDXRef-compiler
PackageVersion: ${CMAKE_CXX_COMPILER_VERSION}
PackageDownloadLocation: NOASSERTION
PackageLicenseConcluded: NOASSERTION
PackageLicenseDeclared: NOASSERTION
PackageCopyrightText: NOASSERTION
FilesAnalyzed: false
PackageSummary: <text>The compiler as identified by CMake, running on ${CMAKE_HOST_SYSTEM_NAME} (${CMAKE_HOST_SYSTEM_PROCESSOR})</text>
PrimaryPackagePurpose: APPLICATION
Relationship: SPDXRef-compiler CONTAINS NOASSERTION
Relationship: SPDXRef-compiler BUILD_DEPENDENCY_OF SPDXRef-${PROJECT_NAME}
RelationshipComment: <text>SPDXRef-${PROJECT_NAME} is built by compiler ${CMAKE_CXX_COMPILER_ID} (${CMAKE_CXX_COMPILER}) version ${CMAKE_CXX_COMPILER_VERSION}</text>

PackageName: ${PROJECT_NAME}
SPDXID: SPDXRef-${SBOM_GENERATE_PROJECT}
ExternalRef: SECURITY cpe23Type ${SBOM_CPE}
ExternalRef: PACKAGE-MANAGER purl pkg:supplier/Demcon/${PROJECT_NAME}@${GIT_VERSION}
PackageVersion: ${GIT_VERSION}
PackageSupplier: Organization: Demcon
PackageDownloadLocation: NOASSERTION
PackageLicenseConcluded: ${SBOM_GENERATE_LICENSE}
PackageLicenseDeclared: ${SBOM_GENERATE_LICENSE}
PackageCopyrightText: ${SBOM_GENERATE_COPYRIGHT}
PackageHomePage: https://demcon.com
PackageComment: <text>Built by CMake ${CMAKE_VERSION} with ${CMAKE_BUILD_TYPE} configuration for ${CMAKE_SYSTEM_NAME} (${CMAKE_SYSTEM_PROCESSOR})</text>
BuiltDate: ${NOW_UTC}
Relationship: SPDXRef-DOCUMENT DESCRIBES SPDXRef-${SBOM_GENERATE_PROJECT}
"
		)

		install(
			CODE "
				file(READ \"${_f}\" _f_contents)
				file(APPEND \"${SBOM_GENERATE_OUTPUT}\" \"\${_f_contents}\")
			"
		)
	else()
		foreach(_f IN LISTS SBOM_GENERATE_INPUT)
			set(_f_in "${CMAKE_CURRENT_BINARY_DIR}/${_f}")
			set(_f_in_gen "${_f_in}_gen")
			configure_file("${_f}" "${_f_in}" @ONLY)
			file(
				GENERATE
				OUTPUT "${_f_in_gen}"
				INPUT "${_f_in}"
			)
			install(
				CODE "
					file(READ \"${_f_in_gen}\" _f_contents)
					file(APPEND \"${SBOM_GENERATE_OUTPUT}\" \"\${_f_contents}\")
				"
			)
		endforeach()
	endif()

	set_property(GLOBAL PROPERTY sbom_filename "${SBOM_GENERATE_OUTPUT}")
	set_property(GLOBAL PROPERTY sbom_project "${SBOM_GENERATE_PROJECT}")
	set_property(GLOBAL PROPERTY sbom_spdxids 0)

	file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/sbom)
	file(WRITE ${PROJECT_BINARY_DIR}/sbom/CMakeLists.txt "")
endfunction()

# Verify the generated SBOM. Call after sbom_generate() and other SBOM populating commands.
#
# Usage: sbom_finalize()
function(sbom_finalize)
	get_property(_sbom GLOBAL PROPERTY sbom_filename)
	get_property(_sbom_project GLOBAL PROPERTY sbom_project)

	if("${_sbom}" STREQUAL "")
		message(FATAL_ERROR "Call sbom_generate() first")
	endif()

	file(
		WRITE ${PROJECT_BINARY_DIR}/sbom/verify.cmake
		"
		message(STATUS \"Verifying: ${_sbom}\")
		execute_process(
			COMMAND ${Python3_EXECUTABLE} -m spdx_tools.spdx.clitools.pyspdxtools
			-i \"${_sbom}\"
			RESULT_VARIABLE _res
		)
		if(NOT _res EQUAL 0)
			message(FATAL_ERROR \"SBOM verification failed\")
		endif()
		"
	)

	file(APPEND ${PROJECT_BINARY_DIR}/sbom/CMakeLists.txt "install(SCRIPT verify.cmake)
"
	)

	# Workaround for pre-CMP0082.
	add_subdirectory(${PROJECT_BINARY_DIR}/sbom ${PROJECT_BINARY_DIR}/sbom)
endfunction()

# Append a file to the SBOM. Use this after calling sbom_generate().
#
# Usage: sbom_file(FILENAME <filename> FILETYPE <type> [RELATIONSHIP <string>] [SPDXID <hint>]
# [OPTIONAL])
#
# The FILENAME must be relative to CMAKE_INSTALL_PREFIX. Generator expressions are supported.
function(sbom_file)
	set(options OPTIONAL)
	set(oneValueArgs FILENAME FILETYPE RELATIONSHIP SPDXID)
	set(multiValueArgs)
	cmake_parse_arguments(SBOM_FILE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	if("${SBOM_FILE_FILENAME}" STREQUAL "")
		message(FATAL_ERROR "Missing FILENAME argument")
	endif()

	sbom_spdxid(
		VARIABLE SBOM_FILE_SPDXID HINTS "${SBOM_FILE_SPDXID}"
		"SPDXRef-${SBOM_FILE_FILENAME}"
	)

	if("${SBOM_FILE_FILETYPE}" STREQUAL "")
		message(FATAL_ERROR "Missing FILETYPE argument")
	endif()

	get_property(_sbom GLOBAL PROPERTY sbom_filename)
	get_property(_sbom_project GLOBAL PROPERTY sbom_project)

	if("${SBOM_FILE_RELATIONSHIP}" STREQUAL "")
		set(SBOM_FILE_RELATIONSHIP "SPDXRef-${_sbom_project} CONTAINS ${SBOM_FILE_SPDXID}")
	endif()

	if("${_sbom}" STREQUAL "")
		message(FATAL_ERROR "Call sbom_generate() first")
	endif()

	file(
		GENERATE
		OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_FILE_SPDXID}.cmake
		CONTENT
			"
			cmake_policy(SET CMP0011 NEW)
			cmake_policy(SET CMP0012 NEW)
			if(NOT EXISTS ${CMAKE_INSTALL_PREFIX}/${SBOM_FILE_FILENAME})
				if(NOT ${SBOM_FILE_OPTIONAL})
					message(FATAL_ERROR \"Cannot find ${SBOM_FILE_FILENAME}\")
				endif()
			else()
				file(SHA1 ${CMAKE_INSTALL_PREFIX}/${SBOM_FILE_FILENAME} _sha1)
				file(APPEND \"${_sbom}\"
\"
FileName: ./${SBOM_FILE_FILENAME}
SPDXID: ${SBOM_FILE_SPDXID}
FileType: ${SBOM_FILE_FILETYPE}
FileChecksum: SHA1: \${_sha1}
LicenseConcluded: NOASSERTION
LicenseInfoInFile: NOASSERTION
FileCopyrightText: NOASSERTION
Relationship: ${SBOM_FILE_RELATIONSHIP}
\"
				)
			endif()
			"
	)

	install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_FILE_SPDXID}.cmake)
endfunction()

# Append a target output to the SBOM. Use this after calling sbom_generate().
#
# Usage: sbom_target(TARGET <target> [RELATIONSHIP <string>] [SPDXID <hint>])
#
# The target must be installed in the default location, according to GNUInstallDirs.
function(sbom_target)
	set(options)
	set(oneValueArgs TARGET)
	set(multiValueArgs)
	cmake_parse_arguments(
		SBOM_TARGET "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)

	if("${SBOM_TARGET_TARGET}" STREQUAL "")
		message(FATAL_ERROR "Missing TARGET argument")
	endif()

	get_target_property(_type ${SBOM_TARGET_TARGET} TYPE)
	if("${_type}" STREQUAL "EXECUTABLE")
		sbom_file(FILENAME
			  ${CMAKE_INSTALL_BINDIR}/$<TARGET_FILE_NAME:${SBOM_TARGET_TARGET}>
			  FILETYPE BINARY ${SBOM_TARGET_UNPARSED_ARGUMENTS}
		)
	else()
		message(FATAL_ERROR "Unsupported target type ${_type}")
	endif()
endfunction()

# Append all files recursively in a directory to the SBOM. Use this after calling sbom_generate().
#
# Usage: sbom_directory(DIRECTORY <dirname> FILETYPE <type> [RELATIONSHIP <string>] [SPDXID <hint>])
#
# The FILENAME must be relative to CMAKE_INSTALL_PREFIX. Generator expressions are supported.
function(sbom_directory)
	set(options)
	set(oneValueArgs DIRECTORY FILETYPE RELATIONSHIP SPDXID)
	set(multiValueArgs)
	cmake_parse_arguments(
		SBOM_DIRECTORY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)

	if("${SBOM_DIRECTORY_DIRECTORY}" STREQUAL "")
		message(FATAL_ERROR "Missing DIRECTORY argument")
	endif()

	sbom_spdxid(
		VARIABLE SBOM_DIRECTORY_SPDXID HINTS "${SBOM_DIRECTORY_SPDXID}"
		"SPDXRef-${SBOM_DIRECTORY_DIRECTORY}"
	)

	if("${SBOM_DIRECTORY_FILETYPE}" STREQUAL "")
		message(FATAL_ERROR "Missing FILETYPE argument")
	endif()

	get_property(_sbom GLOBAL PROPERTY sbom_filename)
	get_property(_sbom_project GLOBAL PROPERTY sbom_project)

	if("${SBOM_DIRECTORY_RELATIONSHIP}" STREQUAL "")
		set(SBOM_DIRECTORY_RELATIONSHIP
		    "SPDXRef-${_sbom_project} CONTAINS ${SBOM_DIRECTORY_SPDXID}"
		)
	endif()

	if("${_sbom}" STREQUAL "")
		message(FATAL_ERROR "Call sbom_generate() first")
	endif()

	file(
		GENERATE
		OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${SBOM_DIRECTORY_SPDXID}.cmake"
		CONTENT
			"
			file(GLOB_RECURSE _files
				LIST_DIRECTORIES false RELATIVE \"${CMAKE_INSTALL_PREFIX}\"
				\"${CMAKE_INSTALL_PREFIX}/${SBOM_DIRECTORY_DIRECTORY}/*\"
			)

			set(_count 0)
			foreach(_f IN LISTS _files)
				file(SHA1 \"${CMAKE_INSTALL_PREFIX}/\${_f}\" _sha1)
				file(APPEND \"${_sbom}\"
\"
FileName: ./\${_f}
SPDXID: ${SBOM_DIRECTORY_SPDXID}-\${_count}
FileType: ${SBOM_DIRECTORY_FILETYPE}
FileChecksum: SHA1: \${_sha1}
LicenseConcluded: NOASSERTION
LicenseInfoInFile: NOASSERTION
FileCopyrightText: NOASSERTION
Relationship: ${SBOM_DIRECTORY_RELATIONSHIP}-\${_count}
\"
				)
				math(EXPR _count \"\${_count} + 1\")
			endforeach()
			"
	)

	install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_DIRECTORY_SPDXID}.cmake)
endfunction()

# Append a package (without files) to the SBOM. Use this after calling sbom_generate().
#
# Usage:
#
# sbom_package(PACKAGE <name> DOWNLOAD_LOCATION <URL> [VERSION <version>] [LICENSE <license>]
# [RELATIONSHIP <string>] [SPDXID <hint>] [EXTREF <ref>]...)
function(sbom_package)
	set(options)
	set(oneValueArgs PACKAGE VERSION LICENSE DOWNLOAD_LOCATION RELATIONSHIP SPDXID)
	set(multiValueArgs EXTREF)
	cmake_parse_arguments(
		SBOM_PACKAGE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)

	if("${SBOM_PACKAGE_PACKAGE}" STREQUAL "")
		message(FATAL_ERROR "Missing PACKAGE")
	endif()

	if("${SBOM_PACKAGE_DOWNLOAD_LOCATION}" STREQUAL "")
		message(FATAL_ERROR "Missing DOWNLOAD_LOCATION")
	endif()

	sbom_spdxid(
		VARIABLE SBOM_PACKAGE_SPDXID HINTS "${SBOM_PACKAGE_SPDXID}"
		"SPDXRef-${SBOM_PACKAGE_PACKAGE}"
	)

	set(_fields)

	if(NOT "${SBOM_PACKAGE_VERSION}" STREQUAL "")
		set(_fields "${_fields}
PackageVersion: ${SBOM_PACKAGE_VERSION}"
		)
	endif()

	if(NOT "${SBOM_PACKAGE_LICENSE}" STREQUAL "")
		set(_fields "${_fields}
PackageLicenseConcluded: ${SBOM_PACKAGE_LICENSE}"
		)
	else()
		set(_fields "${_fields}
PackageLicenseConcluded: NOASSERTION"
		)
	endif()

	foreach(_ref IN LISTS SBOM_PACKAGE_EXTREF)
		set(_fields "${_fields}
ExternalRef: ${_ref}"
		)
	endforeach()

	get_property(_sbom GLOBAL PROPERTY sbom_filename)
	get_property(_sbom_project GLOBAL PROPERTY sbom_project)

	if("${SBOM_PACKAGE_RELATIONSHIP}" STREQUAL "")
		set(SBOM_PACKAGE_RELATIONSHIP
		    "SPDXRef-${_sbom_project} DEPENDS_ON ${SBOM_PACKAGE_SPDXID}"
		)
	endif()

	if("${_sbom}" STREQUAL "")
		message(FATAL_ERROR "Call sbom_generate() first")
	endif()

	file(
		GENERATE
		OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_PACKAGE_SPDXID}.cmake
		CONTENT
			"
			file(APPEND \"${_sbom}\"
\"
PackageName: ${SBOM_PACKAGE_PACKAGE}
SPDXID: ${SBOM_PACKAGE_SPDXID}
ExternalRef: SECURITY cpe23Type ${SBOM_CPE}
PackageDownloadLocation: ${SBOM_PACKAGE_DOWNLOAD_LOCATION}
PackageLicenseDeclared: NOASSERTION
PackageCopyrightText: NOASSERTION
FilesAnalyzed: false${_fields}
Relationship: ${SBOM_PACKAGE_RELATIONSHIP}
Relationship: ${SBOM_PACKAGE_SPDXID} CONTAINS NOASSERTION
\"
			)
			"
	)

	file(APPEND ${PROJECT_BINARY_DIR}/sbom/CMakeLists.txt
	     "install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_PACKAGE_SPDXID}.cmake)
"
	)
endfunction()

# Append something to the SBOM. Use this after calling sbom_generate().
#
# Usage: sbom_add(FILENAME|DIRECTORY|TARGET|PACKAGE...)
#
# This is a wrapper function. See separate sbom_... for more details.
function(sbom_add type)
	if("${type}" STREQUAL "FILENAME")
		sbom_file(${ARGV})
	elseif("${type}" STREQUAL "DIRECTORY")
		sbom_directory(${ARGV})
	elseif("${type}" STREQUAL "TARGET")
		sbom_target(${ARGV})
	elseif("${type}" STREQUAL "PACKAGE")
		sbom_package(${ARGV})
	else()
		message(FATAL_ERROR "Unsupported sbom_add(${type})")
	endif()
endfunction()

# Adds a target that performs `python3 -m reuse lint'.  Python is required with the proper packages
# installed (see dist/common/requirements.txt).
function(reuse_lint)
	if(NOT TARGET ${PROJECT_NAME}-reuse-lint)
		find_package(
			Python3
			COMPONENTS Interpreter
			REQUIRED
		)

		add_custom_target(
			${PROJECT_NAME}-reuse-lint ALL
			COMMAND ${Python3_EXECUTABLE} -m reuse --root "${PROJECT_SOURCE_DIR}" lint
			WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
			VERBATIM
		)
	endif()
endfunction()

# Adds a target that generates a SPDX file of the source code.  Python is required with the proper
# packages installed (see dist/common/requirements.txt).
function(reuse_spdx)
	if(NOT TARGET ${PROJECT_NAME}-reuse-spdx)
		find_package(
			Python3
			COMPONENTS Interpreter
			REQUIRED
		)

		set(outfile "${PROJECT_BINARY_DIR}/${PROJECT_NAME}-src.spdx")

		add_custom_target(
			${PROJECT_NAME}-reuse-spdx ALL
			COMMAND ${Python3_EXECUTABLE} -m reuse --root "${PROJECT_SOURCE_DIR}" spdx
				-o "${outfile}"
			WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
			VERBATIM
		)
	endif()
endfunction()
