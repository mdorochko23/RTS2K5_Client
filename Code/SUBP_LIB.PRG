PROCEDURE Subp_Lib
************************************************************************
* Modifications:
** 03/10/06 EF -  Added to the VFP project.
*-----------------------------------------------------------------------
* 08/02/04 DMA - Remove internal copy of SendMsg
* 07/08/04 DMA - Replace gsQuest with pc_TXQuest
* 06/10/04 DMA - Move PrnTxDoc into Subp_Pa, since only called from there
*                Make pTxAffidavit into stand-alone module PTXAffid
* 01/13/03 EF  - Allow affidavits for "A" and "N" subpoenas
* 01/09/03 dma - Allow affidavits for both admissible and
*                non-admissible subpoenas
* 06/06/02 kdl - Set proper order for seek in entry table
************************************************************************
**EF 10/26/01 Preparation of Texas Subpoenas
************************************************************************
** Called from Subp_PA during initial entry of a request for TX office
** Gathers needed information about deposition questions, affidavits, etc.

PUBLIC szQList, szForm, bDoSubp, arQues, szAtCode, sQuest
STORE "" TO sQuest, szForm, szQList, arQues, szAtCode, sQuest2

bDoSubp = .T.
pl_TXAffid = .F.
DIMENSION arQues[1]
DO DoTxSubp
RETURN

*---------------------------------------------------------------
PROCEDURE DoTxSubp

** Repeat until user cancels Subpoena or returns
** with a selected list of questions.

pl_TXAffid = .F.
szAlias = ALIAS()
DO WHILE bDoSubp
	** Select Questions
	DO SelQType
	IF NOT EMPTY(pc_TXQuest)
		bDoSubp = .F.
	ENDIF
ENDDO
RETURN

*---------------------------------------------------------------
PROCEDURE SelQType
PUBLIC szQList, szForm

szQList = ""

*DEFINE POPUP FormPop ;
FROM 1,1 TO 6,30 ;
TITLE " Written Questions " ;
FOOTER " Highlight and Press <Enter> "

*DEFINE BAR 1 OF FormPop PROMPT "\<Admissible Form"
*DEFINE BAR 2 OF FormPop PROMPT "\<Nonadmissible Form"
*DEFINE BAR 3 OF FormPop PROMPT "\-"
*DEFINE BAR 4 OF FormPop PROMPT "\<Cancel"

*ON SELECTION POPUP FormPop DEACTIVATE POPUP FormPop

*DO WHILE .T.
*ACTIVATE POPUP FormPop
* IF BAR() >= 1
*   EXIT
* ENDIF
*ENDDO

*nBar = 0
*nBar = BAR()
*DO CASE
*CASE nBar = 1
*szForm = "A"

*CASE nBar = 2
* szForm = "N"

*CASE nBar = 4
*szQList = ""
* bDoSubP = .F.

*ENDCASE

l_Set = goApp.OpenForm("Issued.frmTxSubtype", "M")
** Choose questions
IF l_Set
	DO get_qtx WITH szForm

	IF INLIST( szForm, "N", "A")

		*pl_TXAffid = SendMsg( "Is an Affidavit required?", 2, .F., ;
		*"Affidavit Option") = 1
		lc_message = "Is an Affidavit required?"
		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
		o_message.SHOW
		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
		o_message.RELEASE
		IF l_Confirm
			pl_TXAffid=.T.
		ELSE
			pl_TXAffid=.F.
		ENDIF


	ENDIF

ENDIF

** 11/12/01 Choose affidavit types [function in Subp_pa]
IF pl_TXAffid
	cdept = Pick_Aff()
ENDIF

RETURN
****************************************************************************
FUNCTION get_qtx
PARAMETERS szForm
**********************************************************************
PRIVATE lcAlias, lnCount, lcQst

lcAlias = ALIAS()
pc_TXQuest=goApp.OpenForm("issued.frmTxQuestion", "M", MASTER.id_tblMaster,MASTER.id_tblMaster, szForm)

IF pc_TXQuest=""
	RETURN
	l_cancel=.T.
ENDIF


IF NOT EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF
RETURN pc_TXQuest
********************************************************************************

