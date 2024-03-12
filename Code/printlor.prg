**FUNCTION PrintLor
**Called from Subp_pa
**EF 11/30/05 -Switched to SQL
******************************************************
**EF 09/16/04 - Make variable public on a fly
**EF  Released on July 29, 2004.

PARAMETERS c_isstype
PRIVATE c_Alias, c_DocName, c_varname
LOCAL oMed2 AS OBJECT, c_firm as String, c_LOR_Refer as string
LOCAL lnLOR_fnd

c_Alias=ALIAS()

STORE "" TO c_DocName, c_Varname
pn_LORpos=0       &&note:  pn_LORpos=1 if a LOR prints before auths or 2 if after

oMed2 = CREATEOBJ("generic.medgeneric")

**
**  8/19/2021, ZD #232139, JH
**			(moved from below).
c_firm=""
oMed2.closealias("FirmLor")
C_STR= "select dbo.GetFirmCode ('" + ALLTRIM(pc_rqatcod) + "')"
l_done=oMed2.sqlexecute(C_STR,"FirmLor")
c_firm=ALLTRIM(NVL(FirmLor.exp,''))
oMed2.closealias("FirmLor")
**  8/19

&& 3/22/2022, ZD #267470, JH
lnLOR_fnd = 0
c_str = "SELECT RTSVAR,SECOND_PAGE FROM tblLOR_Refer_Firm where lit= '"+alltrim(pc_litcode)+"' and area='"+alltrim(pc_area)+ ;
"' and firm_code ='"+c_firm+"' and authtype in ('"+ALLTRIM(c_isstype)+"','*') and active=1"
l_done=oMed2.sqlexecute(C_STR,"LorReference")
SELECT LorReference
IF NOT EOF()
    lnLOR_fnd = 1
	c_LOR_Refer = ALLTRIM(LorReference.rtsvar)
	LOCAL &c_LOR_Refer as boolean
	&c_LOR_Refer = .T.
	IF second_page
		c_LOR_Refer = ALLTRIM(LorReference.rtsvar)+"2"
		LOCAL &c_LOR_Refer as boolean
		&c_LOR_Refer = .T.
	ENDIF
ENDIF
oMed2.closealias("LorReference")
&& 3/22

&& 09/02/2022, ZD #285788, JH
IF lnLOR_fnd = 0
	c_str = "SELECT RTSVAR,SECOND_PAGE FROM tblLOR_Refer_Firm where area='*' and firm_code ='"+c_firm+"' and active=1"
	l_done=oMed2.sqlexecute(C_STR,"LorReference")
	SELECT LorReference
	IF NOT EOF()
		lnLOR_fnd = 1
		c_LOR_Refer = ALLTRIM(LorReference.rtsvar)
		LOCAL &c_LOR_Refer as boolean
		&c_LOR_Refer = .T.
		IF second_page
			c_LOR_Refer = ALLTRIM(LorReference.rtsvar)+"2"
			LOCAL &c_LOR_Refer as boolean
			&c_LOR_Refer = .T.
		ENDIF
	ENDIF
	oMed2.closealias("LorReference")
ENDIF
&& 09/02

** 9/23/2020, ZD #190778, JH.
IF pl_use_LOR_Refer AND lnLor_fnd = 0
	C_STR = "SELECT RTSVAR,SECOND_PAGE FROM tblLOR_Refer where lit= '"+alltrim(pc_litcode)+"' and area='"+alltrim(pc_area)+"' and authtype in ('"+ALLTRIM(c_isstype)+"','*') and active=1"
	l_done=oMed2.sqlexecute(C_STR,"LorReference")
	SELECT LorReference
	IF NOT EOF()
		c_LOR_Refer = ALLTRIM(LorReference.rtsvar)
		LOCAL &c_LOR_Refer as boolean
		&c_LOR_Refer = .T.
		IF second_page
			c_LOR_Refer = ALLTRIM(LorReference.rtsvar)+"2"
			LOCAL &c_LOR_Refer as boolean
			&c_LOR_Refer = .T.
		ENDIF
    ELSE			&& 08/19/2021, ZD #232139, JH.
		oMed2.closealias("LorReference")
		C_STR = "SELECT RTSVAR,SECOND_PAGE FROM tblLOR_Refer where area='"+alltrim(c_firm)+"' and authtype in ('"+ALLTRIM(c_isstype)+"','*') and active=1"
		l_done=oMed2.sqlexecute(C_STR,"LorReference")
		SELECT LorReference
		IF NOT EOF()
			c_LOR_Refer = ALLTRIM(LorReference.rtsvar)
			LOCAL &c_LOR_Refer as boolean
			&c_LOR_Refer = .T.
			IF second_page
				c_LOR_Refer = ALLTRIM(LorReference.rtsvar)+"2"
				LOCAL &c_LOR_Refer as boolean
				&c_LOR_Refer = .T.
			ENDIF
		ENDIF		&& 08/19
    ENDIF
	oMed2.closealias("LorReference")
ENDIF
** 9/23

IF NOT USED ('LorCtrl')
	SELECT 0
	C_STR= "Exec dbo.GetLorFile2"
	l_done=oMed2.sqlexecute(C_STR,"LorCtrl")
ENDIF
SELECT LorCtrl

** Move up, 8/19/2021, ZD #232139, JH
**c_firm=""
**oMed2.closealias("FirmLor")
**C_STR= "select dbo.GetFirmCode ('" + ALLTRIM(pc_rqatcod) + "')"
**l_done=oMed2.sqlexecute(C_STR,"FirmLor")
**c_firm=ALLTRIM(NVL(FirmLor.exp,''))
**  8/19
**SELECT LorCtrl

SCAN FOR ACTIVE 
	c_Varname=ALLTRIM(rtsvar)
**EF -start 09/16/04 - make variable public on a fly
	IF NOT EMPTY(c_Varname)
		IF TYPE( (c_Varname)) = "U"
			PUBLIC (c_Varname)
		ENDIF
	ENDIF
**EF -end
	IF NOT &c_Varname
		LOOP
	ENDIF

	IF NOT EMPTY (LorCtrl.rq_at_code) AND ALLTRIM(pc_rqatcod)<>ALLTRIM(LorCtrl.rq_at_code)
		LOOP
	ENDIF
	IF NOT EMPTY (LorCtrl.court) AND  ALLTRIM(pc_Court1)<>ALLTRIM(LorCtrl.court)
		LOOP
	ENDIF
	IF NOT EMPTY (LorCtrl.billplan) AND ALLTRIM(pc_billpln)<>ALLTRIM(LorCtrl.billplan)
		LOOP
	ENDIF
	
	IF NOT EMPTY (LorCtrl.firmcode) AND ALLTRIM(c_firm)<>ALLTRIM(LorCtrl.firmcode)
		LOOP
	ENDIF

	IF  LorCtrl.authreq <> LorCtrl.subpreq
		IF  ((LorCtrl.authreq AND c_isstype<>"A")  ;
				OR (LorCtrl.subpreq AND c_isstype<>"S" ))

			LOOP
		ENDIF
	ENDIF


*	c_DocName = ALLTRIM(GROUPNAME)					&& 9/23/2020, ZD #190778, JH.

	IF NOT EMPTY(c_DocName)						&& 9/23/2020, ZD #190778, JH.
		c_DocName = c_DocName+"|"
	ENDIF								&& 9/23
	c_DocName = c_DocName+ALLTRIM(GROUPNAME)
	pn_LORpos = POSITION					
											

ENDSCAN

SELECT LorCtrl
USE


IF NOT EMPTY(c_Alias)
	SELECT (c_Alias)
ENDIF
IF NOT EMPTY(c_DocName)
	WAIT WINDOW "Printing LOR.."  NOWAIT
ENDIF
RELEASE oMed2
RETURN c_DocName	

