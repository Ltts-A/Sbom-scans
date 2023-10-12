@echo off
::****************************************************************************************************************************************************
:: Filename:
::   update_versions_helper.bat
::
:: COPYRIGHT NOTICE
::
:: Copyright (c) 2019-2021 by Parker-Hannifin Corporation
:: All rights reserved.
::
:: No part of this work may be reproduced, published, or distributed in any form
:: or by any means (electronically, mechanically, photocopying, recording or
:: otherwise), or stored in a database or retrieval system, without the prior
:: written permission of Parker-Hannifin Corporation in each instance.
::
:: Repository:
::   - SVN: 1071601
::
:: Description:
::   Takes in a doxyfile name and updates the PROJECT_NUMBER and version information.
::   Since we need to manipulate a variable that is in a for loop, you need to call another batch file to resolve it properly.
::
:: History:
::   2019-Apr-26 by Michael Fetherston - Case 55184, Review 9169
::   - Created.
::   2021-May-13 by Michael Fetherston - Case 69750, Review 11670
::   - Added support for an optional patch number. If patch number is used, the string format will be "Va.b.c.d", with no padding.
::****************************************************************************************************************************************************
if "%~1"=="" goto Help
if "%~2"=="" goto Help
if "%~3"=="" goto Help
if "%~4"=="" goto Help

set DOXYFILE_NAME=%~1
set MAJOR_REV=%~2
set MINOR_REV=%~3

:: Assume no patch number exists.
set PATCH_NUMBER_EXISTS=0

IF "%~5"=="" (
  :: Just va_number, version, issue and build has been passed in.
  set BUILD_NUMBER=%~4

  :: Pad minor rev if less than or equal 9 (e.g. V0.05 instead of V0.5).
  IF %MINOR_REV% leq 9 (
    set MINOR_REV=0%MINOR_REV%
  )
) ELSE (
  :: A patch number has been passed in. No padding is done with this version format.
  set PATCH_NUMBER=%~4
  set BUILD_NUMBER=%~5
  set PATCH_NUMBER_EXISTS=1
)

:: Extract the VA number from the first 7 characters of the DOXYFILE_NAME.
set VA_NUMBER=%DOXYFILE_NAME:~0,7%

IF %PATCH_NUMBER_EXISTS%==0 (
  :: Patch number is not defined. Use format "Vx.yy Build z"
  call env "%LOC_doxygen%/%DOXYFILE_NAME%" --write --doxygen PROJECT_NUMBER="%VA_NUMBER% V%MAJOR_REV%.%MINOR_REV% Build %BUILD_NUMBER%"
) ELSE (
  :: Patch number is defined. Use format "Va.b.c.d"
  call env "%LOC_doxygen%/%DOXYFILE_NAME%" --write --doxygen PROJECT_NUMBER="%VA_NUMBER% V%MAJOR_REV%.%MINOR_REV%.%PATCH_NUMBER%.%BUILD_NUMBER%"
)

goto Done

::****************************************************************************************************************************************************
:Help
echo Usage:
echo    update_versions_helper [doxyfile_name aa bb [pp] cc]
echo    Where doxyfile_name = The name of the doxyfile. The VA number is assumed to be the first 7 characters.
echo          aa = The major version number.
echo          bb = The minor version number.
echo          pp = The patch number. This number is optional.
echo          cc = The build number.
echo.

::****************************************************************************************************************************************************
:Done