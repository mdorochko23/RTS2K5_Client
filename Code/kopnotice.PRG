*PROCEDURE KOPnotice
***  KOP END-of-DAY notices program
********************************************************************************
** EF 03/28/07- added to print KOP/Civil Notices
*********************************************************************************
PARAMETERS d_date
LOCAL l_cancel AS Boolean, l_gotReq AS Boolean
STORE .F. TO l_cancel, l_gotReq
* Turn on global "Notices being reprinted" flag
pl_RepNotc = .F.
pl_BatchNot=.f.
IF TYPE("mv") = "U"
	PUBLIC mv
	mv = ""
ENDIF
_SCREEN.MOUSEPOINTER= 11


WAIT WINDOW "Retrieving Notices. Please wait..." NOWAIT NOCLEAR
oMed = CREATEOBJECT("generic.medgeneric")


IF OpenKOPNotice(d_date)
	SELECT PickNotc
ENDIF
WAIT CLEAR
IF EOF()
	*--9/5/18: add notice source [103895]
	gfmessage("There are no KOP Notices to print!")
	*--gfmessage("There are no Notices to print!")
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
		gfmessage(" Cannot open tblmaster to print KOP Notices. Contact IT dept.")
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
		gfmessage(" Cannot open tblRequest to print kop Notices. Contact IT dept.")
		RETURN
	ENDIF
	**clean the old one
	IF  FILE('C:\TEMP\Tmpnot.dbf')	AND USED('TmpNot')		
		SELECT Tmpnot
		USE
		DELETE FILE "C:\TEMP\TMPNOT.DBF"
	ENDIF
**clean the old one
**02/25/13- clean the IlCook Letter's atty list
oMed.closealias('CookLtr')
		*pl_NoFaxNotice=.T.		&&3/13/14- TEST -PRINT ALL CIVIL FOR NOW
	DO thenotic WITH .f.,ALLTRIM( m.user_code), IIF(ISNULL( m.txn_date),{  /  /    },;
		IIF(TYPE("m.txn_date")="C",CTOD(m.txn_date),CTOD(DTOC(m.txn_date)))), .F.
		
		

**03/11/2013 - added Court Set with a Generic PA form:	"HoldPrint" Project.	
IF checktest("HOLD_PRINT2")=.F. and pc_RpsForm="KOPGeneric" && 07/16/13 -
	 DO hsubcourt WITH d_date,  fixquote(PickNotc.cl_code) 
endif
	SELECT PickNotc
ENDSCAN
_SCREEN.MOUSEPOINTER=0
RELEASE mv, arntc
* Turn off global "Notices being reprinted" flag
pl_NoFaxNotice=.F.
	
RETURN
******************************************************************************************
PROCEDURE OpenKOPNotice
	PARAMETERS ld_date
	LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING, c_Alias AS STRING
	c_Alias=ALIAS()

	STORE .F. TO l_RetVal, l_done,pl_SpecRpsSrv, pl_UpdHoldReqst
	pc_BatchRq=""
	
	**04/23/12- include WCAB subp notices into a batch
	
	IF INLIST(UPPER( ALLTRIM( Pc_UserID)), "ELLEN")
		C_STR="Exec [dbo].[EndDayKOPCivilNoticesTEST] '" + DTOC(ld_date) + "'"
		ELSE
		C_STR="Exec [dbo].[EndDayKOPCivilNotices] '" + DTOC(ld_date) + "'"
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



