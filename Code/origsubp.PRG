
**Procedure OrigSub
**called from subp_pa.prg when a PA court subpoena is issued
PARAMETERS c_court,  n_Tag, c_dep, d_txn11
LOCAL mv_o as String, c_sql as String, omedSub as Object, c_store as String
STORE "" TO mv_o , c_sign, c_store
omedSub=CREATEOBJECT("medgeneric")
**request due date
**12/8/2016: added PA-lackawanna #54160
**09/19/2016 :  added 2nd form for the PA-bucks #48982

		**Check if old or new form by an issue date:  start
		LOCAL l_oldsub as Boolean
		l_oldsub=.t. && assume we use an old one 		

		
		l_oldsub=SubForm2( pn_lrsno , n_Tag , c_court)
		
*!*			IF 		UPPER(ALLTRIM(c_court))	="PA-BUCKSCOUNTY"
*!*				l_oldsub=SubForm( pn_lrsno ,n_Tag)		
*!*			ENDIF
*!*			
	
**09/19/2016 :  added 2nd form for the PA-bucks #48982

pl_PrtOrigSubp=.t.
c_sql="select [dbo].[getRequestDuedate] ('" + pc_clcode +"','" + STR(n_Tag) +"')"
omedSub.sqlexecute(c_sql,"ReqDate")
IF NOT EOF()
d_due=NVL(ReqDate.EXP, d_txn11)
ELSE
d_due=d_txn11
endif
WAIT WINDOW "Storing an original subpoena.. " NOWAIT 
omedSub.closealias("AttySign")
IF NOT EMPTY( pc_rqatcod)
	lc_RqAtty=fixquote(pc_rqatcod)
	omedSub.sqlexecute("SELECT name_inv FROM tbldefendant WHERE at_code='" + lc_RqAtty + "'", "AttySign")	
	c_sign = AttySign.name_inv
endif

			DO PrintGroup WITH mv_o , "Orig" + IIF(l_oldsub, UPPER(ALLTRIM(c_court))	,UPPER(ALLTRIM(c_court))+"2")	 
			DO PrintField WITH mv_o , "DeponentName", ALLTRIM(c_dep)
			DO PrintField WITH mv_o , "RequestDate",  DTOC(d_txn11)
			DO PrintField WITH mv_o , "DepDate", CTOD(LEFT(DTOC(d_due),10))
			DO PrintField WITH mv_o , "Loc", 	pc_Offcode
			DO PrintGroup WITH mv_o , "Case"			
			DO PrintField WITH mv_o, "Plaintiff",ALLTRIM(pc_plcaptn)
			DO PrintField WITH mv_o, "Defendant",  ALLT(pc_dfcaptn)
			DO PrintField WITH mv_o, "AttyType", IIF( pl_plisrq, "P", "D")
			DO PrintField WITH mv_o, "AttyName", ALLTRIM(c_sign)
			DO PrintField WITH mv_o, "Docket", pc_docket
			DO PrintField WITH mv_o, "Term", pd_term
			
			
			
	*************************************************		
			gnRPS = 0
     		gnTag = n_Tag
     		c_store=IIF(EMPTY(ALLTRIM(mclass)),"HoldSub",mclass)
     	 	mclass = "OrigSubp"
      		DO PrintEnQ IN TA_lib WITH mv_o, mclass, "2"	

	************************************************
pl_PrtOrigSubp=.f.
mclass=c_store
RELEASE omedSub
	
	RETURN  