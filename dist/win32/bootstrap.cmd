@echo off

rem SPDX-FileCopyrightText: 2023 Jochem Rutgers
rem
rem SPDX-License-Identifier: MIT

call :check cmake
if errorlevel 1 goto error
call :check python
if errorlevel 1 goto error
call :check git
if errorlevel 1 goto error

:done
exit /b 0

:error
echo.
echo Error occurred, stopping
echo.
:silent_error
pause
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
