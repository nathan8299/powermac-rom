	include		'MacErrors.a'
	include		'Multiprocessing.a'

	include		'InfoRecords.a'
	include		'EmulatorPublic.a'
	include		'NKPublic.a'
	include		'NKOpaque.a'

	include		'NKEquates.s'
	include		'NKMacros.s'

NKTop
	b			SystemCrash
	org			0
	include		'NKInit.s'
	include		'NKSystemCrash.s'
	include		'NKIntHandlers.s'
	include		'NKMemory.s'
	include		'NKExceptions.s'
	include		'NKFloatingPt.s'
	include		'NKSoftInt.s'
	include		'NKLegacyVM.s'
NKBtm
FDP_TableBase
FDP_003C
loc_A38
FDP_011C
loc_D50
FDP_0DA0
MemRetryDSI
MemRetryMachineCheck
