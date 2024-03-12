**FUNCTION GetCAAfftype
PARAMETERS  c_dept, c_cert, l_FormExt, l_Default, l_UseA
LOCAL lc_template as String

IF EMPTY(c_cert)
* Determine which form is to be used by dept type (old way)
	lc_template = ""
	DO CASE
	CASE c_dept = "R"
		DO CASE
		CASE l_Default
			lc_template = "CARadAff" + IIF( l_UseA, "_A", "")
		CASE l_FormExt
			lc_template = "CACivRadAff"
		ENDCASE
	CASE c_dept = "P"
		DO CASE
		CASE l_Default
			lc_template = "CAPathAff" + IIF( l_UseA, "_A", "")
		CASE l_FormExt
			lc_template = "CACivPathAff"
		ENDCASE
	OTHERWISE
		DO CASE
		CASE l_Default
			lc_template = "CAAffidavit" + IIF( l_UseA, "_A", "")
		CASE l_FormExt
			lc_template = "CACivRecAffid"
		ENDCASE
	ENDCASE
ELSE
	lc_template = ""
	DO CASE
	CASE c_cert= "X"
		DO CASE
		CASE l_Default
			lc_template = "CARadAff" + IIF( l_UseA, "_A", "")
		CASE l_FormExt
			lc_template = "CACivRadAff"
		ENDCASE
	CASE c_cert = "P"
		DO CASE
		CASE l_Default
			lc_template = "CAPathAff" + IIF( l_UseA, "_A", "")
		CASE l_FormExt
			lc_template = "CACivPathAff"
		ENDCASE
	OTHERWISE
		DO CASE
		CASE l_Default
			lc_template = "CAAffidavit" + IIF( l_UseA, "_A", "")
		CASE l_FormExt
			lc_template = "CACivRecAffid"
		ENDCASE
	ENDCASE





ENDIF

RETURN lc_template
