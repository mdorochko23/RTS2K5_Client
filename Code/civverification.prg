**************************************************************************
** 2/29/2012EF : Added new USDC form  for ALL KOP Litigation cases
** 07/31/09 EF : Added pl_NoFaxNotice
** 01/08/08 EF : Print a copy of a notice to each plaintiff's atty in a case
** 11/29/07 EF : Civil Order Verification Page
**************************************************************************

PARAMETERS d_date
PRIVATE lc_NameInv, lc_Ratadd1, lc_Ratadd2, lc_Ratadd3, lc_RAtFax, ;
	lc_RqAtType, mLrs, c_pltcap, c_defcap, c_docket, c_term, szSpcIns, ;
	lcTagName, lcNotice, l_gotcourt, c_reqFax AS STRING;
	lcInit, lc_EmailAdd, c_Court1, c_alias, civVerEmail,civVerEmailAdd
LOCAL oMed1 AS OBJECT
oMed1 = CREATEOBJECT("generic.medgeneric")
c_alias =ALIAS()
STORE "" TO lc_NameInv, lc_Ratadd1, lc_Ratadd2, lc_Ratadd3, lc_RAtCSZ,;
	lc_RAtFax, lc_RqAtType, lcInit, lc_EmailAdd, c_Court1, civVerEmail,civVerEmailAdd
llHoldFlag=.F.
pl_OrdVerSet=.T.
*--------------------------------
l_gotcourt=oMed1.sqlexecute("select [dbo].[GetCourtName]('" + pc_Court1 + "')", "Courtdesc")
IF l_gotcourt
	c_Court1=IIF(ISNULL(ALLTRIM(Courtdesc.EXP)),"",ALLTRIM(UPPER(Courtdesc.EXP)))
	IF UPPER(c_Court1)<>ALLTRIM(UPPER(pc_c1Desc))
		c_Court1=pc_c1Desc
	ENDIF

ELSE
	gfmessage('No court found.')
ENDIF
*--------------------------------
IF NOT l_Autho
	l_gothold=oMed1.sqlexecute("EXEC dbo.HoldRulesbyCourt '" + fixquote(PC_CLCODE) + "','" +  pc_Court1 + "'", "IfHold")

	IF IfHold.EXP>0
		llHoldFlag = .T.
	ENDIF
ENDIF
*------------------------------
**2/29/2012 USDC notice print for ALL litigations && removed AND PC_LITCODE='C  '
**3/23/2010 USDC notice print pl caption
**06/09/2015- Always use pl caption
*!*	IF (LEFT( ALLTRIM(pc_Court1), 4) = "USDC"  AND NOT pl_CAVer)
c_pltcap=ALLTRIM( pc_plcaptn)
*!*	ELSE
*!*		c_pltcap  = IIF( llHoldFlag OR pl_zicam  OR PL_ILCOOK, ALLTRIM( pc_plcaptn), pc_plnam)
*!*	ENDIF
c_defcap  = ALLTRIM( pc_dfcaptn)
c_docket  = ALLTRIM( pc_docket)

*c_term = ALLT(DTOC(convrtDate(pd_term)))
&&08/29/13 - use month year per Liz
c_term=termdate(pd_term)

c_reqFax=""
*------------------------------
c_AtNot = fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_AtNot, "M"
lc_NameInv = pc_AtyName
lc_Ratadd1 = pc_AtyFirm
lc_Ratadd2 = pc_Aty1Ad
lc_Ratadd3 =pc_Aty2Ad
lc_RAtCSZ = pc_Atycsz

lc_RAtFax = pc_AtyFax


lc_Attn=IIF(!EMPTY(pc_AtyAttn), "ATTN: " +pc_AtyAttn,'')
c_fax = STRTRAN( lc_RAtFax, " ", "")
c_temp = STRTRAN( c_fax, "-", "")
c_temp2 = STRTRAN( c_temp, "(", "")
IF NOT EMPTY(ALLTRIM(c_temp2))
	lc_FaxNum = "1"+ STRTRAN( c_temp2, ")", "")
ELSE
	lc_FaxNum=""
ENDIF
c_reqFax=lc_FaxNum

lc_SendType= ChkDelivery(c_AtNot)



**03/13/2013 - Check delivery method for the civil ver set - rq atty
l_FaxNotice = (NOT EMPTY( pc_AtyFax) AND lc_SendType == "F")
ll_EmailNot = (NOT EMPTY( pc_AtyFax) AND lc_SendType == "E")
* -- 12/10/2019 MD #150006 
civVerEmail = ll_EmailNot

l_gotemail=.F.
l_gotemail=oMed1.sqlexecute("select dbo.fn_NotEmail('" + c_AtNot + "')", "EmailAddr")
IF l_gotemail
	lc_EmailAdd=IIF(ISNULL(ALLTRIM(EmailAddr.EXP)),"",ALLTRIM(EmailAddr.EXP))
	* -- 12/10/2019 MD #150006 
    civVerEmailAdd=lc_EmailAdd
ELSE
	gfmessage('No email address found.')
ENDIF
&&06/17/2011- USE CORRECT EMAIL TO SEND AN ORDER VERIFICATION SET
pc_EmailAdd=lc_EmailAdd
&&06/17/2011- USE CORRECT EMAIL TO SEND AN ORDER VERIFICATION SET

&&12/02/14- IF EMAIL IS TRU BUT NOT EMAIL ADDRESS FOUND TRY FAX
IF ll_EmailNot AND EMPTY(ALLTRIM(pc_EmailAdd))
	IF  !EMPTY (lc_FaxNum)
		l_FaxNotice=.T.
		lc_SendType = "F"
	ENDIF
ENDIF
&&12/02/14- IF EMAIL IS TRU BUT NOT EMAIL ADDRESS FOUND TRY FAX

** 03/16/2017 #59566 : Added "KOPGeneric" /NJ courts to the rule below
LOCAL  l_c1Form AS Boolean
l_c1Form =pl_c1Form
l_c1Form= Rule1 () &&#59566 :
l_FaxNotice= IIF(l_c1Form =.T., l_FaxNotice, .F.)
** 03/16/2017 #59566 : Added "KOPGeneric" /NJ courts to the rule below

DO PrintGroup WITH mv, "CivilVerif"

IF FILE('C:\TEMP\Tmpnot.dbf') AND USED ('TMPNOT')

	SELECT tmpnot
	SELECT DISTINCT At_CODE FROM tmpnot   INTO CURSOR TMPNOT2
	SELECT TMPNOT2
	c_attylist=""
	c_Addtext="Additional notices have been sent to the following parties in this action as well:"
	SCAN

		c_Atty=fixquote(TMPNOT2.At_CODE)
		pl_GetAt = .F.
		DO gfatinfo WITH c_Atty, "M"
		c_attylist=c_attylist + CHR(13) + UPPER( ALLTRIM(pc_AtyName)) + " " + ALLTRIM(pc_AtyFirm)  + " " +  pc_AtyFax

		SELECT TMPNOT2
	ENDSCAN
	SELECT tmpnot
	USE
	SELECT TMPNOT2
	USE

	DO PrintField WITH mv, "AddAttyList", c_Addtext + CHR(13) + c_attylist

ELSE
	WAIT WINDOW 'Printing Order Verification Set..' NOWAIT
	DO PrintField WITH mv, "AddAttyList", ""
ENDIF

**5/20/15 -MD needs an extra date


IF (pc_c1Name = "MD-BaltimoCity" )
	IF TYPE ("d_date")="D" OR TYPE ("d_date")="T"
		IF  TYPE ("d_date")="T"
			d_date=TTOD(d_date)
		ENDIF
	ELSE
		d_date=DATE()
	ENDIF
	d_date2 = gfChkDat( d_date+ 1, .F., .F.) &&5/20/15 ADDED A DAY PER LIZ
ELSE
	d_date2=d_date

ENDIF

DO PrintField WITH mv, "RequestDate",  DTOC( d_date2)
DO PrintField WITH mv, "Loc", ;
	IIF( pl_ofcPgh OR pl_ofcMD, "P", pc_offcode)
DO PrintField WITH mv, "FaxLoc", ;
	IIF( pl_ofcPgh OR pl_ofcMD, "P", pc_offcode)

DO PrintGroup WITH mv, "Case"
DO PrintField WITH mv, "LRS", pc_lrsno
DO PrintField WITH mv, "Name", pc_plnam
DO PrintField WITH mv, "Plaintiff", c_pltcap
DO PrintField WITH mv, "Defendant", c_defcap
* 02/01/2019 #126302 make usdc upper ------
DO PrintField WITH mv, "Court", IIF(LEFT(ALLTRIM(c_Court1),4)=="USDC", UPPER(c_Court1),PROPER( c_Court1 ))
DO PrintField WITH mv, "Term", c_term
DO PrintField WITH mv, "Docket", c_docket


DO PrintGroup WITH mv, "Atty"

laRTS = ""
lcRPS = ""
DIMENSION laRTS[6]

DIMENSION laRPS[6]
laRTS[1] = "lc_NameInv"
laRTS[2] = "lc_RAtAdd1"
laRTS[3] = "lc_RAtAdd2"
laRTS[4] = "lc_RAtAdd3"
laRTS[5] = "lc_RAtCSZ"
laRTS[6] = "lc_Attn"

laRPS[1] = "Name_inv"
laRPS[2] = "Ata1"
laRPS[3] = "Ata2"
laRPS[4] = "Ata3"
laRPS[5] = "Atacsz"
laRPS[6] = "Attn"

lnRTS = 0
FOR nLoop = 1 TO 6
	lnRTS = lnRTS + 1
	DO WHILE lnRTS < 7
		IF EMPTY(&laRTS[lnRTS].)
			lnRTS = lnRTS + 1
		ELSE
			EXIT
		ENDIF
	ENDDO
	IF lnRTS < 7
		DO PrintField WITH mv, laRPS[nLoop], &laRTS[lnRTS].
	ELSE
		DO PrintField WITH mv, laRPS[nLoop], " "
	ENDIF
NEXT nLoop

DO PrintField WITH mv, "FaxNo", lc_RAtFax

DO PrintGroup WITH mv, "Contact"
DO PrintField WITH mv, "Name", contname
DO PrintField WITH mv, "Phone", contphone

dThisdate=d_date
pl_noticng=.T.
c_platcod=""


***************6/6/2011 If plaintiff =requesting attys
** attach  defense atty's notice ( any defense atty on a case, the rest of defense attys we’ll list on an Order Verification Cover page).
LOCAL n_not AS INTEGER


n_not=1
IF ALLTRIM(pc_rqatcod)=ALLTRIM(pc_platcod)
	c_platcod=""
	c_code="  TABILLS.CODE='D' AND TABILLS.NONOTICE=.F.  AND  n_not =1 "
ELSE
	c_platcod=""
	c_code="  TABILLS.CODE='P' AND TABILLS.NONOTICE=.F. "

ENDIF

* 01/31/2019 MD #126302------
LOCAL dontPrintAttchm,dontPrintTotal
STORE 0 TO dontPrintAttchm,dontPrintTotal
*----------------------------
* 02/08/2019 Md #126940
IF TYPE("c_Addr")="U" OR TYPE("c_Addr")="L" 
   c_Addr=""
ENDIF
*----------------------------  
*-- 10/08/2021 MD Added tempTABills to fix issue with incorrect record positioning
SELECT TABILLS
IF USED("tempTABills")
	USE IN tempTABills
ENDIF
SELECT 0 
SELECT at_code INTO CURSOR tempTABills FROM tabills WHERE &c_code
SELECT tempTABills
&& *-- 10/08/2021 MD 
COUNT TO dontPrintTotal 
GO TOP
SCAN 
	&& *-- 10/08/2021 MD 
	SELECT TABILLS 
	GO TOP 
	locate for ALLTRIM(UPPER(TABILLS.at_code))== ALLTRIM(UPPER(tempTABills.at_code)) 
	IF !FOUND()
		LOOP
	ENDIF 
	&& *-- 10/08/2021 MD 
	N_REC=RECNO()
	n_not=2
	IF pl_MDLead && ONLY COUNT SETS FOR MD LEAD SUBPS
		pn_SetNum=pn_SetNum+1
	ELSE
		pn_SetNum=0
	ENDIF
	* 01/31/2019 MD #126302------  print notice attachments only once with copy set
	dontPrintAttchm=dontPrintAttchm+1
	
	c_platcod=At_CODE
	IF EMPTY(msoc_sec)
		msoc_sec='0'
	ENDIF    
	
    * 01/31/2019 MD #126302 pass additonal parameter ------    
    * DO donotice IN thenotic WITH ALLTRIM( c_platcod), .T. 
	DO donotice IN thenotic WITH ALLTRIM( c_platcod), .T.,IIF(dontPrintAttchm<dontPrintTotal,.T.,.F.)

	IF NOT EMPTY(mv)

		DO CASE
		CASE l_FaxNotice AND LEN(ALLTRIM(c_reqFax))>=10 &&pl_NoFaxNotice=.F.

			mclass="FaxNotice"
			c_Addr=IIF (LEN(ALLTRIM(c_reqFax))<10,"",c_reqFax)
			c_fax = STRTRAN( c_Addr, " ", "")
			c_temp = STRTRAN( c_fax, "-", "")
			c_temp2 = STRTRAN( c_temp, "(", "")
			c_Addr = STRTRAN( c_temp2, ")", "")


		CASE ll_EmailNot OR pl_zicam
			mclass="RpsNotice"
			c_Addr=lc_EmailAdd
		OTHERWISE

			IF  pl_MDLead AND l_BaltCase  && 6/10/15-email md lead subp notices
				mclass='ENotMDLead'
				c_Addr=""
			ELSE
				mclass=mclass
				c_Addr=""
			ENDIF
		ENDCASE

&&03/23/2016 removed  OMRPage #36180
*!*			IF pl_RepNotc OR pl_NoFaxNotice OR EMPTY(ALLTRIM(pc_EmailAdd))
*!*			&&03/08/2012 added OMRPage
*!*				IF  pl_MDLead AND l_BaltCase
*!*			&&waitig for a confirmation
*!*				ELSE
*!*					DO OmrPage
*!*				ENDIF
*!*			ENDIF
&&03/23/2016 removed  OMRPage #36180


&& 07/15/2015 - EMAIL MD Balt verification sets per Liz
		IF  pl_MDLead AND l_BaltCase  && 6/10/15-email md lead subp notices
			mclass='ENotMDLead'
			pc_EmailAdd=""
			c_Addr=""
		ENDIF


		IF pl_RepNotc
			pc_EmailAdd=""
			c_Addr=""
			mclass =IIF ( pl_MDLead AND l_BaltCase ,'ENotMDLead' , "RepNot")
		ENDIF
&&TEST 3/14/2013

		IF EMPTY(ALLTRIM(pc_EmailAdd))

**it is ok to fax again #57382
**09/29/15- PRINT NOTICES FOR PA-PHILADELPHI TILL LIZ SAYS OTHERWISE

*!*			IF pl_WebForm AND NOT pl_RepNotc
*!*				mclass='Notice'
*!*				c_Addr=''
*!*			ENDIF
**09/29/15- PRINT NOTICES FOR PA-PHILADELPHI TILL LIZ SAYS OTHERWISE
**03/16/17 #59568- till we get a new set - email all notices to teh CS Inbox
			IF (pl_c1Form=.F. AND UPPER(pc_RpsForm)="NONPROG"  ) 	AND NOT pl_RepNotc
				mclass='FakeNot'
				c_Addr=''
			ENDIF


			mv_copy=""
			mv_copy=mv
			*DO PrtEnQa IN ta_lib WITH mv, mclass, "2", c_Addr
			IF NOT pl_RepNotc
**08/07/2017: emai a copy of a set to the cs #60687
*-- 03/28/2018 MD don't create FakeOrdVer job  per #83168
				*mv=mv_copy
				*DO PrtEnQa IN ta_lib WITH mv, "FakeOrdVer", "2", c_Addr
*--				
			ENDIF
		ELSE

		ENDIF


	ENDIF


	&&SELECT TABILLS	
	&&GOTO N_REC
	SELECT tempTABills && *-- 10/08/2021 MD 
ENDSCAN
&& *-- 10/08/2021 MD 
IF USED("tempTABills")
	USE IN tempTABills
ENDIF
&& *-- 10/08/2021 MD 

* 02/01/2019 MD #126302 email notices
* 02/04/2019 The area was changed from Torrey to InfectDisease
IF ALLTRIM(UPPER(pc_litcode))=="C" AND ALLTRIM(UPPER(pc_area))==UPPER("InfectDisease")
	mclass="CTorNot"
ENDIF 

* -- 12/10/2019 MD #150006 Reset values that were changed by doNotice process
IF civVerEmail=.T. and pl_ElitNotice=.T.
	mclass="RpsNotice"	
	c_Addr=civVerEmailAdd
	pc_EmailAdd=civVerEmailAdd
ENDIF 
*-- 10/07/2021 MD #253352
pc_EmailAdd=civVerEmailAdd
 
*-- 10/22/2021 MD make sure the requsting attorney email is open
IF USED("EmailAddr")
	USE IN EmailAddr
ENDIF
oMed1.sqlexecute("select dbo.fn_NotEmail('" + fixquote(ALLTRIM(pc_rqatcod)) + "')", "EmailAddr")

* -- 12/10/2019 MD #150006

DO PrtEnQa IN ta_lib WITH mv, mclass, "2", c_Addr
****************


IF  FILE('C:\TEMP\Tmpnot.dbf') AND USED('Tmpnot')
	SELECT tmpnot
	USE
	DELETE FILE "C:\TEMP\TMPNOT.DBF"
ENDIF


pl_OrdVerSet=.F.
pn_SetNum=0
IF NOT EMPTY(c_alias)
	SELECT (c_alias)
ENDIF
RELEASE oMed1
RETURN
*******************************
FUNCTION ChkDelivery
PARAMETERS c_Atty

LOCAL c_alias AS STRING, NREC AS INTEGER
c_alias=ALIAS()

SELECT TABILLS
c_order=ORDER()

SET ORDER TO claC
IF SEEK(PC_CLCODE+c_Atty)
	c_method=ALLTRIM( TABILLS.hownotice)
ELSE
	c_method="F" &&DEFAULT
ENDIF

SELECT TABILLS
IF !EMPTY(c_order)
	SET ORDER TO (c_order)
ENDIF
SELECT TABILLS

IF !EMPTY(c_alias)
	SELECT (c_alias)
ENDIF
RETURN c_method
*******************************
