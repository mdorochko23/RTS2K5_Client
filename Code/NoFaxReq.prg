*FUNCTION NoFaxReq
**3/12/2013- allow to fax a hold subpoenas: "HoldPrint" Project.
******************************************************************************************
PARAMETERS lc_dept, lc_Type, c_tag
PRIVATE l_StopFax, omedfax AS OBJECT
omedfax = CREATEOBJECT("generic.medgeneric")
gnHold = IIF( pl_nohold, 0, pn_c1Hold)
gnFRDays = pn_litfday
gnIssDays = pn_litiday
pn_ObjDay=0
llFromRev = IIF (gnFRDays<>0, .T.,.F.)
c_sql="select dbo.fn_ObjDays('" + pc_clcode + "', '" + c_tag + "')"
l_ObjPeriod= omedfax.sqlexecute (c_sql, "ObjectPeriod")
IF l_ObjPeriod
	pn_ObjDay =ObjectPeriod.EXP
ENDIF

l_StopFax = .F.
** exclude CA and TX office cases
IF (pl_CAVer AND lc_Type="S") OR pl_RisPccp
	l_StopFax = .T.
	pl_FaxOrig= .F.
	RETURN !l_StopFax
ENDIF
**03/12/2013 - allow hold requests
IF lc_Type = "S"
*	IF gnHold <> 0
	IF PL_1ST_REQ && Do not Fax subpoena First Issue  ( any , not just hold like before) #56756
		l_StopFax = .T.
		pl_FaxOrig= .F.
	ENDIF
ENDIF

IF ALLTRIM(PC_COURT1)='USDC'  AND  lc_Type="S" &&11/12/14- do not fax USDC
	l_StopFax = .T.
	pl_FaxOrig= .F.

ENDIF
**5/26/15 - do not fax MD subps: per Liz
IF ALLTRIM(PC_COURT1)='MD-BaltimoCity' AND  lc_Type="S" &&11/12/14- do not fax USDC
	l_StopFax = .T.
	pl_FaxOrig= .F.

ENDIF


IF pl_TxCourt AND  lc_Type="S" &&TX subps -no fax #60359
	l_StopFax = .T.
	pl_FaxOrig= .F.

ENDIF

***********HOLDPRINT MARK
IF pl_PropPA OR pl_PropNJ
	l_StopFax = .T.
ENDIF
IF INLIST (pc_Litcode, "E  ", "D  ", "G  ", "Q  ") AND pl_FromRev
	l_StopFax = .T.
ENDIF
IF pl_zicam AND pn_ObjDay<>0
	l_StopFax = .T.
ENDIF
** Do Not FAX BATCH REQUESTS
IF !EMPTY(pc_batchRq)
	l_StopFax = .T.
ENDIF

**Do Not FAX # like 111111111
IF TYPE('PN_MAILFAX')='C'
	lcExactMail=SET("Exact")
	SET EXACT OFF
	DO CASE
	CASE  pn_MailFax  =  '111'
		l_StopFax = .T.
	CASE EMPTY(pn_MailFax)
		l_StopFax = .T.
	CASE pn_MailFax ='0'
		l_StopFax = .T.
	ENDCASE
	SET EXACT &lcExactMail
ENDIF

** #57632
** do not fax  requests for A472629
IF NVL(pc_mailid, "") ="A472629"
	l_StopFax = .T.
ENDIF

**SL, 1/17/19, #125008
IF (!PL_REISSUE AND ALLTRIM(PC_LITCODE) == "C" AND ALLTRIM(PC_AREA) == "HamiltonMiller")
	l_StopFax = .T.
ENDIF

** #57632
IF  pl_StopPrtIss
	l_StopFax=.T.
ENDIF

** do not fax KOP to CA locations with Checks #61228
IF  PL_KOPVER AND  ALLTRIM(NVL(pc_mailst,''))='CA'   AND NVL(PL_POSTFEE,.F.)
	l_StopFax=.T.
ENDIF

IF l_StopFax
	STORE .F. TO l_Fax1Req, l_PrtFax
ENDIF
RELEASE omedfax
RETURN NOT l_StopFax
