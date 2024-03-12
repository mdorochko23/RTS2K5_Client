PROCEDURE WcabRqst
****EF : 04/23/12 
*** Generates a last page in the WCAB subp KOP requests
*** RPS Documents used: WCABRequest=wcabrq.doc
************************************************************************
PARAMETERS lcAtty
PRIVATE lc_RqAtType, lc_Alias, n_tag, c_FaxCode, l_AMFaxCode AS Boolean, c_Clcode as String
lc_Alias = ALIAS()
STORE "" TO c_FaxCode, c_Clcode, lc_Alias, lc_RqAtType
LOCAL omednot AS OBJECT
omednot = CREATEOBJ("generic.medgeneric")
c_Clcode=fixquote(pc_clcode)


n_tag = IIF( pl_Reissue, pn_SuppTo, pn_Tag)
l_done=omednot.sqlexecute("Exec dbo.GetCaseTagNotice " + c_Clcode + ",'" + STR(n_tag) + "'", "PsNotice")

IF l_done

	SELECT PSNotice

	
	DO PrintGroup WITH mv, "WCABRequest"	
	DO PrintField WITH mv, "RequestDate",  PSNotice.txn_date

		c_FaxCode="P"
		IF ALLTRIM(pc_litcode) ="C"
			l_AMFaxCode= GetAMFaxCode (pc_amgr_id)
			IF l_AMFaxCode
				c_FaxCode=IIF((ISNULL(AMFax.RpsAMFaxCode) OR EMPTY(AMFax.RpsAMFaxCode)), 'P', AMFax.RpsAMFaxCode)
			ENDIF

		ENDIF




	DO PrintField WITH mv, "FaxLoc", IIF( pl_ofcPgh, "P", c_FaxCode)
	DO PrintField WITH mv, "Loc", IIF( pl_ofcPgh, "P", pc_offcode)

	pl_GetAt = .F.
	DO gfAtInfo WITH lcAtty
	DO PrintGroup WITH mv, "Atty"
	DO PrintField WITH mv, "Name_inv", UPPER( pc_AtySign)
	DO PrintField WITH mv, "Ata1", pc_AtyFirm
	DO PrintField WITH mv, "Ata2", pc_Aty1Ad
	DO PrintField WITH mv, "Ata3", pc_Aty2Ad
	DO PrintField WITH mv, "Atacsz", pc_Atycsz
	DO PrintField WITH mv, "Phone", pc_AtyPhn
	DO PrintField WITH mv, "FaxNo", pc_AtyFax
	DO PrintField WITH mv, "AttyType", IIF( TABills.CODE = "P", "P", "D")


	DO PrintGroup WITH mv, "Case"
	DO PrintField WITH mv, "LRS", pc_lrsno
	DO PrintField WITH mv, "Name", pc_plnam
	DO PrintField WITH mv, "Plaintiff", ALLTRIM( pc_plcaptn)
	DO PrintField WITH mv, "Defendant", ALLTRIM( pc_dfcaptn)
*  Print Req atty
	pl_GetAt = .F.
	DO gfAtInfo WITH pc_rqatcod
	DO PrintField WITH mv, "AttyName", pc_AtySign
	lc_RqAtType = IIF( pl_plisrq, "Plaintiff", "Defendant")
	DO PrintField WITH mv, "AttyType", IIF( lc_RqAtType = "Defendant", "D", "P")
	DO PrintField WITH mv, "Court",PROPER( pc_Court1 )

	DO PrintField WITH mv, "Term", pd_term
	DO PrintField WITH mv, "Docket", ALLTRIM( pc_docket)

	DO PrintGroup WITH mv, "Contact"
	DO PrintField WITH mv, "Name", pc_amgr_nm
	DO PrintField WITH mv, "Phone", pc_amgr_ph

ELSE
	gfmessage("There is no record for this tag in the notices file.")
ENDIF
RELEASE omednot
IF NOT EMPTY(lc_Alias)
SELECT (lc_Alias)
ENDIF
RETURN
