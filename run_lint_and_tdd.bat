@echo off
::****************************************************************************************************************************************************
:: Filename:
::   run_lint_and_tdd.bat
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
::  This batch file will run both the lint and the TDD in parallel processes.
::
::  Note that the following considerations should be made:
::    - Makes a call to the run_lint.bat file.
::    - Assumes that it starts in the Jenkins folder and must move up a level to enter the test\CppUTest folder to run TDD.
::    - There are parameters that must be specified. See "Usage" section below.
::
:: History:
::   2022-Oct-05 by Meng Zhong Kuan - Case 78672, Review 14053
::   - Created based on run_lint_and_tdd.bat from 10906A7.
::   - Modified TIMEOUT to WAITFOR.
::****************************************************************************************************************************************************

:: Create a context for this batch file so cd doesn't affect the caller.
setlocal

SET LintExitFile="lintExit.txt"
:: If the lint exit file exits, remove it to make sure this batch file does not exit early.
DEL /Q /F %LintExitFile%

:: init the error results to no error.
set localerr=0

:: Make sure the parameters are passed in.
IF "%~1"=="" goto help
IF "%~2"=="" goto help

:: Grab the project specific make file to use. For example, use custom_project_specific_GVX250B.mk for GVx250B.
set customMakeFile=%~1
echo Using custom make file %customMakeFile%.

:: Grab the project specific lint file to use. For example, use GVx250B.lnt for the GVx250B project.
set customLintExitFile=%~2
echo Using custom lint file %customLintExitFile%.

:: Call the lint processing as a background task. It will create lintExit.txt when done, with the contents of the file being the exit code and 
:: lintOutput.txt being the contents of the lint command line output.
:: - Use the /B option so that a popup window is not created.
START /B CALL run_lint.bat %customLintExitFile%

:: While lint is running in the backgroud, run the TDD tests. First go to the CppUTest directory.
pushd ..\test\CppUTest
:: Copy over the specific custom_project_specific.mk file so that TDD builds the proper job.
cp %customMakeFile% custom_project_specific.mk
call build_all.bat jenkins
if %ERRORLEVEL% neq 0 (
  :: There was an issue with calling build_all.bat.
  echo "Error calling build_all.bat"
  set localerr=1
)
:: Revert back to original directory this script was launched from.
popd

:: Wait until the backgroud process is complete - it will output the ERRORLEVEL in lintExit.txt.
:CheckForLintToBeComplete
IF EXIST %LintExitFile% GOTO DoneLint
:: If we get here, the file is not found. Wait 10 second and then recheck.
WAITFOR SomethingThatIsNeverHappening /t 10 2>NUL
GOTO CheckForLintToBeComplete

:DoneLint
:: Copy the contents of the lint exit code into LintExitCode. 
set /p LintExitCode=<lintExit.txt

echo "Lint is complete. Exit code is %LintExitCode%"

:: print out the contents of the Lint output file.
type lintOutput.txt

if %LintExitCode% neq 0 goto err_handler_lint
:: If here that means there was no error. Goto done.
goto done

:err_handler_lint
echo "Error calling lint_Project.bat"
set localerr=1
goto done

::****************************************************************************************************************************************************
:help
echo Usage:
echo    %~nx0 [customMakeFile] [customLintExitFile]
echo    Where customMakeFile = The name of the custom TDD configuration to use. For example, custom_project_specific_GVX250B.mk.
echo          customLintExitFile = The name of the custom Lint configuration to use. For example, GVx250B.lnt.
echo.
set localerr=1

:done
exit /b %localerr%