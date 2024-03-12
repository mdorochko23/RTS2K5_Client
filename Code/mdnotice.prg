*PROCEDURE Mdnotice
***  KOP END-of-DAY notices program
********************************************************************************
** EF 04/08/15- added to print MD Baltimore City/Civil Notices
*********************************************************************************
PARAMETERS d_date
LOCAL l_cancel AS Boolean, l_gotReq AS Boolean, c_Print AS String
STORE .F. TO l_cancel, l_gotReq
* Turn on global "Notices being reprinted" flag
pl_RepNotc = .F.
pl_BatchNot=.f.
IF TYPE("mv") = "U"
	PUBLIC mv
	mv = ""
ENDIF
_SCREEN.MOUSEPOINTER= 11
 l_test=.f.


WAIT WINDOW "Retrieving  Notices for MD courts. Please wait..." NOWAIT NOCLEAR
oMed = CREATEOBJECT("generic.medgeneric")

IF OpenMDNotice(d_date)
	SELECT PickNotc
ENDIF
WAIT CLEAR

*IF l_test 


IF EOF()
	*gfmessage("There are no MD Notices to print.")
	RETURN
ENDIF


SELECT PickNotc
SCAN
	SCATTER MEMVAR	
	IF l_cancel
		RETURN
	ENDIF
	_SCREEN.MOUSEPOINTER= 11
	C_STR =" EXEC [dbo].[GetMasterByclcode] '" + fixquote(PickNotc.cl_code) + "'"
	l_gotmaster=oMed.sqlexecute(C_STR,"Master")

	IF NOT l_gotmaster
		WAIT CLEAR
		gfmessage(" Cannot open tblmaster to print MD Notices. Contact IT dept.")
		RETURN
	ENDIF

	PN_TAG=PickNotc.tag
	STORE .F. TO pl_GotCase
	DO gfGetCas
	WAIT WINDOW "Printing Notices for the RT# "  + pc_lrsno NOWAIT NOCLEAR
	
	C_STR =" EXEC [dbo].[GetRequestByMasterId] '" + MASTER.id_tblmaster + "'"
	l_gotReq=oMed.sqlexecute(C_STR,"Request")

	IF NOT l_gotReq
		WAIT CLEAR
		gfmessage(" Cannot open tblRequest to print MD Notices. Contact IT dept.")
		RETURN
	ENDIF
	
	IF  FILE('C:\TEMP\Tmpnot.dbf')	AND USED('TmpNot')		
		SELECT Tmpnot
		USE
		DELETE FILE "C:\TEMP\TMPNOT.DBF"
	ENDIF

		pl_NoFaxNotice=.T.		&&4/20/15-  -PRINT ALL md FOR NOW
		
	     DO thenotic WITH .f.,ALLTRIM( m.user_code), IIF(ISNULL( m.txn_date),{  /  /    },;
		IIF(TYPE("m.txn_date")="C",CTOD(m.txn_date),CTOD(DTOC(m.txn_date)))), .F.
		
	&& 4/29/15- print filings for a case here 	
		C_CL =PC_CLCODE		
		WAIT WINDOW "MD Set for Rt#"  + pc_lrsno NOWAIT NOCLEAR
		DO MDFiling WITH   d_date, C_CL
		C_CL=""
	&& 4/29/15- print filings for a case here 	
	SELECT PickNotc
ENDSCAN
*endif
* Turn off global "Notices being reprinted" flag
pl_NoFaxNotice=.F.
gfmessage("The MD Notices have been sent to the RPS Server.")


RELEASE mv, arntc


	
RETURN
******************************************************************************************
PROCEDURE OpenMDNotice
	PARAMETERS ld_date
	LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING, c_Alias AS STRING
	c_Alias=ALIAS()

	STORE .F. TO l_RetVal, l_done,pl_SpecRpsSrv, pl_UpdHoldReqst
	pc_BatchRq=""	
	
IF  ALLTRIM(goApp.CurrentUser.orec.LOGIN) ='ELLEN'
	C_STR="Exec [dbo].[EndDayMDNoticestest] '" + DTOC(ld_date) + "'"
ELSE
	C_STR="Exec [dbo].[EndDayMDNotices] '" + DTOC(ld_date) + "'"
ENDIF
	l_done=oMed.sqlexecute(C_STR, "PickNotc")
	IF l_done THEN
		l_RetVal=.T.
		=CURSORSETPROP("KeyFieldList", "Cl_code, USER_CODE", "PickNotc")
		INDEX ON ALLTRIM(user_code)+ALLTRIM(cl_code) FOR .NOT.PRINTED TAG TOPRINT ADDITIVE
		INDEX ON ALLTRIM(user_code)+ALLTRIM(cl_code) TAG Reprint ADDITIVE
		INDEX ON cl_code TAG  cl_code UNIQUE ADDITIVE

	ENDIF


	SELECT (c_Alias)
	RETURN l_RetVal

************
*************************************************************************
PROCEDURE GetCase
** Gets data regarding selected case/tag
*************************************************************************
PARAMETERS c_client

PRIVATE c_Alias, c_Order1, c_order2, l_Retval

c_Alias = ALIAS()
l_Retval = .T.
IF  TYPE ('oMed')<>'O'
LOCAL oMed AS OBJECT
oMed = CREATEOBJECT("generic.medgeneric")
endif
oMed.CLOSEALIAS('Master')
l_Retval =	oMed.sqlexecute(" EXEC [dbo].[GetMasterByclcode] '" + c_client + "'",'Master')

SELECT MASTER
pl_GotCase = .F.
DO gfGetCas
**Exclude test cases

c_RqAtty=fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_RqAtty, "M"
l_Retval=.T.
IF pl_testcas

	IF  ALLTRIM(goApp.CurrentUser.orec.LOGIN) ='ELLEN'
		pl_testcas=.F.
		RETURN .T.
	ENDIF


	l_Retval = .F.
	RETURN l_Retval
ENDIF






IF NOT EMPTY(c_Alias)
	SELECT (c_Alias)
ENDIF

RETURN l_Retval


**************************************************************************************
PROCEDURE getmdcases
PARAMETERS   n_date
PRIVATE lc_Alias	,  l_req AS Boolean, C_STR AS STRING
LOCAL oMed_md

_SCREEN.MOUSEPOINTER=11
lc_Alias = ALIAS()
l_req=.T.
C_STR =""
oMed_md = CREATEOBJECT("generic.medgeneric")
oMed_md.CLOSEALIAS('MDcases')


********************************************************************************
PROCEDURE  MDFiling
PARAMETERS  ld_Date, clCl_code
WAIT WINDOW " Print MD Filings.."  nowait
**Print Filings
C_ALIAS=ALIAS()
_SCREEN.MOUSEPOINTER=11
	SET PROCEDURE TO TA_LIB ADDITIVE	
		STORE "" TO  MV,  c_serv,  c_cov ,  c_Print
		gcCl_code =clCL_CODE
		gntag =0
		ll_Retval = GetCase (clCL_CODE  )
		IF ll_Retval   &&valid case
		    c_cov = mdfcov(ld_Date)
		    c_serv = mdservice(ld_Date,2) 		    
		    c_Print = c_cov + c_serv
		* DO addlogline  WITH  0 , clCL_CODE, "/RPSSQL/"
		 DO prtenqa WITH c_Print , "MDFiling", "1" , ""	
		ENDIF
	
_SCREEN.MOUSEPOINTER=0
IF !EMPTY(C_ALIAS)
SELECT (C_ALIAS)
ENDIF