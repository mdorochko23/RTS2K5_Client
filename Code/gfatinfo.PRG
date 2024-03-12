PROCEDURE gfAtInfo
*
*   Collects critical information about an atty from taatty.dbf ,
*   and stores it in global variables (defined in Public.prg) for common use.
*
*
* ***************************************************************************
*   Called by Subp_CA, CourtSet, FinBIll, PlNotice, Subp_PA
* ****************************************************************************
***06/29/11 EF -Added pc_AtState
***01/23/06 EF -Add Title to the atty's name
***12/2/05  EF -Use Fax_no instead of Fax
****///////////*********////////////***************////////////*********///////
*  07/22/04 DMA Pre-format phone and fax numbers for printing
*  08/01/03 DMA Change to avoid two spaces when no initial.
*  07/22/03 EF  Original coding
*
******************************************************************************
PARAMETERS lcAtty,c_type
IF PCOUNT()<2
	c_type="M"
ENDIF

LOCAL pn_AtyRec, lcAlias, omedA  AS OBJECT
lcAlias = ALIAS()
IF pl_GetAt
	RETURN
ENDIF

STORE "" TO pc_AtyName, pc_AtyFirm, pc_Aty1Ad, pc_Aty2Ad, pc_Atycsz, ;
	pc_AtyPhn, pc_AtyFax, pc_AtySign,pc_AtyAttn, pc_AtState

omedA=CREATEOBJECT("medgeneric")

c_sql = "exec dbo.getAttyInfoByAtCodeAndAddType '&lcatty.','&c_type.'"
omedA.sqlexecute( c_sql,'taatty')



omedA.sqlexecute("select dbo.gfAtName2('&lcatty.') AS name", "attyname")

omedA.sqlexecute("SELECT name_inv FROM tbldefendant WHERE at_code='&lcatty.'", "inv")
IF USED('taatty')
	IF RECCOUNT('taatty')>0

		pc_AtyName= ALLTRIM(attyname.NAME)+ IIF( NOT EMPTY( TAAtty.TITLE), ", " + TAAtty.TITLE, "")
		pc_AtySign = ALLTRIM( inv.Name_inv)
		pc_AtyFirm = ALLTRIM( TAAtty.printable_Firm)
		pc_Aty1Ad = ALLTRIM( TAAtty.Add1)
		pc_Aty2Ad = ALLTRIM( TAAtty.Add2)
		pc_AtState=ALLTRIM( TAAtty.State)
		pc_Atycsz = ALLTRIM( TAAtty.City) + ;
			", " + ALLTRIM( TAAtty.State) + "  " + ALLTRIM( TAAtty.Zip)
		pc_AtyPhn = TRANSFORM( TAAtty.Phone, pc_fmtphon)
		pc_AtyAttn=ALLTRIM(TAAtty.Attention)
		IF LEN(ALLTRIM(TAAtty.fax_no))=10
			pc_AtyFax = TRANSFORM( TAAtty.fax_no, pc_fmtphon)
		ELSE
			pc_AtyFax=""
		ENDIF

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


