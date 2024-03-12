PROCEDURE ZTXNotice
******************************************************************
* TEXAS NOTICE
*   Reprint all  subp notices for a specific case and day.
** EF 8/22/1017

******************************************************************
PARAMETER dt_date, ll_Reprint, n_rt
* dthisdate is the date for which notices should be reprinted
* llReprint : Original  vs. Reprint flag

PRIVATE nrec, nbal, csuborauth, bcourtd, x, bcourt, l_prtplain, oMed AS OBJECT, ;
	llCourt, llTABills, llTXNotice, llRecord

WAIT WINDOW "Printing notices. Please wait." NOWAIT NOCLEAR
SET PROCEDURE TO ta_lib ADDITIVE
pl_BatchNot=.F.
szEdtReq = ""
pc_BatchRq=""
l_prtplain = .F.
csuborauth = "S"
nbal = 0
pl_RepNotc = .F.
pl_BatchNot=.F.
IF TYPE("mv") = "U"
	PUBLIC mv
	mv = ""
ENDIF
_SCREEN.MOUSEPOINTER= 11

*1) Get a list of cases for the TX issues by date
IF TxList(dt_date, ll_Reprint, n_rt)
	SELECT TxList
ENDIF

WAIT CLEAR
IF EOF()
	*--9/5/18: add notice source [103895]
	gfmessage("There are no TX Notices to print!")
	*--gfmessage("There are no Notices to print!")
	RETURN
ENDIF

mclass = "TXNotice"


IF TYPE ('oMed') ="U"
	oMed = CREATEOBJECT("generic.medgeneric")
ENDIF



SELECT TxList

SCAN


	C_STR=""
	C_STR =" EXEC [dbo].[GetMasterByclcode] '" + fixquote(TxList.cl_code) + "'"
	l_gotmaster=oMed.sqlexecute(C_STR,"Master")

	IF NOT l_gotmaster
		WAIT CLEAR
		gfmessage(" Cannot open tblmaster to print TX Notices. Contact IT dept.")
		RETURN
	ENDIF

	ld_DueDate=  IIF(TYPE("TxList.DUE_date")="T", TTOD(TxList.due_date),TxList.due_date)


	*-- 06/22/2022 MD #276912 to make sure the RqAtty is not switched based on tag
	PN_TAG=0
	STORE .F. TO pl_GotCase
	DO gfGetCas

	WAIT WINDOW "Printing Notices for the RT# "  + pc_lrsno NOWAIT NOCLEAR




* 1) Print the notice : skip Requesting Attorney and Inhibit Notices ones

	l_Tabill=getTXAtty(pc_clcode, pc_rqatcod)
	IF NOT l_Tabill
		gfmessage( "Cannot get TAbills file" )
		RETURN

	ENDIF

	SELECT TABILLS
	SCAN

		SCATTER MEMVAR

		l_Plaint = (m.CODE = "P")
		l_Defend = (m.CODE = "D")
		l_Request = (m.CODE = "R")
		l_Lead = (m.CODE= "L")
		pl_noticng = .T.
** print notices

** second parameters  origial set vs. re-print- here is an original one
		DO TXsubnot WITH m.cl_code , dt_date, m.at_code, ll_Reprint, NVL(m.hownotice,'F') , ld_DueDate



		SELECT TABILLS

	ENDSCAN



	SELECT TxList
ENDSCAN


_SCREEN.MOUSEPOINTER=0
RELEASE mv, arntc
* Turn off global "Notices being reprinted" flag
pl_NoFaxNotice=.F.
IF TYPE ('oMed') ="O"
	RELEASE oMed
ENDIF
RETURN
**************************************************************
PROCEDURE  getTXAtty
**************************************************************
PARAMETERS c_client, c_rqaty
LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING, oMedBill AS OBJECT
oMedBill= CREATEOBJ("generic.medgeneric")

STORE .F. TO l_RetVal, l_done
C_STR="exec [dbo].[GetTxAtty2Notice] '"+ fixquote(c_client) + "','" + fixquote(c_rqaty) + "'"


l_done=oMedBill.sqlexecute(C_STR, "Tabills")
IF l_done THEN
	l_RetVal=.T.
	=CURSORSETPROP("KeyFieldList", "ID_TblBills,Cl_code, AT_code", "Tabills")
	INDEX ON cl_code + at_code TAG clac ADDITIVE
	INDEX ON cl_code TAG cl_code ADDITIVE
ENDIF
RELEASE oMedBill
RETURN l_RetVal


**********************************************************
PROCEDURE TxList
*******************************************************
* list of cases for TX Issues by date
PARAMETERS d_RunDate, l_repnot, n_rtNum
LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING,  c_date AS STRING

IF TYPE ('oMed') ="U"
	oMed = CREATEOBJECT("generic.medgeneric")
ENDIF

STORE .F. TO l_RetVal, l_done
c_alias=ALIAS()
c_date=DTOC(d_RunDate)
STORE "" TO C_STR, c_rtkey
IF l_repnot

 C_STR=" Select [dbo].[GetID_tblmaster] ('" + STR(n_rtNum) + "')"
 oMed.sqlexecute(C_STR, "KeyID")
 IF USED( "KeyID") AND !EOF() 
	 c_rtkey=Nvl(Keyid.Exp,"")
 ENDIF 
 

C_STR= "exec dbo.GetTXNoticesbyRT  '" +c_rtkey+ "'"
ELSE


C_STR="Exec dbo.GetTXNotices2Print '" + c_date + "'" 
ENDIF

l_done=oMed.sqlexecute(C_STR, "TxList")
IF l_done THEN
	l_RetVal=.T.
	=CURSORSETPROP("KeyFieldList", "Cl_code", "TxList")
	INDEX ON cl_code TAG  cl_code UNIQUE ADDITIVE


ENDIF

IF TYPE ('oMed') ="O"
	RELEASE oMed
ENDIF


IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF
RETURN l_RetVal




