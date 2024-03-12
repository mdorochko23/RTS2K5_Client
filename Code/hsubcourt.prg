**************************************************************************
** 3/04/2013 EF : Added new PA Court set
**************************************************************************

PARAMETERS d_date, c_case
LOCAL  c_alias AS STRING

c_alias =ALIAS()
LOCAL c_PrintJob AS STRING
llHoldFlag=.T.
c_PrintJob=""

LOCAL oMed_c AS OBJECT
oMed_c = CREATEOBJECT("generic.medgeneric")


oMed_c.closealias('CourtLtr')
oMed_C.sqlexecute("exec dbo.GetHSubpCourts '"  + DTOC(d_date) + "','" + c_case + "'", "CourtLtr")
IF USED('CourtLtr')
	SELECT CourtLtr
	SCAN
		IF !EOF()

			DO CourtSign WITH d_date, NVL(CourtLtr.COURT_NAME,''), CourtLtr.cl_code

		ELSE
			gfmessage('Cannot get a list of Courts. Try later or contact IT dept.')
			RETURN

		ENDIF

		SELECT CourtLtr
	ENDSCAN
ENDIF
omed_C.closealias("CourtLtr")
RELEASE oMed_c

********************************************************************************************
** Gets a list of tags(subpoenas) per a Court
**************************************************************************

FUNCTION CourtSign
PARAMETERS d_run , c_court, c_client
LOCAL c_alias AS STRING, n_rec AS INTEGER , oMed_c AS OBJECT, c_PrintJob AS STRING, c_attysign as String
c_PrintJob=""
oMed_c = CREATEOBJECT("generic.medgeneric")
c_Alias =ALIAS()
oMed_c.closealias('SubList')
l_done= oMed_c.sqlexecute("exec dbo.GetTagsToCourtSign  '"  + DTOC(d_Run) + "','"  ;
+ c_client + "','" ;
+ ALLTRIM(c_court) +"'","SubList")
SET PROCEDURE TO TA_LIB ADDITIVE

IF l_done THEN
	l_RetVal=.T.
	=CURSORSETPROP("KeyFieldList", "Cl_code, TAG", "SubList")
	INDEX ON CL_CODE + STR(TAG) TAG clTAG ADDITIVE

ELSE
	gfmessage('No subpoenas found.')
	RETURN

ENDIF
SELECT SubList
IF NOT EOF()
	n_rec=0
	n_rec=RECCOUNT()


	DO PrintGroup WITH c_PrintJob, "ToCourtSign"

	DO PrintField WITH c_PrintJob, "IssNums", STR(n_rec)
	DO PrintField WITH c_PrintJob, "Loc", ;
		IIF( pl_ofcPgh OR pl_ofcMD, "P", pc_offcode)


	DO PrintGroup WITH c_PrintJob, "Case"
	DO PrintField WITH c_PrintJob, "LRS", pc_lrsno
	DO PrintField WITH c_PrintJob, "Name", pc_plnam
	DO PrintField WITH c_PrintJob, "Plaintiff",ALLTRIM( pc_plcaptn)
	DO PrintField WITH c_PrintJob, "Defendant", ALLTRIM( pc_dfcaptn)
	DO PrintField WITH c_PrintJob, "Court", UPPER(pc_c1DESC)
	DO PrintField WITH c_PrintJob, "Term", ""
	DO PrintField WITH c_PrintJob, "Docket",  ALLTRIM( pc_docket)

	**06/20/2013  PRINTS signature at Contact
	oMed_c.closealias("AttySign")
	
	l_Ok=oMed_c.sqlexecute("SELECT dbo.AttySignature('" + fixquote(pc_rqatcod) + "')", "AttySign")
	c_attysign=""
	IF NOT l_Ok
		c_attysign=ALLTRIM(pc_AtySign)
	ELSE
		c_attysign=FIXQUOTE(AttySign.exp)
	endif

***Signature added




	DO PrintGroup WITH c_PrintJob, "Contact"
	DO PrintField WITH c_PrintJob, "Name", ALLT( c_attysign )
	DO PrintField WITH c_PrintJob, "Phone", ALLT( pc_amgr_ph )
	DO PrintField WITH c_PrintJob, "Extension", ALLTRIM(pc_amgr_ml)
** attach  subpoenas
	c_class='GenSubCrt'
	
	IF TYPE("MV")="C"
	MV=""
	ENDIF
	DO Subpoenas WITH d_run
	

	c_PrintJob = c_PrintJob + mv

	IF NOT EMPTY( c_PrintJob)		
		DO prtenqa WITH c_PrintJob, c_class, "1" , ""
	ENDIF


ENDIF && EOF

pl_HSubpCourt=.F.

omed_C.closealias("SubList")

*!*	IF !EMPTY(c_alias)
*!*		SELECT (c_alias)
*!*	ENDI
RELEASE oMed_c
RETURN
***************************************************************************************



*******************************************************
PROCEDURE Subpoenas
PARAMETERS dRunSet
** Print subps
LOCAL n_tagnum AS INTEGER
PRIVATE cScan AS STRING, calias AS STRING
LOCAL oMed1 AS OBJECT
oMed1 = CREATEOBJECT("generic.medgeneric")
calias=ALIAS()
Pl_noticng = .T.
pl_HSubpCourt=.T.


SELECT SubList
GO TOP
cScan = "  NOT DELETED() "

SCAN FOR &cScan
	IF USED("spec_ins")
		USE IN spec_ins
	ENDIF
	l_SpecIns=oMed1.sqlexecute(" Exec dbo.GetSpec_InsbyClCode '" + fixquote(pc_clcode) + "'", "Spec_ins")

	IF NOT l_SpecIns
		gfmessage('Cannot get the Special Instruction File. Try later or contact IT dept.')
		RETURN
	ENDIF
	n_tagnum=SubList.TAG
	PN_TAG =n_tagnum

	*IF USED ('RECORD') AND RECORD.TAG <>PN_TAG
		*SELECT RECORD
		*USE
		_SCREEN.MOUSEPOINTER= 11

		WAIT WINDOW " Getting Records.. wait" NOWAIT NOCLEAR
		pl_GotDepo = .F.
		DO gfGetDep WITH fixquote(pc_clcode), n_tagnum
		_SCREEN.MOUSEPOINTER= 0
	*ENDIF


	DO Subp_Pa WITH .T., 2, SubList.TAG, .T., .F., .T., "S"




	SELECT SubList
ENDSCAN
*DO OmrPage
*omed1.closealias("SubList")
omed1.closealias("Spec_ins")
omed1.closealias("REQUEST")
omed1.closealias("RECORD")


RELEASE oMed1
IF NOT EMPTY(calias)
	SELECT(calias)
ENDIF
RETURN
