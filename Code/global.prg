
** GLOBAL: Library of useful RTS functions                                 º
** USED BY BOTH RTS AND UTILITIES PACKAGES
** 08/20/09   EF Replace PrintJCre with Jobcreate
** 02/23/09   EF USE addjobs 
** 07/07/08   EF USE SQL RPSWORK TABLES
** 12/13/05   EF removed GetHosp function.
** 09/29/05   EF  Parameter for the [FUNCTION gfPhoneToChar] is a string now 
**---------------------------old comemnts------------------------------------------------
** 05/09/03   EF  Add "C" cert type to getCertif()
** 11/08/02   DMA Add echo department to INLIST in gfDepartment
** 06/21/02   DMA Move MakeHash function to standalone module
** 06/19/02   DMA Replace mlogname with pc_UserID
** 06/18/02   DMA Comment out unused routine gfIsManager
** 04/05/02   HN  Cleaned up unused code in gfIsManager module.
** 03/19/02   KDL Modified getCertif sub to eliminate release of current
**       window.  replaced it with deac and a react at end of sub.
** 05/05/2001 DMA Add gfClrMsg
** 04/05/2001 DMA Replace APPEND BLANK w/ INSERT INTO where possible
** 03/07/2001 DMA Add gfLastAddr, gfZipDisp
** 09/21/2000 DMA Update gfEntryV for speed
**********************************************************************

FUNCTION gflastaddr
* Purpose   Takes city, state, and zip code information and formats it
*           into a single 40-character string for use in output
* Parms     c_city  - Name of city
*           c_state - Abbreviation of state name
*           c_zip   - Zip code
* Returns   Formatted zip code.
* History
* 03/07/2001 DMA Initial coding

lPARAMETERS c_city, c_state, c_zip
local c_lastline
c_lastline = IIF( NOT EMPTY(c_city), ALLT(c_city) + ", ", "") + ;
	IIF( NOT EMPTY(c_state), ALLT(c_state) + " ", "") + ;
	gfZipDisp(ALLT(c_zip))
c_lastline = PADR(c_lastline, 40)
RETURN c_lastline
*************************************************************************
FUNCTION gfZipDisp
* Purpose   Takes a zip code which may be in 5, 9, or 11-digit format and
*           prepares it for use in an output situation.
* Parms     c_zip   - Zip code field to be transformed
* Returns   Formatted zip code.
* Revision
* History
* 05-20-92  Revision: 15.0 dma
*             Initially written

lPARAMETERS c_zip

c_zip = ALLTRIM( STRTRAN(c_zip, "-", ""))

DO CASE
	CASE LEN(c_zip) > 5
		c_zip = ALLTRIM(TRANSFORM(c_zip, pc_fmtzip))
	CASE LEN(c_zip) = 5
		c_zip = c_zip + SPAC(7)
	CASE LEN(c_zip) = 10
		c_zip = c_zip + "  "
ENDCASE
RETURN c_zip
******************************************************************
FUNCTION gfOpen
lPARAMETERS szTable, szOrder
local DBALIAS, nWorkArea

SELECT 0
nWorkArea = SELECT()
USE (szTable) IN (nWorkArea) AGAIN
IF TYPE("szOrder") = "C"
	szOrder = ALLTRIM(szOrder)
	SET ORDER TO (szOrder)
ENDIF
DBALIAS = ALIAS()

GO TOP

RETURN DBALIAS
*******************************************

FUNCTION gfClose
lPARAMETERS DBALIAS
local dbInit
dbInit = SELECT()
SELECT (DBALIAS)
UNLOCK
USE
SELECT (dbInit)
RETURN .F.

************************************************



FUNCTION gfYesOrNo
lPARAMETERS szQuestion
local lAnswer, wYesOrNo, szAnswer
szAnswer = "Y"
DEFINE WINDOW wYesOrNo ;
	FROM 8,5 TO 12,74 TITLE " Yes or No " DOUBLE ;
	NOCLOSE NOFLOAT NOGROW NOMINIMIZE SHADOW NOZOOM ;
	COLOR SCHEME 12
ACTIVATE WINDOW wYesOrNo
@ 1,0 SAY RTRIM(PADC(szQuestion+" (y/n):",67)) GET szAnswer PICTURE "Y"
READ
lAnswer = (szAnswer="Y")
DEACTIVATE WINDOW wYesOrNo
RELEASE WINDOW wYesOrNo
RETURN lAnswer


**************************************************************
**EF 09/29/05- parameter is a string now
FUNCTION gfPhoneToChar
lPARAMETERS cPhone
local lcPhone
lcPhone = PADL(ALLTRIM(cPhone), 10, " ")
lcPhone = LEFT(lcPhone,3) + "-" + SUBSTR(lcPhone,4,3) + "-" + RIGHT(lcPhone,4)
RETURN lcPhone
***************************************************************
FUNCTION gfCharToPhone
lPARAMETERS szPhone
local nPhone, setDecimals
setDecimals = SET("decimals")
SET DECIMALS TO 0
nPhone = VAL( LEFT(szPhone,3) + SUBSTR(szPhone,5,3) + RIGHT(szPhone,4) )
SET DECIMALS TO (setDecimals)
RETURN nPhone

**************************************
NOTE Beginning of RTS.TA_LIB functions
**************************************

*************************************************************
PROCEDURE printgroup
lPARAMETER mStr, szStr

mStr=mStr+ TRANSFORM(LEN(ALLTRIM(szStr)),"@L 9999") + "3/" +szStr +"/"
RETURN

*************************************************************

PROCEDURE printfield
lPARAMETER mStr, szName, szValue
PRIVATE str_value AS String
str_value=""
szValue=convertToChar(szValue,0)
szName=convertToChar(szName,0)

IF UPPER(ALLTRIM(szName))=="TAG"
	gnTag = INT(VAL(szValue))
ENDIF
 **07/30/08 START
IF INLIST(UPPER(ALLTRIM(szname)),'INFOTEXT','INFOITEM','CCTXT')
 		str_value=remnonasci( ALLTRIM(szvalue))
ELSE
		str_value=ALLTRIM(szvalue)
ENDIF

str_value= STRTRAN( str_value, "''", "'")
**07/30/08 END

mStr = mStr + ;
	TRANSFORM(LEN(ALLTRIM(szName)), "@L 9999") + "1/" + ;
	ALLTRIM(szName) + "/" + ;
	TRANSFORM(LEN(ALLTRIM(str_value)),"@L 9999") + "2/" + ;
	STRTRAN(ALLTRIM(str_value), "^", " ") + "/"

RETURN

******************************************************

PROCEDURE PrintEnq
lPARAMETER ADATA, ACLASS, aGroup,c_clcode, n_tag, c_userid
	DO prtEnq_2 WITH ADATA, ACLASS, aGroup, "",c_clcode, n_tag, c_userid
	
RETURN

* ----- PrtEnqa -------------------------------------
* Enqueue a print job
**8/10/09 CALL jobcreate
PROCEDURE prtEnq_2
lPARAMETER ADATA, ACLASS, aGroup, aAddress, c_clcode, n_tag, c_userid, lcIDSTC
IF PARAMETERS()<8
   lcIDSTC=''
ENDIF 
	DO jobcreate WITH  ADATA,ACLASS, aGroup, aAddress, c_clcode, n_tag, c_userid, .F., lcIDSTC

RETURN
*************************************************************************************
FUNCTION makealph

lPARAMETERS mStr

** Makealph.prg
** Strips off all non-alphanumeric characters from a string (mstr)

local retstr,i,ch
retstr = ""
FOR i = 1 TO LEN(mStr)
	ch = SUBSTR(mStr,i,1)
	** A-Z, a-z, 0-9
	IF BETWEEN(ASC(ch),65,90) OR BETWEEN(ASC(ch),97,122) OR ;
			BETWEEN(ASC(ch),48,57) OR ASC(ch)=32

		retstr = retstr + ch
	ELSE
		retstr = retstr + "x"
	ENDIF
ENDFOR
RETURN retstr



***************************************************************************



PROCEDURE spinclose
IF WEXIST("WndStat")
	DEACTIVATE WINDOW wndstat
	RELEASE WINDOWS wndstat
ENDIF
RETURN
*********************************************************
FUNCTION getCertif
** Allows user to select one or more certification types for a
** request. The string of selected type codes is stored in global
** variable pc_CertTyp, and is also returned to the calling program.
**
***DMA 07/09/04 Replace gsCertType with pc_CertTyp
***DMA 04/16/04 Use globally-defined array of certification types
***EF  04/05/01 Returns a certification type for all kinds of requests
local lcCType, lcActWind, iCnt
lcAlias = ALIAS()

*--3/19/02 kdl start: deact activ window instead of releasing it
lcActWind = WINDOW()
IF NOT ALLT(lcActWind) == ""
	DEAC WIND (lcActWind)
ENDIF

CREATE TABLE C:\TEMP\TmpCert (DESC C(35), SELECT L, CODE C(5))
SELECT TmpCert
* 04/16/04 DMA Certificate types now in pc_Certs, defined in Public.Prg
APPEND FROM ARRAY pc_Certs FIELDS DESC, CODE
REPLACE ALL SELECT WITH .F.
lc_CertSave = pc_CertTyp
IF NOT EMPTY( pc_CertTyp)
	l_nrec = LEN( lc_CertSave)
	iCnt = 1
	lc_Cert = ""
	FOR iCnt = 1 TO l_nrec
		IF iCnt > l_nrec
			EXIT
		ENDIF
		lc_Cert = SUBSTR( lc_CertSave, iCnt, 1)
		IF lc_Cert <> "L"
			SELECT TmpCert
			REPLACE SELECT WITH .T. FOR CODE = lc_Cert
		ENDIF
	NEXT
ENDIF
SELECT TmpCert
GO TOP
ON KEY
DEFINE WINDOW w_GetCert FROM 4, 10 TO MIN( 7+RECC("TmpCert"), 20), 55;
	COLOR SCHEME 10 ;
	CLOSE FLOAT GROW ZOOM
BROWSE FIELDS ;
	SELECT :H= "Select" :P=.F., ;
	DESC   :H= "Certificate", ;
	CODE   :H= "Code" ;
	FREEZE SELECT ;
	TITLE " T/F to Select/Deselect; <Ctrl+W> to save " ;
	WINDOW w_GetCert

GOTO TOP
lcCType = ""
SCAN
	IF TmpCert.SELECT
		lcCType = ALLTRIM(lcCType) + ALLTRIM( TmpCert.CODE)
	ENDIF
ENDSCAN
SELECT TmpCert
USE
DELETE FILE C:\TEMP\TmpCert.DBF

IF NOT EMPTY( lcAlias)
	SELECT (lcAlias)
ENDIF
DEACTIVATE WINDOW w_GetCert
RELEASE WINDOW w_GetCert
ON KEY
pc_CertTyp = lcCType

RETURN lcCType
***********************************************
********************************
NOTE End 
********************************







