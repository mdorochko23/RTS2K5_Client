*:*****************************************************************************
*:    Procedure file from early versions of RTS
*     Used in RTS, Reports, and Utilities packages
*:  EF  08/10/09  call jobcreate to add SQL RPS job
*:  EF  11/29/07 batch printing
*:  EF  11/30/05  Switched to SQL
*:  ******************************************************
*:  EF 02/23/09   USE addjobs 
*:  EF 07/07/08   USE sql rpswork db
*:  EF  02/10/05  Add "RpsNotice"  (Email print class)
*:  DMA 06/10/04  Removed LaserCodes
*:  EF  05/06/04  Removed SendFax()
*:  EF  01/07/04  Add the KOP-Pasadena Rps and edited the RPS itself
*:  EF  09/11/03  Treat KOP Maryland cases as MD ones (pl_MDasb)
*:  EF  11/04/02  Add code related to 'Fax original requests' option
*:  EF  06/26/02  Add code related to CA batch Autofax
*:  DMA 06/21/02  Move MakeHash into standalone function
*:  DMA 06/19/02  Replace mlogname with pc_UserID
*:  kdl 05/23/02  Added check of pl_2ndQue for texas split queue print jobs
*:  KDL 05/13/02  Removed NT Test print que redirection
*:  KDL 04/30/02  Redirected all NT testing print jobs to test printer
*:  KDL 04/23/02  Divide texas print jobs between their 2 printers
*:  DMA 05/05/01  Add optional title parameter to SENDMSG function
*:  Procs & Fncts
*:               : SPINOPEN
*:               : SPINCLOSE
*:               : SPINMOVE()
*:               : SENDMSG()
*:               : GETFNAME()
*:               : SENDPAGE()
*:               : SELENTRY()
*:               SEND2SPOOL (called by CashLog in RTS)
**               NewMail (called by RoloInfo, ViewInst in RTS; RoloInfo in Reports)
*:
**   DMA 03/23/01 Remove items that are unused in RTS/Reports/Utilities packages
**                MKCL_CODE
**                MAXOUT
**                ISMANAGER
**                GETLITNAME
**                SEND2BATCH
**                GFRestoreEnv
**                GFSaveEnv
**                SendMsg2
**                PrintCode
**                BCODE
**                CODE39
**                SETLASER
**                DEF_CODE
*:*****************************************************************************

*!*****************************************************************************
*!
*!      Procedure: SPINOPEN
*!
*!      Called by:
*!               : SUBP_PA
*!               : XRAYSCRN
*!               : XPP_PRNT
*!               : FAXCOV
*!               : CASEPICK
*!
*!*****************************************************************************
PROCEDURE spinopen
PARAMETER sztitle

IF NOT WEXIST("WndStat")
	DEFINE WINDOW wndstat ;
	FROM 5,10 TO 7,10 + (LEN(sztitle) + 10) ;
	TITLE " Processing Data "

	ACTIVATE WINDOW wndstat

	@ 0,1 SAY sztitle
ELSE
	ACTIVATE WINDOW wndstat
ENDIF
RETURN


*---------------------------------------------------------------
*!*****************************************************************************
*!
*!      Procedure: SPINCLOSE
*!
*!      Called by:
*!               : SUBP_PA
*!               : XRAYSCRN
*!               : XPP_PRNT
*!               : FAXCOV
*!               : CASEPICK
*!
*!*****************************************************************************
PROCEDURE spinclose
IF WEXIST("WndStat")
	DEACTIVATE WINDOW wndstat
	RELEASE WINDOWS wndstat
ENDIF
RETURN


*---------------------------------------------------------------
*!*****************************************************************************
*!
*!       Function: SPINMOVE()
*!
*!      Called by:
*!               : XRAYSCRN
*!               : CASEPICK
*!
*!*****************************************************************************
FUNCTION spinmove
PARAMETER nmove

IF WEXIST("WndStat")
	IF NOT WONTOP("WndStat")
		ACTIVATE WINDOW wndstat
	ENDIF

&& Code for spinner
	DO CASE
		CASE nmove == 1
			szspin = "\"

		CASE nmove == 2
			szspin = "|"

		CASE nmove == 3
			szspin = "/"

		OTHERWISE
			szspin = "-"
			nmove = 0
	ENDCASE
	@ 0,WCOLS() - 2 SAY szspin
ENDIF
RETURN nmove


*---------------------------------------------------------------
&& Laser printer codes
*!*****************************************************************************
*!
*!      Procedure: LASERCODES
*!
*!*****************************************************************************
PROCEDURE lasercodes
** 06/10/04  DMA  All laser-printer codes now in routine PUBLIC
RETURN

*---------------------------------------------------------------
*!*****************************************************************************
*!
*!       Function: SENDMSG()
*!
*!      Called by: OPNCASE.PRG
*!               : XRAYSCRN.PRG
*!               : SUBP_PA.PRG
*!               : GETPLCASES()       (function  in GETPLT.PRG)
*!               : GETPLTINFO         (procedure in OPNCASE.PRG)
*!               : GETCHOICE()        (function  in OPNCASE.PRG)
*!               : RMVCODE30          (procedure in CODE30VW.PRG)
*!               : LOCATE41           (procedure in CODE41VW.PRG)
*!               : PROCCODE41         (procedure in CODE41VW.PRG)
*!               : DISPNOTICE         (procedure in PSNOTRP.PRG)
*!               : DISPDEPS()         (function  in SUBP_PA.PRG)
*!               : PRNTINV            (procedure in XPP_PRNT.PRG)
*!               : PRNTTXN            (procedure in XPP_PRNT.PRG)
*!               : PRINTLABEL         (procedure in XPP_LBL.PRG)
*!               : GETBTNCHC()        (function  in PATHEDAD.PRG)
*!
*!*****************************************************************************
FUNCTION sendmsg
PARAMETER szmsg, nbtntype, reverse, titlestr
PRIVATE btnchoice, btnchoice2
** DMA 5/5/2001 Added optional title parameter
IF PCOUNT() < 4
	titlestr = " RT System Message "
ELSE
	titlestr = " " + ALLT(titlestr) + " "
ENDIF
** HN 1/15/98 Added reverse to switch default of buttons.
IF PCOUNT() < 3
	reverse = .F.
ENDIF
btnchoice = 1

DEFINE WINDOW wndmsg ;
FROM INT((SROW()-6)/2),INT((SCOL()-52)/2) ;
TO INT((SROW()-6)/2)+5,INT((SCOL()-52)/2)+51 ;
TITLE titlestr ;
NOFLOAT NOCLOSE DOUBLE

ACTIVATE WINDOW wndmsg

@ 1,1 SAY PADC(szmsg, WCOLS("WndMsg")-1)

DO CASE
	CASE nbtntype = 1
		@ 3,21 GET btnchoice PICTURE "@*HT \<OK" ;
		SIZE 1,8,1 DEFAULT 1

	CASE nbtntype == 2
		btnchoice  = 0
		btnchoice2 = 0
		IF !reverse
			@ 3,(WCOLS("WndMsg")-11)/2 GET btnchoice ;
			PICTURE "@*HT \<Yes"
			@ 3,(WCOLS("WndMsg")-11)/2 + 7 GET btnchoice2 ;
			PICTURE "@*HT \<No"
		ELSE
			@ 3,(WCOLS("WndMsg")-11)/2 + 7 GET btnchoice2 ;
			PICTURE "@*HT \<No"
			@ 3,(WCOLS("WndMsg")-11)/2 GET btnchoice ;
			PICTURE "@*HT \<Yes"
		ENDIF

ENDCASE
&& _CUROBJ = OBJNUM(BtnChoice)

&& Wait for user input!!
READ CYCLE MODAL
IF nbtntype = 2
	IF btnchoice2 = 1
		btnchoice = 2
	ENDIF
ENDIF
DEACTIVATE WINDOW wndmsg
RELEASE WINDOW wndmsg

IF LASTKEY()=27
	btnchoice=0
ENDIF
RETURN btnchoice

*----------------------------------------------------------
&& Get File name.  This function is used by programs
&& which need to print to PSpool.
*!*****************************************************************************
*!
*!       Function: GETFNAME()
*!
*!      Called by: ASLIST.PRG
*!               : AUTH2              (procedure in SUBP.PRG)
*!               : GETCHOICE()        (function  in OPNCASE.PRG)
*!               : PRINTINST          (procedure in OPNCASE.PRG)
*!               : PRNT30             (procedure in CODE30.PRG)
*!               : PRNT41B            (procedure in FHLTR3.PRG)
*!               : PRNT41C            (procedure in FHLTR3.PRG)
*!               : PRNT41D            (procedure in FHLTR3.PRG)
*!               : SUBUSDC            (procedure in ASLIST.PRG)
*!               : COVERLTR           (procedure in SUBP_PA.PRG)
*!               : MKUOBLTR           (procedure in UOBLTR.PRG)
*!               : MKPAGE             (procedure in FAXCOV.PRG)
*!               : BAKTASUBP          (procedure in SUBPCCP.PRG)
*!               : SUBPBUCK           (procedure in SUBBUCK.PRG)
*!               : PITTSSUBP          (procedure in SUBPITT.PRG)
*!               : PRNTINV            (procedure in XPP_PRNT.PRG)
*!               : TXNHEAD            (procedure in XPP_PRNT.PRG)
*!               : PRNDOC()           (function  in PRNTENG.PRG)
*!
*!*****************************************************************************
FUNCTION getfname
PRIVATE szfname

szfname = ""
DO WHILE .T.
	szfname = f_txt + SYS(3) + ".Txt"
	IF NOT FILE(szfname)
		EXIT
	ENDIF
ENDDO
RETURN szfname


&& Send a page to PSpool!!
*!*****************************************************************************
*!
*!       Function: SENDPAGE()
*!
*!      Called by: ASLIST.PRG
*!               : MKPAGE             (procedure in FAXCOV.PRG)
*!               : PRNTINV            (procedure in XPP_PRNT.PRG)
*!               : PRNTTXN            (procedure in XPP_PRNT.PRG)
*!               : PRNDOC()           (function  in PRNTENG.PRG)
*!
*!*****************************************************************************
FUNCTION sendpage
PARAMETER sztxt, szpcx, szptype, nstx, nsty, nendx, nendy
PRIVATE bret, szwrkarea

&& Check parameter count!!
IF PCOUNT() == 3
	nstx = 0
	nsty = 0
	nendx = 1
	nendy = 1
ENDIF

bret = .F.
* 07/20/04 DMA MSoc_Off is no longer in the system.
*IF UPPER( TYPE( "MSOC_OFF")) = "C"
*   IF msoc_off = "KY"
*      szpcx = "L:\PCX\KENTUCKY.PCX"
*      szptype = "L"
*   ENDIF
*ENDIF

&& Update PSpool database!!
szwrkarea = ALIAS()
IF USED("pspool")
	SELECT pspool
	USE
ENDIF
SELECT 0
USE (f_pspool)
APPEND BLANK
FLUSH
DO WHILE NOT RLOCK()
ENDDO
REPLACE txtfile WITH sztxt
REPLACE pcxfile WITH szpcx
REPLACE doc_type WITH szptype
REPLACE printed WITH .F.
REPLACE startx WITH nstx
REPLACE starty WITH nsty
REPLACE endx WITH nendx
REPLACE endy WITH nendy
REPLACE done WITH .T.
USE

IF NOT EMPTY(szwrkarea)
	SELECT (szwrkarea)
ENDIF
RETURN bret


****************************************************************
PROCEDURE PrintGroup
PARAMETER mStr, szStr

mStr = mStr + TRANSFORM( LEN( ALLTRIM( szstr)), "@L 9999") ;
+ "3/" + szstr + "/"
RETURN

****************************************************************

PROCEDURE PrintField
PARAMETER mStr, szName, szValue
**07/30/08 - REMOVE AN EXTRA SPACES FROM THE infotext ON DOCS.
PRIVATE str_value AS String
str_value=""

szValue=convertToChar(szValue,0)
szName=convertToChar(szName,0)

IF UPPER( ALLTRIM( szname)) == "TAG"
	gnTag = INT( VAL( szValue))
ENDIF
 **07/30/08 START
 IF INLIST(UPPER(ALLTRIM(szname)),'INFOTEXT','INFOITEM','CCTXT', 'NAME')
 		str_value=remnonasci( ALLTRIM(szvalue))
ELSE
		str_value=ALLTRIM(szvalue)
ENDIF
str_value= STRTRAN( str_value, "''", "'")
**07/30/08 END

mStr = mStr + ;
TRANSFORM( LEN( ALLTRIM( szname)),  "@L 9999") + ;
"1/" + ALLTRIM( szname) + "/" + ;
TRANSFORM( LEN( ALLTRIM(str_value)), "@L 9999") + ;
"2/" + STRTRAN( ALLTRIM( str_value), "^", " ") + "/"
RETURN

* ----- PrintEnq ---- Enqueue a print job (old style) ------
*********************************************************************

PROCEDURE PrintEnq
PARAMETER ADATA, ACLASS, aGroup

DO prtEnqa WITH ADATA, ACLASS, aGroup, ""


RETURN

* ----- PrtEnqa -------------------------------------
* Enqueue a print job
PROCEDURE PrtEnqa
PARAMETER ADATA, ACLASS, aGroup, aAddress
*  aData    print job data string -- cleared as a result
*  aClass    job's class
*  aGroup    job's group
*         "0": use group 0 no load leveling
*         "1": load level
*         other: rough sort by group
*   aAddress Job's address (or fax number)

* pl_CANotc will be .T. on entry if CA office end-of-day notices
* are being generated
IF TYPE('Pn_tag')<>"N"
  Pn_tag=gnTag
ENDIF 

LOCAL cuserid AS String , cclcode AS String, ntag AS Number
cuserid=""
IF TYPE('Pc_userid')="C"
cuserid=Pc_userid
endif
cclcode=Pc_clcode
ntag=PN_TAG
DO jobcreate WITH  ADATA,ACLASS, aGroup, Aaddress, cclcode, ntag, cuserid, .t.


RETURN
* ----- PrtEnqa2 -------------------------------------
* Enqueue a print job
*-- 01/21/2022 MD added to pass additional parameter - at_code
PROCEDURE PrtEnqa2
PARAMETER ADATA, ACLASS, aGroup, aAddress, aAttyCode
*  aData    print job data string -- cleared as a result
*  aClass    job's class
*  aGroup    job's group
*         "0": use group 0 no load leveling
*         "1": load level
*         other: rough sort by group
*   aAddress Job's address (or fax number)
*   aAttyCode - recipient of email

* pl_CANotc will be .T. on entry if CA office end-of-day notices
* are being generated
IF TYPE('Pn_tag')<>"N"
  Pn_tag=gnTag
ENDIF 

LOCAL cuserid AS String , cclcode AS String, ntag AS Number
cuserid=""
IF TYPE('Pc_userid')="C"
cuserid=Pc_userid
endif
cclcode=Pc_clcode
ntag=PN_TAG
DO jobcreate WITH  ADATA,ACLASS, aGroup, Aaddress, cclcode, ntag, cuserid, .t., '', aAttyCode


RETURN
*!*	*************************************************************
*!*	PROCEDURE CourtForm
*!*	PARAMETERS courtcode
*!*	** Find out if a form exists for this court
*!*	PRIVATE hasit, courtuse, currfile
*!*	o = CREATEOBJECT("generic.medgeneric")
*!*	o.sqlexecute("exec GetAllCourt", "court")
*!*	hasit = .F.

*!*	currfile = ALIAS()
*!*	courtuse = .F.
*!*	IF USED("court")
*!*		courtuse = .T.
*!*		SELECT court
*!*	ELSE
*!*		SELECT 0
*!*		USE (court)
*!*	ENDIF

*!*	GO TOP
*!*	SCAN
*!*		IF ALLTRIM( UPPER( court.court)) == ALLTRIM( UPPER( courtcode))
*!*			IF HasForm
*!*				hasit = .T.
*!*				EXIT
*!*			ENDIF
*!*		ENDIF
*!*	ENDSCAN
*!*	IF NOT CourtUse
*!*		SELECT Court
*!*		USE
*!*	ENDIF

*!*	IF NOT EMPTY( currfile)
*!*		SELECT (currfile)
*!*	ENDIF
*!*	IF hasit
*!*		RETURN .T.
*!*	ELSE
*!*		RETURN .F.
*!*	ENDIF
*************************************************************
**05/26/2010- REPLACED BY A STAND ALONE FUNCTION
*!*	PROCEDURE CourtVal
*!*	PARAMETERS CourtCode
*!*	** Find out if a court is valid
*!*	PRIVATE hasit, courtuse, currfile
*!*	o = CREATEOBJECT("generic.medgeneric")
*!*	o.sqlexecute("exec GetAllCourt", "court")
*!*	hasit = .F.

*!*	currfile = ALIAS()
*!*	courtuse = .F.
*!*	IF USED("court")
*!*		courtuse = .T.
*!*		SELECT court
*!*	ELSE
*!*		SELECT 0
*!*		USE (f_court)
*!*	ENDIF

*!*	GO TOP
*!*	SCAN
*!*		IF ALLTRIM( court.court) == ALLTRIM( courtcode)
*!*			hasit = .T.
*!*			EXIT
*!*		ENDIF
*!*	ENDSCAN
*!*	IF !courtuse
*!*		SELECT court
*!*		USE
*!*	ENDIF
*!*	IF NOT EMPTY(currfile)
*!*		SELECT (currfile)
*!*	ENDIF
*!*	IF hasit
*!*		RETURN .T.
*!*	ELSE
*!*		RETURN .F.
*!*	ENDIF

* ----- makealph -- return a string of alphanumeric characters ----
FUNCTION MakeAlph

PARAMETERS mstr

** Makealph.prg
** Strips off all non-alphanumeric characters from a string (mstr)
* 05/11/04 DMA Eliminate repeated use of ASC(ch) with a local variable
PRIVATE RetStr, i, ch, asc_ch
retstr = ""
FOR i = 1 TO LEN( mstr)
	ch = SUBSTR( mstr, i, 1)
	asc_ch = ASC( ch)
** A-Z, a-z, 0-9
	IF BETWEEN( asc_ch, 65, 90) OR ;
		BETWEEN( asc_ch, 97, 122) OR ;
		BETWEEN(asc_ch, 48, 57) OR ;
		asc_ch = 32
		retstr = retstr + ch
	ELSE
		retstr = retstr + "x"
	ENDIF
ENDFOR
RETURN RetStr

***************************************************************************

FUNCTION newmail
**  Called by RoloInfo, ViewInst in RTS

PARAMETER mailtype

*** Returns the next available mailid number for use in
*** Hospital, Doctor, Association, or Employment rolodi.

IF NOT INLIST( UPPER(mailtype), "D", "H", "A", "E")
	gfmessage("Attempt to assign Mailid to incorrect rolodex type")
	RETURN ""
ENDIF

PRIVATE curfile, docnum, szlet, cnter, prefx, clet
curfile = ALIAS()

SELECT 0
USE (f_mailid)

GOTO TOP
DO WHILE NOT RLOCK()
ENDDO

** IZ 06/14/02 add soft lock flag: loop until flag=.F.,
**             then place soft lock - replace with true
DO WHILE FLAG
ENDDO
REPLACE FLAG WITH .T.
** end IZ

cnter = "mail" + mailtype
docnum = &cnter                                 && Counter number

prefx = "m" + mailtype + "_pre"
szlet = &prefx                                  && Prefix
&&EF 04/14/03 K O P office use new range of mail ids
IF docnum >= IIF( UPPER(mailtype) == "D", 999999, 99999)
	REPLACE &cnter WITH IIF (UPPER( mailtype) == "D", 100001, 1)
*--kdl out 4/14/03: REPLACE &cnter WITH 1

	IF RIGHT(szlet,1) <> "Z"
		clet = RIGHT( szlet,1)
&& Increment Letter!!
		clet = CHR( ASC( clet) + 1)
		REPLACE &prefx WITH mailtype + clet
	ELSE
&& This should never happen!!
		DO WHILE .T.
			gfmessage("Seek MIS help! Please do not continue!!")
			gfmessage("Rolodex overflow !!")
		ENDDO
	ENDIF
ELSE
&& Increment counter!!
	REPLACE &cnter WITH &cnter + 1
ENDIF

** IZ 06/14/02 unlock soft lock
REPLACE FLAG WITH .F.
** end IZ

UNLOCK ALL
SELECT mailid
USE
IF NOT EMPTY( curfile)
	SELECT (curfile)
ENDIF

RETURN szlet + ALLTRIM( STR( docnum))
******************************************************************************
FUNCTION  replacedrps
PARAMETERS c_class
PRIVATE c_oldprt, c_order, l_skip
STORE "" TO c_oldprt,c_order

l_skip=.f.
IF NOT USED('rpqasgn')
IF pl_CAVer
	f_RpqASGN=IIF(pl_ofcPas, goapp.psdatapath,goapp.cadatapath)	+ "\RpqASGN.DBF"	
ELSE

	f_RpqASGN=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","KOP", "\")))+"RPQASGN.DBF"	
ENDIF
	
USE (f_rpqasgn) IN 0
ENDIF

SELECT rpqasgn
c_order=ORDER()
*SET ORDER TO qclass
*IF SEEK(c_class) 
LOCATE FOR UPPER(ALLTRIM(QCLASS))==ALLTRIM(UPPER(c_class))
IF FOUND()
 c_oldprt=printerid
IF NOT EMPTY( c_oldprt)
c_sql= "select RPSWORK.[dbo].[IfReplacedYet] ('" + c_oldprt	+ "')"

l_Gotit=oMed.sqlexecute(c_sql, "ReplacedYet"  )
	IF l_Gotit
	
				*l_skip=IIF(ReplacedYet.exp=1, .t., .f.)
				L_SKIP=ReplacedYet.exp
						
	ENDIF

endif

endif
SELECT rpqasgn
SET ORDER TO (c_order)
RETURN  l_skip