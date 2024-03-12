
**EF 5/15/06 -added from the RTBilling .
PARAMETERS   lnTag

SET NEAR ON
PRIVATE d_depo, n_depoday, c_depomonth, n_depoyear, c_depoday, c_depoyear
PRIVATE d_recv, n_recvday, c_recvmonth, n_recvyear, c_recvday, c_recvyear
PRIVATE c_witness, l_changed, l_return, c_pages, n_done, c_changed, c_return
Public lnAmount, lcAlias, lc_Item1, lc_Atty1, lc_Atty2,lc_Item2, lc_Item3, lc_Item4, ;
	lc_Item5, lc_Item6, lc_Item7, lc_Item8, lc_Item9, lc_Item10, lc_Item11, ln_page , lc_nextpg
PRIVATE lnLMarg, lnPlOff, lnRMarg, lnPLen  && Save Setting for restoration later
STORE "" TO lc_Item1, lc_Atty1, lc_Atty2,lc_Item2,lc_nextpg, ;
	lc_Item3, lc_Item4 ,lc_Item5, lc_Item6, lc_Item7, lc_Item8, lc_Item9, lc_Item10, lc_Item11
_SCREEN.MOUSEPOINTER=11
c_pages = "page           "
d_depo = d_today
d_recv = d_today
c_witness = SPAC(40)
l_changed = .F.
c_changed = "has not"
STORE 1 TO n_done, ln_page
lnAmount = 0
lcAmount = "______________"


omed=CREATEOBJECT('medgeneric')

DO getofccert WITH  timesheet.TAG

SELECT OfcrCert
*SET ORDER TO Cltag
IF NOT EOF()&&SEEK(PC_Clcode + "*" + STR(lnTag))
	d_depo    = OfcrCert.depodate
	c_witness = OfcrCert.custodian
	d_recv    = OfcrCert.recptdate
	l_changed = OfcrCert.changed
	c_pages   = OfcrCert.pageschg
	lnAmount  = OfcrCert.Amount
	IF lnAmount > 0
		lcAmount  = ALLTRIM(TRANSFORM(lnAmount,"99,999.99"))
	ENDIF


ELSE
	gfmessage( "Reprint information missing.")

	RETURN
ENDIF
c_changed = "has " + IIF( l_changed, "", "not ")
n_depoday = DAY(d_depo)
c_depoday = ALLT(STR(n_depoday, 2))
c_depoday = PrtDate(n_depoday, c_depoday)
c_depomonth = ALLT(CMONTH(d_depo))
n_depoyear = YEAR(d_depo)
c_depoyear = STR(n_depoyear, 4)
n_recvday = DAY(d_recv)
c_recvday = ALLT(STR(n_recvday, 2))
c_recvday = PrtDate(n_recvday, c_recvday)
c_witness = ALLT(c_witness)
c_recvmonth = ALLT(CMONTH(d_recv))
n_recvyear = YEAR(d_recv)
c_recvyear = STR(n_recvyear, 4)
WAIT WINDOW "Printing Officer's Certification Page." NOWAIT NOCLEAR 

SET CONSOLE OFF
&& Store current workarea
lcAlias = ALIAS()

lcCause = "Cause No.: " + pc_Docket

SELECT timesheet
lcAtCode = ALLTRIM(Rq_at_code)
lcDepName = ALLTRIM(DESCRIPT)

&& Requesting Attorney Info
lc_Addtype="M"

omed.sqlexecute("exec GetAttyAddressByAtCodeAndAddType @Atcode='" + lcAtCode+ "', @AddType='" +lc_Addtype + "'","TaattyAd")
SELECT TAAttyAd
*SEEK lcAtCode
WAIT WINDOW "Getting Attorney's data...Wait" NOWAIT NOCLEAR 
lcRqName = ALLTRIM(NewFirst) + " " + ALLTRIM(NewLast) + ;
	", " + ALLTRIM(TITLE)
lcRqAdd1 = ALLTRIM(add1)

IF !EMPTY(add2)
	lcRqAdd2 = ALLTRIM(add2)
	lcRqCSZ = ALLTRIM(city)+" "+ALLT(state)+" "+ALLTRIM(zip)
ELSE
	lcRqAdd2 = ALLTRIM(city)+" "+ALLT(state)+" "+ALLTRIM(zip)
	lcRqCSZ = ""
ENDIF
IF ALLTRIM(pc_platcod) == lcAtCode
	lcRqType = "Attorney for Plaintiff"
ELSE
	lcRqType = "Attorney for Defendant"
ENDIF

lc_Item1="Pursuant to Texas Rules of Civil Procedure 203, I, the undersigned Notary " + CHR(13);
	+ "Public for the State of Texas, do hereby certify the following:"

lc_Item2="On the " + ALLTRIM((c_depoday))+ " day of " +ALLTRIM((c_depomonth)) + ;
	", " + c_depoyear + ", " + ALLTRIM( c_witness)

lc_Item3="was duly cautioned and sworn to testify the truth, the whole truth, and " + ;
	"nothing but the truth."

lc_Item4= "The preceding transcript is a true and accurate record of the testimony " + CHR(13 ) + ;
	"given by " + c_witness + ", Custodian of Records for"


lc_Item5 = "Charges for RECORDTRAK's preparation of Answers to Deposition By Written" +CHR(13)+ ;
	"Questions and records pertaining to " + ALLTRIM(pc_plnam) + ", along with " + CHR(13) + ;
	"any requested exhibits, are $ "  + ALLTRIM(lcAmount) + "."

lc_Item6 = "On the " + ALLTRIM(c_depoday) + " day of " + ALLTRIM(c_depomonth) + ", " + ;
	c_depoyear+ ", " + "the Answers to Written Deposition" + CHR(13) + ;
	"Questions were submitted to " +  c_witness + ", for examination and" + CHR(13) + ;
	"signature, and were returned to me by the " + ALLTRIM(c_recvday)+ " day of " ;
	+ ALLTRIM( c_recvmonth) + ", " + c_recvyear + "."

lc_Item7= ALLTRIM(c_witness)+ " " + ALLTRIM(c_changed) + " made changes in the preceding " + CHR(13) + ;
	"Answers To Written Deposition Questions."


IF l_changed
	lc_Item8="The changes are reflected on " + ALLTRIM(c_pages) + " of the transcript."

ENDIF

lc_Item9=ALLTRIM( c_witness) +  " has returned the examined and signed" + CHR(13) + ;
	"transcript to me on the " + ALLTRIM( c_recvday) + " day of " + ALLTRIM(c_recvmonth) + ;
	", " + c_recvyear + "."

lc_Item10="The original Answers to Written Deposition Questions, any copies of all " + CHR(13) + ;
	"exhibits thereto, and a copy of this Officer's Certification was " + CHR(13) + ;
	"delivered by certified mail or hand delivery to:"

&& Code to go through TABills and print names of all other
&& participating attorneys in this case.

lcWrkArea = ALIAS()
l_Tab= gettabill ( PC_Clcode)

SELECT tabills
*SEEK lcClcode
DIMENSION arAtty[1]

arAtty = ""
arAtty[1] = "No Opposing Atty"
x = 0

llPlAdded = .F.

&& Display names of Opposing Counsel
DO WHILE ALLTRIM(tabills.cl_code) == ALLTRIM(PC_Clcode) AND NOT EOF()
	cAtty = ALLTRIM(tabills.At_Code)
&& Do not include the Requesting Attorney
	IF cAtty == ALLTRIM(pc_rqatcod)
		SKIP
		LOOP
	ENDIF

&& Locate Attorney in TAAtty
	* DO getatty WITH cAtty
	lc_Addtype="M"
	omed.sqlexecute("exec GetAttyAddressByAtCodeAndAddType @Atcode='" + cAtty+ "', @AddType='" +lc_Addtype + "'","Taatty")


	SELECT TAAtty
	*SEEK cAtty

	x = x + 1
	DIMENSION arAtty[x]
	IF x < 10
		arAtty[x] = " " + ALLTRIM(STR(x)) + ". "
	ELSE
		arAtty[x] = ALLTRIM(STR(x)) + ". "
	ENDIF

&& Store Attorney name and Title
	arAtty[x] = arAtty[x] + ALLTRIM(NewFirst) + " " + ;
		ALLTRIM(NewLast)

	IF NOT EMPTY(TITLE)
		arAtty[x] = arAtty[x] + ", " + ALLTRIM(TITLE)
	ENDIF

	IF pc_platcod = tabills.At_Code
		llPlAdded = .T.
	ENDIF

	SELECT tabills
	SKIP
ENDDO

&& Plaintiff Atty

IF ALLTRIM(pc_platcod) != ALLTRIM(lcAtCode) AND !llPlAdded
	*DO getatty WITH pc_platcod
	lc_Addtype="M"
	omed.sqlexecute("exec GetAttyAddressByAtCodeAndAddType @Atcode='" + pc_platcod+ "', @AddType='" +lc_Addtype + "'","Taatty")
	SELECT TAAtty
	*SEEK ALLTRIM(pc_platcod)

	x = x + 1
	DIMENSION arAtty[x]
	IF x < 10
		arAtty[x] = " " + ALLTRIM(STR(x)) + ". "
	ELSE
		arAtty[x] = ALLTRIM(STR(x)) + ". "
	ENDIF

&& Store Attorney name and Title
	arAtty[x] = arAtty[x] + ALLTRIM(NewFirst) + " " + ;
		ALLTRIM(NewLast)
	IF NOT EMPTY(TITLE)
		arAtty[x] = arAtty[x] + ", " + ALLTRIM(TITLE)
	ENDIF
ENDIF
SELECT &lcWrkArea

IF ALEN(arAtty,1) > 16
&& Have to print on next page!!
	ln_page = 2
	lc_nextpg=  "(Continued on next page)"
	*EJECT
ENDIF

FOR x = 1 TO ALEN(arAtty,1)
	lc_Atty1 = ALLTRIM(lc_Atty1) + CHR(13) + ALLTRIM(arAtty[x] )
	IF x + 1 <= ALEN(arAtty,1)
		x = x + 1
		lc_Atty2=ALLTRIM(lc_Atty2)+ CHR(13) +ALLTRIM((arAtty[x]))
	ENDIF
NEXT x

lc_Item11= "RECORDTRAK #: " + ALLTRIM(STR(pn_lrsno))+ "." +ALLTRIM(STR(lnTag))

SET PRINTER ON

*SET PRINTER TO name  gaPrinters (2,1) &&SHERI#HP LASERJET 1100    &&hp81 &&\\LRS_Texas\Tx_4100\
lcprinter=GETPRINTER()
IF !EMPTY(lcprinter)
	*SET PRINTER TO NAME (lcprinter)   && note the brackets
ENDIF


SELECT OfcrCert
*REPORT FORM txofcert2 RANGE 1 , ln_page 
REPORT FORM txofcert2 RANGE 1 , ln_page  TO PRINTER NAME lcprinter

SET CONSOLE ON

IF !EMPTY(lcAlias)
	SELECT &lcAlias
ENDIF
_SCREEN.MOUSEPOINTER=0
WAIT CLEAR

RETURN
*****************************************************************************************88
FUNCTION PrtDate
	PARAMETERS n_day, c_day

	DO CASE
		CASE INLIST(n_day, 1, 21, 31)
			c_day = c_day + "st"
		CASE INLIST(n_day, 2, 22)
			c_day = c_day + "nd"
		CASE INLIST(n_day, 3, 23)
			c_day = c_day + "rd"
		OTHERWISE
			c_day = c_day + "th"
	ENDCASE
	RETURN c_day


