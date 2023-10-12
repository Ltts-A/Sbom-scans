@echo off
::****************************************************************************************************************************************************
:: Filename:
::   update_versions.bat
::
:: COPYRIGHT NOTICE
::
:: Copyright (c) 2021 by Parker-Hannifin Corporation
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
::   Updates the version information in version.h.
::
:: History:
::   2021-Apr-07 by Jonathon Church - Case 69010, Review 11576
::   - Created based on 1071604.
::   2021-May-13 by Michael Fetherston - Case 69750, Review 11670
::   - Added support for patch number.
::   2021-Oct-25 by Jonathon Church - Case 69974, Review 12061
::   - Added the doxygen configuration file so the doxygen configuration gets updated.
::   2021-Oct-26 by Michael Fetherston - Case 73380, Reviewed by Jonathon Church
::   - Fixed an issue where update_versions_helper.bat modified the VA_NUMBER environment variable.
::****************************************************************************************************************************************************

set LOC=../root/Indy
set FILE=version.h

set LOC_doxygen=../../Documents/doxygen
:: List the doxyfile configurations in a space separated list.
set FILE_doxyfile_list=1090601_Application_Doxyfile

set SW_MAJOR=VERSION_MAJOR
set SW_MINOR=VERSION_MINOR
set SW_PATCH=VERSION_PATCH
set SW_BUILD=VERSION_BUILD

:: Read the current values in version.h.
call env "%LOC%/%FILE%" --read --define MAJOR_REV=%SW_MAJOR% MINOR_REV=%SW_MINOR% PATCH_NUMBER=%SW_PATCH% BUILD_NUMBER=%SW_BUILD%

::****************************************************************************************************************************************************
:: Now check the parameters to see which way this script is being called (see Help below).
if "%~1"=="" goto Help
if "%~2"=="" goto Help

:: If %~1 equals --build_number, then this script is being called to fill in only the build number.
if "%~1"=="--build_number" set BUILD_NUMBER="%~2"
if "%~1"=="--build_number" goto Write

if "%~3"=="" goto Help
if "%~4"=="" goto Help

::****************************************************************************************************************************************************
:: If reacing this point in the script, it is being called to specify the version, issue, patch and build numbers.
set MAJOR_REV=%~1
set MINOR_REV=%~2
set PATCH_NUMBER=%~3
set BUILD_NUMBER=%~4

::****************************************************************************************************************************************************
:Write
:: Use the env.bat file from 983631 to update the version numbers.

:: Update version.h
call env "%LOC%/%FILE%" --write --define %SW_MAJOR%=%MAJOR_REV% %SW_MINOR%=%MINOR_REV% %SW_PATCH%=%PATCH_NUMBER% %SW_BUILD%=%BUILD_NUMBER%

:: Skip doxygen if there is no doxyfile provided.
if "%FILE_doxyfile_list%"=="" goto Done

:: update_versions_helper.bat modifies the VA_NUMBER environment variable. To preserve it, we call setlocal to save the current environment settings.
:: Endlocal will be called to restore them.
setlocal
:: Loop though FILE_doxyfile_list. %%G contains an element of the list.
for %%G in (%FILE_doxyfile_list%) do (
  call update_versions_helper.bat %%G %MAJOR_REV% %MINOR_REV% %PATCH_NUMBER% %BUILD_NUMBER%
)
endlocal

goto Done

::****************************************************************************************************************************************************
:Help
echo Usage:
echo    update_versions [aa bb cc dd]^|[--build_number dd]
echo    Where aa = The major version number.
echo          bb = The minor version number.
echo          cc = The patch version number.
echo          dd = The build number.
echo.

::****************************************************************************************************************************************************
:Done