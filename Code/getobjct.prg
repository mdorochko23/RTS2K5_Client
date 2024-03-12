**PROCEDURE GetObjct
**MD 12/08/2005 - Modified to use "select" instead of "exec" when call sql functions
**EF 11/07/05 Switched to sql
**EF 02/10/05 Get an Objection Period for Zicam issues
*******************************************************
PARAMETERS  c_Clcode, n_tag, l_reprnt
PRIVATE c_Alias, d_IssDate
**Called: Depopts.prg, GfAllDat.prg, SetRec.prg
**Calls: gfunuse.prg, gfuse.prg
**l_reprnt=.t. -reprint
c_Alias=ALIAS()
oMed = CREATEobject("generic.medgeneric")

pn_ObjDay=0
*l_recspec = gfuse("recspec")
*SELECT RecSpec
*SET ORDER TO cltagfld

*IF  SEEK( c_Clcode + "*" + STR(n_tag) + "OBJDAYS")
*pn_ObjDay = num_fld
*d_IssDate = date_fld
*ELSE
*d_IssDate = d_today
*ENDIF
*= gfunuse("recspec",l_recspec)
STORE d_null TO  pd_IssDte, pd_NotDte, pd_MailDte, pd_DueDte
c_sql="select dbo.fn_ObjDueDate('" + c_clcode + "' , '" + ALLTRIM(STR(n_tag)) + "', '" + DTOC(DATE()) + "')"
l_Obj= oMed.sqlexecute (c_sql, "ObjectData")
IF l_Obj
	d_IssDate= ObjectData.EXP
ELSE
	d_IssDate = d_today
ENDIF
c_sql="select dbo.fn_ObjDays('" + c_clcode + "', '" + STR(n_tag) + "')"
l_ObjPeriod= oMed.sqlexecute (c_sql, "ObjectPeriod")
IF l_ObjPeriod
	pn_ObjDay =ObjectPeriod.EXP
ENDIF

*l_holdreq = gfuse("Holdreq")
SELECT 0
IF USED('HoldReq')
	SELECT Holdreq
	USE
ENDIF
c_sql="Select * from tblHoldreq with (nolock) where cl_code = '" + c_clcode + "' AND Tag = '" + ALLTRIM(STR(n_tag)) +"' and active=1"
ln_Result=oMed.sqlexecute(c_sql,"HoldReq")

IF ln_Result
	IF NOT EOF()
		SELECT Holdreq
*SET ORDER TO cltag
*IF SEEK (c_Clcode+STR(n_tag))
		pd_IssDte=issue_date
		pd_MailDte= notic_date
		pd_DueDte =due_date
		pd_ObjDte =Objct_date
	ELSE

		IF l_reprnt
			pd_IssDte=d_IssDate
			pd_MailDte= d_IssDate
			pd_DueDte =gfChkDat(d_IssDate+10,.F.,.F.)
			pd_ObjDte =d_null
		ENDIF
	ENDIF
ELSE
	=gfmessage("cannot get HoldReq data")
*--	=MESSAGEBOX("cannot get HoldReq data",16, "GrtObjct module")
*= gfunuse("Holdreq",l_holdreq)
ENDIF 

	SELECT (c_Alias)

	RETURN
