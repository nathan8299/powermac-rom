;	AUTO-GENERATED SYMBOL LIST



;	These registers will be used throughout

rCI 	set		rCI
		lwz		rCI, KDP.PA_ConfigInfo(r1)

rNK 	set		rNK
		lwz		rNK, KDP.PA_NanoKernelCode(r1)

rPgMap 	set		rPgMap
		lwz		rPgMap, KDP.PA_PageMapStart(r1)

rXER 	set		rXER
		mfxer	rXER



InitVectorTables

	;	System/Alternate Context tables

	_kaddr	r23, rNK, Panic
	addi	r8, r1, KDP.VecBaseSystem
	li		r22, 3 * VecTable.Size
@vectab_initnext_segment
	subic.	r22, r22, 4
	stwx	r23, r8, r22
	bne		@vectab_initnext_segment

rSys set r9 ; to clarify which table is which
rAlt set r8

	addi	rSys, r1, KDP.VecBaseSystem
	mtsprg	3, rSys

	addi	rAlt, r1, KDP.VecBaseAlternate

	_kaddr	r23, rNK, Panic
	stw		r23, VecTable.SystemResetVector(rSys)
	stw		r23, VecTable.SystemResetVector(rAlt)

	_kaddr	r23, rNK, IntMachineCheck
	stw		r23, VecTable.MachineCheckVector(rSys)
	stw		r23, VecTable.MachineCheckVector(rAlt)

	_kaddr	r23, rNK, IntDSI
	stw		r23, VecTable.DSIVector(rSys)
	stw		r23, VecTable.DSIVector(rAlt)

	_kaddr	r23, rNK, IntISI
	stw		r23, VecTable.ISIVector(rSys)
	stw		r23, VecTable.ISIVector(rAlt)

	lbz		r22, NKConfigurationInfo.InterruptHandlerKind(rAlt)

	cmpwi	r22, 0
	_kaddr	r24, rNK, IntForEmulator_1
	beq		@chosenIntHandler
	cmpwi	r22, 1
	_kaddr	r24, rNK, IntForEmulator_2
	beq		@chosenIntHandler
	cmpwi	r22, 2
	_kaddr	r24, rNK, IntForEmulator_3
	beq		@chosenIntHandler

@chosenIntHandler
	stw		r23, VecTable.ExternalIntVector(rSys)

	_kaddr	r23, rNK, IntProgram
	stw		r23, VecTable.ExternalIntVector(rAlt)

	_kaddr	r23, rNK, IntAlignment
	stw		r23, VecTable.AlignmentIntVector(rSys)
	stw		r23, VecTable.AlignmentIntVector(rAlt)

	_kaddr	r23, rNK, IntProgram
	stw		r23, VecTable.ProgramIntVector(rSys)
	stw		r23, VecTable.ProgramIntVector(rAlt)

	_kaddr	r23, rNK, IntFPUnavail
	stw		r23, VecTable.FPUnavailVector(rSys)
	stw		r23, VecTable.FPUnavailVector(rAlt)

	_kaddr	r23, rNK, IntDecrementerSystem
	stw		r23, VecTable.DecrementerVector(rSys)
	_kaddr	r23, rNK, IntDecrementerAlternate
	stw		r23, VecTable.DecrementerVector(rAlt)

	_kaddr	r23, rNK, IntSyscall
	stw		r23, VecTable.SyscallVector(rSys)
	stw		r23, VecTable.SyscallVector(rAlt)

	_kaddr	r23, rNK, IntPerfMonitor
	stw		r23, VecTable.PerfMonitorVector(rSys)
	stw		r23, VecTable.PerfMonitorVector(rAlt)

	_kaddr	r23, rNK, IntTrace
	stw		r23, VecTable.TraceVector(rSys)
	stw		r23, VecTable.TraceVector(rAlt)
	stw		r23, 0x0080(rSys)			; Unexplored parts of vecBase
	stw		r23, 0x0080(rAlt)


	;	MemRetry vector table

	addi	r8, r1, KDP.VecBaseMemRetry

	_kaddr	r23, rNK, MemRetryMachineCheck
	stw		r23, VecTable.MachineCheckVector(r8)

	_kaddr	r23, rNK, MemRetryDSI
	stw		r23, VecTable.DSIVector(r8)



;	Fill the NanoKernelCallTable, the IntProgram interface to the NanoKernel

InitKCalls

	;	Start with a default function
	
	_kaddr	r23, rNK, KCallSystemCrash

	addi	r8, r1, KDP.NanoKernelCallTable

	li		r22, NanoKernelCallTable.Size

@kctab_initnext_segment
	subic.	r22, r22, 4
	stwx	r23, r8, r22
	bne		@kctab_initnext_segment


	;	Then some overrides (names still pretty poor)

	_kaddr	r23, rNK, KCallReturnFromException
	stw		r23, NanoKernelCallTable.ReturnFromException(r8)

	_kaddr	r23, rNK, KCallRunAlternateContext
	stw		r23, NanoKernelCallTable.RunAlternateContext(r8)

	_kaddr	r23, rNK, KCallResetSystem
	stw		r23, NanoKernelCallTable.ResetSystem(r8)

	_kaddr	r23, rNK, KCallVMDispatch
	stw		r23, NanoKernelCallTable.VMDispatch(r8)

	_kaddr	r23, rNK, KCallPrioritizeInterrupts
	stw		r23, NanoKernelCallTable.PrioritizeInterrupts(r8)

	_kaddr	r23, rNK, KCallThud
	stw		r23, NanoKernelCallTable.Thud(r8)



;	Init the NCB Pointer Cache

	_InvalNCBPointerCache scratch=r23



;	Put HTABORG and PTEGMask in KDP, and zero out the last PTEG

InitHTAB

	mfspr	r8, sdr1

	;	get settable HTABMASK bits
	rlwinm	r22, r8, 16, 7, 15

	;	and HTABORG
	rlwinm	r8, r8, 0, 0, 15

	;	get a PTEGMask from upper half of HTABMASK
	ori		r22, r22, (-64) & 0xffff

	;	Save in KDP (OldWorld must do this another way)
	stw		r8, KDP.HTABORG(r1)
	stw		r22, KDP.PTEGMask(r1)

	;	zero out the last PTEG in the HTAB
	li		r23, 0
	addi	r22, r22, 64
@next_segment
	subic.	r22, r22, 4
	stwx	r23, r8, r22
	bgt		@next_segment
@skip_zeroing_pteg

	;	Flush the TLB after touching the HTAB
	bl		PagingFlushTLB



;	Get a copy of the PageMap (and the SegMaps required to interpret it)

;	Each entry in the PageMap specifies a contiguous part of the MacOS
;	address space (or it has a special value). The four SegMaps (supervisor,
;	user, CPU, overlay) contain pointers that tell us which entries belong
;	in which 256 MB "segments".

CopyPageMap

	;	r9 = PageMap ptr, r22 = PageMap size
	lwz		r9, NKConfigurationInfo.PageMapInitOffset(rCI)
	lwz		r22, NKConfigurationInfo.PageMapInitSize(rCI)
	add		r9, r9, rCI

@copynext_segment_pagemap
	subi	r22, r22, 4		;	load a word from the CI pagemap (top first)
	lwzx	r21, r9, r22

	andi.	r23, r21, PageMapEntry.DaddyFlag | PageMapEntry.PhysicalIsRelativeFlag
	cmpwi	r23, PageMapEntry.PhysicalIsRelativeFlag
	bne		@physical_address_not_relative_to_config_info

	;	if the physical address of the area is relative to the ConfigInfo struct:
	rlwinm	r21, r21, 0, ~PageMapEntry.PhysicalIsRelativeFlag
	add		r21, r21, rCI
@physical_address_not_relative_to_config_info

	stwx	r21, rPgMap, r22	;	save in the KDP pagemap

	subic.	r22, r22, 4
	lwzx	r20, r9, r22	;	load another word, but no be cray
	stwx	r20, rPgMap, r22	;	just save it in KDP
	bgt		@copynext_segment_pagemap
@skip_copying_pagemap


	;	Edit three entries in the PageMap that the kernel "owns"

	lwz		r8, NKConfigurationInfo.PageMapIRPOffset(rCI)
	add		r8, rPgMap, r8
	lwz		r23, PageMapEntry.PBaseAndFlags(r8)
	rlwimi	r23, r19, 0, 0xFFFFF000
	stw		r23, PageMapEntry.PBaseAndFlags(r8)

	lwz		r8, NKConfigurationInfo.PageMapKDPOffset(rCI)
	add		r8, rPgMap, r8
	lwz		r23, PageMapEntry.PBaseAndFlags(r8)
	rlwimi	r23, r19, 0, 0, 0xFFFFF000
	stw		r23, PageMapEntry.PBaseAndFlags(r8)

	lwz		r19, KDP.PA_EmulatorData(r1)
	lwz		r8, NKConfigurationInfo.PageMapEDPOffset(rCI)
	add		r8, rPgMap, r8
	lwz		r23, PageMapEntry.PBaseAndFlags(r8)
	rlwimi	r23, r19, 0, 0, 0xFFFFF000
	stw		r23, PageMapEntry.PBaseAndFlags(r8)


	;	Copy the SegMap

	addi	r9, rCI, NKConfigurationInfo.SegMaps - 4
	addi	r8, r1, KDP.SegMaps - 4
	li		r22, 4*16*8 ; 4 maps * 16 segments * (ptr+flags=8b)

@segmap_copynext_segment
	lwzu	r23, 4(r9)
	subic.	r22, r22, 8
	add		r23, rPgMap, r23	;	even-indexed words are PMDT offsets in PageMap
	stwu	r23, 4(r8)

	lwzu	r23, 4(r9)
	stwu	r23, 4(r8)

	bgt		@segmap_copynext_segment



;	Copy "BATRangeInit" array

CopyBATRangeInit

	addi	r9, rCI, NKConfigurationInfo.BATRangeInit - 4
	addi	r8, r1, KDP.BATs - 4
	li		r22, 4*4*8 ; 4 maps * 4 BATs * (UBAT+LBAT=8b)

@bat_copynext_segment
	lwzu	r20, 4(r9)		; grab UBAT
	lwzu	r21, 4(r9)		; grab LBAT
	stwu	r20, 4(r8)		; store UBAT

	_bclr	r23, r21, 22	; if LBAT[22] (reserved) is set:
	cmpw	r21, r23
	beq		@bitnotset
	add		r21, r23, rCI	; then LBAT[BRPN] is relative to ConfigInfo struct
@bitnotset

	subic.	r22, r22, 8
	stwu	r21, 4(r8)		; store LBAT
	bgt		@bat_copynext_segment



;	Save some ptrs that allow us to enable Overlay mode, etc

	addi	r23, r1, KDP.SegMap32SupInit
	stw		r23, KDP.SupervisorSegMapPtr(r1)
	lwz		r23, NKConfigurationInfo.BatMap32SupInit(rCI)
	stw		r23, KDP.SupervisorBatMap(r1)

	addi	r23, r1, KDP.SegMap32UsrInit
	stw		r23, KDP.UserSegMapPtr(r1)
	lwz		r23, NKConfigurationInfo.BatMap32UsrInit(rCI)
	stw		r23, KDP.UserBatMap(r1)

	addi	r23, r1, KDP.SegMap32CPUInit
	stw		r23, KDP.CPUSegMapPtr(r1)
	lwz		r23, NKConfigurationInfo.BatMap32CPUInit(rCI)
	stw		r23, KDP.CPUBatMap(r1)

	addi	r23, r1, KDP.SegMap32OvlInit
	stw		r23, KDP.OverlaySegMapPtr(r1)
	lwz		r23, NKConfigurationInfo.BatMap32OvlInit(rCI)
	stw		r23, KDP.OverlayBatMap(r1)



;	Create a PageList for the Primary Address Range

;	Usable physical pages are:
;		Inside a RAM bank, and
;		NOT inside the kernel's reserved physical memory

;	By 'draft PTE', I mean these parts of the second word of a PTE:
;		physical page number (base & 0xfffff000)
;		WIMG bits (from oddly formatted ConfigInfo.PageAttributeInit)
;		bottom PP bit always set

;	And all this goes at the bottom of the kernel reserved area.
;	Leave ptr to kernel reserved area in r21
;	Leave ptr to topmost entry in r29.

CreatePageList

	lwz		r21, KDP.KernelMemoryBase(r1) ; "KernelMemory" is forbidden
	lwz		r20, KDP.KernelMemoryEnd(r1)
	subi	r29, r21, 4 ; ptr to last added entry

	addi	r19, r30, IRP.SystemInfo + NKSystemInfo.Bank0Start - 8

	lwz		r23, KDP.PageAttributeInit(r1)	;	default WIMG/PP settings in PTEs

	;	Pull WIMG bits out of PageAttributeInit
	li		r30, 1
	rlwimi	r30, r23, 1, 25, 25
	rlwimi	r30, r23, 31, 26, 26
	xori	r30, r30, 0x20
	rlwimi	r30, r23, 29, 27, 27
	rlwimi	r30, r23, 27, 28, 28

	li		r23, NKSystemInfo.MaxBanks

@nextbank
	subic.	r23, r23, 1
	blt		@done

	lwzu	r31, 8(r19)		;	bank start address
	lwz		r22, 4(r19)		;	bank size
	or		r31, r31, r30	;	looks a lot like the second word of a PTE

@nextpage
	cmplwi	r22, 4096
	cmplw	cr6, r31, r21
	cmplw	cr7, r31, r20
	subi	r22, r22, 4096
	blt		@nextbank

	;	Check that this page is outside the kernel's reserved area
	blt		cr6, @below_reserved
	blt		cr7, @in_reserved
@below_reserved
	stwu	r31, 4(r29)		;	write that part-PTE at the base of kernel memory
@in_reserved

	addi	r31, r31, 4096
	b		@nextpage
@done



;	In the PageMap, create a Primary Address Range matching the size of PageList

;	For every segment that contains part of the PAR, the first PageMapEntry will be rewritten
;	Going in, r21/r29 point to first/last element of PageList

CreatePARInPageMap

	;	r19 = size of RAM represented in PageList ("Usable" and initial "Logical" RAM)
	;	r22 = number of 4096b pages, minus one page (counter)
	subf	r22, r21, r29
	li		r30, 0
	addi	r19, r22, 4
	slwi	r19, r19, 10
	ori		r30, r30, 0xffff
	stw		r19, IRP.SystemInfo + NKSystemInfo.UsableMemorySize(r8)
	srwi	r22, r22, 2
	stw		r19, IRP.SystemInfo + NKSystemInfo.LogicalMemorySize(r8)

	;	convert r19 to pages, and save in some places
	srwi	r19, r19, 12
	stw		r19, KDP.VMLogicalPages(r1)
	stw		r19, KDP.TotalPhysicalPages(r1)

	addi	r29, r1, KDP.PARPerSegmentPLEPtrs - 4	; where to save per-segment PLE ptr
	addi	r19, r1, KDP.SegMap32SupInit - 8		; which part of PageMap to update 

@next_segment
	cmplwi	r22, 0xffff				; continue (bgt) while there are still pages left
	
	;	Rewrite the first PageMapEntry in this segment
	lwzu	r8, 8(r19)				; find PageMapEntry using SegMap32SupInit
	rotlwi	r31, r21, 10
	ori		r31, r31, 0xC00
	stw		r30, 0(r8)				; LBase = 0, PageCount = 0xFFFF
	stw		r31, 4(r8)				; PBase = PLE ptr, Flags = DaddyFlag + CountingFlag

	stwu	r21, 4(r29)				; point PARPerSegmentPLEPtrs to segments's first PLE

	addis	r21, r21, 4				; increment pointer into PLE (64k pages/segment * 4b/PLE)
	subis	r22, r22, 1				; decrement number of pending pages (64k pages/segment)

	bgt		@next_segment

	;	Reduce the number of pages in the last segment
	sth		r22, PageMapEntry.PageCount(r8)



;	Enable the ROM Overlay

	addi	r29, r1, KDP.OverlaySegMapPtr
	bl		PagingFunc2



;	Make sure some important areas of RAM are in the HTAB

	lwz		r27, KDP.PA_ConfigInfo(r1)
	lwz		r27, NKConfigurationInfo.LA_InterruptCtl(r27)
	bl		PagingFunc1

	lwz		r27, KDP.PA_ConfigInfo(r1)
	lwz		r27, NKConfigurationInfo.LA_KernelData(r27)
	bl		PagingFunc1

	lwz		r27, KDP.PA_ConfigInfo(r1)
	lwz		r27, NKConfigurationInfo.LA_EmulatorData(r27)
	bl		PagingFunc1



;	Restore the fixedpt exception register (not sure where we clobbered it?)

	mtxer	rXER