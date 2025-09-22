# SPDX-FileCopyrightText: 2023-2025 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

if(NOT CMAKE_VERSION VERSION_LESS 3.17)
	set(rmdir rm -rf)
else()
	set(rmdir "remove_directory")
endif()

add_custom_target(tests ALL)

sbom_find_python(REQUIRED)

function(test name)
	set(options)
	set(oneValueArgs BIN TARGET)
	set(multiValueArgs ENV)
	cmake_parse_arguments(TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	if("${TEST_BIN}" STREQUAL "")
		set(TEST_BIN "${name}")
	endif()

	if("${TEST_TARGET}" STREQUAL "")
		set(TEST_TARGET "test-${name}")
	endif()

	if(TARGET "${TEST_TARGET}")
		set(TEST_TARGET "${TEST_TARGET}-${TEST_BIN}")
	endif()

	set(_dir "${CMAKE_CURRENT_BINARY_DIR}/${TEST_BIN}")
	make_directory(${_dir}/src)
	make_directory(${_dir}/build)

	set(TEST_PREAMBLE
	    "cmake_minimum_required(VERSION 3.10)
cmake_policy(VERSION 3.10)
project(${name} LANGUAGES NONE)
include(git_version)
"
	)

	configure_file("${name}.cmake" "${_dir}/src/CMakeLists.txt" @ONLY)

	add_custom_target(
		${TEST_TARGET}
		DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${name}.cmake
		COMMAND
			${CMAKE_COMMAND} -E env ${TEST_ENV} ${CMAKE_COMMAND} "${_dir}/src" -G
			"${CMAKE_GENERATOR}" "-DCMAKE_INSTALL_PREFIX=${_dir}/out"
			"-DCMAKE_MODULE_PATH=${PROJECT_SOURCE_DIR}/cmake"
			"-DPython3_EXECUTABLE=${Python3_EXECUTABLE}"
			"-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
		COMMAND ${CMAKE_COMMAND} --build . --target install
		WORKING_DIRECTORY "${_dir}/build"
		COMMENT "Testing ${name}"
		VERBATIM
	)

	add_dependencies(tests ${TEST_TARGET})
endfunction()

test(minimal)
test(minimal2)
test(full_doc)
test(input_doc)
test(file)
test(package)
test(dir)
test(target)
test(external)
test(C)
test(CXX)
test(C_CXX)
test(version)
test(env_version BIN env_branch ENV GIT_VERSION_BRANCH=testbranch)
test(env_version BIN env_tag ENV GIT_VERSION_TAG=v2.4.8)
test(env_version BIN env_both ENV GIT_VERSION_BRANCH=testbranch GIT_VERSION_TAG=v2.4.8)
