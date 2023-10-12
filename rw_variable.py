#!/usr/bin/env python3
# *****************************************************************************
# Filename:
#   rw_variable.py
#
# COPYRIGHT NOTICE
#
# Copyright (c) 2017 by Parker-Hannifin Corporation
# All rights reserved.
#
# No part of this work may be reproduced, published, or distributed in any form
# or by any means (electronically, mechanically, photocopying, recording or
# otherwise), or stored in a database or retrieval system, without the prior
# written permission of Parker-Hannifin Corporation in each instance.
#
# Coding Standard(s):
#   - 983F30.00A - Parker WPG Python Coding Standard.
#
# Repository:
#   - MKS: 983631
#
# Description:
#   To be used with env.bat. For C or H files, will parse the file for
#   #define variables in order to read the value, or replace the value.
#   Similarly, for Doxygen files, will parse the file for FOO = BAR style
#   variables in order to read the value, or replace the value.
#   See ENTRY POINT below for details about command line usage.
#
# History:
#   2017-Jul-25 by Tamkin Rahman - Case 40919, Review 6027
#   - Created.
#   2017-Sep-01 by Tamkin Rahman - Case 41993, Review 6092
#   - Case 41992, bugfix so that values read as numerical '0' do not cause an
#   error.
#   - Updated help section.
#   2017-Dec-19 by Tamkin Rahman - Case 43246, Review 7285
#   - Updated to allow the --string option to indicate the value written during
#     a write operation is a string (i.e. add quotes).
# *****************************************************************************

# *****************************************************************************
#   IMPORTS
# *****************************************************************************

import os
import re
import sys

# *****************************************************************************
#   CONSTANTS
# *****************************************************************************

# *****************************************************************************
# This array contains the list of characters that will be ignored when reading
# a number value in a C or H file.
#
# Note:
#   Python recognizes:
#       - Exponent notation (e.g. 3eX, or 3EX), and
#       - Hexadecimal notation (e.g. 0x4 or 0x4b).
#   Python will not recognize:
#       - Unsigned notation (e.g. 3u, or 3U),
#       - Long notation (e.g. 3l, or 3L), and
#       - Octal notation (e.g. 012). Instead, use 0o12 for Python 3.
# *****************************************************************************
ignore_for_numbers = ['(', ')', 'u', 'U', 'L', 'l']


# *****************************************************************************
# Contains the list of valid file/variable types.
# *****************************************************************************
type_options = ["--define", "--doxygen"]

# *****************************************************************************
#   FUNCTIONS
# *****************************************************************************


# *****************************************************************************
# stderr_out
#   Parameters:
#       message : String to print to stderr.
#       exit    : If asserted, will exit with error level -1 (default True).
#
#   Returns:
#       None.
# *****************************************************************************
def stderr_out(message, exit=True):
    sys.stderr.write("{}\n".format(message))
    if (exit):
        sys.exit(-1)
    return None


# *****************************************************************************
# read_variable
#   Parameters:
#      variable: The name of the #define value to read.
#      line    : The string where the #define value resides.
#      number  : A boolean asserting whether the value should be read as an
#                integer.
#      type    : Type of file the line is from. The default is C or H file.
#
#   Description:
#       If the type is "--define", then the variable is checked as though it
#       were a C or H file.
#       If the type is "--doxygen" , then the variable is checked as though it
#       were a doxygen file.
#
#   Returns:
#       The value of the variable on success.
#       None, on the failure.
# *****************************************************************************
def read_variable(variable, line, number=False, type="--define"):
    result = None
    if (type == "--define"):
        result = read_variable_pound_define(variable, line, number)
    elif (type == "--doxygen"):
        result = read_variable_doxygen(variable, line)
    return result


# *****************************************************************************
# read_variable_doxygen
#   Parameters:
#       variable: The name of the doxygen variable.
#       line    : The string where the variable is in.
#
#   Returns:
#       If the variable is found:
#           The string following the pattern "variable[ \t]=", with leading
#           and trailing whitespace removed, is returned.
#       Else, None is returned.
# *****************************************************************************
def read_variable_doxygen(variable, line):
    result = None

    # Remove anything after the first #
    ix = line.find('#')
    if (ix >= 0):
        line = line[0:ix]

    r_xp = re.compile("[ \t]*" + variable + "[ \t]*=[ \t]*" +
                      "(.+)$", re.DOTALL)
    match = re.match(r_xp, line)
    if (match):
        result = match.group(1)
        result = result.strip()

    return result


# *****************************************************************************
# read_variable_pound_define
#   Parameters:
#      variable: The name of the #define value to read.
#      line    : The string where the #define value resides.
#      number  : A boolean asserting whether the value should be read as an
#                integer.
#   Returns:
#       If the variable is found:
#           If 'number' is asserted:
#              - Then the 'ignore_for_numbers' characters will be
#                ignored. Also, the leading 0 will be replaced with 0o
#                for octal.
#            - The returned value will be an int.
#           Else, the string following #define, with whitespace removed
#           at the ends, is returned.
#       Else, None is returned.
#
#   Raises:
#       On ValueError, the string of the number is given, and the error is
#       printed to the screen.
#
#   Description:
#       Strips the line of comments, and leading and trailing whitespace. Then
#       searches the line for the pattern '#define[ \t]+variable'. Then value
#       after the variable is read, stripped of leading and trailing
#       whitespace. If "number" is asserted, then the characters in
#       ignore_for_numbers will be removed from the value, then cast to an int.
# *****************************************************************************
def read_variable_pound_define(variable, line, number=False):
    result = None

    # Remove all singleline streamed comments (/*COMMENT */) from string.
    # https://stackoverflow.com/questions/2319019/using-regex-to-remove-comments-from-source-files
    line = re.sub(re.compile(r'/\*.*?\*/', re.DOTALL), " ", line)

    r_xp = r'[ \t]*#define[ \t]+' + variable + r'[ \t]+.+'

    # Regex is used to match a valid line.
    # Order:
    #   [ \t]*      Match 0 or more characters of whitespace.
    #   #define     Match the string "#define" exactly.
    #   [ \t]+      Match 1 or more characters of whitespace.
    #   variable    Match the string "variable" exactly.
    #   [ \t]+      Match 1 or more characters of whitespace.
    #   .+          Matches 1 or more characters.

    if (re.match(r_xp, line)):
        # Remove all occurrences of the start of streamed comments (/*COMMENT)
        # or single-line comments (//COMMENT).
        line = re.sub(re.compile(r'/[\*/].*', re.DOTALL), " ", line)
        line = re.sub(re.compile(r'#define[ \t]+' + variable), "", line)

        line = line.strip()
        if (number):
            for char in ignore_for_numbers:
                line = line.replace(char, "")

            line = line.strip()

            if (len(line) > 0):
                start = line[0]

                if (start == '-'):
                    line = line[1:]
                else:
                    start = ""

                # If octal, insert the 'o' character so Python 3 can recognize
                # it.
                if (len(line) >= 2 and line[0] == '0' and line[1] != 'x'):
                    line = line[0] + 'o' + line[1:]

                line = start + line
                try:
                    line = int(line.strip(), 0)
                # If value error, just use the string.
                except ValueError:
                    if (len(line) >= 3 and line[1] == 'o'):
                        line = line[0] + line[2:]
                    stderr_out("Python Error: Value error occurred.\n", False)

        if (line == ""):
            result = None
        else:
            result = line

    return result


# *****************************************************************************
# read_variable_from_file:
#   Parameters:
#       variable: The name of the #define value to read.
#       filename: The filename where the #define value resides.
#       number  : A boolean asserting whether the value should
#                 be read as an integer.
#       type    : Type of file the line is from. The default is C or H file.
#
#   Returns:
#       On success, the value of the variable is returned.
#       On failure, None is returned.
#
#   Description:
#       Runs read_variable on all lines in the given file. On the first
#       occurrence of the given #define variable, the value is returned.
# *****************************************************************************
def read_variable_from_file(variable, filename, number=False, type="--define"):
    with open(filename) as f:
        content = f.readlines()
    f.close()

    value_read = None
    first_occurrence = False
    ix = 0
    while ((not first_occurrence) and (ix < len(content))):
        value = read_variable(variable, content[ix], number, type)
        if (value is not None):
            first_occurrence = True
            value_read = value
        ix += 1
    return value_read


# *****************************************************************************
# write_variable:
#   Parameters:
#       variable:  The name of the #define value to read.
#       new_value: The value that will be replacing the old value.
#       line:      The string where the variable name resides in.
#
#   Returns:
#       None on failure, or
#       A string containing the new line (with the value replaced) on
#       success.
#
#   Description:
#       For the given line, check whether the variable is in the line with
#       read_variable(). If it is, replace it with the new value.
# *****************************************************************************
def write_variable(variable, new_value, line, type="--define"):
    value = read_variable(variable, line, False, type)

    new_line = None
    if (value):
        new_line = line.replace(" " + value, " " + new_value)

    return new_line


# *****************************************************************************
# write_variable_to_file:
#   Parameters:
#       variable : The name of the #define value to write to.
#       new_value: The value that will be replacing the old variable value.
#       filename : The filename where the #define value resides.
#       type     : The type of variable (e.g. doxygen, c/h file).
#
#   Returns:
#       True, if the variable was found and replaced.
#       False, if the variable was not found.
#
#   Description:
#       Runs write_variable on all lines in the given file. On the first
#       occurrence of the given #define variable, the value is replaced.
# *****************************************************************************
def write_variable_to_file(variable, new_value, filename, type="--define"):
    if (not find_variable_in_file(variable, filename, type)):
        return False

    with open(filename) as f:
        content = f.readlines()
    f.close()

    new_content = ""
    first_occurrence = True
    for line in content:
        new_line = write_variable(variable, new_value, line, type)

        if (first_occurrence and new_line):
            new_content += new_line
            first_occurrence = False
        else:
            new_content += line

    with open(filename, 'w') as f:
        f.write(new_content)
    f.close()

    return (not first_occurrence)


# *****************************************************************************
# find_variable_in_file
#   Parameters:
#       variable:  The name of the #define value to write to.
#       filename:  The filename where the #define value resides.
#       type    :  Type of file to check.
#
#   Description:
#       Runs read_variable on all lines in the given file. On the first
#       occurrence found of the #define variable, True is returned. Else,
#       False is returned.
# *****************************************************************************
def find_variable_in_file(variable, filename, type="--define"):
    with open(filename) as f:
        content = f.readlines()

    found = False
    ix = 0

    while ((ix < len(content)) and (not found)):
        line = content[ix]
        ix += 1
        if (read_variable(variable, line, False, type)):
            found = True

    f.close()
    return found


# *****************************************************************************
# read_operation
#   Parameters:
#       param   : The name of the value to read.
#       filename: The filename where the #define value resides.
#       number  : A boolean asserting whether the value should
#                 be read as an integer.
#       type    : Type of file the line is from.
#
#   Returns:
#       True on success, False on failure.
# *****************************************************************************
def read_operation(param, filename, number, type):
    success = False

    value = read_variable_from_file(param, filename, number, type)
    if ((value is not None) and (value != "")):
        print(value)
        success = True

    return success


# *****************************************************************************
#   ENTRY POINT
# *****************************************************************************

# *****************************************************************************
# To be used with env.bat.
#
# Assumptions:
#    - The first argument is the filename.
#    - The second argument is '--read' or '--write'.
#    - The third argument is the type. It must match one of the types in
#      the type_options list.
#    - The fourth argument is '--string' or '--not_string'.
#    - The fifth argument is:
#           if "--read" asserted:
#               Then it is the variable to read from the file.
#           if "--write" asserted:
#               Then it is the pair FOO=BAR, where FOO is the variable in the
#               file, and BAR is the value to write to the variable.
# *****************************************************************************
if (__name__ == '__main__'):
    TOTAL_ARGS = 6

    if (len(sys.argv) >= TOTAL_ARGS):

        r_w = False  # The read/write flag; True = read, False = write.
        number = False

        filename = sys.argv[1]
        read_write = sys.argv[2]
        type = sys.argv[3]

        # Check second argument for read/write.
        if (read_write == "--read"):
            r_w = True
        elif (read_write == "--write"):
            r_w = False
        else:
            message = "Python Error: Read or write not specified in arg 2."
            stderr_out(message)

        # Check third argument for file type.
        if (type not in type_options):
            message = "Python Error: File type not specified in arg 3."
            stderr_out(message)

        # Check fourth argument for "--string" or "--not_string".
        if ('--string' == sys.argv[4]):
            number = False
        elif ('--not_string' == sys.argv[4]):
            number = True
        else:
            message = "Python Error: --[not_]string not specified"
            message += "in arg 4: {}.".format(sys.argv[4])
            stderr_out(message)

        # Fifth argument is the variable to read, or variable=value to write.
        param = sys.argv[5]

        # ********************************************************************
        # Read operation.
        if (r_w):
            if (read_operation(param, filename, number, type)):
                sys.exit(0)  # Exit successfully.
            else:
                message = "Python Error: Variable {} not found in {}."
                stderr_out(message.format(param, filename))

        # ********************************************************************
        # Write operation.
        if (not r_w):
            if ('=' in param):
                pair = param.split('=')
                value = pair[1]

                # According to doxygen documentation, "Values that contain
                # spaces should be placed between quotes (\" \")."
                if ((
                     ((type == "--doxygen") and (" " in value)) or
                     (not number)
                    ) and
                   (value[0] != r'"') and (value[-1] != r'"')):

                    pair[1] = "\"{}\"".format(pair[1])
            else:
                message = "Python Error: Invalid argument: {}."
                stderr_out(message.format(str(param)))

            if (not write_variable_to_file(pair[0], pair[1], filename, type)):
                message = "Python Error: Variable\"{}\" not found in {}."
                stderr_out(message.format(pair[0], filename))
    else:
        message = "Python error: Expected {} arguments, got {}."
        stderr_out(message.format(TOTAL_ARGS, str(len(sys.argv))))
