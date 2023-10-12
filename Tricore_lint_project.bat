@echo off
:: **************************************************************************************************************************************************
:: COPYRIGHT NOTICE
::
:: Copyright (c) 2018-2021 by Parker-Hannifin Corporation.
:: All rights reserved.
::
:: No part of this work may be reproduced, published, or distributed in any form or by any means (electronically, mechanically, photocopying,
:: recording or otherwise), or stored in a database or retrieval system, without the prior written permission of Parker-Hannifin Corporation in each
:: instance.
::
:: Repository:
::   - SVN: 983643
::
:: Description:
::   Lints C files for TASKING TriCore projects. Calls 983642 lint.bat and 1065602 makeLintFileList.py (must be located in same directory). There is
::   an optional configuration file that will be called if it exists (see the Configuration section below).
::
::   Do NOT modify this file to adjust the files linted and the compiler path, as this is a common batch file used for multiple projects.
::
::   In order to build this project, the computer must have the following tools installed:
::     1. Lint is installed to either %ProgramFiles%\Lint or %ProgramFiles(x86)%\Lint. See W34 for installation instructions.
::     2. The Tasking TriCore VX toolset is installed to either %ProgramFiles%\TASKING\TriCore v6.2r1 or %ProgramFiles(x86)%\TASKING\TriCore v6.2r1. See W570 for installation instructions.
::     3. Python V3.5 or higher must be installed on the computer and in the system path. To test, you can type py -3 –version at your prompt and if python is
::        installed, that command will print out the version. See N:\Software Group\Tools\Python for installer.
::     4. The pycodechecker module needs to be installed by typing pip install pycodestyle at the command line.
::
:: Configuration:
::   If there is a need to have this batch file call multiple lint configurations (or override the existing file names), setup a
::   lint_project_config.bat file as follows and make it available to this batch file (same directory):
::
::   The following needs to be set as environment variables (# is an index number, starting at 0):
::     - LintList[#][lintFileList]=This is set to the lintFileList.txt file for configuration #.
::     - LintList[#][projectSpecific]=This is set to the project_specific.txt file for configuration #.
::     - LintList[#][finalOutput]=This is set to the lint_all_output.txt file for configuration #.
::
::   Also, LintListLength needs to be set to contain the number of configurations that are setup.
::
::   By default, this uses the Tasking V6.2r1 header files for linting. Other versions of Tasking are supported by setting the Compiler_pathx86 and
::   Compiler_path environment variables prior to calling this batch file. See Tricore_v6_3r1_lint_project.bat.
::
:: Input Documents
::   - None.
::
:: History:
::   2018-Oct-29 by Michael Fetherston - Case 51698, Review 8926
::   - Created based on 1065608 CODE1.
::   2018-Nov-20 by Michael Kuusela - Review 8951
::   - Accommodate 32-bit and 64-bit windows operating system.
::   2019-Jan-07 by Michael Coyne - Review 9002
::   - Get rid of utf-8 base64 encoding, revert to simple utf-8. This was causing strange characters at the beginning of the batch file, which caused
::   a complaint in Jenkins.
::   2019-Jan-08 by Michael Fetherston - Case 53150, Review 9007
::   - Change the way the ouput file is created. Lines were being left out when creating XML files.
::   2019-Apr-30 by Michael Fetherston - Case 55184, Review 9169
::   - Add support for going through a list of lint projects - one for each hardware configuration. Call lint_project_config.bat to setup the
::     configuration for the various lint projects.
::   2021-Apr-29 by Jonathon Church - Case 69412, Review 11576
::   - Modified to allow Compiler_path and Compiler_pathx86 to be set externally, to support other versions of Tasking.
:: **************************************************************************************************************************************************

:: Setup the batch file to expand variables within the exclamation marks (example: !var!) every time the line is executed, instead of at parse time.
setlocal EnableDelayedExpansion

pushd .

:: Change to the drive the batch file is on.
%~d0

:: Change to the directory the batch file is in.
cd %~dp0

:: Setup some defaults that most projects will use.
set LintList[0][lintFileList]=lintFileList.txt
set LintList[0][projectSpecific]=project_specific.lnt
set LintList[0][finalOutput]=lint_all_output.txt

set LintListLength=1

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Begin custom initialization area:
:: If lint_project_config.bat exists, call it to setup the project specific lint files. See module header for what
:: lint_project_config.bat must contain.
if exist lint_project_config.bat (
  echo Lint found a lint_project_config.bat file to call.
  call lint_project_config.bat
)
:: End of initialization.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

set lintFiles=lint_files.lnt
::set finalOutput=lint_all_output.txt
set outFile=lint_output.txt

if not "%Compiler_path%"=="" goto CompilerPathSet
:: Update this path to match the path for v6.2r1.
set Compiler_path=C:\Program Files\TASKING\TriCore v6.2r1
set Compiler_pathx86=C:\Program Files (x86)\TASKING\TriCore v6.2r1

:CompilerPathSet
if exist "%Compiler_path%" goto SetLibPath
if not exist "%Compiler_pathx86%" goto No_Compiler_Found
:: Use the x86 path
set Compiler_path=%Compiler_pathx86%

:SetLibPath
:: Set the library include paths. Carets are used to break the command across multiple lines. Most of the library files are assumed to be in folders
:: on the same level as this folder. However, stddef.h and stdlib.h are assumed to be in the default location.
set LibIncPath= ^
  %Compiler_path%\ctc\include

:: Need to calculate the max loop value that the loop will go up to (convert from 1 based index to the max).
set maxLoopValue=%LintListLength%
set /a maxLoopValue-=1

for /l %%x in (0, 1, %maxLoopValue%) do (
  :: Set project_specific_lnt to override the project_specific.lnt file.
  set project_specific_lnt=!LintList[%%x][projectSpecific]!

  echo Lint is working on the following files:
  echo - listFile is !LintList[%%x][lintFileList]!
  echo - proj specific is !LintList[%%x][projectSpecific]!
  echo - finalOut is !LintList[%%x][finalOutput]!

  call py -3 makeLintFileList.py -i !LintList[%%x][lintFileList]! -o %lintFiles%
  if errorlevel 1 goto Python_Script_Failure

  del %outFile%
  del !LintList[%%x][finalOutput]!
  ::set quiet=1
  call lint.bat %* %lintFiles% > !LintList[%%x][finalOutput]!
  del %outFile%
  if errorlevel 1 goto Lint_Script_Failure
)


set localerr=0
goto Done

:: **************************************************************************************************************************************************
:Python_Script_Failure
set localerr=1
goto Done

:: **************************************************************************************************************************************************
:Lint_Script_Failure
set localerr=2
goto Done

:: **************************************************************************************************************************************************
:No_Compiler_Found
set localerr=3
echo ******************************************************************************** >> %finalOutput%
echo Unable to find a path to the compiler. Searched in: "%Compiler_path%" >> %finalOutput%
echo Unable to find a path to the compiler. Searched in: "%Compiler_pathx86%" >> %finalOutput%
echo ******************************************************************************** >> %finalOutput%
goto Done

:Done
popd

exit /b %localerr%
