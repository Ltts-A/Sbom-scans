#!/usr/bin/env python3
# *****************************************************************************
# COPYRIGHT NOTICE
#
# Copyright (c) 2018-2022 by Parker-Hannifin Corporation
# All rights reserved.
#
# No part of this work may be reproduced, published, or distributed in any form
# or by any means (electronically, mechanically, photocopying, recording or
# otherwise), or stored in a database or retrieval system, without the prior
# written permission of Parker-Hannifin Corporation in each instance.
#
# Coding Standard(s):
#   - 948F30.00A - Parker WPG Python Coding Standard
#
# Repository:
#   - SVN: 1065602
#
# Description:
#   Refer to the constant PROGRAM_DESCRIPTION below for a description.
#
# Input Documents:
#   The following is a list of input documents that support this document.
#   Input documents that change after release of this document may have an
#   impact on this document.
#   - None.
#
# History:
#   2018-Mar-13 by Jonathon Church - Case 46573, Review 7468
#   - Created.
#   2022-Feb-09 by Sandesh Vadye - Case 76120, Review 12377
#   - Added command 'r' to provide capability to exclude a specified folder recursively.
#   2022-Feb-17 by Sandesh Vadye - Case 76379, Review 12401
#   - Given provision to display version number and program description.
# *****************************************************************************

# *****************************************************************************
#   IMPORTS
# *****************************************************************************
import argparse
from datetime import datetime
import os
from pathlib import Path
import subprocess
import sys

# *****************************************************************************
#   GLOBAL VARIABLES
# *****************************************************************************

# *****************************************************************************
#   CONSTANTS
# *****************************************************************************

DEFAULT_INPUT_FILE = "lintFileList.txt"
DEFAULT_OUTPUT_FILE = "files.lnt"
VERSION = "1.08 Build 9"

PROGRAM_DESCRIPTION = (
    # Note that this is all reformatted by limit_chars().
    "Version: " + VERSION + "\n"

    "This script takes an input file and generates an output file that contains a list of source files to lint. The input file tells the script "
    "which files or directories to include, and also allows for files and directories to be excluded. Note the following details about the input "
    "file:\n"

    "- All paths specified in the input file are relative to the input file.\n"

    "- A '#' symbol indicates the remaining characters in a line are to be ignored.\n"

    "- An 'i' as the first non-white space character on a line followed by a file name will add the file name to the list of files to include. "
    "File names are added recursively from the base directory given and can use the standard command line wild cards (* for anything and ? for a "
    "single character). So .\\*.c will add all .c files starting in .\\ and all its subdirectories.\n"

    "- An 'f' as the first non-white space character on a line will remove the specified file from the list of files to lint. Wild cards are not "
    "accepted and the path and file name must be an exact match.\n"

    "- A 'd' as the first non-white space character on a line will remove all the files in the specified directory from the list of files to lint. "
    "This is not a recursive operation, so if .\\dir\\1.c and .\\dir\\dir\\2.c are added to the list with a '- .\\*.c' command and then '-d "
    ".\\dir' is used, then .\\dir\\1.c will be removed and .\\dir\\dir\\2.c will be in the list of files to be linted.\n"

    "- A 'r' as the first non-white space character on a line will remove all the files in the specified directory from the list of files to lint. "
    "This is a recursive operation, so if .\\dir\\1.c and .\\dir\\dir\\2.c are added to the list with a '- .\\*.c' command and then '-r "
    ".\\dir' is used, then .\\dir\\1.c will be removed and .\\dir\\dir\\2.c will also be removed. This can use the standard command line wild "
    "cards (* for anything and ? for a single character). So .\\*.c will remove all .c files starting in .\\ and all its subdirectories.\n"

    "Note that the exclusions aren't used until after the script has processed the input file.\n"

    "The output file that is generated is then used with lint and will specify the fully qualified path to the files that need to be linted. It is "
    "recommended that the output file is not under revision control, since it is generated each time it is needed."
    )

# Command line options, sorted by name, abbreviation, default value, type, and
# description. Use type==None to indicate flags.
OPTIONS = [["--input", "-i", DEFAULT_INPUT_FILE, str,
            ("Specifies the input file.\n")],
           ["--output", "-o", DEFAULT_OUTPUT_FILE, str,
            ("Specifies the output file\n")]]

CHAR_LIMIT = 80

# *****************************************************************************
#   CLASSES
# *****************************************************************************


# A simple class that loads a description file on initialization to build a list of files to lint. When write is called, it checks to see if each
# file to be linted should be filtered out or included. If included, it is output to the specified file.
class CreateLintFiles:

    # *************************************************************************
    # Opens file_name, assuming it is a valid file, and builds a list of files
    # to include and the exclusion list. The user needs to call the write()
    # method to have the file list output to file.
    #
    # Parameters:
    #   file_name: The description file to open and read commands from.
    # *************************************************************************
    def __init__(self, file_name):
        # Assume failure.
        self.valid = False
        self.file_list = []
        self.exclude_file_list = []
        self.exclude_dir_list = []
        self.isCommandValid = False

        if Path(file_name).exists():
            # Determine the path for the input file and save it for when
            # we write.
            self.file_path = os.path.dirname(os.path.abspath(file_name))

            with open(file_name) as file:
                # Now that the file is open, change the working directory to
                # match where the file was opened from.
                self.cd_to_input_file_path()
                self.valid = True
                line_number = 0
                for line in file:
                    line_number += 1

                    # Remove comments.
                    comment_ix = line.find('#')
                    if comment_ix >= 0:
                        line = line[0:comment_ix]

                    line = line.strip()
                    if len(line) > 0:
                        original_line = line
                        command = line[0]

                        # Ignore the command and remove excess white space.
                        line = line[1:]
                        line = line.strip()
                        if command == 'i':
                            self.isCommandValid = True
                            try:
                                # Run the directory command.
                                dir_output = subprocess.check_output(
                                    ["dir", "/s", "/b", line],
                                    shell=True).decode('utf-8')

                                # Split on \r\n so we can get rid of both
                                # characters. This saves a split and allows
                                # direct comparisons when handling exclusions.
                                self.file_list += dir_output.split('\r\n')
                            except subprocess.CalledProcessError:
                                stderr_out("Couldn't find '%s'" % (line, ))
                        elif command == 'f':
                            # This is a file exclude. Expand to full path on
                            # this device.
                            self.isCommandValid = True
                            self.exclude_file_list.append(
                                os.path.abspath(line))
                        elif command == 'd':
                            # This is a file exclude. Expand to full path on
                            # this device.
                            self.isCommandValid = True
                            self.exclude_dir_list.append(os.path.abspath(line))
                        elif command == 'r':
                            # This is a recursive file exclude command. Expand to full path on
                            # this device.
                            self.isCommandValid = True
                            try:
                                # Run the directory command.
                                dir_output = subprocess.check_output(
                                    ["dir", "/s", "/b", line],
                                    shell=True).decode('utf-8')

                                # Split on \r\n so we can get rid of both
                                # characters. This saves a split and allows
                                # direct comparisons when handling exclusions.
                                self.exclude_file_list += dir_output.split('\r\n')
                            except subprocess.CalledProcessError:
                                stderr_out("Couldn't find '%s'" % (line, ))
                        else:
                            # We have a command we don't understand
                            stderr_out("Warning line %i: ignoring non-empty line '%s'" % (line_number, original_line))
                if not self.isCommandValid:
                    self.valid = False

    # *************************************************************************
    # Changes to the directory where the input file is so relative paths work.
    # *************************************************************************
    def cd_to_input_file_path(self):
        os.chdir(self.file_path)

    # *************************************************************************
    # Determines whether the file specified in line is not excluded by checking
    # against the excluded lists. Returns True if the file is not excluded and
    # False otherwise.
    #
    # Parameters:
    #   line: The path and file name to see if it should be excluded.
    #   criteria: The expression to check.
    # *************************************************************************
    def not_excluded(self, line):
        # Determine the path to the file listed in line.
        path = os.path.dirname(line)

        excluded = (line in self.exclude_file_list) or \
            (path in self.exclude_dir_list)

        return not excluded

    # *************************************************************************
    # Writes the list of files to Lint to the specified file, provided the
    # is not excluded.
    #
    # Parameters:
    #   file_name: The name of the file to write to.
    # *************************************************************************
    def write(self, file_name):
        self.cd_to_input_file_path()
        with open(file_name, "w") as file:
            file.write(datetime.now().strftime(
                "// Generated on %Y-%m-%d at %H:%M:%S\n"))
            if self.valid:
                for line in self.file_list:
                    if self.not_excluded(line):
                        file.write(line + '\n')
            else:
                string_list = PROGRAM_DESCRIPTION.split("\n")
                for string in string_list:
                    file.write("// %s\n" % string)


# *****************************************************************************
#   FUNCTIONS
# *****************************************************************************

# *****************************************************************************
# stderr_out
#   Parameters:
#       message : String to print to stderr.
#       exit    : If asserted, will exit with error level -1 (default False).
#
#   Returns:
#       None.
# *****************************************************************************
def stderr_out(message, exit=False):
    sys.stderr.write("{}\n".format(message))

    if (exit):
        sys.exit(EXIT_FAILURE)
    return None


# ***************************************************************************************************************************************************
# limit_chars
#   Limits the input string to CHAR_LIMIT characters per line. It first separates the string based of "\n" to determine the paragraphs. Each
#   paragraph is then separated on spaces to get the words. If the first letter of a paragraph is a "-" then it is treated as a bulleted list
#   and as words are wrapped, they are done so with a hanging indent.
#
#   Parameters:
#       string : The string to parse.
#   Returns:
#       The string, spanning 80 characters on each line.
# ***************************************************************************************************************************************************
def limit_chars(string):
    paragraphs = string.split("\n")
    output = ""

    for line in paragraphs:
        words = line.split(" ")
        # See if we need a hanging indent.
        if words[0] == '-':
            output += "  -"  # Omit the space after the dash since a space will be added in the next for loop.
            indent = "    "
            current_count = len(indent)
        else:
            indent = ""
            output += words[0]
            current_count = len(words[0])

        for word in words[1:]:
            if (word != ""):
                if ((current_count + len(word)) >= CHAR_LIMIT):
                    output += "\n"
                    current_count = 0
                else:
                    output += " "

                if (current_count == 0) and (len(indent) > 0):
                    # We have a new line that needs to be indented.
                    current_count += len(indent)
                    output += indent

                current_count += len(word)
                output += word

        # End the paragraph with a new line.
        output += "\n"

    return output


# *****************************************************************************
# parse_args
#   Parses an array of command line arguments, and returns an args object if
#   the command succeeded.
#
#   Parameters:
#       args              : The array of command line arguments to parse.
#       prefix            : On error, this prefix will be printed prior to the
#                           message.
#       allow_unversioned : If asserted, don't check if a directory is under
#                           version control.
#
#   Returns:
#       An args object, if the args were valid.
#       None, otherwise.
# *****************************************************************************
def parse_args(args, prefix="", allow_unversioned=False):
    rc = None

    parser = argparse.ArgumentParser(
                                 description=limit_chars(PROGRAM_DESCRIPTION),
                                 formatter_class=argparse.RawTextHelpFormatter
                                 )

    for option in OPTIONS:
        if (option[0][0] == '-'):
            if (option[3] is None):

                action = 'store_true'
                if (option[2] is True):
                    action = 'store_false'

                parser.add_argument(option[0],
                                    option[1],
                                    help="{}".format(option[4]),
                                    action=action)
            else:
                parser.add_argument(option[0],
                                    option[1],
                                    help="{} (Default = {})".format(option[4],
                                                                    option[2]),
                                    default=option[2],
                                    type=option[3])
        else:
            parser.add_argument(option[0],
                                help="{}".format(option[4]),
                                type=option[3])

    args = parser.parse_args(args)
    rc = args

    # Validate the args:
    if not os.path.exists(args.input):
        parser.error("{}Couldn't find {}".format(prefix, args.input))
        rc = None

    return rc


# *****************************************************************************
#   ENTRY POINT
# *****************************************************************************
if (__name__ == '__main__'):
    args = parse_args(sys.argv[1:])

    lintFiles = CreateLintFiles(args.input)
    lintFiles.write(args.output)
