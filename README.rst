

..
   SPDX-FileCopyrightText: 2023-2024 Jochem Rutgers
   
   SPDX-License-Identifier: CC-BY-4.0

CMake SBOM generation
=====================

This project provides a CMake module that helps generating (*Produce (Build)*) an `NTIA`_-compliant Software Bill of Materials (SBOM) in `SPDX`_ 2.3.0 for an arbitrary CMake project.

It automates two tasks:

- extracting version information from Git, and pass it to CMake, shell scripts and C/C++; and
- generate a SBOM in SPDX format, based on install artifacts.

The version extraction helps to get the version in the application and SBOM right.
The SBOM contains the files you mention explicitly, just like you mention what to ``install()`` in CMake.

To integrate this library in your project, see `below <sec_how_to_use_>`_ for basic instructions or the `example`_ for a complete example project.

.. _SPDX: https://spdx.github.io/spdx-spec/v2.3/
.. _NTIA: http://ntia.gov/SBOM
.. _example: https://github.com/DEMCON/cmake-sbom/tree/main/example



|  

   **Contents**

   - `Version extraction <sec_version_extraction_>`_
   - `SBOM generation <sec_sbom_generation_>`_
      - `sbom_spdxid() <sec_sbom_spdxid_>`_
      - `sbom_generate() <sec_sbom_generate_>`_
      - `sbom_add() <sec_sbom_add_>`_
      - `sbom_finalize() <sec_sbom_finalize_>`_
   - `REUSE compliance <sec_reuse_>`_
      - `reuse_lint() <sec_reuse_lint_>`_
      - `reuse_spdx() <sec_reuse_spdx_>`_
   - `How to use <sec_how_to_use_>`_
   - `Testing <sec_testing_>`_
   - `License <sec_license_>`_



.. _sec_version_extraction:

|  

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
   For this, the tag shall adhere to `Semantic Versioning 2.0.0 <semver_>`_, optionally prefixed with ``v``.

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



.. _sec_sbom_generation:

|  

SBOM generation
---------------

In your ``CMakeLists.txt``, make sure the ``cmake`` directory is in your ``CMAKE_MODULE_PATH``.
Then call ``include(sbom)`` from you ``CMakeLists.txt`` to setup the SBOM functions.
The concept is that an SBOM is generated for one project.
It contains one package (the output of the project), which contains files, and other package dependencies.
The files are all installed under ``CMAKE_INSTALL_PREFIX``.
The package dependencies are all black boxes; their files are not specified.

Generally, the following sequence is executed to create the SBOM:

.. code:: cmake
   
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



.. _sec_sbom_spdxid:

|  

``sbom_spdxid``
```````````````

Generate a unique SPDX identifier.

.. code:: cmake
   
   sbom_spdxid(
      VARIABLE <variable_name>
      [CHECK <id> | HINTS <hint>...]
   )

``VARIABLE``
   The output variable to generate a unique SDPX identifier in.

``CHECK``
   Verify and return the given identifier.

``HINTS``
   One or more hints, which are converted into a valid identifier.
   The first non-empty hint is used.
   If no hint is specified, a unique identifier is returned, with unspecified format.



.. _sec_sbom_generate:

|  

``sbom_generate``
`````````````````

Generate the header of the SBOM, based on a standard template where the given details are filled in.

.. code:: cmake
   
   sbom_generate(
      [OUTPUT <filename>]
      [INPUT <filename>...]
      [COPYRIGHT <string>]
      [LICENSE <string>]
      [NAMESPACE <URI>]
      [DOWNLOAD_URL <URL>]
      [EXTREF <ref>]
      [PROJECT <name>]
      [SUPPLIER <name>]
      [SUPPLIER_URL <name>]
      [OSV_QUERY <filename>]
   )

``OUTPUT``
   Output filename.
   It should probably start with ``${CMAKE_INSTALL_PREFIX}``, as the file is generated during ``install``.
   The variable ``SBOM_FILENAME`` is set to the full path.

``INPUT``
   One or more file names, which are concatenated into the SBOM output file.
   Variables and generator expressions are supported in these files.
   Variables in the form ``@var@`` are replaced during config, ``${var}`` during install.
   When omitted, a standard document/package SBOM is generated.
   The other parameters can be referenced in the input files, prefixed with ``SBOM_GENERATE_``.

``COPYRIGHT``
   Copyright information.
   If not specified, it is generated as ``<year> <supplier>``.

``LICENSE``
   License information.
   If not specified, ``NOASSERTION`` is used.

``NAMESPACE``
   Document namespace.
   If not specified, default to a URL based on ``SUPPLIER_URL``, ``PROJECT_NAME`` and ``GIT_VERSION``.

``DOWNLOAD_URL``
   Download URL for the software.
   If not specified, ``NOASSERTION`` is used.

``EXTREF``
   External reference regarding package manager information.
   Refer to the `SPDX`_ specification for details.

``PROJECT``
   Project name.
   Defaults to ``PROJECT_NAME``.

``SUPPLIER``
   Supplier name.
   It may be omitted when the variable ``SBOM_SUPPLIER`` is set or when any ``INPUT`` is given.

``SUPPLIER_URL``
   Supplier home page.
   It may be omitted when the variable ``SBOM_SUPPLIER_URL`` is set or when any ``INPUT`` is given.

``OSV_QUERY``
   Generate a JSON file for batch-querying the `OSV database <osv_>`_.
   The file is generated during CMake configure, based on successive ``sbom_add(PACKAGE)`` calls.
   Pass the generated file through the database by running:
   ``curl -d @<filename> "https://api.osv.dev/v1/querybatch"``

.. _osv: https://osv.dev/



.. _sec_sbom_add:

|  

``sbom_add``
````````````

Add something to the SBOM.

.. code:: cmake
   
   sbom_add(
      FILENAME <filename>
      FILETYPE <type>
      [LICENSE <string>]
      [RELATIONSHIP <string>]
      [SPDXID <id>]
   )

``FILENAME``
   The file to add.
   It should be a relative path from ``CMAKE_INSTALL_PREFIX``.
   Generator expressions are allowed.

``FILETYPE``
   The SPDX File Type.
   Refer to the `SPDX specification <SPDX_>`_.

``LICENSE``
   License of the file.
   Defaults to ``NOASSERTION`` when not specified.

``RELATIONSHIP``
   A relationship definition related to this file.
   The string ``@SBOM_LAST_SPDXID@`` will be replaced by the SPDXID that is used for this SBOM item.
   Refer to the `SPDX specification <SPDX_>`_.

``SPDXID``
   The ID to use for identifier generation.
   By default, generate a new one.
   Whether or not this is specified, the variable ``SBOM_LAST_SPDXID`` is set to just generated/used SPDXID, which could be used for later relationship definitions.

.. code:: cmake

   sbom_add(
      DIRECTORY <path>
      FILETYPE <type>
      [LICENSE <string>]
      [RELATIONSHIP <string>]
   )

``DIRECTORY``
   A path to the directory, relative to ``CMAKE_INSTALL_PREFIX``, for which all files are to be added to the SBOM recursively.
   Generator expressions are supported.

``LICENSE``
   License of the files in the directory.
   Defaults to ``NOASSERTION`` when not specified.

.. code:: cmake
   
   sbom_add(
      TARGET <target>
      [LICENSE <string>]
      [RELATIONSHIP <string>]
      [SPDXID <id>]
   )

``TARGET``
   The CMake target to add.
   Only executables are supported.
   It is assumed that the binary is installed under ``CMAKE_INSTALL_BINDIR``.

``LICENSE``
   License of the target.
   Defaults to ``NOASSERTION`` when not specified.

.. code:: cmake

   sbom_add(
      PACKAGE <name>
      [DOWNLOAD_LOCATION <URL>]
      [EXTREF <ref>...]
      [LICENSE <string>]
      [RELATIONSHIP <string>]
      [SPDXID <id>]
      [SUPPLIER <name>]
      [VERSION <version>]
      [COMMIT <commit>]
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

``SUPPLIER``
   Package supplier, which can be ``Person: name (email)``, or ``Organization: name (email)``.

``VERSION``
   Version of the package.

``COMMIT``
   Git commit hash.

.. code:: cmake

   sbom_add(
      EXTERNAL <id>
      FILENAME <path>
      [RENAME <filename>]
      [RELATIONSHIP <string>]
      [SPDXID <id>]
   )

``EXTERNAL``
   The SDPX identifier of a package in an external file.

``FILENAME``
   Reference to another SDPX file as External document reference.
   Then, depend on the package named in that document.
   The external SDPX file is copied next to the SBOM.
   Generator expressions are supported.

``RENAME``
   Rename the external document to the given filename, without directories.

``SPDXID``
   The identifier of the external document, which is used as prefix for the package identifier.
   Defaults to a unique identifier.
   The package identifier is added automatically.
   The variable ``SBOM_LAST_SPDXID`` is set to the used identifier.

.. code:: cmake
   
   sbom_add(
      LICENSE LicenseRef-<string>
      [NAME <string>]
      [FILE <path> | TEXT <string>]
   )

``LICENSE``
   The ``LicenseRef-...`` identifier.

``NAME``
   The license name.
   Defaults to ``NOASSERTION`` when not specified.

``FILE``
   The license file.
   It defaults to ``${PROJECT_SOURCE_DIR}/LICENSES/<LICENSE>``.

``TEXT``
   The license text.
   It defaults to the contents of ``FILE``.



.. _sec_sbom_finalize:

|  

``sbom_finalize``
`````````````````

Finalize the SBOM and verify its contents and/or format.

.. code:: cmake

   sbom_finalize(
      [NO_VERIFY | VERIFY]
   )
   
   sbom_finalize(
      GRAPH <filename>
   )

``NO_VERIFY``
   Do not run the verification against the generated SBOM.
   By default, verification is only performed when python3 is found with the appropriate packages.

``VERIFY``
   Always run the verification against the generated SBOM.
   Make sure to install ``dist/common/requirements.txt`` in your python environment first.

``GRAPH``
   Generate a dependency graph of the SBOM.
   This implies ``VERIFY``.
   It requires ``spdx-tools[graph_generation]`` python package to be installed first.



.. _sec_reuse:

|  

REUSE
-----

This section lists a few functions that help with `REUSE`_ compliance of your repository.

.. _sec_reuse_lint:

|  

``reuse_lint``
``````````````

Perform checking for `REUSE`_ compliance of the project repository source files.

.. code:: cmake
   
   reuse_lint(
      [TARGET <target>]
      [CONFIG] [ALL]
   )

``TARGET``
   Target name to run the linter.
   Defaults to ``${PROJECT_NAME}-reuse-lint`` when omitted.

``CONFIG``
   Run the linting during CMake configure instead of during build.
   When this flag is set, the target is still created too.

``ALL``
   Add a dependency from ``all`` to the ``TARGET``.



.. _sec_reuse_spdx:

|  

``reuse_spdx``
``````````````

Export an SPDX file based on the source code of the project with copyright and license information.

.. code:: cmake

   reuse_spdx(
      [TARGET <target>]
      [OUTPUT <file>]
   )

``TARGET``
   Target name that executes the exporter.
   Defaults to ``${PROJECT_NAME}-reuse-spdx``.

``OUTPUT``
   The output SPDX file.



.. _sec_how_to_use:

|  

How to use
----------

To use this library, perform the following steps:

1. Put this repository somewhere on your system (e.g., make it a Git submodule in your project).
2. Add the ``cmake`` directory to your ``CMAKE_MODULE_PATH``.
   For example, add to your ``CMakeLists.txt``:

   .. code:: cmake

      list(APPEND CMAKE_MODULE_PATH "path/to/cmake-sbom/cmake")

3. Optional: when you want to verify the generated SBOM for `NTIA`_ compliance, install ``dist/common/requirements.txt`` in your Python (virtual) environment:

   .. code:: bash

      $ python3 -m pip install -r path/to/cmake-sbom/dist/common/requirements.txt

4. In your top-level ``CMakeLists.txt``, somwhere after ``project(...)``, prepare the SBOM:

   .. code:: cmake

      include(sbom)
      sbom_generate(SUPPLIER you SUPPLIER_URL https://some.where)
      # Add sbom_add() ...
      sbom_finalize()

5. Build *and install* your project, such as:

   .. code:: bash

      mkdir build
      cd build
      cmake ..
      cmake --build . --target all
      cmake --build . --target install

   The SBOM will by default be generated in your ``CMAKE_INSTALL_PREFIX`` directory (see also CMake output).



.. _sec_testing:

|  

Testing
-------

For testing purposes, go to ``dist/<your_platform>``, run ``bootstrap`` to install system dependencies, and then run ``build`` to build the example and all tests.
Running the bootstrap and building is not required when you only want to use this library in your project, as discussed `above <sec_how_to_use_>`_.



.. _sec_license:

|  

License
-------

Most of the code in this repository is licensed under MIT.
This project complies to `REUSE`_.

.. _REUSE: https://reuse.software/
