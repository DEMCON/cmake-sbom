

..
   SPDX-FileCopyrightText: 2023 Jochem Rutgers
   
   SPDX-License-Identifier: CC-BY-4.0

CMake SBOM generation
=====================

This project provides a CMake module that helps generating an SBOM for an arbitrary project.

It automates two tasks:

- extracting version information from Git, and pass it to CMake, shell scripts and C/C++; and
- generate a SBOM in SPDX format, based on install artifacts.

Version extraction
------------------

To extract the version from Git, make sure that the ``cmake`` directory is in your ``CMAKE_MODULE_PATH``.
Then call ``include(version)`` from you ``CMakeLists.txt``.
The current project's ``GIT_VERSION`` and friends are set correctly.
Additionally, it creates a ``version.sh`` file in the ``PROJECT_BINARY_DIR`` with the detected version, and a header file with ``${PROJECT_NAME}-version`` static library that allows accessing version information from a C/C++ application.

SBOM generation
---------------

In you ``CMakeLists.txt``, make sure the ``cmake`` directory is in your ``CMAKE_MODULE_PATH``.
Then call ``include(sbom)`` from you ``CMakeLists.txt`` to setup the SBOM functions.
To generate the SBOM, perform the following sequence:

.. code: cmake

   # Start SBOM generation. Optionally, provide template files, licence, copyright.
   sbom_generate(OUTPUT some_output_file.spdx)

   # Call for every artifact that should be recorded:
   sbom_add(TARGET some_target)
   sbom_add(FILENAME some_filename ...)
   sbom_add(DIRECTORY all_files_from_some_directory ...)

   # To indicate dependencies on other packages/libraries/etc.:
   sbom_add(PACKAGE some_dependency ...)

   # Finally:
   sbom_finalize()

The SBOM is generated during the ``install`` target, as the SHA1 hashes of the (installed) files end up in the SBOM.
All functions support CMake generator expressions.

License
-------

Most of the code in this repository is licensed under MIT.
This project complies to `REUSE`_.

.. _REUSE: https://reuse.software/
