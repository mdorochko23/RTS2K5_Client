PROCEDURE PlNotice
****02/29/2012 - EF  - removed "AND PC_LITCODE='C  '" as the same USDC form will be used for all KOP lit cases
****09/17/09   - EF  - all usdc courts follow teh same rule
*** 03/23/2009 - EF  - USDC Court TEXT
*** 04/14/2008 - EF  - Added AM Fax number
*** 12/02/2005 - EF  - Switched to SQL
*****************************************************************************
*** 07/22/2004 - DMA - Eliminate unused parms; ensure that tag # is not reset
*** 01/21/2004 - EF - Add 'Atty for:' line
*** 08/29/2003 - EF - Print Req Atty
*** 08/26/2003 - EF - Add scanned signature of client representative
*** 08/12/2003 - EF - Print a HIPAA Plaintiff Notice for Civil Lit Cases
*** Calls: gfatinfo
*** Called from : Subp_PA.prg
*** Assumes that gfGetCas, gfGetDep have already been called
*** RPS Documents used: PlNotHIPAA
************************************************************************
PARAMETERS lcAtty
PRIVATE lc_RqAtType, lc_Alias, n_tag, c_FaxCode, l_AMFaxCode AS Boolean
*--- 08/14/2018 MD #98879 Do not print for ABl/MDL
IF ALLTRIM(UPPER(pc_LitCode))=="ABL" AND ALLTRIM(UPPER(pc_Area))="MDL"
   RETURN
ENDIF   
lc_Alias = ALIAS()
LOCAL omednot AS OBJECT
omednot = CREATEOBJ("generic.medgeneric")
c_Clcode=oMednot.cleanstring(pc_clcode)


n_tag = IIF( pl_Reissue, pn_SuppTo, pn_Tag)
l_done=omednot.sqlexecute("Exec dbo.GetCaseTagNotice " + c_Clcode + ",'" + STR(n_tag) + "'", "PsNotice")

IF l_done

	SELECT PSNotice

	IF pl_Njsub OR pl_ILCook&& NJ pl notice designed by Alec and Co. on 7/7/2011
		DO PrintGroup WITH mv, "NJPlNotice"
	ELSE

		DO PrintGroup WITH mv, IIF(( LEFT( ALLTRIM(pc_Court1), 4) = "USDC"  AND NOT pl_CAVer),"USDCPlNot","PlNotHIPAA")
	ENDIF

	DO PrintField WITH mv, "Loc", IIF( pl_ofcPgh, "P", pc_offcode)
	DO PrintField WITH mv, "DueDate",  PSNotice.due_date
	DO PrintField WITH mv, "DepDate",  PSNotice.due_date
	DO PrintField WITH mv, "RequestDate",  PSNotice.txn_date
**4/14/08 -added AM Fax Number form civil lit cases only -start
	IF  pl_KOPVer
		c_FaxCode="P"
		IF ALLTRIM(pc_litcode) ="C"
			l_AMFaxCode= GetAMFaxCode (pc_amgr_id)
			IF l_AMFaxCode
				c_FaxCode=IIF((ISNULL(AMFax.RpsAMFaxCode) OR EMPTY(AMFax.RpsAMFaxCode)), 'P', AMFax.RpsAMFaxCode)
			ENDIF

		ENDIF
	ELSE
		c_FaxCode=pc_offcode
	ENDIF
**4/14/08 -added AM Fax Number form civil lit cases only-end



	DO PrintField WITH mv, "FaxLoc", IIF( pl_ofcPgh, "P", c_FaxCode)



	DO PrintField WITH mv, "GroupName", ;
		IIF( pl_nogroup, "", PROPER( pc_grpname))
	DO PrintField WITH mv, "GCaseName", ;
		IIF( pl_nogroup, "", PROPER( pc_casname))
	DO PrintField WITH mv, "CaseNum", ;
		IIF( pl_nogroup, "", PROPER( pc_casenum))


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
**09/05/2013 - use Court's description for all courts!
**05/19/11- print just court's name on all the pl notices
**3/23/09- USDC TEXT
*!*		IF (LEFT( ALLTRIM(pc_Court1), 4) = "USDC"  AND NOT pl_CAVer  )
		DO PrintField WITH mv, "Court", PROPER( pc_c1Desc)
*!*	*	DO PrintField WITH mv, "Court", PROPER(ALLT(  pc_distrct)) + " District of " + getstatename(pc_c1State)
*!*		ELSE
*!*			DO PrintField WITH mv, "Court", IIF(pl_ILCook, ALLTRIM(pc_c1Desc),PROPER( pc_Court1 ))
*!*		ENDIF


	LOCAL c_term as String
	c_term=""
	&&08/29/13 - use month year per Liz 
	c_term=termdate(pd_term)	
	DO PrintField WITH mv, "Term", c_term
	*DO PrintField WITH mv, "Term", pd_term
	DO PrintField WITH mv, "Docket", ALLTRIM( pc_docket)

	DO PrintGroup WITH mv, "Contact"
	DO PrintField WITH mv, "Name", pc_amgr_nm
	DO PrintField WITH mv, "Phone", pc_amgr_ph
* 08/26/03 Print the client representative's scanned signature
	DO PrintField WITH mv, "Id", pc_ScanSg
ELSE
	gfmessage("There is no record for this tag in the notices file.")
ENDIF
RELEASE omednot
SELECT (lc_Alias)
RETURN
