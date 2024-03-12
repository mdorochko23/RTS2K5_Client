**PROCEDURE AtyMixed
*
* ***************************************************************************
*   Called by TX Printing modules when we need a proper cases for the Atty's data : l_mixed =.t.
******************************************************************************
PARAMETERS lcAtty,c_type, l_mixed

IF PCOUNT()<2
	c_type="M"
ENDIF

PUBLIC pc_AtyCity, pc_AtyState, pc_AtyZip	&& 6/14/2022, ZD #273584, JH

LOCAL pn_AtyRec, lcAlias, omedA  AS OBJECT
lcAlias = ALIAS()
IF pl_GetAt
	RETURN
ENDIF

STORE "" TO pc_AtyName, pc_AtyFirm, pc_Aty1Ad, pc_Aty2Ad, pc_Atycsz, ;
	pc_AtyPhn, pc_AtyFax, pc_AtySign,pc_AtyAttn, pc_AtState, ;
	pc_AtyCity, pc_AtyState, pc_AtyZip								&& 6/14/2022, ZD #273584, JH


omedA=CREATEOBJECT("medgeneric")

IF l_mixed

	c_sql = "exec dbo.getTXAtty4Docs '&lcatty.','&c_type.'"
ELSE

	c_sql = "exec dbo.getAttyInfoByAtCodeAndAddType '&lcatty.','&c_type.'"
ENDIF
omedA.sqlexecute( c_sql,'taatty')


IF l_mixed
	omedA.sqlexecute("select dbo.TxAtName4Docs('&lcatty.') AS name", "attyname")
ELSE

	omedA.sqlexecute("select dbo.gfAtName2('&lcatty.') AS name", "attyname")
ENDIF

omedA.closealias('inv')
c_sql="Exec dbo.GetDefAtName4Docs '" + fixquote(lcAtty) +"'," + IIF(l_mixed , STR(1),STR(0) )

omedA.sqlexecute(c_sql, "inv")





IF USED('taatty')
	IF RECCOUNT('taatty')>0

		pc_AtyName= ALLTRIM(attyname.NAME)+ IIF( NOT EMPTY( TAAtty.TITLE), ", " + ALLTRIM(TAAtty.TITLE) + "." , "")
		pc_AtySign = ALLTRIM( inv.Name_inv)  +IIF(l_mixed,  IIF( NOT EMPTY(ALLTRIM(TAAtty.TITLE)), ", " + ALLTRIM(PROPER(TAAtty.TITLE)) + ".", ""),"")
		pc_AtyFirm = ALLTRIM( TAAtty.printable_Firm)
		pc_Aty1Ad = ALLTRIM( TAAtty.Add1)
		pc_Aty2Ad = ALLTRIM( TAAtty.Add2)
		pc_AtState=ALLTRIM( TAAtty.State)

		IF l_mixed AND RIGHT(ALLTRIM( TAAtty.Zip) ,1) ='-'
			pc_Atycsz = ALLTRIM( TAAtty.City) + ;
				", " + ALLTRIM( TAAtty.State) + " " + LEFT(ALLTRIM( TAAtty.Zip),5)
		ELSE


			pc_Atycsz = ALLTRIM( TAAtty.City) + ;
				", " + ALLTRIM( TAAtty.State) + "  " + ALLTRIM( TAAtty.Zip)
		ENDIF

		pc_AtyPhn = TRANSFORM( TAAtty.Phone, pc_fmtphon)
		pc_AtyAttn=ALLTRIM(TAAtty.Attention)
		IF LEN(ALLTRIM(TAAtty.fax_no))=10
			pc_AtyFax = TRANSFORM( TAAtty.fax_no, pc_fmtphon)
		ELSE
			pc_AtyFax=""
		ENDIF
		pc_AtyCity = ALLTRIM( TAAtty.City)			&& 6/14/2022, ZD #273584, JH
	    pc_AtyState	= ALLTRIM( TAAtty.State)		&& 6/14
	    pc_AtyZip= ALLTRIM( TAAtty.Zip)				&& 6/14

		pl_GetAt = .T.
	ENDIF
ENDIF

IF USED('taatty')
	USE IN TAAtty
ENDIF
IF USED('attyname')
	USE IN attyname
ENDIF
IF USED('inv')
	USE IN inv
ENDIF
RELEASE omedA

IF NOT EMPTY( lcAlias)
	SELECT ( lcAlias)
ENDIF
RETURN


