@echo off
::****************************************************************************************************************************************************
:: Filename:
::   run_lint.bat
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
::   - SVN: 10906A7
::
:: Description:
::  This batch file will run the lint job and output the following:
::    - The output of the lint process is outputted to lintOutput.txt.
::    - The ERRORLEVEL is put in lintExit.txt. 
::
::  Note that the following considerations should be made:
::    - Makes a call to the lint_project.bat file in the lint folder.
::    - Assumes that it starts in the Jenkins folder and must move up a level to enter the lint folder to run the lint batch file.
::    - lintExit.txt will be created last, so it can be used to see when this batch file is complete (when running it in the background).
::    - There are parameters that must be specified. See "Usage" section below.
::
:: History:
::   2021-Dec-03 by Michael Fetherston - Case 75038, Review 12178
::   - Created.
::****************************************************************************************************************************************************

:: Create a context for this batch file so cd doesn't affect the caller.
setlocal

:: Move to the lint folder from the jenkins folder.
cd ..\lint

set localerr=0
set quiet=1         :: Setup lint.bat so that it runs in quiet mode.

:: Make sure the parameters are passed in.
IF "%~1"=="" goto help

:: Grab the project specific lint file to use. For example, use GVx250B.lnt for the GVx250B project.
set customLintFile=%~1

:: Call once for Jenkins. Output file must be in format of "lint_jenkins*.txt". Redirect all output all of the messages to lintOutput.txt. 
call lint_project.bat %customLintFile% jenkins.lnt > lintOutput.txt 2>&1

:: Echo the contents of ERRORLEVEL to lintExit.txt
echo %ERRORLEVEL% > lintExit.txt

if %ERRORLEVEL% neq 0 goto err_handler
rename lint_all_output.txt lint_jenkins_GVx250B.txt

:: Call once more for human friendly output. Lint takes a long time. Disable the human friendly format for now.
::call lint_project.bat GVx250B.lnt
::if %ERRORLEVEL% neq 0 goto err_handler

:: move the files to the jenkins folder. Copy lintExit.txt last as the caller is waiting on that file.
move /Y "lintOutput.txt" "..\Jenkins\"
move /Y "lintExit.txt" "..\Jenkins\"
goto done

:err_handler
echo Error calling lint_Project.bat
goto done

::****************************************************************************************************************************************************
:help
echo Usage:
echo    %~nx0 [customLintExitFile]
echo    Where customLintExitFile = The name of the custom Lint configuration to use. For example, GVx250B.lnt.
echo.

:done
