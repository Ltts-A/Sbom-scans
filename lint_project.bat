@echo off
:: **************************************************************************************************************************************************
:: COPYRIGHT NOTICE
::
:: Copyright (c) 2021 by Parker-Hannifin Corporation.
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
::   Lints C files for TASKING V6.3r1 TriCore projects. Calls 983643 Tricore_lint_project.bat. Follow all the configuration and notes required for
::   Tricore_lint_project.bat
::
::   Do NOT modify this file to adjust the files linted and the compiler path, as this is a common batch file used for multiple projects.
::
:: Input Documents
::   - None.
::
:: History:
::   2021-Apr-29 by Jonathon Church - Case 69412, Review 11576
::   - Created based off of 983643 Tricore_lint_project.bat, so set the compiler path variables and call Tricore_lint_project.bat.
:: **************************************************************************************************************************************************

:: Save which directory the batch file started in.
pushd .

:: Change to the drive the batch file is on.
%~d0

:: Change to the directory the batch file is in.
cd %~dp0

:: Update this path to match the path for v6.3r1.
set Compiler_path=C:\Program Files\TASKING\TriCore v6.3r1
set Compiler_pathx86=C:\Program Files (x86)\TASKING\TriCore v6.3r1

:: Call the common Tricore batch file and pass in all the parameters.
call Tricore_lint_project.bat %*

:: Restore the directory the batch file started in.
popd
