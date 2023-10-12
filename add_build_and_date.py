#!/usr/bin/env python3
# ***************************************************************************************************************************************************
# COPYRIGHT NOTICE
#
# Copyright (c) 2018 by Parker-Hannifin Corporation
# All rights reserved.
#
# No part of this work may be reproduced, published, or distributed in any form or by any means (electronically, mechanically, photocopying,
# recording or otherwise), or stored in a database or retrieval system, without the prior written permission of Parker-Hannifin Corporation in each
# instance.
#
#
# Coding Standard(s):
#   - 983F30.01A - Parker WPG Python Coding Standard
#
# Repository:
#   - WPG SVN: 1071601
#
# Description:
#   Replaces the string "$BUILD" with a given build number, and "$DATE" with the current date (in the format "YYYY/MM/DD") in a given file.
#
#   Usage: python add_build_and_date.py filename build_num
#
# Input Documents:
#   The following is a list of input documents that support this document. Input documents that change after release of this document may have an
#   impact on this document.
#     - See case 52219.
#
# History:
#   2018 November 20 by Stuart Thain - Case 52219, Review 8966
#     - Created.
#
# ***************************************************************************************************************************************************


# ***************************************************************************************************************************************************
#   IMPORTS
# ***************************************************************************************************************************************************
import sys
import datetime

# ***************************************************************************************************************************************************
#   CONSTANTS
# ***************************************************************************************************************************************************
DATE_FORMAT = "%Y/%m/%d"

# ***************************************************************************************************************************************************
#   FUNCTIONS
# ***************************************************************************************************************************************************


def add_build_and_date():
    exit_status = -1
    if len(sys.argv) == 3:
        filename = sys.argv[1]
        build_num = sys.argv[2]
        date = datetime.date.today().strftime(DATE_FORMAT)

        # Read contents of file.
        file = open(filename, "r")
        out = file.read()
        file.close()

        # Replace keywords, and write contents back
        out = out.replace("$BUILD", build_num).replace("$DATE", date)
        file = open(filename, "w")
        file.write(out)
        file.close()
        exit_status = 0
    else:
        print("Error: Expected 2 arguments, got " + str(len(sys.argv) - 1))
    exit(exit_status)


# ***************************************************************************************************************************************************
#   ENTRY POINT
# ***************************************************************************************************************************************************
if (__name__ == '__main__'):
    add_build_and_date()
