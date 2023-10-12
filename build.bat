@echo off
::****************************************************************************************************************************************************
:: Filename:
::   build.bat
::
:: COPYRIGHT NOTICE
::
:: Copyright (c) 2021-2023 by Parker-Hannifin Corporation
:: All rights reserved.
::
:: No part of this work may be reproduced, published, or distributed in any form
:: or by any means (electronically, mechanically, photocopying, recording or
:: otherwise), or stored in a database or retrieval system, without the prior
:: written permission of Parker-Hannifin Corporation in each instance.
::
:: Repository:
::   - SVN: 1090601
::
:: Description:
::  This batch file uses the Eclipse "headlessbuild" application to build Tasking
::  TriCore projects from the command line (intended use for Jenkins). Note that
::  all configurations will be built.
::
::  Note that the following considerations should be made:
::		- Make sure the following files are checked in:
::			- The ".project" file for each project. NOTE, the ".project" file's project name(s)
::            must match the folder the ".project" file is in.
::			- The ".cproject" file for each project.
::		- Make sure the following files are NOT checked in:
::      	- Other files or folders that begin with ".".
::			- Object files and temporary files (i.e. The <project>/<configuration_name> folders).
::		- Fetch a fresh copy of the repository on each build.
::		- The workspace CANNOT reside within one of the projects. If this is attempted, eclipse
::		  will return an error.
::    - There are optional parameters that can be specified. See "Usage" section below.
::
:: History:
::   2021-Apr-07 by Jonathon Church - Case 69010 and 67930, Review 11576
::   - Created based on 1071604.
::   2021-May-21 by Michael Fetherston - Case 69750, Review 11670
::   - Changed the version number format for the published hex file to Va_b_c_d.
::   2021-Jun-01 by Michael Fetherston - Case 70010, Review 11704 
::   - Allow an optional parameter to specify the Tasking build configuration.
::   2021-Dec-13 by Nicolaj Jensen - Case 72004, Review 12214 
::   - Removed "set SKIP_REPO_CHECK=1". No longer needed.
::   2023-Jul-04 by Michael Fetherston - Issue GVI-1175, Review 14873
::   - Publish _uds.hex files as well. This is an input to creating .pesp files.
::****************************************************************************************************************************************************
set INSTALL_PATH=C:\Program Files\TASKING\TriCore v6.3r1

set ECLIPSE_WORKSPACE=..\root
set PROJECT_NAME=Indy
:: Default to Debug_SKAI configuration if none provided.
IF "%~1"=="" (
  set CONFIGURATION=Debug_SKAI
) ELSE (
  set CONFIGURATION=%~1
)

:: Default to 1090601 VA number if none provided.
IF "%~2"=="" (
  set VA_NUMBER=1090601
) ELSE (
  set VA_NUMBER=%~2
)

:: Default to SKAI variant name if none provided.
IF "%~3"=="" (
  set VARIANT_NAME=SKAI
) ELSE (
  set VARIANT_NAME=%~3
)

set LOGFILE=%VA_NUMBER%_build_log.txt

:: A workspace can consist of multiple configurations. To build:
:: - all configurations of a given project, use %PROJECT_NAME%
:: - A specific configuration of a given project, use %PROJECT_NAME%/CONFIG, where CONFIG is the build configuration to use.
set BUILD_CONFIGURATION=%PROJECT_NAME%/%CONFIGURATION%

:: MAJOR_REV, MINOR_REV, and BUILD_NUMBER are set/updated here.
if "%BUILD_NUMBER%"=="" set BUILD_NUMBER=0
call update_versions.bat --build_number %BUILD_NUMBER%

::****************************************************************************************************************************************************
:: Delete the ".metadata" folder from our workspace if it exists, so that we can use "import <project>" on each build.
:: /S = Recursively delete all files in the directory.
:: /Q = Run in quiet mode, delete directories without confirmation.
if exist "%ECLIPSE_WORKSPACE%/.metadata" (
  rmdir /Q /S "%ECLIPSE_WORKSPACE%/.metadata"
)

echo %DATE% %TIME% >"%LOGFILE%"

:: The option --launcher.suppressErrors prevents a pop-up from appearing (and thus stalling the build) during errors.
:: The option -nosplash option prevents the IDE from opening.
:: The option -cleanBuild will just build the project (since Jenkins cleans the workspace before doing anything). Alternatively, just -cleanBuild can be used.
:: The option -data points to the location of the workspace to use.
:: The option -application tells eclipse to do execute these commands "headless" (i.e. without the IDE).
:: The option -import adds projects to the workspace.
call "%INSTALL_PATH%/ctc/eclipse/eclipsec" --launcher.suppressErrors -nosplash -data "%ECLIPSE_WORKSPACE%" -application com.tasking.managedbuilder.headlessbuild -import "%ECLIPSE_WORKSPACE%/%PROJECT_NAME%" -build "%BUILD_CONFIGURATION%" >>"%LOGFILE%"
if not "%ERRORLEVEL%"=="0" goto Error

type "%LOGFILE%"

:: Copy the compiler output to publish and put in the proper version information.
:: Note that the post build step creates the signed .hex file as Indy_signed.hex. That is the one we wish to archive.
copy "%ECLIPSE_WORKSPACE%\%PROJECT_NAME%\%CONFIGURATION%\%PROJECT_NAME%_signed.hex" "..\publish\%VA_NUMBER%_%VARIANT_NAME%_V%MAJOR_REV%_%MINOR_REV%_%PATCH_NUMBER%_%BUILD_NUMBER%.hex"
copy "%ECLIPSE_WORKSPACE%\%PROJECT_NAME%\%CONFIGURATION%\%PROJECT_NAME%_uds.hex" "..\publish\%VA_NUMBER%_%VARIANT_NAME%_V%MAJOR_REV%_%MINOR_REV%_%PATCH_NUMBER%_%BUILD_NUMBER%_uds.hex"
copy "%ECLIPSE_WORKSPACE%\%PROJECT_NAME%\%CONFIGURATION%\%PROJECT_NAME%.map" "..\publish\%VA_NUMBER%_%VARIANT_NAME%.map"

goto Done

::****************************************************************************************************************************************************
:Error
type "%LOGFILE%"

echo Error occurred during compile.
echo.
::****************************************************************************************************************************************************
echo Usage:
echo    build.bat [TASKING_Configuration_name VA_number Variant_name]
echo    Where TASKING_Configuration_name = The name of the Tasking configuration to build. Debug_SKAI is the default.
echo          VA_number = the VA number of the software. Used in the naming of the files. 1090601 is the default.
echo          Variant_name = the human readable variant name of the software. Used in the naming of the files. SKAI is the default.
echo.

exit /B 1

:Done
