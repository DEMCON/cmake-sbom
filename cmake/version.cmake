# SPDX-FileCopyrightText: 2023 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.5)

if(COMMAND version_generate)
	version_extract()
	version_generate()
	return()
endif()

set(VERSION_SOURCE_DIR
    "${CMAKE_CURRENT_LIST_DIR}"
    CACHE INTERNAL ""
)

find_package(Git)

function(version_show)
	message(STATUS "${PROJECT_NAME} version is ${GIT_VERSION}")
endfunction()

# Extract version information from Git of the current project.
function(version_extract)
	set(options VERBOSE)
	set(oneValueArgs)
	set(multiValueArgs)
	cmake_parse_arguments(
		VERSION_EXTRACT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN}
	)

	set(version_git_head "unknown")
	set(version_git_hash "")
	set(version_git_branch "dev")
	set(version_git_tag "")

	if(Git_FOUND)
		execute_process(
			COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
			WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
			OUTPUT_VARIABLE version_git_head
			ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
		)

		execute_process(
			COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
			WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
			OUTPUT_VARIABLE version_git_hash
			ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
		)

		execute_process(
			COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
			WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
			OUTPUT_VARIABLE version_git_branch
			ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
		)

		if("${version_git_branch}" STREQUAL "HEAD")
			if(NOT "$ENV{CI_COMMIT_BRANCH}" STREQUAL "")
				# Probably a detached head running on a gitlab runner
				set(version_git_branch "$ENV{CI_COMMIT_BRANCH}")
			endif()
		endif()

		execute_process(
			COMMAND ${GIT_EXECUTABLE} tag --points-at HEAD
			WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
			OUTPUT_VARIABLE version_git_tag
			ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
		)

		string(REGEX REPLACE "[ \t\r\n].*$" "" version_git_tag "${version_git_tag}")

		if("${version_git_tag}" STREQUAL "")
			if(NOT "$ENV{CI_COMMIT_TAG}" STREQUAL "")
				# Probably a detached head running on a gitlab runner
				set(version_git_tag "$ENV{CI_COMMIT_TAG}")
			endif()
		endif()

		execute_process(
			COMMAND ${GIT_EXECUTABLE} status -s
			WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
			OUTPUT_VARIABLE version_git_dirty
			ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
		)

		if(NOT "${version_git_dirty}" STREQUAL "")
			set(version_git_dirty "+dirty")
		endif()

		macro(git_hash TAG TAG_VAR)
			execute_process(
				COMMAND ${GIT_EXECUTABLE} rev-parse ${TAG}
				WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
				OUTPUT_VARIABLE ${TAG_VAR}_
				ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
			)

			set(${TAG_VAR}
			    "${${TAG_VAR}_}"
			    PARENT_SCOPE
			)
		endmacro()

		execute_process(
			COMMAND ${GIT_EXECUTABLE} tag
			WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
			OUTPUT_VARIABLE GIT_TAGS
			ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
		)

		if(GIT_TAGS)
			string(REGEX REPLACE "[ \t\r\n]+" ";" GIT_TAGS_LIST ${GIT_TAGS})
			foreach(tag IN LISTS GIT_TAGS_LIST)
				git_hash(${tag} GIT_HASH_${tag})
				if(VERSION_EXTRACT_VERBOSE)
					message(
						STATUS
							"git hash of tag ${tag} is ${GIT_HASH_${tag}}"
					)
				endif()
			endforeach()
		endif()
	else()
		message(WARNING "Git not found")
	endif()

	if("$ENV{CI_BUILD_ID}" STREQUAL "")
		set(version_build "")
	else()
		set(version_build "+build$ENV{CI_BUILD_ID}")
	endif()

	set(GIT_HASH
	    "${version_git_hash}"
	    PARENT_SCOPE
	)
	set(GIT_HASH_SHORT
	    "${version_git_head}"
	    PARENT_SCOPE
	)

	if(NOT ${version_git_tag} STREQUAL "")
		set(_GIT_VERSION "${version_git_tag}")

		if("${_GIT_VERSION}" MATCHES "^v[0-9]+\.")
			string(REGEX REPLACE "^v" "" _GIT_VERSION "${_GIT_VERSION}")
		endif()

		set(GIT_VERSION "${_GIT_VERSION}${version_git_dirty}")
	else()
		set(GIT_VERSION
		    "${version_git_head}+${version_git_branch}${version_build}${version_git_dirty}"
		)
	endif()

	set(GIT_VERSION
	    "${GIT_VERSION}"
	    PARENT_SCOPE
	)
	string(REGEX REPLACE "[^-a-zA-Z0-9_.]+" "+" _GIT_VERSION_PATH "${GIT_VERSION}")
	set(GIT_VERSION_PATH
	    "${_GIT_VERSION_PATH}"
	    PARENT_SCOPE
	)

	if(VERSION_EXTRACT_VERBOSE)
		version_show()
	endif()
endfunction()

# Generate version files and a static library based on the extract version information of the
# current project.
function(version_generate)
	string(TIMESTAMP VERSION_TIMESTAMP "%Y-%m-%d %H:%M:%S")
	set(VERSION_TIMESTAMP "${VERSION_TIMESTAMP}")
	set(VERSION_TIMESTAMP
	    "${VERSION_TIMESTAMP}"
	    PARENT_SCOPE
	)

	if("${GIT_VERSION}" MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+([-+].*)?$")
		set(GIT_VERSION_TRIPLET ${GIT_VERSION})
		string(REGEX REPLACE "^([0-9]+)\\.([0-9]+)\\.([0-9]+)([-+].*)?$" "\\1"
				     GIT_VERSION_MAJOR "${GIT_VERSION}"
		)
		string(REGEX REPLACE "^([0-9]+)\\.([0-9]+)\\.([0-9]+)([-+].*)?$" "\\2"
				     GIT_VERSION_MINOR "${GIT_VERSION}"
		)
		string(REGEX REPLACE "^([0-9]+)\\.([0-9]+)\\.([0-9]+)([-+].*)?$" "\\3"
				     GIT_VERSION_PATCH "${GIT_VERSION}"
		)
		string(REGEX REPLACE "^([0-9]+)\\.([0-9]+)\\.([0-9]+)(([-+].*)?)$" "\\4"
				     GIT_VERSION_SUFFIX "${GIT_VERSION}"
		)
	else()
		# Choose a high major number, such that it is always incompatible with existing
		# tags.
		set(GIT_VERSION_TRIPLET "9999.0.0")
		set(GIT_VERSION_MAJOR 9999)
		set(GIT_VERSION_MINOR 0)
		set(GIT_VERSION_PATCH 0)
		set(GIT_VERSION_SUFFIX "+${GIT_HASH_SHORT}")
	endif()

	set(GIT_VERSION_TRIPLET
	    "${GIT_VERSION_TRIPLET}"
	    PARENT_SCOPE
	)
	set(GIT_VERSION_MAJOR
	    "${GIT_VERSION_MAJOR}"
	    PARENT_SCOPE
	)
	set(GIT_VERSION_MINOR
	    "${GIT_VERSION_MINOR}"
	    PARENT_SCOPE
	)
	set(GIT_VERSION_PATCH
	    "${GIT_VERSION_PATCH}"
	    PARENT_SCOPE
	)
	set(GIT_VERSION_SUFFIX
	    "${GIT_VERSION_SUFFIX}"
	    PARENT_SCOPE
	)

	set(GIT_VERSION_HEADER "/* This is a generated file. Do not edit. */")

	string(TOUPPER "${PROJECT_NAME}" PROJECT_NAME_UC)
	string(REGEX REPLACE "[^A-Z0-9]+" "_" PROJECT_NAME_UC "${PROJECT_NAME_UC}")

	configure_file(
		${VERSION_SOURCE_DIR}/version.sh.in ${PROJECT_BINARY_DIR}/version.sh ESCAPE_QUOTES
		@ONLY
	)

	configure_file(
		${VERSION_SOURCE_DIR}/version.h.in
		${PROJECT_BINARY_DIR}/include/${PROJECT_NAME}_version.h ESCAPE_QUOTES @ONLY
	)
	file(WRITE ${PROJECT_BINARY_DIR}/version.txt "${GIT_VERSION}")

	if(NOT TARGET ${PROJECT_NAME}-version)
		add_library(${PROJECT_NAME}-version INTERFACE)

		set_target_properties(
			${PROJECT_NAME}-version
			PROPERTIES LINKER_LANGUAGE C
				   PUBLIC_HEADER
				   "${PROJECT_BINARY_DIR}/include/${PROJECT_NAME}_version.h"
		)

		target_include_directories(
			${PROJECT_NAME}-version
			INTERFACE "$<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>"
				  "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
		)
	endif()
endfunction()

version_extract()
version_generate()
version_show()
