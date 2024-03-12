*****************************************************************************
* PrintBar.prg
*   Allows user to print Bar Code, CA first look cover pages,
*   and storage labels
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 10/19/04  Hsu   Enlarge Deponent barcodes
* 7/15/04   EF    Added "B" (Bates needed)
* 9/15/03   HN    Added option to Print Labels (for Photo/Video)
* 4/09/04   kdl   added skip condition to first look prompt for KOP
* 12/10/02  kdl   Removed parameter statement and substituted public variables
*                 for the originally passed values lrs_no and lnTag
* 04/18/02  KDL   Repositioned tamaster Record pointer at current case
* 03/23/01  DMA   Use bar-code character definitions in PUBLIC.PRG
* 03/05/99  Riz   Add popup to select "Bar Code" or "First Look"
* 03/05/99  Riz   Add cabability for printing the "first look" page
* 09/18/97  Hsu   Initial release for RTS 3.0
*****************************************************************************
*
*  Called by DepOpts
*  Calls FLook, gfBarDef, PrtLabel
*  Assumes that gfGetCas, gfGetDep have been called

*--kdl out 12/10/02: Parameter nlrsno, lnTag
PRIVATE lcAlias, nnarrow, nbarhi
lcAlias = ALIAS()
SELECT Tamaster

*--4/18/02 kdl start: need to ensure tamaster record pointer is at current case
PRIVATE  m.lcCurOrd
m.lcCurOrd = ORDER()
SET ORDER TO lrs_no
SEEK (pn_lrsno)
SET ORDER TO (m.lcCurOrd)
*--4/18/02 kdl end

DEFINE POPUP v_opts TITLE " Printing Options " FROM 10,10
DEFINE BAR 1 OF v_opts ;
   PROMPT " Print \<Bar Code " ;
   MESSAGE "Generate a bar-code sheet for this deponent."
*--4/09/04 kdl start: added the skip condition
DEFINE BAR 2 OF v_opts ;
   PROMPT " Print \<First Look " ;
   MESSAGE "Generate a first-look delivery cover page." ;
   SKIP FOR pc_Offcode = "P"
*-- 4/9/03 kdl end:
DEFINE BAR 3 OF v_opts ;
   PROMPT " Print \<Labels " ;
   MESSAGE "Print Labels (Authorized users only)" ;
   SKIP FOR pc_Offcode <> "P"

DEFINE BAR 4 OF v_opts PROMPT "\-"
DEFINE BAR 5 OF v_opts ;
   PROMPT " \<Cancel " ;
   MESSAGE "Cancel printing and return to deponent options menu."
ON SELECTION POPUP v_opts ;
   DO v_option IN printbar WITH BAR()
ACTIVATE POPUP v_opts
RELEASE POPUP v_opts
IF NOT EMPTY(lcAlias)
   SELECT (lcAlias)
ENDIF
RETURN

** Popup selection
PROCEDURE v_option
PARAMETERS lnBar
HIDE POPUP V_OPTS
DO CASE
   CASE lnBar=1                     && print out bar code
      *--10/19/04 Hsu enlarge barcode
      If .F. Then
         nnarrow = 3.60
         nbarhi = 3
      Else
         nnarrow = 5.5
         nbarhi = 4
      Endif
      *--10/19/04 Hsu enlarge barcode End
      DO gfBarDef WITH nnarrow, nbarhi
      DO lfBarCode

   CASE lnBar=2                     && print CA First-look cover sheet
*!*	*!*	      DO flook
*!*	*!*	Craig Anderson override to compile

   CASE lnBar = 3                   && print storage labels
*!*	*!*	      DO prtlabel WITH 1

ENDCASE
DEACTIVATE POPUP v_opts
RETURN

* --------------------------------------------------------------
* Print out bar code
* --------------------------------------------------------------
PROCEDURE lfBarCode
PRIVATE arblines, szchars, szcode
DIMENSION arbline[8]
EXTERNAL ARRAY artext

WAIT WINDOW "Printing BarCode sheet" NOWAIT NOCLEAR 

* Process the text items to be printed as BarCodes!!
&& Bar Code #1 -- dummy tab
arbline[1] = "000"

&& Bar Code #2: LRS_No
arbline[2] = ALLTRIM(Master.lrs_no)
&& Check Length of LRS_No
IF LEN( arbline[2]) < 8
   arbline[2] = arbline[2] + REPLICATE( "-", 8 - LEN( arbline[2]))
ENDIF

&& BarCode #3: Tag number!!
*--12/10/02 kdl start: replace local with public variables for tag number
IF CaseDeponent.Tag <> 0
   *--kdl out 12/10/02: IF lnTag != 0
   IF CaseDeponent.Tag < 10
      *--kdl out 12/10/02:   IF lnTag < 10
      arbline[3] = "00" + ALLTRIM( STR( CaseDeponent.Tag))
      *--kdl out 12/10/02:      arbline[3] = "00" + ALLTRIM(STR(lnTag))
   ELSE
      arbline[3] = ALLTRIM( STR( CaseDeponent.Tag))
      *--kdl out 12/10/02:      arbline[3] = ALLTRIM(STR(lnTag))
   ENDIF
   IF LEN(arbline[3]) < 3
      arbline[3] = REPLICATE( "0", 3 - LEN(arbline[3])) + arbline[3]
   ENDIF
ELSE
   arbline[3] = "000"
ENDIF

&& Bar Code #4: Record Provider (deponent)
arbline[4] = lfDeponent( Master.cl_code, CaseDeponent.Tag)
*--kdl out 12/10/02:arbline[4] = lfDeponent(tamaster.cl_code, lnTag)
arbline[4] = STRTRAN( arbline[4], "'")
arbline[4] = STRTRAN( arbline[4], "(")
arbline[4] = STRTRAN( arbline[4], ")")
arbline[4] = STRTRAN( arbline[4], "*")
arbline[4] = STRTRAN( arbline[4], ",")
arbline[4] = STRTRAN( arbline[4], "&")
arbline[4] = STRTRAN( arbline[4], "#")
arbline[4] = STRTRAN( arbline[4], ";")
arbline[4] = STRTRAN( arbline[4], '"')
IF LEN( arbline[4]) > 25
   arbline[4] = LEFT( arbline[4], 25)
ENDIF
arbline[4] = LEFT( ALLTRIM( arbline[4]) + REPL( "-", 25), 25)

* -- Barcodes 5-7: Plaintiff First Name, Last Name, Middle Initial --
arbline[5] = ALLTRIM( Master.name_first)
arbline[5] = STRTRAN( arbline[5], "*")
arbline[5] = STRTRAN( arbline[5], ",")
arbline[5] = STRTRAN( arbline[5], "'")
arbline[5] = STRTRAN( arbline[5], "&")
arbline[5] = STRTRAN( arbline[5], "#")
arbline[5] = STRTRAN( arbline[5], " ", "-")
arbline[5] = LEFT( ALLTRIM( arbline[5]) + REPL( "-", 6), 6)

arbline[6] = ALLTRIM( Master.name_last)
arbline[6] = STRTRAN( arbline[6], "*")
arbline[6] = STRTRAN( arbline[6], ",")
arbline[6] = STRTRAN( arbline[6], "'")
arbline[6] = STRTRAN( arbline[6], "&")
arbline[6] = STRTRAN( arbline[6], "#")
arbline[6] = LEFT( ALLTRIM( arbline[6]) + REPL( "-", 13),13)

arbline[7] = ""
IF NOT EMPTY(Master.name_init)
   szchars = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-. *$/+%"
   IF AT( Master.name_init, szchars) > 0
      IF Master.name_init <> "*"
         arbline[7] = Master.name_init
      ENDIF
   ENDIF
ENDIF

arbline[7] = LEFT( ALLTRIM( arbline[7]) + REPL( "-", 3),3)

* -- Date of Birth --
** This field is being removed to make room for Deponent name

** IF NOT EMPTY(Master.brth_date)
**    arbline[8] = left(alltrim(STRTRAN(Master.brth_date, "/", "-"))+"-",1)
** ELSE
**    arbline[8] = "--------"
** ENDIF

arbline[8] = "---"

&& BarCode 9 is Version #!!
** arBLine[9] = "00"

&& BarCode #10 is the Print Status (L/U)!!
** arBLine[10] = "L"

&& Print the BarCode
SET PRINTER TO LPT1
SET DEVICE TO PRINTER
SET PRINTER ON
SET CONSOLE OFF

DO lfPrtCode WITH arbline
EJECT
SET PRINTER OFF
SET PRINTER TO
SET CONSOLE ON
SET DEVICE TO SCREEN
WAIT CLEAR
RETURN

* --------------------------------------------------------------
PROCEDURE lfPrtCode
PARAMETERS artext
PRIVATE nbetween, nlength, nmargin

nlabelhi = 2
nskipline = nlabelhi - nbarhi
ncpi = 10
nwide = ROUND( nnarrow * 2.25,0)                && 2.25 x nNarrow
nlblacross = 3
bartext = SPACE(30)
&& Get current margin position
nmargin = SET( "MARGIN")
SET MARGIN TO 0

? " " + CHR(13) &&+ CHR(10) AT 0

* -- Do this for each row in the array --
FOR x = 1 TO ALEN( artext)
   && Setup for Code39 using "*" for check digits
   artext[x] = "*" + UPPER( ALLTRIM( artext[x])) + "*"
   bartext = ALLTRIM( artext[x])
   barstring = artext[x]

   && Code39 width
   nlength = ( LEN( barstring) + 2) * ((3 * nwide) + (6 * nnarrow) + nnarrow)
   nbetween = IIF( nlblacross > 1, (2550 / nlblacross) - nlength, 0)
   ndistance = nlength + nbetween

   && This prints out the bar codes and inter-code spacing!!
   * ??? SPACE(30) + gfCode39(barstring)
   ??? SPACE(6) + gfCode39(barstring)
   ??? pc_esc + "*p+" + ALLTRIM(STR(nbetween,5)) + "X"

   && Move Printer position, then print the text below the bar code
   FOR kk = 1 TO nbarhi - 1
      IF X==1 AND KK==1
       
         Private lc_f42B         
         lc_f42B = pc_esc + "(s1p42v0s3b4T"
         ??? lc_f42b
***** Craig Anderson commented
         pl_bates = .F.
         ?iif(pl_bates,"B","") AT 30        
         pc_f10  = pc_esc + "(s0p10v0s0b4T"
         ??? pc_f10
      
      else
      ??? CHR(10) + CHR(13)
      ENDIF
   ENDFOR
   ? artext[x] AT 6
   *   ? artext[x] AT30

   && Move Printer position to print the next barcode!!
   FOR kk = 1 TO 3	&& nbarhi + 1
      ??? CHR(10) + CHR(13)
   ENDFOR
NEXT x

*--12/10/02 kdl start: use public variable instead of local
IF CaseDeponent.Tag <> 0
   *--kdl out 12/10/02: If lnTag != 0
   ? lfDepDesc(Master.cl_code, CaseDeponent.Tag) AT 30
   *--kdl out 12/10/02:? lfDepDesc(Master.cl_code, lnTag) At 30
   *--12/10/02 kdl end:
ENDIF
SET MARGIN TO nmargin                           && Restore margin position
RETURN

* --------------------------------------------------------------
FUNCTION lfDepDesc
PARAMETER lcClient, lnTag
PRIVATE lcDesc, lcEntry, lcAlias

*lcAlias = ALIAS()
*lcEntry = gfEntryN( lcClient)
*SELECT ( lcEntry)
*SET ORDER TO TAG cltag
*IF SEEK( lcClient + "*" + STR( lnTag))
*   lcDesc = UPPER( ALLTRIM( Descript))
*ELSE
*   lcDesc = "Unknown deponent description:" + ALLTRIM( lcClient) + ;
*      " Tag:" + ALLTRIM( STR( lnTag))
*ENDIF
*IF NOT EMPTY( lcAlias)

*   SELECT (lcAlias)
*ENDIF

IF LEN(CaseDeponent.Name) > 0
   lcDesc = UPPER( ALLTRIM( CaseDeponent.Name))
ELSE
   lcDesc = "Unknown deponent description:" + ALLTRIM( lcClient) + ;
      " Tag:" + ALLTRIM( STR( CaseDeponent.Tag))
ENDIF
RETURN lcDesc

* ---------------------------------------------------------------
FUNCTION lfDeponent
PARAMETER lcClient, lnTag
PRIVATE lcDesc, lcEntry, lcAlias

lcAlias = ALIAS()

lcDesc = ""
IF USED( "Record")
   IF ALLTRIM( Record.cl_code) == ALLTRIM( lcClient) AND Record.Tag = lnTag
      lcDesc = Record.Descript
   ENDIF
ENDIF

IF NOT EMPTY(lcAlias)
   SELECT (lcAlias)
ENDIF

RETURN ALLTRIM(lcDesc)
