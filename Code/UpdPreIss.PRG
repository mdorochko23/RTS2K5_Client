********************update request with an origibal pre-issue status/data.
*PROCEDURE UpdPreIss
PARAMETERS cstep,cdesc, cclcode, ntagnum, cUser, ct_today
LOCAL o_med as Object, C_STR as String, l_TagCntUpd as Boolean
LOCAL l_Retval AS Boolean, n_oldTag AS INTEGER, c_Alias AS STRING
o_Med = CREATEOBJECT("generic.medgeneric")
c_Alias=ALIAS()
C_STR=""
STORE .f. to l_TagCntUpd,l_Retval
IF FILE("IfCancel")
SELECT IfCancel
IF IfCancel.ACTION="U" AND TBLName ="Record"
	l_Retval= .T.
	C_STR="Update tblRequest set req_date = NULL, " ;
		+ "status='T', mailid_no = null, descript ='" + fixquote(cdesc) + "'" ;
		+ " Where cl_code = '" + fixquote(cclcode) + "' AND " + ;
		+ "  Tag = '" + STR(ntagnum) +"' and deleted is null"
ELSE

	C_STR="update tblRequest  set active=0, status='T', deleted='"+ct_today+"', "+;
		"deletedby='"+cstep+" CANCELED BY "+ALLTRIM(cUser)+"'"+ ;
		" where cl_code='"+fixquote(cclcode)+"' and tag ='"+STR(ntagnum)+"'"
ENDIF
l_Retval= o_Med.sqlexecute(C_STR,"")
C_STR=""
IF l_Retval
	IF IfCancel.ACTION="D" AND INLIST(TBLName,"Record", "Request")
		n_oldTag =ntagnum-1
		C_STR= "Update tblMaster set subcnt='" +  STR(n_oldTag) + "' Where cl_code = '" + fixquote(cclcode) + "' and active =1"
		l_TagCntUpd=o_Med.sqlexecute(C_STR , "")
		IF NOT l_TagCntUpd

			gfmessage("Cannot retrieve an old Tag's Number for the case. Contact IT. ")
			RETURN
		ENDIF
	ENDIF
ENDIF
ELSE
l_Retval= .T.
ENDIF 

RELEASE o_med
SELECT (c_Alias)
RETURN l_Retval
