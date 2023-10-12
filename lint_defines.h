#ifndef LINT_DEFINES_H
#define LINT_DEFINES_H
//****************************************************************************************************************************************************
// COPYRIGHT NOTICE
//
// Copyright (c) 2021-2023 by Parker-Hannifin Corporation.
// All rights reserved.
//
// No part of this work may be reproduced, published, or distributed in any form or by any means (electronically, mechanically, photocopying,
// recording or otherwise), or stored in a database or retrieval system, without the prior written permission of Parker-Hannifin Corporation in each
// instance.
//
// Coding Standard(s):
//   - Wi527-1 : Embedded C Coding Standard
//
// Repository:
//   - SVN: 983639
//
// Description:
//   See \file section below for module description.
//
//   Note: This file contains doxygen commands in order to facilitate documentation generation. Please see http://www.doxygen.org/ for details on
//     command usage.
//
// Input Documents
//   The following is a list of input documents that support this document. Input documents that change after release of this document may have an
//   impact on this document.
//   - http://www.tasking.com/support/tricore/tc_user_guide_v4.0.pdf
//
// History:
//   2021-May-26 by Michael Fetherston - Case 69999, Review 11694
//   - Created based on 983639 lint_defines.h.
//   2021-Jun-17 by Michael Fetherston - Case 70365, Review 11738
//   - Added __clone define for non-TDD builds (IE lint).
//   2023-May-30 by Nicolaj Jensen - Issue GVI-121, Review 14792
//   - Added __fabsf intrinsic prototype.
//   2023-Aug-04 by Nicolaj Jensen - Issue GVI-1561, Review 14986
//   - De-linting trc_sys.c.
//****************************************************************************************************************************************************

//****************************************************************************************************************************************************
//! \file
//!
//! \par Description:
//!   Defines types for PC Lint that the Tasking compiler provides when compiling in the Tasking environment.
//****************************************************************************************************************************************************

//****************************************************************************************************************************************************
//  INCLUDES
//****************************************************************************************************************************************************

//****************************************************************************************************************************************************
//  DEFINES
//****************************************************************************************************************************************************
// Used to satisfy Lint with a definition for these TASKING intrinsics.
// Surrounded by a TDD include guard as some projects may need __get_tin, __mfcr() and __mtcr defined for their TDD, but some projects may need to
// mock the calls.
#ifndef TDD

  // Note: the use of typedefs (such as uint32_t) may cause lint to complain that it couldn't see the prototype.

  unsigned int __crc32( unsigned int b, unsigned int a );
  float __fabsf(float f);
  unsigned int __get_tin( void );
  int __mfcr( const unsigned int);
  void __mtcr( const unsigned int a, int b );
  void __enable( void );
  void __swapmskw(unsigned int * a, unsigned int b, unsigned int c);
  void __putbit(int value, int * address, int bitoffset);

  unsigned int __cmpswapw(unsigned int * a, unsigned int b, unsigned int c);

  #define __far
  #define __near
  #define __private1
  #define __private2
  #define __clone

  int __disable_and_save(void);
  void __restore(int ie);
#endif

//****************************************************************************************************************************************************
//  STRUCTURES AND STRUCTURE TYPEDEFS
//****************************************************************************************************************************************************

//****************************************************************************************************************************************************
//  ENUMERATIONS AND ENUMERATION TYPEDEFS
//****************************************************************************************************************************************************

//****************************************************************************************************************************************************
//  TYPEDEFS
//****************************************************************************************************************************************************

//****************************************************************************************************************************************************
//  EXTERNS
//****************************************************************************************************************************************************

//****************************************************************************************************************************************************
//  FUNCTION PROTOTYPES
//****************************************************************************************************************************************************

#endif // LINT_DEFINES_H