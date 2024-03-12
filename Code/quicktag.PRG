
*****************************************************************************
****Add Received Tag from the AIP/QC system
**2//26/13- use docname instead of comment for lc_descript per Alec/Susan
*****************************************************************************

PARAMETERS c_BBWebNo
LOCAL lc_image AS STRING, lc_descript AS STRING, lc_alias2 AS STRING, lc_RT AS STRING, lc_sql AS STRING, L_OK  AS Boolean, nRec2 AS INTEGER
lc_alias2 =ALIAS()
nRec2 =RECNO()

_SCREEN.MOUSEPOINTER=11
PRIVATE OMED AS OBJECT
OMED=CREATEOBJECT("generic.medgeneric")

L_OK =.F.
STORE "" TO  lc_image , lc_message,  lc_alias, lc_RT
SELECT ImgData

*--6/4/18: KDL -  Quick Request from Uploaded Case documents: suppress multiple confirmation prompts [56363]
LOCAL iCnt
iCnt = 1

SCAN FOR addtag AND NOT done

	*--6/29/18: KDL -  Quick Request from Uploaded Case documents: accomodate multiple order numbers for selected files [56363]
	c_BBWebNo = ALLTRIM(STR(NVL(ImgData.ordnum,0)))

	OMED.closealias('ImgPath')
	lc_sql= "select [dbo].[getUplFilePathName] ('"+ c_BBWebNo +"','" + STR( NVL(ImgData.UPLSEQID,0) )+ "')"

	OMED.sqlexecute(lc_sql,"ImgPath")

	lc_image=ALLTRIM(NVL(ImgPath.EXP,""))
	lc_descript=ALLTRIM(NVL(ImgData.docname,""))

	IF EMPTY(lc_image)
		gfmessage("Cannot find an image file.")
		RETURN
	ENDIF

*--6/4/18: KDL -  Quick Request from Uploaded Case documents: check confirmation counter [56363]
	IF iCnt = 1
		lc_message = "Are you sure you want to create a tag?"
		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
		o_message.SHOW
		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
		o_message.RELEASE
	ELSE
		l_Confirm=.T.
	ENDIF

*!*		lc_message = "Are you sure you want to create a tag?"
*!*		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
*!*		o_message.SHOW
*!*		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
*!*		o_message.RELEASE


	IF l_Confirm

*--6/4/18: KDL -  Quick Request from Uploaded Case documents: increment counter after the first user confirmation [56363]
		iCnt = iCnt + 1

		lc_RT =ALLTRIM(PC_lrsno)
		DO QCQUICKTAG WITH lc_RT  ,lc_descript,'P',lc_image
		SELECT ImgData
		REPLACE done WITH .T.
** mark as Tag <>0 in the tblUploads so the docs won't be displayed on the web

		lc_sql= "exec	[dbo].[qc_EditUploadsQuickTag] '" +  c_BBWebNo + "','" +  STR( NVL(ImgData.UPLSEQID,0) ) + "','" + pc_UserID + "'"
		OMED.sqlexecute(lc_sql,"")

		L_OK =.T.
	ENDIF


	SELECT ImgData
ENDSCAN
RELEASE OMED

IF NOT EMPTY(lc_alias2)
	SELECT (lc_alias2)
	IF !EOF()
		GOTO nRec2
	ENDIF
ENDIF
RETURN L_OK
