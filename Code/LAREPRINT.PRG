PUBLIC gcCl_code AS STRING ,gnTag AS INTEGER, pd_Date AS DATE, pn_option AS INTEGER , pn_lrsno as Integer;
pcScanSg AS STRING, pcamgr_nm AS STRING, pcamgr_ml AS STRING , mv_1 AS strung,  mv_2   AS strring,  ;
mv_3 AS STRING, mv_4 AS STRING, mv_5 AS STRING, mv_6 AS STRING, mv_8 AS STRING, ;
pcamgr_ph AS STRING,  pcphone AS STRING, pc_Attn AS STRING, n_occurences AS INTEGER
PUBLIC pcInitials  AS STRING
pn_option=0
pc_Attn="MEDICAL RECORD CUSTODIAN"
STORE "" TO 		mv_1,mv_2 ,mv_3,mv_4 ,mv_5, mv_7,mv_6, mv_8


PUBLIC  oMed AS OBJECT

_SCREEN.MOUSEPOINTER= 11
IF TYPE("mv") = "U"
	PUBLIC mv
	mv = ""
ENDIF

*WAIT WINDOW "Looking for tags to process...." NOWAIT NOCLEAR

SET ESCAPE ON
oMed = CREATEOBJECT("generic.medgeneric")
SET PROCEDURE TO ta_lib ADDITIVE

N_OK=goapp.OpenForm("issued.frmlareprint", "S")

DO CASE
	CASE pn_option=0
		RETURN
	CASE pn_option=1 
	&&whole request
	WAIT WINDOW 'Under Construction..Hit any key to exit' 
	RETURN
		*c_mailid=pc_mailidno
		*n_count =n_occurences
		*DO  SendToRps WITH pc_mailid, .F., 0, pd_Date, n_count
		
	OTHERWISE
	&&cert page only
		DO  LA_certpage WITH  pn_lrsno, gnTag, pd_date

ENDCASE

_SCREEN.MOUSEPOINTER= 0
RETURN
*********************************************************************************
PROCEDURE LA_Certpage

PARAMETERS  C_lrsno, nTag, d_date

LOCAL l_cancel AS Boolean, l_gotReq AS Boolean, cProvider as String
STORE .F. TO l_cancel, l_gotReq
STORE "" TO 		mv_1, mv_2 , mv_3,  mv_4 ,mv_5, mv_7, mv_6,  mv_8, cProvider

gcCl_code="LACERT"
gnTag=1

mclass="LACert"

WAIT WINDOW "Printing Certification..." NOWAIT NOCLEAR

c_sql="exec  [dbo].[GetLATag]  '" + DTOC(d_date) + "', '" + (C_lrsno) + "'" 
oMed.sqlexecute(c_sql,'Request')

SELECT REQUEST
n_Tag=REQUEST.TAG
ncount= 1
pc_offcode="P"

C_STR="Exec dbo.GetLAServiceProvider '" + Request.mailid_NO + "'"

l_done=oMed.sqlexecute(C_STR, "DepInfo")
SELECT depinfo
cProvider=DepInfo.provider

****
*!*	c_sql="exec dbo.RPSTodoList '" + Request.mailid_NO + "'"
*!*	oMed.sqlexecute(c_sql,'Listtodo')	
*!*	SELECT listtodo
*!*	ncount =Listtodo.occurences
****
ncount=0
pc_amgr_id='Alec'
DO getsign WITH pc_amgr_id


	SELECT REQUEST	
	GO TOP
	MV_8=''
	SCAN FOR tag =n_Tag
		MV_7=LAcert (cProvider)
		
		IF ncount>190
			DO prtenqa WITH mv_7, mclass, "5", ""
		ELSE		
		  mv_8 = MV_8+MV_7
		ENDIF
		
		SELECT REQUEST
	ENDSCAN




mv=mv_8

IF NOT EMPTY(mv)
DO prtenqa WITH mv, mclass, "5", ""
endif

_SCREEN.MOUSEPOINTER=0
RELEASE mv
WAIT CLEAR 
**gfmessage("The Requests have been sent to the RPS.")

RETURN

**************************************************************************
PROCEDURE getsign
PARAMETERS c_amgr_id

IF  NOT EMPTY( c_amgr_id)
	IF TYPE("oMedGen")!="O" OR ISNULL(oMedGen)=.T.
		oMedGen=CREATEOBJECT("generic.medgeneric")
	ENDIF
	oMedGen.sqlexecute("exec dbo.GetUserByLogin '" + fixquote(ALLTRIM( c_amgr_id)) + "'", "UserCtrl")
	SELECT UserCtrl
	pcamgr_nm = ALLT( UserCtrl.FULLNAME)
	pcamgr_ml = ALLT( UserCtrl.Email)
	pcamgr_ph = ALLT( UserCtrl.DirectDial)
	pcScanSg = ALLT( UserCtrl.SigFile)
	pcInitials =getInitials(c_amgr_id)
	pcphone = ALLT( UserCtrl.DirectDial)


ENDIF
RELEASE  oMedGen
RETURN
************************************************************************

***************************************************************************
PROCEDURE Lacert
PARAMETERS  c_name


mv1=""
pc_litcode='RLA'
DO PrintGroup WITH mv1, "LACert"
DO PrintField WITH mv1, "DeponentName",  ALLTRIM(c_name)

DO PrintField WITH mv1, "Tag",  STR(REQUEST.TAG)
DO PrintField WITH mv1, "RecipientName",  REQUEST.casename
DO PrintField WITH mv1, "RecipientRT",  STR(REQUEST.Lrs_no)
DO PrintField WITH mv1, "RecipientDOB",  NVL(DTOC( REQUEST.brth_date),'')
DO PrintField WITH mv1, "RecipientSSN",   NVL(ALLTRIM(REQUEST.Claim_no),"")

c_Specmark=ALLTRIM(UPPER(NVL(pc_litcode,"")))+"."+ALLTRIM(UPPER(NVL(pcInitials,"")))

DO PrintField WITH mv1, "SpecMark", c_Specmark

DO PrintGroup WITH mv1, "Control"
DO PrintField WITH mv1, "Date",''
DO PrintField WITH mv1, "LrsNo", STR(REQUEST.lrs_no)
DO PrintField WITH mv1, "Tag", STR(REQUEST.TAG)









