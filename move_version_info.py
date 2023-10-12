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
#   Extracts HTML source of the sole doxygen generated version entry from from_file, and inserts the entry in to_file in a way such that
#   chronological order is maintained.
#   Usage: python move_version_info.py from_file to_file
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

# ***************************************************************************************************************************************************
#   CONSTANTS
# ***************************************************************************************************************************************************
CONTENTS_DIV_OPEN = "<div class=\"contents\">"
CONTENTS_DIV_CLOSE = "</div><!-- contents -->"

# ***************************************************************************************************************************************************
#   FUNCTIONS
# ***************************************************************************************************************************************************


def move_version_info():
    exit_status = -1
    if len(sys.argv) == 3:
        from_file_name = sys.argv[1]
        to_file_name = sys.argv[2]

        # Read old version history.
        from_file = open(from_file_name, "r")
        read_lines = False
        old_version_info = ""
        # This loop adds content between CONTENTS_DIV_OPEN and CONTENTS_DIV_CLOSE to old_version_info.
        for line in from_file:
            if (line.find(CONTENTS_DIV_CLOSE) > -1):
                read_lines = False
            if (read_lines):
                old_version_info += line
            if (line.find(CONTENTS_DIV_OPEN) > -1):
                read_lines = True
        from_file.close()

        # Read new version history entry, and insert old version history after it.
        to_file = open(to_file_name, "r")
        new_version_info = ""
        for line in to_file:
            if (line.find(CONTENTS_DIV_CLOSE) > -1):
                # Insert old history just before the closing div tag.
                new_version_info += old_version_info
            new_version_info += line
        to_file.close()

        # Write everything back to to_file
        to_file = open(to_file_name, "w")
        to_file.write(new_version_info)
        to_file.close()
        exit_status = 0
    else:
        print("Error: Expected 2 arguments, got " + str(len(sys.argv) - 1))
    exit(exit_status)


# ***************************************************************************************************************************************************
#   ENTRY POINT
# ***************************************************************************************************************************************************
if (__name__ == '__main__'):
    move_version_info()
