*PROCEDURE NotcBatch
***  KOP END-of-DAY notices program(not civil authorization and subpoenas, also exclude Risperdal auths)
********************************************************************************
** EF 06/21/11- added to print KOP/non Civil Notices
*********************************************************************************
PARAMETERS d_date, c_type
LOCAL l_cancel AS Boolean, l_gotReq AS Boolean, oMed_N as Object
STORE .F. TO l_cancel, l_gotReq
* Turn on global "Notices being reprinted" flag
pl_RepNotc = .F.
IF TYPE("mv") = "U"
	PUBLIC mv
	mv = ""
ENDIF
_SCREEN.MOUSEPOINTER= 11

WAIT WINDOW "Retrieving Notices. Please wait..." NOWAIT NOCLEAR
oMed_N  = CREATEOBJECT("generic.medgeneric")

IF BatchNotice(d_date, c_type)
	SELECT PickNotc
ENDIF
WAIT CLEAR
IF EOF()
	gfmessage("There are no Notices to print!")
	RETURN
ENDIF
**clean the old one
	IF  FILE('C:\TEMP\Tmpnot.dbf')	AND USED('TmpNot')		
		SELECT Tmpnot
		USE
		DELETE FILE "C:\TEMP\TMPNOT.DBF"
	ENDIF
**clean the old one

pl_BatchNot=.t.


SELECT PickNotc
SCAN
	SCATTER MEMVAR
	IF l_cancel
		RETURN
	ENDIF
	_SCREEN.MOUSEPOINTER= 11
	oMed_N.closealias("Master")
	C_STR =" EXEC [dbo].[GetMasterByclcode] '" + fixquote(PickNotc.cl_code) + "'"
	l_gotmaster=oMed_N.sqlexecute(C_STR,"Master")

	IF NOT l_gotmaster
		WAIT CLEAR
		gfmessage(" Cannot open tblmaster to print KOP Notices. Contact IT dept.")
		RETURN
	ENDIF

	STORE .F. TO pl_GotCase
	DO gfGetCas
	WAIT WINDOW "Printing Notices for the RT# "  + pc_lrsno NOWAIT NOCLEAR
	oMed_N.closealias("Request")
	C_STR =" EXEC [dbo].[GetRequestByMasterId] '" + MASTER.id_tblmaster + "'"
	l_gotReq=oMed_N.sqlexecute(C_STR,"Request")

	IF NOT l_gotReq
		WAIT CLEAR
		gfmessage(" Cannot open tblRequest to print kop Notices. Contact IT dept.")
		RETURN
	ENDIF
	
	
	DO thenotic WITH .f.,ALLTRIM( m.user_code), IIF(ISNULL( m.txn_date),{  /  /    },;
		IIF(TYPE("m.txn_date")="C",CTOD(m.txn_date),CTOD(DTOC(m.txn_date)))), .F.

	SELECT PickNotc
ENDSCAN
**clean the old one
	IF  FILE('C:\TEMP\Tmpnot.dbf')	AND USED('TmpNot')		
		SELECT Tmpnot
		USE
		DELETE FILE "C:\TEMP\TMPNOT.DBF"
	ENDIF
**clean the old one
_SCREEN.MOUSEPOINTER=0
RELEASE mv, arntc, oMed_N, pl_BatchNot
* Turn off global "Notices being reprinted" flag

gfmessage("The Notices have been generated and sent to the RPS Servers.")
	
RETURN
******************************************************************************************
PROCEDURE BatchNotice
	PARAMETERS ld_date, lc_type
	LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING, c_Alias AS STRING, oMed_N2 as Object
	c_Alias=ALIAS()
	oMed_N2  = CREATEOBJECT("generic.medgeneric")

	STORE .F. TO l_RetVal, l_done, pl_SpecRpsSrv
	pc_BatchRq=""
	C_STR="Exec [dbo].[GetKOPBatchNotices] '" + DTOC(ld_date) + "','" + lc_type + "'"

	l_done=oMed_N2.sqlexecute(C_STR, "PickNotc")
	IF l_done THEN
		l_RetVal=.T.
		=CURSORSETPROP("KeyFieldList", "Cl_code, USER_CODE", "PickNotc")
		INDEX ON ALLTRIM(user_code)+ALLTRIM(cl_code) FOR .NOT.PRINTED TAG TOPRINT ADDITIVE
		INDEX ON ALLTRIM(user_code)+ALLTRIM(cl_code) TAG Reprint ADDITIVE
		INDEX ON cl_code TAG  cl_code UNIQUE ADDITIVE

	ENDIF

RELEASE oMed_n2
	SELECT (c_Alias)
	RETURN l_RetVal



