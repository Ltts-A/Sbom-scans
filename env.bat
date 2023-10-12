@echo off
::*************************************************************************************************
:: Filename:
::   env.bat
::
:: COPYRIGHT NOTICE
::
:: Copyright (c) 2017 by Parker-Hannifin Corporation
:: All rights reserved.
::
:: No part of this work may be reproduced, published, or distributed in any form
:: or by any means (electronically, mechanically, photocopying, recording or
:: otherwise), or stored in a database or retrieval system, without the prior
:: written permission of Parker-Hannifin Corporation in each instance.
::
:: Repository:
::   - MKS: 983631
::
:: Description:
::   This batch file uses the rw_variable.py file to provide the following functionality:
::      -Reading of #define variables from C or H files, and using these values as definitions to
::       environment variables.
::      -Writing to #define variables in C or H files, replacing the values of the variable with
::       the given value.
::
::   See :help below for usage for this script.
::
:: History:
::   2017-Jul-25 by Tamkin Rahman - Case 40919, Review 6027
::   - Created.
::   2017-Sep-01 by Tamkin Rahman - Case 41993, Review 6092
::   - Case 41992, bugfix so that values read as numerical '0' do not cause an error.
::   - Updated help section.
::   2017-Dec-19 by Tamkin Rahman - Case 43246, Review 7285
::   - Updated help text to indicate the "--string" option can be used to write strings to a
::     value.
::   - Use the absolute path to the helper script so that env.bat can be called from any directory.
::   - Explicitly use python 3 when calling the helper script.
::   2018-Nov-21 by Stuart Thain - Reviewed at my desk by Michael Kuusela
::   Fixed error in read routine (Python wasn't called on the helper script)
::*************************************************************************************************

set ENV_VERSION_MAJOR=1
set ENV_VERSION_MINOR=03
set ENV_BUILD_NUMBER=4

set ENV_PRODUCT_NUMBER=983631

::*************************************************************************************************

set helper_script="%~dp0rw_variable.py"

:: First argument should be the filename,
:: Second argument should be --write or --read,
:: Third argument should be the file type (e.g. --define or --doxygen),
:: Fourth argument, optionally, can be --string, which indicates that the value will be
:: read as a raw string.
set filename=%1
set option=%2
set type=%3
set string=%4

if "%string%"=="--string" shift
if NOT "%string%"=="--string" set string="--not_string"

:check_options
if "%option%"=="--write" goto write
if "%option%"=="--read" goto read
goto :help

::*************************************************************************************************

:: Reading from a file
:read
shift
shift
shift

:read_loop
set var=%1
set val=%2

set temp_file="%var%_temporary.txt"

:: When reading, we expect the python file to print the value that was read. This batch file will
:: pipe it to a temporary file. Then, the environment variable can be set by piping the contents
:: of the temporary file to the variable.
call py -3 %helper_script% %filename% %option% %type% %string% %val%>%temp_file%
if "%ERRORLEVEL%"=="-1" goto not_found
set /p %var%=<%temp_file%
del %temp_file%

shift
shift
if not "%~1"=="" goto read_loop
goto done
:: End reading from a file

::*************************************************************************************************

:: Writing to a file
:write
shift
shift
shift

:write_loop
set var=%1
set val=%2

call py -3 %helper_script% %filename% %option% %type% %string% %var%=%val%
if not "%ERRORLEVEL%"=="0" goto not_found

shift
shift
if not "%~1"=="" goto write_loop

goto done
:: End writing to a file

::*************************************************************************************************

:help
echo   Project: %ENV_PRODUCT_NUMBER%
echo   Version %ENV_VERSION_MAJOR%.%ENV_VERSION_MINOR%, Build %ENV_BUILD_NUMBER%
echo   %DATE% at %TIME%
echo[
echo   Usage:
echo      env filename {--write^|--read} type [--string] FOO1=BAR1 FOO2=BAR2 ...
echo[
echo      filename: The name of the .c or .h file that will be read or written to.
echo      --write : If this is asserted, the value for the variable FOO1 will be changed to BAR1
echo                in filename.
echo      --read  : If this is asserted, the value for the environment variable FOO1 will be defined
echo                as the value for the variable BAR1.
echo      type    : The type of variable that will be read/written to. Currently available are:
echo                --define : C or H files, and #define FOO BAR style variables.
echo                --doxygen: Doxygen files, with typical FOO = BAR style variables.
echo      --string: If this is asserted, for read operations, the value that is read from the FOO1 
echo                variable will be read as a raw string, instead of a number. Whitespace around the
echo                start and end of the value will not be preserved. For a write operation, the 
echo                value that is written will have quotes around it.
echo[
echo      Examples:
echo          Suppose in the file version.h, there is a line:
echo               #define VERSION_MAJOR (3U)   //comment
echo          Running:
echo               "env version.h --write VERSION_MAJOR=30"
echo          Will change this line to:
echo               #define VERSION_MAJOR 30 //comment
echo[
echo          Suppose you have an environment variable VERSION_MAJ, and currently "%%VERSION_MAJ%%"="".
echo[
echo          Further, suppose in the file version.h, there is the line:
echo                  #define VERSION_MAJOR ( 3U ) //comment
echo          Then,
echo               Running:
echo                   "env --read --define VERSION_MAJ=VERSION_MAJOR"
echo               Will result in "%%VERSION_MAJ%%"="3"
echo               Running:
echo                   "env --read --define --string VERSION_MAJ=VERSION_MAJOR"
echo               Will result in "%%VERSION_MAJOR%%"="( 3U )"
echo[
echo  NOTES: The environment variables created by this script will last for the duration of the
echo         cmd.exe session.
echo[
echo         When calling this batch file from other batch files, use "call env" instead of "env".
echo[
echo         To clear read-only flags for files, use "attrib -r <filename>" prior to using this batch
echo         file for writing.

goto done

:not_found
echo Env: Variable %val% wasn't found in %filename%.
echo      Variable pairs after %val%=%var% or %var%=%val% were not read from or written to.

:done