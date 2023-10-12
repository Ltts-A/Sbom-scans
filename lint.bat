@echo off
:: **************************************************************************************************************************************************
:: COPYRIGHT NOTICE
:: 
:: Copyright (c) 2017-2019 by Parker-Hannifin Corporation.
:: All rights reserved.
:: 
:: No part of this work may be reproduced, published, or distributed in any form or by any means (electronically, mechanically, photocopying, 
:: recording or otherwise), or stored in a database or retrieval system, without the prior written permission of Parker-Hannifin Corporation in each 
:: instance.
:: 
:: Repository:
::   - SVN: 983642
::
:: Description:
::   A batch file used to run PC Lint on your project and capture the output for the Tasking VX TriCore compiler. This batch file adds the following
::   information to the captured output:
::   - The time and date Lint was run.
::   - The version information for Lint.
:: 
::   End users should not modify this file.
:: 
::   This file may have its version number updated without any history being added. Please see versions.doc for relevant version history.
:: 
::   Define a "quiet" variable before calling this batch file in order to suppress un-necessary messages.
::
::   Expects "outFile" to be defined.
::
:: Input Documents
::   - None.
:: 
:: History:
::   2017-Nov-20 by Tamkin Rahman - Case 44377
::   - Created using 983620's lint.bat file as a template for the TriCore compiler.
::   2018-Jan-16 by Jonathon Church - Case 44377, Review (see comment)
::   - Added the printing of the version of the CODE1 Lint configuration to the output file.
::   - Reviewed by Michael Fetherston prior to checkin.
::   2018-Feb-23 by Tamkin Rahman - Case 46457, Review 7435
::   - Search paths no longer use expansions due to Jenkins using 32-bit java.
::   - Passes all command line arguments to lint-nt (instead of the first 9).
::   2018-Apr-26 by Michael Coyne - Case 47796, Review 7615
::   - Add error reporting if no compiler or no lint executable is found.
::   2019-Jan-08 by Michael Fetherston - Case 53150, Review 9007
::   - Added support for a quiet flag so that the extra messages create by this batch file are suppressed. Also suppress the PC Lint version info.
::   2019-Apr-25 by David Kanceruk - Case 55210, Review 9175
::   - Added support for multiple projects by letting environment variable project_specific_lnt define which project specific lint file to use.
:: **************************************************************************************************************************************************

set VERSION=V1.06 Build 7

if "%outFile%" NEQ "" goto OutFile_Setup_Properly
:: Define the final output file.
  set localerr=5
  echo ERROR: outFile is not set.
  goto Done
  
:OutFile_Setup_Properly
:: Define the file that Lint will output to.
set lintOutFile=lintOut.txt

:: **************************************************************************************************************************************************
:: Compiler_path should be set by the batch file that calls this batch file.
if not exist "%Compiler_path%" goto No_Compiler_Found

:: **************************************************************************************************************************************************
:: project_specific_lnt should be set by the batch file that calls this batch file or left blank to use the default project_specific.lnt file.
if "%project_specific_lnt%"=="" set project_specific_lnt=project_specific.lnt
if not exist "%project_specific_lnt%" goto No_PSL_Found

:: Define the path to Lint.
set LintPath=C:\Program Files\Lint
set LintPathx86=C:\Program Files (x86)\Lint

if exist "%LintPath%" goto RunLint
if not exist "%LintPathx86%" goto No_Lint_Found
:: Use the x86 path
set LintPath=%LintPathx86%

:: **************************************************************************************************************************************************
:RunLint
:: Run lint on the files requested.
"%LintPath%\lint-nt" "%project_specific_lnt%" -os(%lintOutFile%) -passes(2) %*

set localerr=0

:: Print out some PC Lint information if quiet is not set.
if "%quiet%"  NEQ "" goto Do_Not_Echo
  :: Print the time and date so it is clear when Lint was last run, followed by a blank line.
  echo Lint run on %DATE% at %TIME% > %outFile%
  echo: >> %outFile%

  :: Version info: Referenced from release procedure. Prepend a reference to the version of the configuration we're using.
  echo Uses 1065602 %VERSION% as the initial PC-Lint configuration >> %outFile%
  echo: >> %outFile%

  :: Get the version of lint. Lint prints to stdout, so we need 2> to capture stdout.
  "%LintPath%\lint-nt" -v 2>> %outFile%
  goto Done_Lint_Call

:Do_Not_Echo

  :: Get the version of lint. Lint prints to stdout, so we need 2> to capture stdout.
  "%LintPath%\lint-nt" -v -b 2>> %outFile%

:Done_Lint_Call

:: Combine the version information with the output from lint.
type %lintOutFile% >> %outFile%

:: Tidy up the temporary file.
del %lintOutFile%

:: Print out some PC Lint information if quiet is not set.
if "%quiet%"  NEQ "" goto Do_Not_Echo_2
  echo ---
  echo PC-lint for C/C++ output placed in %outFile%
:Do_Not_Echo_2
goto Done

:: **************************************************************************************************************************************************
:No_PSL_Found
set localerr=2
echo ******************************************************************************** > %outFile%
echo Unable to find a project specific lint file. "%project_specific_lnt%" not found. >> %outFile%
echo ******************************************************************************** >> %outFile%
goto Done

:: **************************************************************************************************************************************************
:No_Lint_Found
set localerr=3
echo ******************************************************************************** > %outFile%
echo No path to Lint found. Searched in %LintPath% and %LintPathx86% >> %outFile%
echo ******************************************************************************** >> %outFile%
goto Done

:: **************************************************************************************************************************************************
:No_Compiler_Found
set localerr=4
echo ******************************************************************************** > %outFile%
echo Unable to find a path to the compiler. Searched in: "%Compiler_path%" >> %outFile%
echo ******************************************************************************** >> %outFile%
goto Done

:: **************************************************************************************************************************************************
:Done
type %outFile%
exit /b %localerr%
