*PROCEDURE NoRqLtr
****EF : 10/31/16- a replacment for a Request Cover Letter - non-programmed courts subp issues
*** added as a part of the #51529 project 
*** RPS Documents used: NoRqltr.doc
************************************************************************
PARAMETERS n_request
PRIVATE  lc_Alias, n_tag, c_Clcode , mv_var 
STORE "" TO mv_var , c_Clcode, lc_Alias 
n_tag=0
LOCAL omednot AS OBJECT
lc_Alias = ALIAS()
omednot = CREATEOBJ("generic.medgeneric")
c_Clcode=fixquote(pc_clcode)
n_tag = IIF( pl_Reissue, pn_SuppTo, pn_Tag)

	DO PrintGroup WITH mv_var, "NoRqLetter"	
	
	DO PrintField WITH mv_VAR, "RequestDate",  DTOC(DATE())
	
	DO PrintField WITH mv_var, "Loc", IIF( pl_ofcPgh, "P", pc_offcode)	
	DO PrintField WITH mv_var, "Tag", STR(n_tag)
	DO PrintGroup WITH mv_var, "Case"
	DO PrintField WITH mv_var, "LRS", pc_lrsno
	DO PrintField WITH mv_var, "Name", pc_plnam
	DO PrintField WITH mv_var, "Plaintiff", ALLTRIM( pc_plcaptn)
	DO PrintField WITH mv_var, "Defendant", ALLTRIM( pc_dfcaptn)
	DO PrintField WITH mv_var, "Court",PROPER( pc_Court1 )
	DO PrintField WITH mv_var, "Term", pd_term
	DO PrintField WITH mv_var, "Docket", ALLTRIM( pc_docket)

	DO PrintGroup WITH mv_var, "Contact"
	DO PrintField WITH mv_var, "Name", pc_amgr_nm
	DO PrintField WITH mv_var, "Phone", pc_amgr_ph

RELEASE omednot
IF NOT EMPTY(lc_Alias)
SELECT (lc_Alias)
ENDIF

*DO PRTENQA WITH mv_var, MCLASS, IIF( EMPTY(MGROUP), "1", MGROUP), ""
RETURN mv_var
