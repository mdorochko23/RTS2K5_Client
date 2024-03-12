**************************************************************************
** 2/22/2013 EF : Added new Il_cook Court set
**************************************************************************

PARAMETERS d_date
LOCAL  c_alias AS STRING

c_alias =ALIAS()
LOCAL c_PrintJob AS STRING
llHoldFlag=.F.
c_PrintJob=""
pl_CrtSetCook=.t.



DO PrintGroup WITH c_PrintJob, "CookCrt"
IF USED('CookLtr')
	SELECT CookLtr
	SELECT DISTINCT At_CODE FROM CookLtr   INTO CURSOR TMPNOT2
	SELECT TMPNOT2
	c_attylist=""
	c_Addtext=""
	SCAN
		c_Atty=fixquote(tmpnot2.at_code)
		pl_GetAt = .F.
		DO gfatinfo WITH c_Atty, "M"
		c_attylist=c_AtTylist + CHR(13) + UPPER( ALLTRIM(pc_AtyName)) + CHR(13) + ALLTRIM(pc_AtyFirm)  + CHR(13)+  pc_Aty1Ad ;
			+ " " + pc_Aty2Ad + CHR(13) +  pc_Atycsz + CHR(13)+ pc_AtyFax + CHR(13) 

		SELECT tmpnot2
	ENDSCAN
	
	SELECT tmpnot2
	USE

	DO PrintField WITH c_PrintJob, "AddAttyList", c_Addtext + CHR(13) + c_attylist

ELSE

	DO PrintField WITH c_PrintJob, "AddAttyList", ""
ENDIF

DO PrintField WITH c_PrintJob, "IssueDate",  DTOC( d_date)
DO PrintField WITH c_PrintJob, "Loc", ;
	IIF( pl_ofcPgh OR pl_ofcMD, "P", pc_offcode)
DO PrintField WITH c_PrintJob, "FaxLoc", ;
	IIF( pl_ofcPgh OR pl_ofcMD, "P", pc_offcode)


DO PrintGroup WITH c_PrintJob, "Case"
DO PrintField WITH c_PrintJob, "LRS", pc_lrsno
DO PrintField WITH c_PrintJob, "Name", pc_plnam
DO PrintField WITH c_PrintJob, "Plaintiff",ALLTRIM( pc_plcaptn)
DO PrintField WITH c_PrintJob, "Defendant", ALLTRIM( pc_dfcaptn)
DO PrintField WITH c_PrintJob, "Court", ""
DO PrintField WITH c_PrintJob, "Term", ""
DO PrintField WITH c_PrintJob, "Docket",  ALLTRIM( pc_docket)


DO PrintGroup WITH c_PrintJob, "Contact"
DO PrintField WITH c_PrintJob, "Name", ALLT( pc_amgr_nm )
DO PrintField WITH c_PrintJob, "Phone", ALLT( pc_amgr_ph )
DO PrintField WITH c_PrintJob, "Extension", ALLTRIM(pc_amgr_ml)
** attach  subpoenas
c_class='CtrLetter'


DO Subps WITH d_date

c_PrintJob = c_PrintJob + mv 

IF NOT EMPTY( c_PrintJob)
	
	SET PROCEDURE TO TA_LIB ADDITIVE
	DO prtenqa WITH c_PrintJob, c_class, "1" , ""
ENDIF

pl_CrtSetCook=.f.
IF USED('CookLtr')
SELECT CookLtr
USE
endif
IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF

RETURN
*******************************************************
PROCEDURE Subps
PARAMETERS dRunSet
** Print subps
LOCAL n_tagnum as Integer
PRIVATE cScan as String, calias AS String
LOCAL oMed1 AS OBJECT
oMed1 = CREATEOBJECT("generic.medgeneric")
calias=ALIAS()
pl_noticng = .T.
omed1.closealias("SubpOrd")
oMed1.sqlexecute("exec [dbo].[IlCookCourtLetter] '" + fixquote(pc_clcode) + "','" + DTOC(dRunSet) + "'", "SubpOrd")


SELECT SubpOrd
GO TOP
IF EOF()
gfmessage('No tag(s) to print subpoenas for.')
RETURN
ENDIF

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
	n_tagnum=SubpOrd.Tag
	PN_TAG =n_tagnum

	IF USED ('RECORD') AND RECORD.TAG <>PN_TAG
		SELECT RECORD
		USE
		_SCREEN.MOUSEPOINTER= 11

		WAIT WINDOW " Getting Records.. wait" NOWAIT NOCLEAR
		pl_GotDepo = .F.
		DO gfGetDep WITH fixquote(pc_clcode), n_tagnum
		_SCREEN.MOUSEPOINTER= 0
	ENDIF


		DO Subp_Pa WITH .T., 2, SubpOrd.Tag, .T., .F., .T., "S"
		
		


	SELECT SubpOrd
ENDSCAN
WAIT CLEAR
&&03/23/2016 removed  OMRPage #36180
*DO OmrPage
&&03/23/2016 removed  OMRPage #36180
omed1.closealias("SubpOrd")
omed1.closealias("Spec_ins")
omed1.closealias("REQUEST")
omed1.closealias("RECORD")

RELEASE oMed1
IF NOT EMPTY(calias)
SELECT(calias)
ENDIF
RETURN
