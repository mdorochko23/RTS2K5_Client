**FUNCTION TXN44_2RQ
**EF 10/07/05 - adds entry into the tblTimesheet and tblComment
PARAMETERS cDESCRIPT, ccl_code, ntxn, ntag, cmailid_no, ctype, clogin ,	cid, lcdept,lSpecInst
**lCommOk : .f./.t. add a record to a special instruction table
LOCAL C_STR AS STRING, l_done AS Boolean, l_EntryID AS Boolean, l_ok AS Boolean, c_request AS STRING
IF INLIST(ALLTRIM(goApp.CurrentUser.ntlogin) ,"ELLEN", "MARINA")
	WAIT WINDOW "No txn 44 will be added." NOWAIT
	RETURN
ENDIF
STORE "" TO C_STR, c_request
oMedspec = CREATEOBJECT("generic.medgeneric")
c_Desc=fiXquote(ALLTRIM(cDESCRIPT))
C_STR= "Exec dbo.gfAddTxn '" + DTOC(DATE())+  " ', '" ;
	+ NVL(c_DESC,"") + "' ,'" + ccl_code + "',' " ;
	+ ALLTRIM(STR(ntxn)) + "','"  + ALLTRIM(STR(ntag)) + "','" ;
	+ NVL(cmailid_no,"") + "','" + STR(0) + "','" ;
	+ ALLTRIM(STR(0)) + "','" +  "" + "','" ;
	+ ALLTRIM(STR(0)) + "', '"  + "" + "','" ;
	+ ctype + "','" ;
	+ ALLTRIM(clogin) + "','" ;
	+ cid +"'"

l_done=oMedspec.sqlexecute(C_STR,"")


IF USED('EntryID')
	SELECT EntryID
	USE
ENDIF
l_EntryID= oMedspec.sqlexecute("select dbo.fn_GetID_tblTimesheet ('" + ccl_code + "','" ;
	+ STR(ntag) +"','" + STR(ntxn)+ "','" +DTOC(DATE()) +"')", "EntryId")

IF l_EntryID AND lSpecInst
	IF TYPE("pcPublicBlurb")!="C"
		pcPublicBlurb=""
	ENDIF

IF NOT USED('SPEC_INS') AND EMPTY(pcPublicBlurb)
	gfmessage("Special Instruction was not found. Check the data and try again.")
	RETURN .F.
ENDIF


	c_request= fixquote(IIF(!EMPTY(ALLTRIM(pcPublicBlurb)),pcPublicBlurb,FIXQUOTE( gfAddCR(SPEC_INS.SPEC_INST))))
**insert new specinst and edit psnotice
	IF TYPE('pc_userid')='U'
		pc_userid=ALLTRIM(GOAPP.currentuser.orec.login)
	ENDIF
	l_ok=AddSpec_ins( EntryId.EXP, ccl_code, ntag,  NVL(c_DESC,""), ctype,cmailid_no, lcdept,c_request)
	IF l_ok


		C_STR="Update tblPSnotice SET EDITED='"+ DTOC(DATE()) +"', EDITEDBY ='" + pc_UserID + "',  Spec_Inst ='" + c_request + ;
			"' Where cl_code = '" +ccl_code + "' AND" + ;
			"  Tag = '" + STR(nTAG) +"'"
		l_PSnotUpd = oMedspec.sqlexecute(C_STR,"")
		IF NOT l_PSnotUpd
			gfmessage("Special Instruction did not get to the Notices File")
		ENDIF

	ELSE
		gfmessage("Special Instruction was not stored.")

	ENDIF

	l_done=l_ok
ENDIF

RELEASE oMedspec
RETURN l_done


