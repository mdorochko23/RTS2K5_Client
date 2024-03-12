
**EF 10/20/15 - reset tag in QC

PARAMETERS lnRTnum, lnTagNum, lcord
LOCAL l_reset  AS Boolean, c_str AS STRING, l_keep7 AS Boolean, l_done AS Boolean
c_str=""
oMed = CREATEOBJECT("generic.medgeneric")
oMed.closealias("Reqtag")
oMed.closealias("Btag")
oMed.closealias("viewWitFee")
oMed.closealias("viewVoided")
c_str=" exec dbo.Getrequestbylrsno '" +lnRTnum + "','" + lnTagNum +"'"
oMed.sqlexecute(c_str,"Reqtag")
l_reset =.T. && assume we can reset
STORE .F. TO l_keep7 , l_done

*---------------------------------------------------------------------------------------------------------------------------
**1)  check if  tag was billed  already, if so - do not allow to reset
*---------------------------------------------------------------------------------------------------------------------------
IF USED("Reqtag") AND NOT EOF()
	SELECT Reqtag
	SCATTER MEMVAR
	WAIT WINDOW "Checking for billed status and any checks on a tag.. Please wait" NOWAIT NOCLEAR

	c_str="select dbo.IfTagBilled ('" + m.cl_code+ "','" + lnTagNum + "')"
	oMed.sqlexecute(c_str,"Btag")
	IF USED("Btag") AND !EOF()
		SELECT Btag
		l_reset =IIF(Btag.EXP>0,.F.,.T.)
	ENDIF
	IF !l_reset
		gfmessage( "A tag was billed. We cannot reset a billed tag." )
		RETURN .F.
	ENDIF

*---------------------------------------------------------------------------------------------------------------------------
**2)  check for active txn 7/13 -WitnessFee check
*---------------------------------------------------------------------------------------------------------------------------
	c_str="exec [dbo].[qc_CheckWFtransactions] '" + lnRTnum + "','" + lnTagNum+"'"
	oMed.sqlexecute(c_str , "viewWitFee")
	SELECT viewWitFee
	IF RECCOUNT()>0
		gfmessage( "A witness fee has been issued. First move a check to a different tag." )
		l_reset=.F.
		RETURN .F.
	ENDIF

*---------------------------------------------------------------------------------------------------------------------------
**3) : check for voided checks
*---------------------------------------------------------------------------------------------------------------------------
	c_str=""
	c_str="exec [dbo].[CheckVoidedChk] '" +lnRTnum + "','" + lnTagNum+"'"
	oMed.sqlexecute(c_str , "viewVoided")
	SELECT viewVoided
	IF RECCOUNT()>0
		gfmessage( "A tag has a voided check which we'll keep on a tag." )
		l_keep7 =.T.
	ENDIF
** Allow to reset if 1-3 returned .false.
	IF  l_reset
		IF  INLIST(lcord , 'C','L') && case level orders 

			c_str ="exec [dbo].[QC_ResetNewCase]'" + ALLTRIM(lnRTnum) + "','" + lnTagNum + "','"  ;
				+ ALLTRIM(goApp.CurrentUser.orec.LOGIN) +"'"
			oMed.sqlexecute(c_str , "")
		ENDIF



		c_str ="exec [dbo].[QC_ResetTag] '" + lnRTnum+ "','" + lnTagNum+ "','"  ;
			+ ALLTRIM(goApp.CurrentUser.orec.LOGIN) +"', " + IIF(l_keep7 =.T., STR(1), STR(0) )

		l_done=oMed.sqlexecute(c_str , "")
		IF l_done
			lc_memo ="Tag Reset by : " + ALLTRIM(goApp.CurrentUser.orec.LOGIN)
			DO addtxn4 WITH LEFT(m.descript,50), m.cl_code, 4, lnTagNum, m.mailid_no, m.type, ALLTRIM(goApp.CurrentUser.orec.LOGIN), m.id_tblrequests, lc_memo , .F.
		ENDIF
	ENDIF

ENDIF
WAIT CLEAR
RELEASE oMed

RETURN

*---------------------------------------------------------------------------------------------------------------------------
FUNCTION addtxn4
*---------------------------------------------------------------------------------------------------------------------------

PARAMETERS cDESCRIPT, ccl_code, ntxn, ntag, cmailid_no, ctype, clogin ,	cid_tblcode, cMemo, lCommOk
LOCAL c_str AS STRING, l_done AS Boolean, l_EntryID AS Boolean
c_str=""

c_Desc=oMed.cleanstring(cDESCRIPT)
c_str= "Exec dbo.gfAddTxn '" + DTOC(DATE())+  " ', " ;
	+ ALLTRIM(NVL(c_Desc,"")) + " ,'" + ccl_code + "',' " ;
	+ ALLTRIM(STR(ntxn)) + "','"  + ALLTRIM(ntag) + "','" ;
	+ NVL(cmailid_no,"") + "','" + STR(0) + "','" ;
	+ ALLTRIM(STR(0)) + "','" +  "" + "','" ;
	+ ALLTRIM(STR(0)) + "', '"  + "" + "','" ;
	+ ctype + "','" ;
	+ ALLTRIM(clogin) + "','" ;
	+ cid_tblcode +"'"

l_done=oMed.sqlexecute(c_str,"")


IF USED('EntryID')
	SELECT EntryID
	USE
ENDIF
l_EntryID= oMed.sqlexecute("select dbo.fn_GetID_tblTimesheet ('" + ccl_code + "','" ;
	+ ntag+"','" + STR(ntxn)+ "','" +DTOC(DATE()) +"')", "EntryId")
IF l_EntryID
	l_Comm=oMed.sqlexecute("Exec gfAddCom '" + DTOC(DATE())+  " ', " ;
		+ ALLTRIM(c_Desc) + ",'" + ccl_code + "',' " ;
		+ ALLTRIM(STR(ntxn)) + "','"  + ALLTRIM(ntag)+ "','" ;
		+ NVL(cmailid_no,"") + "','" + "" + "','" ;
		+ fixquote(NVL(cMemo,""))  + "','"  ;
		+ ALLTRIM(STR(0)) + "','"  ;
		+ ALLTRIM(clogin) + "','" + EntryID.EXP +"'")

	l_done=l_Comm
ENDIF

RETURN l_done

