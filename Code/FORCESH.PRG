**function forceSH
PARAMETERS   C_REQTYPE
LOCAL L_FORCESH AS BOOLEAN
L_FORCE=.F.
&& #61228 4/28/17: Check for the location's State 
IF EMPTY(ALLTRIM(NVL(pc_mailst,'')) ) AND  PL_KOPVER
		pc_mailst= TgState(pc_mailid) 
ENDIF

DO CASE		

CASE  PL_1ST_REQ AND (pl_Txcourt  AND pc_IssType="S")
	L_FORCESH=.T.
CASE  PL_KOPVER AND  pc_mailst='CA' AND PL_POSTFEE && #61228
	L_FORCESH=.T.
CASE NVL(pc_mailid,'')="A472629" &&#57632 
	L_FORCESH=.T.
CASE ALLTRIM(pC_COURT1)='IL-WCC'  AND C_REQTYPE = "S" AND PL_KOPVER
	L_FORCESH=.T.
CASE  (LEFT( ALLTRIM(pC_COURT1), 4) = "USDC" )  AND C_REQTYPE = "S"  &&11/12/14 force the spec handling
	L_FORCESH=.T.
CASE	PL_1ST_REQ AND	ALLTRIM(PC_ISSTYPE)="S"  AND PL_ILCOOK AND PL_KOPVER
	PL_HANDDLVR= .T. && force SP for IL-cookcounty subps
	L_FORCESH=.T.
CASE   (pl_MailOrig  AND PC_ISSTYPE="S") AND  PL_HANDDLVR
	L_FORCESH=.T.
CASE  PL_HANDDLVR
	L_FORCESH=.T.
CASE  PL_1ST_REQ AND (pl_Txcourt  AND pc_IssType="S")
	L_FORCESH=.T.  &&60359 TX subps need a spec hanling/certified mail
**SL, 1/17/19, #125008
CASE !PL_REISSUE AND ALLTRIM(PC_LITCODE) == "C" AND ALLTRIM(PC_AREA) == "HamiltonMiller"
	L_FORCESH=.T.
** 08/01/2019 MD #138050 force SH for hitech first request
CASE  PL_1ST_REQ AND ALLTRIM( NVL(record.hitech,""))=="1" 
	L_FORCESH=.T.
CASE UPPER(LEFT(LTRIM(PC_COURT1),3)) = "MI-" AND PL_1ST_REQ AND alltrim(pc_IssType)="S" AND PL_KOPVER		&& 8/9/2022, ZD #282397, JH
	L_FORCESH=.T.
	
OTHERWISE
	L_FORCESH=.F.
ENDCASE

RETURN L_FORCESH