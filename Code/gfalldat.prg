**gfAllDate
**EF 11/21/05 - Add parameters to the gfgetdep call
**EF 11/07/05 - Switch to sql
**EF 02/10/05 - Get all issue/notice related dates for a tag
**Called: subp_pa.prg
**Calls: gfChkDat.prg, GetObjct.prg
PARAMETERS n_request
**n_request=1-first
**n_request=2-second
**n_request=3-reprint

PRIVATE c_Alias,l_holdreq

oMed = CREATE("generic.medgeneric")
c_clcode=oMed.cleanstring(pc_clcode)

c_Alias=ALIAS()

IF  INLIST(n_request,2)
	pn_ObjDay=0
	STORE d_today TO  pd_IssDte, pd_NotDte, pd_MailDte
	pd_DueDte =gfChkDat(d_today+10,.F.,.F.)
	RETURN
ENDIF

IF pl_Alldate
	RETURN
ENDIF

*pl_GotDepo=.F.
*DO gfgetdep WITH pc_clcode, pn_tag

IF n_request=1
	IF pc_rqatcod = pc_platcod
		pn_ObjDay=0
	ELSE
		pn_ObjDay=IIF(pl_fromRev, 10, 5)
	ENDIF
ELSE
	DO GetObjct WITH pc_clcode, pn_tag, .T.

ENDIF


IF NOT pl_1st_Req AND pn_ObjDay<>0
*l_holdreq = gfuse("Holdreq")


	l_holdreq=oMed.sqlexecute("Exec dbo.GetHoldRequests " + c_clcode + ",'" + STR(pn_tag) + "'","HoldReq")
	IF l_holdreq
		SELECT Holdreq
*SET ORDER TO cltag
*IF SEEK (pc_clcode+STR(pn_tag))
		STORE d_null TO  pd_IssDte, pd_NotDte, pd_MailDte, pd_DueDte
		*pd_IssDte=issue_date
		*pd_MailDte= notic_date
		*pd_DueDte =due_date
		*pd_ObjDte =Objct_date
		pd_IssDte=CTOD( LEFT(DTOC(issue_date),10))
		pd_MailDte= CTOD( LEFT(DTOC(notic_date),10))
		pd_DueDte =CTOD( LEFT(DTOC(due_date),10))
		pd_ObjDte =CTOD( LEFT(DTOC(Objct_date),10))
*ENDIF
*= gfunuse("Holdreq",l_holdreq)


	ELSE
		gfmessage(" Cannot get the data from the tblHoldReq")

	ENDIF
ENDIF

IF NOT EMPTY(c_Alias)
	SELECT (c_Alias)
ENDIF

pl_Alldate=.T.
RETURN
******************************************************************
