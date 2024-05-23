@echo off

rem SPDX-FileCopyrightText: 2023-2024 Jochem Rutgers
rem
rem SPDX-License-Identifier: MIT

set "here=%~dp0"
set "cmake_here=%here:\=/%"
pushd "%here%"

rem Just guess where binaries may be.
set "PATH=%ProgramFiles%\CMake\bin;%ChocolateyInstall%\lib\mingw\tools\install\mingw64\bin;%ChocolateyInstall%\lib\ninja\tools;%PATH%;%ChocolateyInstall%\bin"

echo Checking your environment...
call :check cmake
if errorlevel 1 goto error
call :check python
if errorlevel 1 goto error
call :check git
if errorlevel 1 goto error

if exist ..\venv goto have_venv
echo Installing venv...
python -m venv ..\venv
if errorlevel 1 goto error
..\venv\Scripts\python.exe -m pip install -r ..\common\requirements.txt
if errorlevel 1 goto error

:have_venv
echo Building...
if not exist build mkdir build
if errorlevel 1 goto error
cd build
if errorlevel 1 goto error
cmake ..\..\.. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="%cmake_here%/build/deploy" -DPython3_EXECUTABLE="%cmake_here%/../venv/Scripts/python.exe" %*
if errorlevel 1 goto error
cmake --build . --target install
if errorlevel 1 goto error

:done
popd
exit /b 0

:error
echo.
echo Error occurred, stopping
echo.
:silent_error
popd
exit /b 1

:check
setlocal
where /q "%1" > NUL 2>NUL
if errorlevel 1 goto missing
goto :eof
:missing
echo Cannot find %1. Please install on your system first.
endlocal
goto :eof
