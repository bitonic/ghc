/* -----------------------------------------------------------------------------
 * $Id: Stg.h,v 1.3 1999/01/18 14:37:43 sof Exp $
 *
 * Top-level include file for everything STG-ish.  
 *
 * This file is included *automatically* by all .hc files.
 *
 * ---------------------------------------------------------------------------*/

#ifndef STG_H
#define STG_H

#ifndef NON_POSIX_SOURCE
#define _POSIX_SOURCE
#endif

/* Configuration */
#include "config.h"
#ifdef __HUGS__ /* vile hack till the GHC folks come on board */
#include "options.h"
#endif

/* ToDo: Set this flag properly: COMPILER and INTERPRETER should not be mutually exclusive. */
#ifndef INTERPRETER
#define COMPILER 1
#endif

/* Global type definitions*/
#include "StgTypes.h"

/* Global constaints */
#include "Constants.h"

/* Profiling information */
#include "Profiling.h"

/* Storage format definitions */
#include "Closures.h"
#include "InfoTables.h"
#include "TSO.h"

/* STG/Optimised-C related stuff */
#include "MachRegs.h"
#include "Regs.h"
#include "TailCalls.h"

/**
 * Added by Ian McDonald 7/5/98 
 * XXX The position of this code is very
 * important - it must come after the 
 * Regs.h include
 **/
#ifdef nemesis_TARGET_OS
#define _NEMESIS_OS_
#ifndef __LANGUAGE_C
#define __LANGUAGE_C
#endif
#include <nemesis.h>
#endif

/* these are all ANSI C headers */
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <errno.h>
#include <stdio.h>

#ifdef HAVE_SIGNAL_H
#include <signal.h>
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

/* GNU mp library */
#include "gmp.h"

/* Wired-in Prelude identifiers */
#include "Prelude.h"

/* Storage Manager */
#include "StgStorage.h"

/* Macros for STG/C code */
#include "ClosureMacros.h"
#include "InfoMacros.h"
#include "StgMacros.h"
#include "StgProf.h"
#include "PrimOps.h"
#include "Updates.h"
#include "Ticky.h"
#include "CCall.h"

/* Built-in entry points */
#include "StgMiscClosures.h"

/* Runtime-system hooks */
#include "Hooks.h"

/* Misc stuff without a home */
extern char **prog_argv;	/* so we can get at these from Haskell */
extern int    prog_argc;

extern char **environ;

/* Creating and destroying an adjustor thunk.
   I cannot make myself creating a separate .h file
   for these two (sof.)
*/
extern void* createAdjustor(int cconv, StgStablePtr hptr, StgFunPtr wptr);
extern void  freeHaskellFunctionPtr(void* ptr);

#endif /* STG_H */
