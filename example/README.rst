

..
   SPDX-FileCopyrightText: 2023-2024 Jochem Rutgers
   
   SPDX-License-Identifier: CC0-1.0

Example
=======

This example extracts version information from Git, and builds a simple application that uses it.

To build the example, run something like:

.. code:: bash
   
   mkdir build
   cd build
   cmake ..
   cmake --build . --target install

The project installs the build artifacts in ``build/deploy``, including the ``example`` application, a text file with the version, and the SBOM.

An example of the generated output is available in `output`_.

.. _output: https://github.com/DEMCON/cmake-sbom/tree/main/example/output
