# SPDX-FileCopyrightText: 2023 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

if(COMMAND sbom_generate)
	return()
endif()

include(GNUInstallDirs)
include(${CMAKE_CURRENT_LIST_DIR}/version.cmake)

# Common Platform Enumeration: https://nvd.nist.gov/products/cpe
#
# TODO: This detection can be improved.
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
function(sbom_spdxid)
	set(options)
	set(oneValueArgs VARIABLE CHECK)
	set(multiValueArgs HINTS)

	cmake_parse_arguments(
		SBOM_SPDXID "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)
	if(SBOM_SPDXID_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Unknown arguments: ${SBOM_SPDXID_UNPARSED_ARGUMENTS}")
	endif()

	if("${SBOM_SPDXID_VARIABLE}" STREQUAL "")
		message(FATAL_ERROR "Missing VARIABLE")
	endif()

	if("${SBOM_SPDXID_CHECK}" STREQUAL "")
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
	else()
		set(_id "${SBOM_SPDXID_CHECK}")
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
function(sbom_generate)
	set(options)
	set(oneValueArgs
	    OUTPUT
	    LICENSE
	    COPYRIGHT
	    PROJECT
	    SUPPLIER
	    SUPPLIER_URL
	    NAMESPACE
	)
	set(multiValueArgs INPUT)
	cmake_parse_arguments(
		SBOM_GENERATE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)
	if(SBOM_GENERATE_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Unknown arguments: ${SBOM_GENERATE_UNPARSED_ARGUMENTS}")
	endif()

	string(TIMESTAMP NOW_UTC UTC)

	if("${SBOM_GENERATE_OUTPUT}" STREQUAL "")
		set(SBOM_GENERATE_OUTPUT
		    "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/${PROJECT_NAME}-sbom-${GIT_VERSION_PATH}.spdx"
		)
	endif()

	if("${SBOM_GENERATE_LICENSE}" STREQUAL "")
		set(SBOM_GENERATE_LICENSE "NOASSERTION")
	endif()

	if("${SBOM_GENERATE_PROJECT}" STREQUAL "")
		set(SBOM_GENERATE_PROJECT "${PROJECT_NAME}")
	endif()

	if("${SBOM_GENERATE_SUPPLIER}" STREQUAL "")
		set(SBOM_GENERATE_SUPPLIER "${SBOM_SUPPLIER}")
	elseif("${SBOM_SUPPLIER_URL}" STREQUAL "")
		set(SBOM_SUPPLIER
		    "${SBOM_GENERATE_SUPPLIER}"
		    CACHE STRING "SBOM supplier"
		)
	endif()

	if("${SBOM_GENERATE_COPYRIGHT}" STREQUAL "")
		# There is a race when building at New Year's Eve...
		string(TIMESTAMP NOW_YEAR "%Y" UTC)
		set(SBOM_GENERATE_COPYRIGHT "${NOW_YEAR} ${SBOM_GENERATE_SUPPLIER}")
	endif()

	if("${SBOM_GENERATE_SUPPLIER_URL}" STREQUAL "")
		set(SBOM_GENERATE_SUPPLIER_URL "${SBOM_SUPPLIER_URL}")
		if("${SBOM_GENERATE_SUPPLIER_URL}" STREQUAL "")
			set(SBOM_GENERATE_SUPPLIER_URL "${PROJECT_HOMEPAGE_URL}")
		endif()
	elseif("${SBOM_SUPPLIER_URL}" STREQUAL "")
		set(SBOM_SUPPLIER_URL
		    "${SBOM_GENERATE_SUPPLIER_URL}"
		    CACHE STRING "SBOM supplier URL"
		)
	endif()

	if("${SBOM_GENERATE_NAMESPACE}" STREQUAL "")
		set(SBOM_GENERATE_NAMESPACE
		    "${SBOM_GENERATE_SUPPLIER_URL}/spdxdocs/${PROJECT_NAME}-${GIT_VERSION}"
		)
	endif()

	string(REGEX REPLACE "[^-A-Za-z.]+" "-" SBOM_GENERATE_PROJECT "${SBOM_GENERATE_PROJECT}")

	install(
		CODE "
		message(STATUS \"Installing: ${SBOM_GENERATE_OUTPUT}\")
		set(SBOM_EXT_DOCS)
		file(WRITE \"${PROJECT_BINARY_DIR}/sbom/sbom.spdx.in\" \"\")
		"
	)

	file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/sbom)

	if("${SBOM_GENERATE_INPUT}" STREQUAL "")
		if("${SBOM_GENERATE_SUPPLIER}" STREQUAL "")
			message(FATAL_ERROR "Specify a SUPPLIER, or set SBOM_SUPPLIER")
		endif()

		if("${SBOM_GENERATE_SUPPLIER_URL}" STREQUAL "")
			message(FATAL_ERROR "Specify a SUPPLIER_URL, or set SBOM_SUPPLIER_URL")
		endif()

		set(_f "${CMAKE_CURRENT_BINARY_DIR}/SPDXRef-DOCUMENT.spdx.in")

		get_filename_component(doc_name "${SBOM_GENERATE_OUTPUT}" NAME_WE)

		file(
			GENERATE
			OUTPUT "${_f}"
			CONTENT
				"SPDXVersion: SPDX-2.3
DataLicense: CC0-1.0
SPDXID: SPDXRef-DOCUMENT
DocumentName: ${doc_name}
DocumentNamespace: ${SBOM_GENERATE_NAMESPACE}
Creator: Organization: ${SBOM_GENERATE_SUPPLIER}
Creator: Tool: cmake-sbom
CreatorComment: <text>This SPDX document was created from CMake ${CMAKE_VERSION}, using cmake-sbom
from https://github.com/DEMCON/cmake-sbom</text>
Created: ${NOW_UTC}\${SBOM_EXT_DOCS}

PackageName: ${CMAKE_CXX_COMPILER_ID}
SPDXID: SPDXRef-compiler
PackageVersion: ${CMAKE_CXX_COMPILER_VERSION}
PackageDownloadLocation: NOASSERTION
PackageLicenseConcluded: NOASSERTION
PackageLicenseDeclared: NOASSERTION
PackageCopyrightText: NOASSERTION
PackageSupplier: Organization: Anonymous
FilesAnalyzed: false
PackageSummary: <text>The compiler as identified by CMake, running on ${CMAKE_HOST_SYSTEM_NAME} (${CMAKE_HOST_SYSTEM_PROCESSOR})</text>
PrimaryPackagePurpose: APPLICATION
Relationship: SPDXRef-compiler CONTAINS NOASSERTION
Relationship: SPDXRef-compiler BUILD_DEPENDENCY_OF SPDXRef-${SBOM_GENERATE_PROJECT}
RelationshipComment: <text>SPDXRef-${SBOM_GENERATE_PROJECT} is built by compiler ${CMAKE_CXX_COMPILER_ID} (${CMAKE_CXX_COMPILER}) version ${CMAKE_CXX_COMPILER_VERSION}</text>

PackageName: ${PROJECT_NAME}
SPDXID: SPDXRef-${SBOM_GENERATE_PROJECT}
ExternalRef: SECURITY cpe23Type ${SBOM_CPE}
ExternalRef: PACKAGE-MANAGER purl pkg:supplier/${SBOM_GENERATE_SUPPLIER}/${PROJECT_NAME}@${GIT_VERSION}
PackageVersion: ${GIT_VERSION}
PackageSupplier: Organization: ${SBOM_GENERATE_SUPPLIER}
PackageDownloadLocation: NOASSERTION
PackageLicenseConcluded: ${SBOM_GENERATE_LICENSE}
PackageLicenseDeclared: ${SBOM_GENERATE_LICENSE}
PackageCopyrightText: ${SBOM_GENERATE_COPYRIGHT}
PackageHomePage: ${SBOM_GENERATE_SUPPLIER_URL}
PackageComment: <text>Built by CMake ${CMAKE_VERSION} with ${CMAKE_BUILD_TYPE} configuration for ${CMAKE_SYSTEM_NAME} (${CMAKE_SYSTEM_PROCESSOR})</text>
PackageVerificationCode: \${SBOM_VERIFICATION_CODE}
BuiltDate: ${NOW_UTC}
Relationship: SPDXRef-DOCUMENT DESCRIBES SPDXRef-${SBOM_GENERATE_PROJECT}
"
		)

		install(
			CODE "
				file(READ \"${_f}\" _f_contents)
				file(APPEND \"${PROJECT_BINARY_DIR}/sbom/sbom.spdx.in\" \"\${_f_contents}\")
			"
		)

		set(SBOM_LAST_SPDXID
		    "SPDXRef-${SBOM_GENERATE_PROJECT}"
		    PARENT_SCOPE
		)
	else()
		foreach(_f IN LISTS SBOM_GENERATE_INPUT)
			get_filename_component(_f_name "${_f}" NAME)
			set(_f_in "${CMAKE_CURRENT_BINARY_DIR}/${_f_name}")
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
					file(APPEND \"${PROJECT_BINARY_DIR}/sbom/sbom.spdx.in\" \"\${_f_contents}\")
				"
			)
		endforeach()

		set(SBOM_LAST_SPDXID
		    ""
		    PARENT_SCOPE
		)
	endif()

	install(CODE "set(SBOM_VERIFICATION_CODES)")

	set_property(GLOBAL PROPERTY SBOM_FILENAME "${SBOM_GENERATE_OUTPUT}")
	set(SBOM_FILENAME
	    "${SBOM_GENERATE_OUTPUT}"
	    PARENT_SCOPE
	)
	set_property(GLOBAL PROPERTY sbom_project "${SBOM_GENERATE_PROJECT}")
	set_property(GLOBAL PROPERTY sbom_spdxids 0)

	file(WRITE ${PROJECT_BINARY_DIR}/sbom/CMakeLists.txt "")
endfunction()

# Find python.
#
# Usage sbom_find_python([REQUIRED])
macro(sbom_find_python)
	if(Python3_EXECUTABLE)
		set(Python3_FOUND TRUE)
	elseif(CMAKE_VERSION VERSION_GREATER_EQUAL 3.12)
		find_package(Python3 COMPONENTS Interpreter ${ARGV})
	else()
		if(WIN32)
			find_program(Python3_EXECUTABLE NAMES python ${ARGV})
		else()
			find_program(Python3_EXECUTABLE NAMES python3 ${ARGV})
		endif()

		if(Python3_EXECUTABLE)
			set(Python3_FOUND TRUE)
		else()
			set(Python3_FOUND FALSE)
		endif()
	endif()

	if(Python3_FOUND)
		if(NOT DEFINED SBOM_HAVE_PYTHON_DEPS)
			execute_process(
				COMMAND
					${Python3_EXECUTABLE} -c "
import reuse
import spdx_tools.spdx.clitools.pyspdxtools
import ntia_conformance_checker.main
"
				RESULT_VARIABLE _res
				ERROR_QUIET OUTPUT_QUIET
			)

			if("${_res}" STREQUAL "0")
				set(SBOM_HAVE_PYTHON_DEPS
				    TRUE
				    CACHE INTERNAL ""
				)
			else()
				set(SBOM_HAVE_PYTHON_DEPS
				    FALSE
				    CACHE INTERNAL ""
				)
			endif()
		endif()

		if("${ARGN}" STREQUAL "REQUIRED" AND NOT SBOM_HAVE_PYTHON_DEPS)
			message(FATAL_ERROR "Missing python packages")
		endif()
	endif()
endmacro()

# Verify the generated SBOM. Call after sbom_generate() and other SBOM populating commands.
function(sbom_finalize)
	set(options NO_VERIFY VERIFY)
	set(oneValueArgs GRAPH)
	set(multiValueArgs)
	cmake_parse_arguments(
		SBOM_FINALIZE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)
	if(SBOM_FINALIZE_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Unknown arguments: ${SBOM_FINALIZE_UNPARSED_ARGUMENTS}")
	endif()

	get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)
	get_property(_sbom_project GLOBAL PROPERTY sbom_project)

	if("${_sbom_project}" STREQUAL "")
		message(FATAL_ERROR "Call sbom_generate() first")
	endif()

	file(
		WRITE ${PROJECT_BINARY_DIR}/sbom/verify.cmake
		"
		message(STATUS \"Finalizing: ${_sbom}\")
		list(SORT SBOM_VERIFICATION_CODES)
		string(REPLACE \";\" \"\" SBOM_VERIFICATION_CODES \"\${SBOM_VERIFICATION_CODES}\")
		file(WRITE \"${PROJECT_BINARY_DIR}/sbom/verification.txt\" \"\${SBOM_VERIFICATION_CODES}\")
		file(SHA1 \"${PROJECT_BINARY_DIR}/sbom/verification.txt\" SBOM_VERIFICATION_CODE)
		configure_file(\"${PROJECT_BINARY_DIR}/sbom/sbom.spdx.in\" \"${_sbom}\")
		"
	)

	if(NOT "${SBOM_FINALIZE_GRAPH}" STREQUAL "")
		set(SBOM_FINALIZE_NO_VERIFY FALSE)
		set(SBOM_FINALIZE_VERIFY TRUE)
		set(_graph --graph --outfile "${SBOM_FINALIZE_GRAPH}")
	else()
		set(_graph)
	endif()

	if(SBOM_FINALIZE_NO_VERIFY)
		set(SBOM_FINALIZE_VERIFY FALSE)
	else()
		if(SBOM_FINALIZE_VERIFY)
			# Force verify.
			set(_req REQUIRED)
		else()
			# Check if we can verify.
			set(_req)
		endif()

		sbom_find_python(${_req})

		if(Python3_FOUND)
			set(SBOM_FINALIZE_VERIFY TRUE)
		endif()
	endif()

	if(SBOM_FINALIZE_VERIFY)
		file(
			APPEND ${PROJECT_BINARY_DIR}/sbom/verify.cmake
			"
			message(STATUS \"Verifying: ${_sbom}\")
			execute_process(
				COMMAND ${Python3_EXECUTABLE} -m spdx_tools.spdx.clitools.pyspdxtools
				-i \"${_sbom}\" ${_graph}
				RESULT_VARIABLE _res
			)
			if(NOT _res EQUAL 0)
				message(FATAL_ERROR \"SBOM verification failed\")
			endif()

			execute_process(
				COMMAND ${Python3_EXECUTABLE} -m ntia_conformance_checker.main
				--file \"${_sbom}\"
				RESULT_VARIABLE _res
			)
			if(NOT _res EQUAL 0)
				message(FATAL_ERROR \"SBOM NTIA verification failed\")
			endif()
			"
		)
	endif()

	file(APPEND ${PROJECT_BINARY_DIR}/sbom/CMakeLists.txt "install(SCRIPT verify.cmake)
"
	)

	# Workaround for pre-CMP0082.
	add_subdirectory(${PROJECT_BINARY_DIR}/sbom ${PROJECT_BINARY_DIR}/sbom)

	# Mark finalized.
	set(SBOM_FILENAME
	    "${_sbom}"
	    PARENT_SCOPE
	)
	set_property(GLOBAL PROPERTY sbom_project "")
endfunction()

# Append a file to the SBOM. Use this after calling sbom_generate().
function(sbom_file)
	set(options OPTIONAL)
	set(oneValueArgs FILENAME FILETYPE RELATIONSHIP SPDXID)
	set(multiValueArgs)
	cmake_parse_arguments(SBOM_FILE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
	if(SBOM_FILE_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Unknown arguments: ${SBOM_FILE_UNPARSED_ARGUMENTS}")
	endif()

	if("${SBOM_FILE_FILENAME}" STREQUAL "")
		message(FATAL_ERROR "Missing FILENAME argument")
	endif()

	sbom_spdxid(
		VARIABLE SBOM_FILE_SPDXID
		CHECK "${SBOM_FILE_SPDXID}"
		HINTS "SPDXRef-${SBOM_FILE_FILENAME}"
	)

	set(SBOM_LAST_SPDXID
	    "${SBOM_FILE_SPDXID}"
	    PARENT_SCOPE
	)

	if("${SBOM_FILE_FILETYPE}" STREQUAL "")
		message(FATAL_ERROR "Missing FILETYPE argument")
	endif()

	get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)
	get_property(_sbom_project GLOBAL PROPERTY sbom_project)

	if("${SBOM_FILE_RELATIONSHIP}" STREQUAL "")
		set(SBOM_FILE_RELATIONSHIP "SPDXRef-${_sbom_project} CONTAINS ${SBOM_FILE_SPDXID}")
	else()
		string(REPLACE "@SBOM_LAST_SPDXID@" "${SBOM_FILE_SPDXID}" SBOM_FILE_RELATIONSHIP
			       "${SBOM_FILE_RELATIONSHIP}"
		)
	endif()

	if("${_sbom_project}" STREQUAL "")
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
				list(APPEND SBOM_VERIFICATION_CODES \${_sha1})
				file(APPEND \"${PROJECT_BINARY_DIR}/sbom/sbom.spdx.in\"
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
		sbom_file(FILENAME ${CMAKE_INSTALL_BINDIR}/$<TARGET_FILE_NAME:${SBOM_TARGET_TARGET}>
			  FILETYPE BINARY ${SBOM_TARGET_UNPARSED_ARGUMENTS}
		)
	elseif("${_type}" STREQUAL "STATIC_LIBRARY")
		sbom_file(FILENAME ${CMAKE_INSTALL_LIBDIR}/$<TARGET_FILE_NAME:${SBOM_TARGET_TARGET}>
			  FILETYPE BINARY ${SBOM_TARGET_UNPARSED_ARGUMENTS}
		)
	elseif("${_type}" STREQUAL "SHARED_LIBRARY")
		if(WIN32)
			sbom_file(
				FILENAME
					${CMAKE_INSTALL_BINDIR}/$<TARGET_FILE_NAME:${SBOM_TARGET_TARGET}>
				FILETYPE BINARY ${SBOM_TARGET_UNPARSED_ARGUMENTS}
			)
			sbom_file(
				FILENAME
					${CMAKE_INSTALL_LIBDIR}/$<TARGET_LINKER_FILE_NAME:${SBOM_TARGET_TARGET}>
				FILETYPE BINARY OPTIONAL ${SBOM_TARGET_UNPARSED_ARGUMENTS}
			)
		else()
			sbom_file(
				FILENAME
					${CMAKE_INSTALL_LIBDIR}/$<TARGET_FILE_NAME:${SBOM_TARGET_TARGET}>
				FILETYPE BINARY ${SBOM_TARGET_UNPARSED_ARGUMENTS}
			)
		endif()
	else()
		message(FATAL_ERROR "Unsupported target type ${_type}")
	endif()

	set(SBOM_LAST_SPDXID
	    "${SBOM_LAST_SPDXID}"
	    PARENT_SCOPE
	)
endfunction()

# Append all files recursively in a directory to the SBOM. Use this after calling sbom_generate().
function(sbom_directory)
	set(options)
	set(oneValueArgs DIRECTORY FILETYPE RELATIONSHIP)
	set(multiValueArgs)
	cmake_parse_arguments(
		SBOM_DIRECTORY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)
	if(SBOM_DIRECTORY_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Unknown arguments: ${SBOM_DIRECTORY_UNPARSED_ARGUMENTS}")
	endif()

	if("${SBOM_DIRECTORY_DIRECTORY}" STREQUAL "")
		message(FATAL_ERROR "Missing DIRECTORY argument")
	endif()

	sbom_spdxid(VARIABLE SBOM_DIRECTORY_SPDXID HINTS "SPDXRef-${SBOM_DIRECTORY_DIRECTORY}")

	set(SBOM_LAST_SPDXID "${SBOM_DIRECTORY_SPDXID}")

	if("${SBOM_DIRECTORY_FILETYPE}" STREQUAL "")
		message(FATAL_ERROR "Missing FILETYPE argument")
	endif()

	get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)
	get_property(_sbom_project GLOBAL PROPERTY sbom_project)

	if("${SBOM_DIRECTORY_RELATIONSHIP}" STREQUAL "")
		set(SBOM_DIRECTORY_RELATIONSHIP
		    "SPDXRef-${_sbom_project} CONTAINS ${SBOM_DIRECTORY_SPDXID}"
		)
	else()
		string(REPLACE "@SBOM_LAST_SPDXID@" "${SBOM_DIRECTORY_SPDXID}"
			       SBOM_DIRECTORY_RELATIONSHIP "${SBOM_DIRECTORY_RELATIONSHIP}"
		)
	endif()

	if("${_sbom_project}" STREQUAL "")
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
				list(APPEND SBOM_VERIFICATION_CODES \${_sha1})
				file(APPEND \"${PROJECT_BINARY_DIR}/sbom/sbom.spdx.in\"
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

	set(SBOM_LAST_SPDXID
	    ""
	    PARENT_SCOPE
	)
endfunction()

# Append a package (without files) to the SBOM. Use this after calling sbom_generate().
function(sbom_package)
	set(options)
	set(oneValueArgs
	    PACKAGE
	    VERSION
	    LICENSE
	    DOWNLOAD_LOCATION
	    RELATIONSHIP
	    SPDXID
	    SUPPLIER
	)
	set(multiValueArgs EXTREF)
	cmake_parse_arguments(
		SBOM_PACKAGE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)
	if(SBOM_PACKAGE_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Unknown arguments: ${SBOM_PACKAGE_UNPARSED_ARGUMENTS}")
	endif()

	if("${SBOM_PACKAGE_PACKAGE}" STREQUAL "")
		message(FATAL_ERROR "Missing PACKAGE")
	endif()

	if("${SBOM_PACKAGE_DOWNLOAD_LOCATION}" STREQUAL "")
		set(SBOM_PACKAGE_DOWNLOAD_LOCATION NOASSERTION)
	endif()

	sbom_spdxid(
		VARIABLE SBOM_PACKAGE_SPDXID
		CHECK "${SBOM_PACKAGE_SPDXID}"
		HINTS "SPDXRef-${SBOM_PACKAGE_PACKAGE}"
	)

	set(SBOM_LAST_SPDXID
	    "${SBOM_PACKAGE_SPDXID}"
	    PARENT_SCOPE
	)

	set(_fields)

	if("${SBOM_PACKAGE_VERSION}" STREQUAL "")
		set(SBOM_PACKAGE_VERSION "unknown")
	endif()

	if("${SBOM_PACKAGE_SUPPLIER}" STREQUAL "")
		set(SBOM_PACKAGE_SUPPLIER "Person: Anonymous")
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

	get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)
	get_property(_sbom_project GLOBAL PROPERTY sbom_project)

	if("${SBOM_PACKAGE_RELATIONSHIP}" STREQUAL "")
		set(SBOM_PACKAGE_RELATIONSHIP
		    "SPDXRef-${_sbom_project} DEPENDS_ON ${SBOM_PACKAGE_SPDXID}"
		)
	else()
		string(REPLACE "@SBOM_LAST_SPDXID@" "${SBOM_PACKAGE_SPDXID}"
			       SBOM_PACKAGE_RELATIONSHIP "${SBOM_PACKAGE_RELATIONSHIP}"
		)
	endif()

	if("${_sbom_project}" STREQUAL "")
		message(FATAL_ERROR "Call sbom_generate() first")
	endif()

	file(
		GENERATE
		OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_PACKAGE_SPDXID}.cmake
		CONTENT
			"
			file(APPEND \"${PROJECT_BINARY_DIR}/sbom/sbom.spdx.in\"
\"
PackageName: ${SBOM_PACKAGE_PACKAGE}
SPDXID: ${SBOM_PACKAGE_SPDXID}
ExternalRef: SECURITY cpe23Type ${SBOM_CPE}
PackageDownloadLocation: ${SBOM_PACKAGE_DOWNLOAD_LOCATION}
PackageLicenseDeclared: NOASSERTION
PackageCopyrightText: NOASSERTION
PackageVersion: ${SBOM_PACKAGE_VERSION}
PackageSupplier: ${SBOM_PACKAGE_SUPPLIER}
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

# Add a reference to a package in an external file.
function(sbom_external)
	set(options)
	set(oneValueArgs EXTERNAL FILENAME RENAME SPDXID RELATIONSHIP)
	set(multiValueArgs)
	cmake_parse_arguments(
		SBOM_EXTERNAL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)
	if(SBOM_EXTERNAL_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Unknown arguments: ${SBOM_EXTERNAL_UNPARSED_ARGUMENTS}")
	endif()

	if("${SBOM_EXTERNAL_EXTERNAL}" STREQUAL "")
		message(FATAL_ERROR "Missing EXTERNAL")
	endif()

	if("${SBOM_EXTERNAL_FILENAME}" STREQUAL "")
		message(FATAL_ERROR "Missing FILENAME")
	endif()

	if("${SBOM_EXTERNAL_SPDXID}" STREQUAL "")
		get_property(_spdxids GLOBAL PROPERTY sbom_spdxids)
		set(SBOM_EXTERNAL_SPDXID "DocumentRef-${_spdxids}")
		math(EXPR _spdxids "${_spdxids} + 1")
		set_property(GLOBAL PROPERTY sbom_spdxids "${_spdxids}")
	endif()

	if(NOT "${SBOM_EXTERNAL_SPDXID}" MATCHES "^DocumentRef-[-a-zA-Z0-9]+$")
		message(FATAL_ERROR "Invalid DocumentRef \"${SBOM_EXTERNAL_SPDXID}\"")
	endif()

	set(SBOM_LAST_SPDXID
	    "${SBOM_EXTERNAL_SPDXID}"
	    PARENT_SCOPE
	)

	get_property(_sbom GLOBAL PROPERTY SBOM_FILENAME)
	get_property(_sbom_project GLOBAL PROPERTY sbom_project)

	if("${_sbom_project}" STREQUAL "")
		message(FATAL_ERROR "Call sbom_generate() first")
	endif()

	get_filename_component(sbom_dir "${_sbom}" DIRECTORY)

	if("${SBOM_EXTERNAL_RELATIONSHIP}" STREQUAL "")
		set(SBOM_EXTERNAL_RELATIONSHIP
		    "SPDXRef-${_sbom_project} DEPENDS_ON ${SBOM_EXTERNAL_SPDXID}:${SBOM_EXTERNAL_EXTERNAL}"
		)
	else()
		string(REPLACE "@SBOM_LAST_SPDXID@" "${SBOM_EXTERNAL_SPDXID}"
			       SBOM_EXTERNAL_RELATIONSHIP "${SBOM_EXTERNAL_RELATIONSHIP}"
		)
	endif()

	# Filename may not exist yet, and it could be a generator expression.
	file(
		GENERATE
		OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_EXTERNAL_SPDXID}.cmake
		CONTENT
			"
			file(SHA1 \"${SBOM_EXTERNAL_FILENAME}\" ext_sha1)
			file(READ \"${SBOM_EXTERNAL_FILENAME}\" ext_content)
			if(\"${SBOM_EXTERNAL_RENAME}\" STREQUAL \"\")
				get_filename_component(ext_name \"${SBOM_EXTERNAL_FILENAME}\" NAME)
				file(WRITE \"${sbom_dir}/\${ext_name}\" \"\${ext_content}\")
			else()
				file(WRITE \"${sbom_dir}/${SBOM_EXTERNAL_RENAME}\" \"\${ext_content}\")
			endif()

			if(NOT \"\${ext_content}\" MATCHES \"[\\r\\n]DocumentNamespace:\")
				message(FATAL_ERROR \"Missing DocumentNamespace in ${SBOM_EXTERNAL_FILENAME}\")
			endif()

			string(REGEX REPLACE \"^.*[\\r\\n]DocumentNamespace:[ \\t]*([^#\\r\\n]*).*$\"
				\"\\\\1\" ext_ns \"\${ext_content}\")

			list(APPEND SBOM_EXT_DOCS \"
ExternalDocumentRef: ${SBOM_EXTERNAL_SPDXID} \${ext_ns} SHA1: \${ext_sha1}\")

			file(APPEND \"${PROJECT_BINARY_DIR}/sbom/sbom.spdx.in\"
\"
Relationship: ${SBOM_EXTERNAL_RELATIONSHIP}\")
		"
	)

	file(APPEND ${PROJECT_BINARY_DIR}/sbom/CMakeLists.txt
	     "install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/${SBOM_EXTERNAL_SPDXID}.cmake)
"
	)

endfunction()

# Append something to the SBOM. Use this after calling sbom_generate().
function(sbom_add type)
	if("${type}" STREQUAL "FILENAME")
		sbom_file(${ARGV})
	elseif("${type}" STREQUAL "DIRECTORY")
		sbom_directory(${ARGV})
	elseif("${type}" STREQUAL "TARGET")
		sbom_target(${ARGV})
	elseif("${type}" STREQUAL "PACKAGE")
		sbom_package(${ARGV})
	elseif("${type}" STREQUAL "EXTERNAL")
		sbom_external(${ARGV})
	else()
		message(FATAL_ERROR "Unsupported sbom_add(${type})")
	endif()

	set(SBOM_LAST_SPDXID
	    "${SBOM_LAST_SPDXID}"
	    PARENT_SCOPE
	)
endfunction()

# Adds a target that performs `python3 -m reuse lint'.  Python is required with the proper packages
# installed (see dist/common/requirements.txt).
function(reuse_lint)
	if(NOT TARGET ${PROJECT_NAME}-reuse-lint)
		sbom_find_python(REQUIRED)

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
		sbom_find_python(REQUIRED)

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
