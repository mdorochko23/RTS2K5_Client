*GetTxHeaderStyle
*#255675 12/15/2021 WY
PARAMETERS tnLrsNo, tnTag

*1 standard header style
*2 upper left only, plaintiff name only (no v., no defendent name)
*3 plaintiff name in the middle in v. position (blank top, blank bottom)
IF IsCalledFrom ("frmDeponentOptions") OR UPPER(LEFT(pc_Court1,7)) == "USDC-TX"
	RETURN 1  && standard header style
else
	**RETURN 3 &&2 &&1
	RETURN ObtainHeaderType(tnLrsNo, tnTag)
ENDIF


FUNCTION ObtainHeaderType (tnLrsNo, tnTag) 
	LOCAL loMed, llRetValue, lnHeadType
	
	loMed=CREATEOBJECT('medgeneric')
	loMed.closealias("TxHeadStyle")
	llRetValue = .f.
	llRetValue = loMed.sqlexecute("Exec [dbo].[GetHeaderType] " + ALLTRIM(STR(tnLrsNo)) + ", " + ;
									ALLTRIM(STR(tnTag)), "HeadType")
	lnHeadType = 1 && Default standard type
	IF llRetValue
		SELECT HeadType
		IF NOT EOF()	
			lnHeadType= NVL(HeadType.headerType, 1) && convert null to 1 (standard)
		ENDIF
		USE IN HeadType
	ELSE 
		gfmessage("Failed to get a blurb's data.")
	ENDIF

	RELEASE loMed
	RETURN lnHeadType
ENDFUNC