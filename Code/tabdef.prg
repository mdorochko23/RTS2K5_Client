PROCEDURE TabDef
*** Tabdef.prg
** Called by Orders, ACManOrd
** Get an attorney's default values for billcat, numcopy, fedex, mhandling
** from tabills file
* Modified"
* 9/21/04 kdl - Added default ship method string set up
****************************************************************************************

lPARAMETERS mcl, matc, mbillcat, mnumcopy, mfedex, mhandling, c_shipstr

LOCAL tabused, tabord, recnum, curfile

curfile = ALIAS()
tabord = ORDER()
recnum = IIF(NOT EMPTY (curfile), RECNO(), 1)

tabused = gfuse( "tabills")
SET ORDER TO ClAc
* 07/15/03 DMA Always fill in defaults in advance.
mbillcat = "P"
mnumcopy = 1
mfedex = .F.
mhandling = "N"

IF SEEK( mcl + matc)
   IF ALLTRIM( tabills.cl_code) == ALLTRIM( mcl) ;
         and ALLTRIM( tabills.at_code) == ALLTRIM( matc)
      mbillcat  = tabills.billcat
      mnumcopy  = tabills.numcopy
      mfedex    = tabills.fedex
      mhandling = tabills.handling
   ENDIF
ENDIF

*--9/21/04 kdl start: ship method default
c_shipstr = ""
l_gtaship = gfuse("gtaship")
SELECT gtaship
c_order = ORDER()
SET ORDER TO clat IN gtaship
IF SEEK(  mcl + matc) AND ;
   ALLTRIM( gtaship.cl_code) == ALLTRIM( mcl) AND ;
   ALLTRIM( gtaship.at_code) == ALLTRIM( matc)
	IF gtaship.rpapernum > 0
		setpub("c_shipstr", "P")
	ENDIF
	IF gtaship.rdsnum > 0
		setpub("c_shipstr", IIF( EMPTY(getpub("c_shipstr")), "D", getpub("c_shipstr") + ",D"))
	ENDIF
	IF gtaship.rvsnum > 0
		setpub("c_shipstr", IIF( EMPTY(getpub("c_shipstr")), "V", getpub("c_shipstr") + ",V"))
	ENDIF
	IF gtaship.rcdnum > 0
		setpub("c_shipstr", IIF( EMPTY(getpub("c_shipstr")), "C", getpub("c_shipstr") + ",C"))
	ENDIF
	IF gtaship.rshipftp
		setpub("c_shipstr", IIF( EMPTY(getpub("c_shipstr")), "F", getpub("c_shipstr") + ",F"))
	ENDIF
ELSE
	setpub("c_shipstr",  "P")
ENDIF
SET ORDER TO (c_order) IN gtaship
=gfunuse("gtaship", l_gtaship)
*--9/21/04 kdl end:


IF NOT EMPTY( curfile)
   SELECT (curfile)
   IF NOT EMPTY( tabord)
      SET ORDER TO &tabord
   ENDIF
   IF BETWEEN( recnum, 1, RECCOUNT())
      GO recnum
   ELSE
      GO TOP
   ENDIF
ELSE
   = gfunuse( "tabills", tabused)
ENDIF
RETURN
