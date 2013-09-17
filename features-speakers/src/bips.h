#ifndef __bips_h
#define __bips_h "Copyright $Id: bips.h,v 1.1 2008/03/25 17:14:39 patrick Exp $ Bill.Triggs@inrialpes.fr"
/** Distribute freely. Use at your own risk. Fixes welcome.**/
/*------------------------------------------------------------------------
  BIPS -- Bill's Image Processing Subroutines. Basic types and hacks.
 ------------------------------------------------------------------------*/
#ifdef bipsconfig_h
# include bipsconfig_h
#endif
#ifndef __u8
# define __u8
  typedef unsigned char u8;
#endif
#ifndef __s8
# define __s8
  typedef signed char s8;
#endif
#ifndef __u16
# define __u16
  typedef unsigned short u16;
#endif
#ifndef __s16
# define __s16
  typedef short s16;
#endif
#ifndef __u32
# define __u32
  typedef unsigned long u32;
#endif
#ifndef __s32
# define __s32
  typedef long s32;
#endif
#ifndef __f32
# define __f32
  typedef float f32;
#endif
#ifndef __f64
# define __f64
  typedef double f64;
#endif

/* ANSI-CPP symbol pasting of macro-expanded args. */
#ifndef _2
# define _2(A,B) __2(A,B)
# define _3(A,B,C) __3(A,B,C)
# define _4(A,B,C,D) __4(A,B,C,D)
# define _5(A,B,C,D,E) __5(A,B,C,D,E)
# define _6(A,B,C,D,E,F) __6(A,B,C,D,E,F)
# define _7(A,B,C,D,E,F,G) __7(A,B,C,D,E,F,G)
# define _8(A,B,C,D,E,F,G,H) __8(A,B,C,D,E,F,G,H)
# define _9(A,B,C,D,E,F,G,H,I) __9(A,B,C,D,E,F,G,H,I)
# define __2(A,B) A##B
# define __3(A,B,C) A##B##C
# define __4(A,B,C,D) A##B##C##D
# define __5(A,B,C,D,E) A##B##C##D##E
# define __6(A,B,C,D,E,F) A##B##C##D##E##F
# define __7(A,B,C,D,E,F,G) A##B##C##D##E##F##G
# define __8(A,B,C,D,E,F,G,H) A##B##C##D##E##F##G##H
# define __9(A,B,C,D,E,F,G,H,I) A##B##C##D##E##F##G##H##I
#endif

#ifndef M_PI
#define M_PI        3.14159265358979323846
#endif

#ifndef ALLOC
    # include <stdlib.h>
    # define ALLOC(typ,siz)	(typ*)mxMalloc((siz)*sizeof(typ))
#endif
#ifndef CALLOC
    # include <stdlib.h>
    # define CALLOC(typ,siz)	(typ*)mxCalloc((siz)*sizeof(typ))
#endif
/*#ifndef REALLOC
# define REALLOC(typ,ptr,siz)	(typ*)realloc((void*)ptr,(siz)*sizeof(typ))
#endif
*/
#ifndef FREE
# define FREE mxFree
#endif
/*#ifndef TMPALLOC
# include <alloca.h>
# define TMPALLOC(typ,siz) (typ*)alloca((siz)*sizeof(typ))
# define TMPFREE(ptr)	   
#endif*/
#ifndef _MEMALIGN_
# ifndef _memalign_
#  define _memalign_ sizeof(double)
# endif
# define _MEMALIGN_(siz) ((((siz)+_memalign_-1)/_memalign_)*_memalign_)
#endif

#ifndef MIN
# define MIN(a,b) (((a)<=(b))?(a):(b))
#endif
#ifndef MAX
# define MAX(a,b) (((a)>=(b))?(a):(b))
#endif
#ifndef _LIMIT
# define _LIMIT(x,lo,hi) (((x)<=(lo))? (lo): ((x)>=(hi))? (hi):(x))
#endif
#define u8_LIMIT(x) _LIMIT(x,0,255)
#define s8_LIMIT(x) _LIMIT(x,-128,127)
#define u16_LIMIT(x) _LIMIT(x,0,65535)
#define s16_LIMIT(x) _LIMIT(x,-32768,32767)
#define f32_LIMIT(x) (x)

#ifndef SQ
# define SQ(x) ((x)*(x))
#endif

#endif /*__bips_h */
