

..
   SPDX-FileCopyrightText: 2023-2025 Jochem Rutgers
   
   SPDX-License-Identifier: CC0-1.0

CHANGELOG
=========

All notable changes to this project will be documented in this file.

The format is based on `Keep a Changelog`_, and this project adheres to `Semantic Versioning`_.

.. _Keep a Changelog: https://keepachangelog.com/en/1.0.0/
.. _Semantic Versioning: https://semver.org/spec/v2.0.0.html



`Unreleased`_
-------------

Added
`````

- Add ``sbom_target()`` support for ``MODULE_LIBRARY`` and ``INTERFACE_LIBRARY`` (#63).
- Add ``COPYRIGHT`` argument to ``sbom_add(PACKAGE)``.
- Add ``VERSION`` to ``sbom_generate()``.

Fixed
`````

- #74: Handling enabled languages other than CXX.

Changed
```````

- Renamed ``version.cmake`` to ``git_version.cmake`` (and marked the old file as deprecated).
  This makes using Git optional, such that it is more usable in other environments (#79).
- ``<project>_version.h``'s ``<project>_TIMESTAMP`` does not use ``VERSION_TIMESTAMP`` (build timestamp) anymore, but ``GIT_TIMESTAMP`` (commit timestamp).
  This way, the build is more reproducable (#79).

.. _Unreleased: https://github.com/DEMCON/cmake-sbom/compare/v1.3.0...HEAD



`1.3.0`_ - 2025-04-17
---------------------

Added
`````

- ``sbom_add(LICENSE)`` to add a `LicenseRef-...` license to the SBOM.
- Generate a batch-querying JSON file for the OSV database.

Fixed
`````

- Fix section ordering in SBOM.

.. _1.3.0: https://github.com/DEMCON/cmake-sbom/releases/tag/v1.3.0



`1.2.0`_ - 2025-02-06
---------------------

Added
`````

- Allow running ``reuse-lint`` during configure, as workaround for a race in changing files while linting during build.

Fixed
`````

- Postpone expansion of ``CMAKE_INSTALL_PREFIX`` for CPack support.
- Handle non-alphanum characters in branch names.

.. _1.2.0: https://github.com/DEMCON/cmake-sbom/releases/tag/v1.2.0



`1.1.2`_ - 2024-05-24
---------------------

Bugfix for mandatory SPDXID prefix ``Package-`` by ``ntia-conformance-checker`` 2.0.0.

.. _1.1.2: https://github.com/DEMCON/cmake-sbom/releases/tag/v1.1.2



`1.1.1`_ - 2024-01-18
---------------------

Bugfixes.

.. _1.1.1: https://github.com/DEMCON/cmake-sbom/releases/tag/v1.1.1



`1.1.0`_ - 2023-09-29
---------------------

Misc improvements.

Added
`````

- NTIA checks.
- External document references.
- Handling library TARGETs.
- Tests.

.. _1.1.0: https://github.com/DEMCON/cmake-sbom/releases/tag/v1.1.0



`1.0.0`_ - 2023-09-27
---------------------

Initial version.

Added
`````

- Git version extraction.
- SPDX SBOM generation from CMake.

.. _1.0.0: https://github.com/DEMCON/cmake-sbom/releases/tag/v1.0.0
