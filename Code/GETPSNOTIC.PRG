
PARAMETERS c_client
LOCAL l_RetVal AS Boolean, l_done AS Boolean, C_STR AS STRING
oMed = CREATEOBJECT("generic.medgeneric")
c_Clcode=oMed.cleanstring(c_client)
STORE .F. TO l_RetVal, l_done
C_STR=" exec [dbo].[GetPSNoticesbyClcode] " + c_Clcode
l_done=oMed.sqlexecute(C_STR, "PSnotice")
IF l_done THEN


	IF USED("PSnotice") AND  TYPE("pc_TgNotice")="C"
		SELECT PSnotice
		DELETE ALL FOR TYPE <>pc_TgNotice
		GO TOP
	ENDIF




	l_RetVal=.T.
	=CURSORSETPROP("KeyFieldList", "ID_tblPSnotice,Cl_code, USER_CODE", "PSnotice")
	INDEX ON ALLTRIM(USER_CODE)+ALLTRIM(CL_CODE) FOR .NOT.PRINTED TAG TOPRINT ADDITIVE
	INDEX ON ALLTRIM(USER_CODE)+ALLTRIM(CL_CODE) TAG REPRINT ADDITIVE
	INDEX ON CL_CODE TAG CL_CODE ADDITIVE

ENDIF
RETURN l_RetVal




