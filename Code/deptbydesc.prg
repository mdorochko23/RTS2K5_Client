**Function DeptbyDescription
PARAMETERS cDescript
LOCAL lc_deptype as String, oMed_dept as Object, C_SQL AS String
c_alias =ALIAS()
lc_deptype="Z"
oMed_dept = CREATEOBJECT("generic.medgeneric")
IF NOT pl_CaVer
	DO CASE
	CASE "(CATH)" $ UPPER(ALLT(cDescript))
		lc_deptype = "C"
		*pc_MAttn="ATTN: ECHOCARDIOGRAM DEPARTMENT"
	CASE "(ECHO)" $ UPPER(ALLT(cDescript))
		lc_deptype = "E"
		*pc_MAttn="ATTN: ECHOCARDIOGRAM DEPARTMENT"
	CASE "(RAD)" $ UPPER(ALLT(cDescript))
		lc_deptype= "R"
		*pc_MAttn="ATTN: RADIOLOGY DEPARTMENT"
	CASE "(PATH)" $ UPPER(ALLT(cDescript))
		lc_deptype = "P"
		*pc_MAttn= "ATTN: PATHOLOGY DEPARTMENT"
	CASE "(BILL)" $ UPPER(ALLT(cDescript)) OR ;
			"(BILLING)" $ UPPER(ALLT(cDescript))
		lc_deptype = "B"
		*pc_MAttn=  "ATTN: BILLING DEPARTMENT"
	CASE "(MED)" $ UPPER(ALLT(cDescript))
		lc_deptype= "M"
		*pc_MAttn=	"ATTN: MEDICAL RECORDS DEPARTMENT"
	OTHERWISE
		lc_deptype = "Z"
		*pc_MAttn=""
	ENDCASE
ELSE

IF  (lc_deptype="Z" or pc_deptype ="H")
	  **04/22/2010 - ca OFFICE MAY NOT HAVE A DEPT IN A DESCRIP LINE SO WE HAVE TO PULL IT FROM
	  *** THE SPEC_INS
	 	 IF NOT USED ("Spec_ins") 
	 	    C_SQL="Exec [dbo].[GetSpecInsByClCodeTag]  '" + ;
			FIXQUOTE(pc_clcode) + "', '" + ALLTRIM(STR(PN_TAG)) + "'"
			oMed_dept.SQLEXECUTE (C_SQL, "Spec_ins")
	 	 ENDIF	 	 
	 SELECT SPEC_INS
	 IF NOT EOF()
	 	lc_deptype= ALLTRIM(SPEC_INS.DEPT) 
 	 ENDIF
ENDIF
ENDIF





IF NOT EMPTY(c_alias)
SELECT (c_alias)
ENDIF
RELEASE oMed_dept
RETURN lc_deptype