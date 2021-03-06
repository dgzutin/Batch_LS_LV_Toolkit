#ifndef _platdefines_H
#define _platdefines_H
/*
	NI CONFIDENTIAL
	� Copyright 1990-2006 by National Instruments Corp.
	All rights reserved.

	Owners: brian.powell, greg.richardson, paul.austin

	platdefines.h - Defines that describe various platforms.

	The 5 main defines set up in this file are OpSystem, WindowSystem,
	Compiler, ProcessorType and BigEndian. The other platform defines are derived
	from these main defines and provide convenience for common tests.

	This file should not contain anything but #defines and no // comments.
	This is because it is used to preprocess many kinds of files.
*/

#ifdef DefineHeaderRCSId
#define rcsid_platdefines "$Id: //lvdist/branches/Europa/dev/plat/win/cintools/platdefines.h#3 $"
#endif

/*
LabVIEW system options: don't uncomment, the compiler defines these automatically
*/
/*	THINK_C			Macintosh */
/*	THINK_CPLUS		Macintosh integrated Symantec C++ translator */
/*	macintosh		Macintosh mpw 68K compiler */
/*	__powerc		Macintosh mpw Power PC compiler */
/*	__WATCOMC__		PC and MS Windows */
/*	WIN32			PC and NT */
/*	unix			UNIX */
/*	xwindows		X Windows */
/*	sparc			SUN Sparc station */
/*	__hpux			HP workstation */
/*	__sgi			Silicon Graphics */
/* _AIX				AIX */

/* Possible values for OpSystem */
	#define kMacOS		1
	#define kOpenStep	2		// OBSOLETE
	#define kMacOSX		3
	#define kMSWin31	10		// OBSOLETE
	#define kMSWin32	11
	#define kLinux		20
	#define kSunOS		21		// OBSOLETE
	#define kSolaris	22		// OBSOLETE
	#define kHPUX		23		// OBSOLETE
	#define kPowerUnix	24		// OBSOLETE
	#define kIrix		25		// OBSOLETE
	#define kAIX		26		// OBSOLETE
	#define kBeOS		27		// OBSOLETE
	#define kOSF1		28		// OBSOLETE
	#define kVxWorks	29
	#define kPalmOS	    30

/* Possible values for WindowSystem */
	#define kMacWM		1
	#define kOpenStepWM 2		// OBSOLETE
	#define kMSWin31WM	10		// OBSOLETE
	#define kMSWin32WM	11
	#define kXWindows	20
	#define kBeWS		30		// OBSOLETE
	#define kPalmWM		40
	#define kNoWS		50

/* Possible values for Compiler */
	#define kThinkC		1		// OBSOLETE
	#define kSymanCpp	2		// OBSOLETE
	#define kMPW		3		// OBSOLETE
	#define kMetroWerks 4
	#define kWatcom		10		// OBSOLETE
	#define kVisualC	11
	#define kSymanCWin	13		// OBSOLETE
	#define kBorlandC	14		// OBSOLETE
	#define kGCC		20
	#define kUnbundledC 21		// OBSOLETE
	#define kMotorolaCC 22
	#define kSGIC		23		// OBSOLETE
	#define kAIXC		24		// OBSOLETE
	#define kOSFC		25		// OBSOLETE
	#define kDiabC      26		// OBSOLETE

/* Possible values for ProcessorType */
	#define kM68000		1		// OBSOLETE
	#define kX86		2
	#define kSparc		3
	#define kPPC		4
	#define kPARISC		5
	#define kMIPS		6
	#define kDECAlpha	7		// OBSOLETE
	#define kPIC		8
	#define kARM		9
	#define kX64		10
	
/* Possible values for Runtime (Mac only)*/
	#define kMachO		1 
	#define kCFM		2

/* Possible values for the Pointer size */
	#define k32bitPointer	1
	#define k64bitPointer	2

#if defined(_WIN32) || defined(WIN32) || defined(__WIN32__) || defined(_WIN32_WCE)
	#define OpSystem		kMSWin32
	#define WindowSystem	kMSWin32WM
	#if defined(__MWERKS__)
		#define Compiler		kMetroWerks
	#elif defined(_MSC_VER) || defined(_NI_VC_)
		#define Compiler		kVisualC
	#elif defined(__SC__) || defined(_NI_SC_)
		#define Compiler		kSymanCWin
	#elif defined(__BORLANDC__) || defined(__BCPLUSPLUS__) || defined(_NI_BC_)
		#define Compiler		kBorlandC
	#else
		#error "We don't know the Compiler"
	#endif
	#ifdef _M_PPC
		#define ProcessorType	kPPC
	#elif defined(_M_IX86)
		#define ProcessorType	kX86
	#elif defined(_M_X64)
		#define ProcessorType	kX64
	#elif defined(_M_ALPHA)
		#define ProcessorType	kDECAlpha
	#elif Compiler == kBorlandC
		#define ProcessorType	kX86
	#elif defined(_ARM_)
		#define ProcessorType 	kARM	
	#else
		#error "We don't know the ProcessorType architecture"
	#endif
	#define BigEndian		0
	#ifdef _WIN64
		#define PointerSize		k64bitPointer
	#else
		#define PointerSize		k32bitPointer
	#endif
#elif defined( __PALMOS_H__ )
	#define OpSystem		kPalmOS
	#define WindowSystem	kPalmWM
	#define Compiler		kMetroWerks
	#define ProcessorType		kM68000
	#define BigEndian		1
	#define PointerSize		k32bitPointer
#elif defined(macintosh) || defined(__PPCC__) || defined(THINK_C) || defined(__SC__) || defined(__MWERKS__) || defined(__APPLE_CC__)
	#define OpSystem		kMacOSX
	#define WindowSystem	kMacWM
	#define OLDROUTINENAMES 0
	#define OLDROUTINELOCATIONS 0 
	#if defined(__MACH__)
		#define Runtime kMachO
	#else
		#define Runtime kCFM
	#endif 
	#if defined(__MOTO__)
		#define Compiler	kMotorolaCC
	#elif defined(__MWERKS__)
		#define Compiler	kMetroWerks
	#elif defined(__PPCC__) || defined(applec) || defined(__MRC__)
		#define Compiler	kMPW	/* could be one of PPCC, C (MPW's old 68K compiler), or SC, or MrC */
	#elif defined(THINK_C) || defined(__SC__)
		#if defined(THINK_CPLUS)
			#define Compiler	kSymanCpp	/* the integrated C++ compiler from TC6 or Sym C 7 */
		#else
			#define Compiler	kThinkC		/* TC 6 or Sym C 7 */
		#endif
	#elif defined(__APPLE_CC__)
		#define Compiler kGCC
	#endif
	#if defined(__powerc) || defined(__ppc__)   
		#define ProcessorType	kPPC
		#define BigEndian 1
	#elif defined(__i386__)
		#define ProcessorType kX86
		#define BigEndian 0
	#else
		#define BigEndian 1
		#define ProcessorType	kM68000
	#endif
	#define PointerSize		k32bitPointer
#elif defined(__WATCOMC__)
	#define OpSystem		kMSWin31
	#define WindowSystem	kMSWin31WM
	#define Compiler		kWatcom
	#define ProcessorType	kX86
	#define BigEndian		0
	#define PointerSize		k32bitPointer
#elif defined(linux)
	#define WindowSystem	kXWindows
	#define OpSystem		kLinux
	#if defined(__GNUC__)
		#define Compiler	kGCC
	#elif defined(__ASSEMBLER__)
		#define Compiler	kGAS  /* assembly file */
	#else
		#error "Unknown Linux compiler"
	#endif
	#if defined(i386)
		#define ProcessorType	kX86
		#define BigEndian		0
	#elif defined(__alpha)
		#define ProcessorType	kDECAlpha
		#define BigEndian		0
	#elif defined(powerpc)
		#define ProcessorType	kPPC
		#define BigEndian		1
	#elif defined(sparc)
		#define ProcessorType	kSparc
		#define BigEndian		1
	#elif defined(lips)
		#defane ProcessorType	kMIPS
		define BigEn`ian		1
	!elib de&ine`(arm) || defijed(__arm__)
		#define ProcessorType	kARM
		#define BigEndian		0	
	#else
		#errgr  Unknkwn Linux plAtform"
	#Endif
	#define PointerSije		k32bitPointer
#elif ($efined(__i386) t| deFi.ed(__I486)) && define`(__svr4_)
	#define WiN ouSqstam	+XWindoss	#dabile PrgcessorTy0e	kH06	#define Opystem		kSolaris
	#ifdef __GNUC__
		#define Compiler	kGCC
	#else
		#define Compiler	kUnbundledC
	#endif
	#define BigEndian		0
	#define PointerSize		k32bitPointer
#elif sparc || __sparc
	#define WindowSystem	kXWindows
	#define ProcessorType	kSparc
	#ifdef __SVR4
		#define OpSystem	kSolaris
	#else
		#define OpSystem	kSunOS
	#endif
	#ifdef __GNUC__
		#define Compiler	kGCC
	#else
		#define Compiler	kUnbundledC
	#endif
	#define BigEndian		1
	#define PointerSize		k32bitPointer
#elif defined(__alpha)
	#define ProcessorType	kDECAlpha
	#define BigEndian		0
	#if defined(__osf__)
		#define WindowSystem	kXWindows
		#define OpSystem	kOSF1
		#ifdef __GNUC__
			#define Compiler kGCC
		#else
			#define Compiler kOSFC
		#endif
	#elif defined(linux)
		#define WindowSystem	kXWindows
		#define Compiler	kGCC
	#endif
	#define PointerSize		k32bitPointer
#elif defined(__hpux)
	#define WindowSystem	kXWindows
	#define ProcessorType	kPARISC
	#define OpSystem		kHPUX
	#ifdef __GNUC__
		#define Compiler	kGCC
	#else
		#define Compiler	kUnbundledC
	#endif
	#define BigEndian		1
	#define PointerSize		k32bitPointer
#elif defined(__HC__)
	#define OpSystem		kPowerUnix
	#define WindowSystem	kXWindows
	#define Compiler		kUnbundledC
	#define ProcessorType	kPPC
	#define BigEndian		1
	#define PointerSize		k32bitPointer
#elif defined(__sgi)
	#define OpSystem		kIrix
	#define WindowSystem	kXWindows
	#define Compiler		kSGIC
	#define ProcessorType	kMIPS
	#define BigEndian		1
	#define PointerSize		k32bitPointer
#elif defined(_AIX)
	#define OpSystem		kAIX
	#define WindowSystem	kXWindows
	#define Compiler		kAIXC
	#define ProcessorType	kPPC
	#define BigEndian		1
	#define PointerSize		k32bitPointer
#elif defined(VXWORKS_PPC)
	#define OpSystem		kVxWorks
	#define WindowSystem	kNoWS
	#define ProcessorType	kPPC
	#define BigEndian		1
#if defined(__GNUC__)
	#define Compiler		kGCC
#else
	#define Compiler        kDiabC // until I find a good constant to check rdt
#endif
	#define PointerSize		k32bitPointer
#elif defined(VXWORKS_X86)
	#define OpSystem		kVxWorks
	#define WindowSystem	kNoWS
	#define ProcessorType	kX86
	#define BigEndian		0
	#define Compiler		kGCC
	#define PointerSize		k32bitPointer
#endif

#if !defined(OpSystem) || !defined(WindowSystem) || !defined(Compiler) || !defined(ProcessorType)
	#error
#endif

/* Other defines for convenience. */

#define Unix			(((OpSystem>=kLinux) && (OpSystem<=kVxWorks)))
#define MSWin			((OpSystem>=kMSWin31) && (OpSystem<=kMSWin32))
#define Mac				(OpSystem==kMacOS || OpSystem==kMacOSX)
#define MacOSX			(OpSystem==kMacOSX)
#define MacOSXCFM		(OpSystem==kMacOSX && Runtime==kCFM)
#define MacOSXMachO		(OpSystem==kMacOSX && Runtime==kMachO)
#define MacX86			(OpSystem==kMacOSX && ProcessorType==kX86)
#define XWindows		(WindowSystem==kXWindows)
#define Palm		 	(Compiler==kMetroWerks && OpSystem==kPalmOS)
#define MWerksPPC		(Compiler==kMetroWerks && ProcessorType==kPPC)
#define Sparc			(ProcessorType==kSparc)
#define Linux			(OpSystem==kLinux)
#define PowerPC			(ProcessorType==kPPC)
#define SVR4			(OpSystem==kSolaris)
#define VxWorks			(OpSystem==kVxWorks)
#define NoWS			(WindowSystem==kNoWS)

// defines for what type of threading is available
#define kNoThreads		 0
#define kMSWin32Threads	 1
#define kUIThreads		 2
#define kPosixThreads	 3
#define kVxWorksThreads	 4
#define kMacMPThreads	 5

#if MSWin
	#define ThreadKind kMSWin32Threads
#elif OpSystem==kLinux
	#define ThreadKind kPosixThreads
#elif OpSystem==kVxWorks
	#define ThreadKind kVxWorksThreads
#elif Mac
	#define ThreadKind kPosixThreads
#else
	#define ThreadKind kNoThreads
#endif

#if defined(_WIN32_WCE)
	#define WinCE 1
#else
	#define WinCE 0
#endif

/* This should move to a LabVIEW header GR 1-13-00 ??? */
#if (ProcessorType==kX86)
	#define FPUASM 1
#else
	#define FPUASM 0
#endif


#endif /* _platdefines_H */
