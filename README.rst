

..
   SPDX-FileCopyrightText: 2023 Jochem Rutgers
   
   SPDX-License-Identifier: CC-BY-4.0

CMake SBOM generation
=====================

This project provides a CMake module that helps generating an SBOM in `SPDX`_ for an arbitrary project.

It automates two tasks:

- extracting version information from Git, and pass it to CMake, shell scripts and C/C++; and
- generate a SBOM in SPDX format, based on install artifacts.

.. _SPDX: https://spdx.github.io/spdx-spec/v2.3/

Version extraction
------------------

To extract the version from Git, make sure that the ``cmake`` directory is in your ``CMAKE_MODULE_PATH``.
Then call ``include(version)`` from you ``CMakeLists.txt``.
It will set the following variables in the current scope for the current project:

``GIT_HASH``
   The full Git hash.

``GIT_HASH_SHORT``
   The short Git hash.

``GIT_HASH_<tag>``
   The full Git hash for the given tag.

``GIT_VERSION``
   The Git tag, or a combination of the branch and hash if there is no tag set for the current commit.

``GIT_VERSION_PATH``
   ``GIT_VERSION``, but safe to be used in file names.

``GIT_VERSION_TRIPLET``
   A major.minor.patch triplet, extracted from the current tag.
   For this, the tag shall adhere to `Semantic Versioning 2.0.0 <semver>`_, optionally prefixed with ``v``.

.. _semver: https://semver.org/

``GIT_VERSION_MAJOR``
   The major part of ``GIT_VERSION_TRIPLET``.

``GIT_VERSION_MINOR``
   The minor part of ``GIT_VERSION_TRIPLET``.

``GIT_VERSION_PATCH``
   The patch part of ``GIT_VERSION_TRIPLET``.

``GIT_VERSION_SUFFIX``
   Everything after the triplet of ``GIT_VERSION_TRIPLET``.

``VERSION_TIMESTAMP``
   The current build time.

Additionally, it creates:

``${PROJECT_BINARY_DIR}/version.sh``
   A shell file that sets ``GIT_VERSION``, ``GIT_VERSION_PATH``, and ``GIT_HASH``.

``${PROJECT_BINARY_DIR}/version.txt``
   A text file that contains ``GIT_VERSION``.

``${PROJECT_NAME}-version`` static library target
   When linking to this target, one can access the version information in C/C++ by including the ``<${PROJECT_NAME}-version.h>`` header file.
   The file is generated in ``${PROJECT_BINARY_DIR}/include``.

SBOM generation
---------------

In your ``CMakeLists.txt``, make sure the ``cmake`` directory is in your ``CMAKE_MODULE_PATH``.
Then call ``include(sbom)`` from you ``CMakeLists.txt`` to setup the SBOM functions.
The concept is that an SBOM is generated for one project.
It contains one package (the output of the project), which contains files, and other package dependencies.
The files are all installed under ``CMAKE_INSTALL_PREFIX``.
The package dependencies are all black boxes; their files are not specified.

Generally, the following sequence is executed to create the SBOM:

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

``cmake/sbom.cmake`` provides the following functions:

``sbom_spdxid``
^^^^^^^^^^^^^^^

Generate a unique SPDX identifier.

.. code:: cmake
   
   sbom_spdxid(
      VARIABLE <variable_name>
      [HINTS <hint>...]
   )

``VARIABLE``
   The output variable to generate a unique SDPX identifier in.

``HINTS``
   One or more hints, which are converted into a valid identifier.
   The first non-empty hint is used.
   If no hint is specified, a unique identifier is returned, with unspecified format.

``sbom_generate``
^^^^^^^^^^^^^^^^^

Generate the header of the SBOM, based on a standard template where the given details are filled in.

.. code:: cmake
   
   sbom_generate(
      [OUTPUT <filename>]
      [COPYRIGHT <string>]
      [LICENSE <string>]
      [NAMESPACE <URI>]
      [PROJECT <name>]
      [SUPPLIER <name>]
      [SUPPLIER_URL <name>]
   )

``OUTPUT``
   Output filename.
   It should probably start with ``${CMAKE_INSTALL_PREFIX}``, as the file is generated during ``install``.

``COPYRIGHT``
   Copyright information.
   If not specified, it is generated as ``<year> <supplier>``.

``LICENSE``
   License information.
   If not specified, ``NOASSERTION`` is used.

``NAMESPACE``
   Document namespace.
   If not specified, default to a URL based on ``SUPPLIER_URL``, ``PROJECT_NAME`` and ``GIT_VERSION``.

``PROJECT``
   Project name.
   Defaults to ``PROJECT_NAME``.

``SUPPLIER``
   Supplier name.
   It may be omitted when the variable ``SBOM_SUPPLIER`` is set.

``SUPPLIER_URL``
   Supplier home page.
   It may be omitted when the variable ``SBOM_SUPPLIER_URL`` is set.

Alternatively, you can specify your own template.

.. code:: cmake
   
   sbom_generate(
      [OUTPUT <filename>]
      INPUT <filename>...
   )

``INPUT``
   One or more file names, which are concatenated into the SBOM output file.
   Variables and generator expressions are supported in these files.

``sbom_add``
^^^^^^^^^^^^

Add something to the SBOM.

.. code:: cmake
   
   sbom_add(
      FILENAME <filename>
      FILETYPE <type>
      [RELATIONSHIP <string>]
      [SPDXID <id>]
   )

``FILENAME``
   The file to add.
   It should be a relative path from ``CMAKE_INSTALL_PREFIX``.
   Generator expressions are allowed.

``FILETYPE``
   The SPDX File Type.
   Refer to the `SPDX specification <SPDX>`_.

``RELATIONSHIP``
   A relationship definition related to this file.
   The string ``@SBOM_LAST_SPDXID@`` will be replaced by the SPDXID that is used for this SBOM item.
   Refer to the `SPDX specification <SPDX>`_.

``SPDXID``
   The ID to use.
   By default, generate a new one.
   Whether or not this is specified, the variable ``SBOM_LAST_SPDXID`` is set to just generated/used SPDXID, which could be used for later relationship definitions.

.. code:: cmake

   sbom_add(
      DIRECTORY <path>
      FILETYPE <type>
      [RELATIONSHIP <string>]
   )

``DIRECTORY``
   A path to the directory, relative to ``CMAKE_INSTALL_PREFIX``, for which all files are to be added to the SBOM recursively.
   Generator expressions are supported.

.. code:: cmake
   
   sbom_add(
      TARGET <target>
      [RELATIONSHIP <string>]
      [SPDXID <id>]
   )

``TARGET``
   The CMake target to add.
   Only executables are supported.
   It is assumed that the binary is installed under ``CMAKE_INSTALL_BINDIR``.

.. code:: cmake

   sbom_add(
      PACKAGE <name>
      DOWNLOAD_LOCATION <URL>
      [EXTREF <ref>...]
      [LICENSE <string>]
      [RELATIONSHIP <string>]
      [SPDXID <id>]
      [VERSION <version>]
   )

``PACKAGE``
   A package to be added to the SBOM.
   The name is something that is identifiable by standard tools, so use the name that is given by the author or package manager.
   The package files are not analyzed further; it is assumed that this package is a dependency of the project.

``DOWNLOAD_LOCATION``
   Package download location.
   The URL may be used by tools to identify the package.

``EXTREF``
   External references, such as security or package manager information.
   Refer to the `SPDX`_ specification for details.

``LICENSE``
   License of the package.
   Defaults to ``NOASSERTION`` when not specified.

``VERSION``
   Version of the package.

``sbom_finalize``
^^^^^^^^^^^^^^^^^

Finalize the SBOM and verify its contents and/or format.

.. code:: cmake

   sbom_finalize()

License
-------

Most of the code in this repository is licensed under MIT.
This project complies to `REUSE`_.

.. _REUSE: https://reuse.software/
