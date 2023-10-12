@echo off
::****************************************************************************************************************************************************
:: Filename:
::   tag_build.bat
::
:: COPYRIGHT NOTICE
::
:: Copyright (c) 2023 by Parker-Hannifin Corporation
:: All rights reserved.
::
:: No part of this work may be reproduced, published, or distributed in any form
:: or by any means (electronically, mechanically, photocopying, recording or
:: otherwise), or stored in a database or retrieval system, without the prior
:: written permission of Parker-Hannifin Corporation in each instance.
::
:: Repository:
::   - SVN: 983657
::
:: Description:
::  Creates a tag comprised of the appropriate project and version information in SVN and copies content from trunk to the tag.
::  Please refer to the Runtime Variables section for details on the parameters supported.
:: 
::  Note: This batch file uses env.bat (983631) to parse the project and version information from a given version history file.
::
:: History:
::   2023-Aug-16 by Daniel Deluz - Issue GVI-1595, Review 15021
::   - Created.
::   2023-Aug-31 by Daniel Deluz - Issue GVI-1694, Review 15065
::   - Updated to group tagged builds in intervals of 100.
::****************************************************************************************************************************************************

set ENV_VERSION_MAJOR=0
set ENV_VERSION_MINOR=0
set ENV_BUILD_NUMBER=2

set ENV_PRODUCT_NUMBER=983657

::****************************************************************************************************************************************************
::   Runtime Variables
::****************************************************************************************************************************************************

:: First argument: Product or project number.
:: Second argument: Path to the version history .h file.
:: Third argument: Any descriptors used before the version information labels. If no descriptors are used, leave as "". 
:: - Example: Version Major in 10906A7_platformVersion.h is labelled as PLATFORM_VERSION_MAJOR, therefore "PLATFORM" is passed as the descriptor.
:: Fourth argument: Path to project repository in SVN.
:: Fifth argument: Build number provided by Jenkins.
:: Sixth argument: Optional - Path of the extended version file.
set PRODUCT_NUMBER=%1
set VERSION_FILE=%2
set VERSION_DESCRIPTOR=%3
set SVN_REPO_PATH=%4
set BUILD_NUMBER=%5
set EXT_VERSION_FILE=%6

:: Concatenate any descriptors used on the version labels.
if %VERSION_DESCRIPTOR% == "" (set SW_MAJOR=VERSION_MAJOR) else (set SW_MAJOR=%VERSION_DESCRIPTOR%_VERSION_MAJOR)
if %VERSION_DESCRIPTOR%  == "" (set SW_MINOR=VERSION_MINOR) else (set SW_MINOR=%VERSION_DESCRIPTOR%_VERSION_MINOR)
if %VERSION_DESCRIPTOR%  == "" (set SW_PATCH=VERSION_PATCH) else (set SW_PATCH=%VERSION_DESCRIPTOR%_VERSION_PATCH)
if %VERSION_DESCRIPTOR%  == "" (set SW_BUILD=VERSION_BUILD) else (set SW_BUILD=%VERSION_DESCRIPTOR%_VERSION_BUILD)

::****************************************************************************************************************************************************
::   Script Body
::****************************************************************************************************************************************************

echo Project: %ENV_PRODUCT_NUMBER%
echo Version: %ENV_VERSION_MAJOR%.%ENV_VERSION_MINOR%, Build %ENV_BUILD_NUMBER%

:: Check if the version file exists.
if not exist %VERSION_FILE% (
    echo No such file or directory: %VERSION_FILE%
    goto fail
)

:: Determine if there is an extended file needing to be read for major and minor numbers.
if [%6] == [] ( goto read ) else ( goto ext_read )

:: Certain projects have the major and minor numbers defined in another version history file, parse the extended file for the numbers.
:ext_read
:: Check if the ext file exists.
if not exist %EXT_VERSION_FILE% (
    echo No such file or directory: %EXT_VERSION_FILE%
    goto fail
)

:: Parse version file for the definition name for the major and minor numbers and parse the patch number. 
call env "./%VERSION_FILE%" --read --define --string EXT_MAJOR=%SW_MAJOR% EXT_MINOR=%SW_MINOR% PATCH_NUMBER=%SW_PATCH%
if %ERRORLEVEL% NEQ 0 ( goto fail ) else ( goto tag )

:: Parse extended file for major and minor number.
call env "./%EXT_VERSION_FILE%" --read --define MAJOR_REV=%EXT_MAJOR% MINOR_REV=%EXT_MINOR%
if %ERRORLEVEL% NEQ 0 ( goto fail ) else ( goto tag )

:: Read the version file and parse for the major, minor and patch numbers.
:read
:: Read the current values in the version file.
call env "./%VERSION_FILE%" --read --define --string MAJOR_REV=%SW_MAJOR% MINOR_REV=%SW_MINOR% PATCH_NUMBER=%SW_PATCH%
if %ERRORLEVEL% NEQ 0 ( goto fail ) else ( goto tag )

:: Tag the build in SVN.
:tag
:: Formulate the tag group
set /a num_check=%BUILD_NUMBER%
if %num_check% NEQ %BUILD_NUMBER% ( goto fail )

set /a prefix=%BUILD_NUMBER/100

if %prefix% NEQ 0 (
    set tag_group=%prefix%XX
) else (
    set tag_group=XX
)

:: Construct project and version string used for tagging.
set PROJECT_AND_VERSION=%PRODUCT_NUMBER%_V%MAJOR_REV%.%MINOR_REV%.%PATCH_NUMBER%.%BUILD_NUMBER%

:: Copy contents from trunk to a tag using the following command and options:
:: Command: svn copy SOURCE_URL DESTINATION_URL
:: Options:
::  --pin-externals: Pins the externals to their latest version.
::  --parents: Creates the tag directory if it does not already exist.
::  -m "LogMessage": Adds a message to the log. 
svn copy --pin-externals --parents %SVN_REPO_PATH%/trunk/ %SVN_REPO_PATH%/tags/%tag_group%/%PROJECT_AND_VERSION%/ -m "Jenkins post-build tag %BUILD_NUMBER%"

:: Verify tag was successful
if %ERRORLEVEL% NEQ 0 ( goto fail ) else ( goto done )

:fail
echo Failed to tag build
exit 1

:done