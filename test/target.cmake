# SPDX-FileCopyrightText: 2023-2025 Jochem Rutgers
#
# SPDX-License-Identifier: MIT

@TEST_PREAMBLE@

enable_language(C)
include(GNUInstallDirs)

include(sbom)

sbom_generate(SUPPLIER Demcon SUPPLIER_URL https://demcon.com)

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/foo.c "int main() {}")

if(MSVC)
	set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
	set(BUILD_SHARED_LIBS TRUE)
endif()

add_executable(foo ${CMAKE_CURRENT_BINARY_DIR}/foo.c)
install(TARGETS foo)
sbom_add(TARGET foo)

add_library(libfoo STATIC ${CMAKE_CURRENT_BINARY_DIR}/foo.c)
install(TARGETS libfoo)
sbom_add(TARGET libfoo)

add_library(libfoo2 SHARED ${CMAKE_CURRENT_BINARY_DIR}/foo.c)
install(TARGETS libfoo2 ARCHIVE)
sbom_add(TARGET libfoo2)

add_library(libfoo3 MODULE ${CMAKE_CURRENT_BINARY_DIR}/foo.c)
install(TARGETS libfoo3 LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}")
sbom_add(TARGET libfoo3)

add_library(libfoo4 INTERFACE)
install(TARGETS libfoo4)
sbom_add(TARGET libfoo4)

# Headers are not included. You may want to add sbom_add(DIRECTORY include FILETYPE SOURCE).

sbom_finalize()
