*PROCEDURE EmailNot
***KOP Risperdal END-of-DAY notices program
********************************************************************************
***EF 03/04/11- email Risperdal/PCCP Notices
*********************************************************************************
PARAMETERS d_date
LOCAL l_cancel AS Boolean,  oRequest as Object, n_gotmaster as Integer, n_gotReq as Integer
STORE .F. TO l_cancel, l_gotReq
STORE 0 TO n_gotmaster, n_gotReq
* Turn on a global "Notices being reprinted" flag
pl_RepNotc = .F.
IF TYPE("mv") = "U"
	PUBLIC mv
	mv = ""
ENDIF


oRequest=CREATEOBJECT("Litigation.medlitigation")
_SCREEN.MOUSEPOINTER= 11

WAIT WINDOW "Retrieving Notices. Please wait..." NOWAIT NOCLEAR


IF OpenNotice(d_date)
	SELECT PickNotc
ENDIF
WAIT CLEAR
IF EOF()
	gfmessage("There are no Notices to send.")
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
	n_gotmaster=oRequest.directsqlconnect(C_STR,"Master")

	IF  n_gotmaster=0  
		WAIT CLEAR
		gfmessage(" Cannot open tblmaster to generate the Risperdal KOP Notices. Contact IT dept.")
		RETURN
	ENDIF
	
	IF  EMPTY(NVL(Master.CL_CODE,""))
		WAIT CLEAR
		gfmessage("One of the cases is not found or marked as test. Check the cases and try again.")
		RETURN
	ENDIF
	

	STORE .F. TO pl_GotCase
	DO gfGetCas
	WAIT WINDOW "Printing Notices for the RT# "  + pc_lrsno NOWAIT NOCLEAR
	
	C_STR =" EXEC [dbo].[GetRequestByMasterId] '" + MASTER.id_tblmaster + "'"
	n_gotReq=oRequest.directsqlconnect(C_STR,"Request")

	IF n_gotReq=0 OR EOF()
		WAIT CLEAR
		gfmessage(" Cannot open tblRequest to print the Risperdal KOP Notices. Contact IT dept.")
		RETURN
	ENDIF
	STORE .F. TO pl_StopPrtIss, pl_UpdHoldReqst  

	DO thenotic WITH .f.,ALLTRIM( m.user_code), IIF(ISNULL( m.txn_date),{  /  /    },;
		IIF(TYPE("m.txn_date")="C",CTOD(m.txn_date),CTOD(DTOC(m.txn_date)))), .F.

	SELECT PickNotc
ENDSCAN
_SCREEN.MOUSEPOINTER=0
RELEASE mv, arntc, oRequest
* Turn off global "Notices being reprinted" flag

gfmessage("The Notices have been generated.")
	
RETURN
******************************************************************************************
PROCEDURE OpenNotice
	PARAMETERS lc_date
	LOCAL l_RetVal AS Boolean, n_done AS Integer, C_STR AS STRING, c_Alias AS STRING
	c_Alias=ALIAS()
	LOCAL oRequest2 as Object
	STORE .F. TO l_RetVal,  pl_SpecRpsSrv
	STORE "" TO pc_BatchRq, C_STR
	STORE 0 TO n_done
	oRequest2=CREATEOBJECT("Litigation.medlitigation")
	C_STR="Exec [dbo].[GetRisperdalNotices] '" + lc_date + "'"

	n_done=oRequest2.directsqlconnect(C_STR, "PickNotc")
	IF n_done=1 AND NOT EOF() THEN
		SELECT PickNotc
		l_RetVal=.T.
		=CURSORSETPROP("KeyFieldList", "Cl_code, USER_CODE", "PickNotc")
		INDEX ON ALLTRIM(user_code)+ALLTRIM(cl_code) FOR .NOT.PRINTED TAG TOPRINT ADDITIVE
		INDEX ON ALLTRIM(user_code)+ALLTRIM(cl_code) TAG Reprint ADDITIVE
		INDEX ON cl_code TAG  cl_code UNIQUE ADDITIVE

	ENDIF

	RELEASE oRequest2
	SELECT (c_Alias)
	RETURN l_RetVal



