# SPDX-FileCopyrightText: 2023-2026 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.10)

if(COMMAND cpe_detect)
	return()
endif()

set(CPE_FALLBACK "cpe:2.3:o:generic:generic:-:*:*:*:*:*:*:*")

function(_cpe_normalize_component input output)
	string(TOLOWER "${input}" _value)
	if("${_value}" STREQUAL "")
		set(_value "-")
	else()
		string(REGEX REPLACE "[^a-z0-9._-]" "_" _value "${_value}")
	endif()
	set(${output}
	    "${_value}"
	    PARENT_SCOPE
	)
endfunction()

function(_cpe_split_like_values input output)
	set(_likes)
	string(STRIP "${input}" _input)
	if(NOT "${_input}" STREQUAL "")
		string(REPLACE " " ";" _input_list "${_input}")
		foreach(_like IN LISTS _input_list)
			if(NOT "${_like}" STREQUAL "")
				_cpe_normalize_component("${_like}" _like_norm)
				list(APPEND _likes "${_like_norm}")
			endif()
		endforeach()
	endif()
	set(${output}
	    "${_likes}"
	    PARENT_SCOPE
	)
endfunction()

function(_cpe_detect_arch output)
	set(_proc_input "${CMAKE_SYSTEM_PROCESSOR}")
	if("${_proc_input}" STREQUAL "")
		set(_proc_input "${CMAKE_HOST_SYSTEM_PROCESSOR}")
	endif()
	string(TOLOWER "${_proc_input}" _proc)
	if("${_proc}" STREQUAL "amd64" OR "${_proc}" STREQUAL "x86_64")
		set(_arch "x64")
	elseif("${_proc}" STREQUAL "ia64")
		set(_arch "x64")
	elseif("${_proc}" STREQUAL "arm64" OR "${_proc}" STREQUAL "aarch64")
		set(_arch "arm64")
	elseif(
		"${_proc}" STREQUAL "x86"
		OR "${_proc}" STREQUAL "i386"
		OR "${_proc}" STREQUAL "i486"
		OR "${_proc}" STREQUAL "i586"
		OR "${_proc}" STREQUAL "i686"
	)
		set(_arch "x86")
	elseif(CMAKE_CXX_COMPILER MATCHES "64" OR CMAKE_C_COMPILER MATCHES "64")
		set(_arch "x64")
	elseif(CMAKE_CXX_COMPILER MATCHES "86" OR CMAKE_C_COMPILER MATCHES "86")
		set(_arch "x86")
	elseif(_proc MATCHES "arm")
		set(_arch "arm")
	else()
		_cpe_normalize_component("${_proc_input}" _arch)
	endif()

	set(${output}
	    "${_arch}"
	    PARENT_SCOPE
	)
endfunction()

function(_cpe_detect_linux_distrib output_id output_version output_id_like)
	set(_id "")
	set(_version "-")
	set(_id_like "")

	if((CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
	   AND NOT CMAKE_CROSSCOMPILING
	)
		if(NOT CMAKE_VERSION VERSION_LESS 3.22)
			cmake_host_system_information(RESULT _distro_info QUERY DISTRIB_INFO)
			if(DEFINED _distro_info_ID)
				_cpe_normalize_component("${_distro_info_ID}" _id)
			endif()
			if(DEFINED _distro_info_VERSION_ID)
				_cpe_normalize_component("${_distro_info_VERSION_ID}" _version)
			endif()
			if(DEFINED _distro_info_ID_LIKE)
				_cpe_split_like_values("${_distro_info_ID_LIKE}" _id_like)
			endif()
		endif()

		if("${_id}" STREQUAL "" AND EXISTS "/etc/os-release")
			file(READ "/etc/os-release" _os_release)
			string(REPLACE "\n" ";" _os_release_lines "${_os_release}")
			foreach(_line IN LISTS _os_release_lines)
				if(_line MATCHES "^ID=(.+)$")
					set(_id_raw "${CMAKE_MATCH_1}")
					string(REGEX REPLACE "^\"|\"$" "" _id_raw "${_id_raw}")
					_cpe_normalize_component("${_id_raw}" _id)
				elseif(_line MATCHES "^ID_LIKE=(.+)$")
					set(_id_like_raw "${CMAKE_MATCH_1}")
					string(REGEX REPLACE "^\"|\"$" "" _id_like_raw
							     "${_id_like_raw}"
					)
					_cpe_split_like_values("${_id_like_raw}" _id_like)
				elseif(_line MATCHES "^VERSION_ID=(.+)$")
					set(_version_raw "${CMAKE_MATCH_1}")
					string(REGEX REPLACE "^\"|\"$" "" _version_raw
							     "${_version_raw}"
					)
					_cpe_normalize_component("${_version_raw}" _version)
				endif()
			endforeach()
		endif()
	endif()

	set(${output_id}
	    "${_id}"
	    PARENT_SCOPE
	)
	set(${output_version}
	    "${_version}"
	    PARENT_SCOPE
	)
	set(${output_id_like}
	    "${_id_like}"
	    PARENT_SCOPE
	)
endfunction()

function(_cpe_detect_macos_version output_version)
	set(_version "-")

	if((CMAKE_SYSTEM_NAME STREQUAL "Darwin" OR CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
	   AND NOT CMAKE_CROSSCOMPILING
	)
		find_program(_sw_vers sw_vers)
		if(_sw_vers)
			execute_process(
				COMMAND "${_sw_vers}" -productVersion
				OUTPUT_VARIABLE _version_raw
				OUTPUT_STRIP_TRAILING_WHITESPACE
				ERROR_QUIET
			)
			if(NOT "${_version_raw}" STREQUAL "")
				_cpe_normalize_component("${_version_raw}" _version)
			endif()
		endif()
	endif()

	set(${output_version}
	    "${_version}"
	    PARENT_SCOPE
	)
endfunction()

function(cpe_detect)
	set(options)
	set(oneValueArgs OUTPUT DEFAULT)
	set(multiValueArgs)
	cmake_parse_arguments(CPE_DETECT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
	if(CPE_DETECT_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Unknown arguments: ${CPE_DETECT_UNPARSED_ARGUMENTS}")
	endif()

	if("${CPE_DETECT_OUTPUT}" STREQUAL "")
		message(FATAL_ERROR "Missing OUTPUT argument")
	endif()

	if("${CPE_DETECT_DEFAULT}" STREQUAL "")
		set(CPE_DETECT_DEFAULT "${CPE_FALLBACK}")
	endif()

	_cpe_detect_arch(_arch)

	if(WIN32)
		if("${CMAKE_SYSTEM_VERSION}" STREQUAL "6.1")
			set(_cpe "cpe:2.3:o:microsoft:windows_7:-:*:*:*:*:*:${_arch}:*")
		elseif("${CMAKE_SYSTEM_VERSION}" STREQUAL "6.2")
			set(_cpe "cpe:2.3:o:microsoft:windows_8:-:*:*:*:*:*:${_arch}:*")
		elseif("${CMAKE_SYSTEM_VERSION}" STREQUAL "6.3")
			set(_cpe "cpe:2.3:o:microsoft:windows_8.1:-:*:*:*:*:*:${_arch}:*")
		elseif("${CMAKE_SYSTEM_VERSION}" VERSION_LESS 10)
			set(_cpe "cpe:2.3:o:microsoft:windows:-:*:*:*:*:*:${_arch}:*")
		elseif("${CMAKE_SYSTEM_VERSION}" VERSION_LESS 10.0.22000)
			set(_cpe "cpe:2.3:o:microsoft:windows_10:-:*:*:*:*:*:${_arch}:*")
		else()
			set(_cpe "cpe:2.3:o:microsoft:windows_11:-:*:*:*:*:*:${_arch}:*")
		endif()
	elseif(APPLE)
		set(_version "-")
		_cpe_detect_macos_version(_version)
		set(_cpe "cpe:2.3:o:apple:mac_os:${_version}:*:*:*:*:*:${_arch}:*")
	elseif(ANDROID)
		set(_cpe "cpe:2.3:o:google:android:-:*:*:*:*:*:${_arch}:*")
	elseif(UNIX)
		set(_vendor "linux")
		set(_product "linux_kernel")
		set(_version "-")
		set(_id_like)
		_cpe_detect_linux_distrib(_id _version _id_like)

		if("${_id}" STREQUAL "ubuntu")
			set(_vendor "canonical")
			set(_product "ubuntu_linux")
		elseif("${_id}" STREQUAL "debian")
			set(_vendor "debian")
			set(_product "debian_linux")
		elseif("${_id}" STREQUAL "fedora")
			set(_vendor "fedoraproject")
			set(_product "fedora")
		elseif("${_id}" STREQUAL "rhel")
			set(_vendor "redhat")
			set(_product "enterprise_linux")
		elseif("${_id}" STREQUAL "centos")
			set(_vendor "centos")
			set(_product "centos")
		elseif("${_id}" STREQUAL "almalinux")
			set(_vendor "almalinux")
			set(_product "almalinux")
		elseif("${_id}" STREQUAL "rocky")
			set(_vendor "rocky")
			set(_product "rocky_linux")
		elseif("${_id}" STREQUAL "opensuse-leap")
			set(_vendor "suse")
			set(_product "opensuse_leap")
		elseif("${_id}" STREQUAL "opensuse-tumbleweed")
			set(_vendor "suse")
			set(_product "opensuse_tumbleweed")
		elseif("${_id}" STREQUAL "sles")
			set(_vendor "suse")
			set(_product "linux_enterprise_server")
		elseif("${_id}" STREQUAL "linuxmint")
			set(_vendor "linuxmint")
			set(_product "linux_mint")
		elseif(NOT "${_id}" STREQUAL "")
			set(_vendor "${_id}")
			set(_product "${_id}")
		endif()

		if("${_vendor}" STREQUAL "${_id}" OR "${_vendor}" STREQUAL "linux")
			foreach(_like IN LISTS _id_like)
				if("${_like}" STREQUAL "ubuntu")
					set(_vendor "canonical")
					set(_product "ubuntu_linux")
					break()
				elseif("${_like}" STREQUAL "debian")
					set(_vendor "debian")
					set(_product "debian_linux")
					break()
				elseif("${_like}" STREQUAL "rhel" OR "${_like}" STREQUAL "fedora")
					set(_vendor "redhat")
					set(_product "enterprise_linux")
					break()
				elseif("${_like}" STREQUAL "suse")
					set(_vendor "suse")
					set(_product "linux")
					break()
				endif()
			endforeach()
		endif()

		set(_cpe "cpe:2.3:o:${_vendor}:${_product}:${_version}:*:*:*:*:*:${_arch}:*")
	elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
		set(_cpe "cpe:2.3:h:arm:arm:-:*:*:*:*:*:*:*")
	else()
		message(AUTHOR_WARNING "Unsupported platform for automatic CPE detection")
		set(_cpe "${CPE_DETECT_DEFAULT}")
	endif()

	set(${CPE_DETECT_OUTPUT}
	    "${_cpe}"
	    PARENT_SCOPE
	)
endfunction()
