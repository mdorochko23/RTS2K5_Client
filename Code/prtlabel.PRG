** PrtLabel.prg
* Called by PrintBar
* Calls GetCount

*--3/14/06 kdl start: VFP RTS conversion

** 9/15/2003 HN  Prints Labels for shipping Photo/Video.
**               For those with Label Printer only

PARAMETERS lblCount

PRIVATE lcCommand, lcHoldDir

*!*	do case
*!*		case !used("tamaster") or !used("record")
*!*			return
*!*		case tamaster.cl_code <> Record.cl_code
*!*			return
*!*		case eof("tamaster") or eof("record")
*!*			return
*!*	endcase

IF EMPTY(pn_lrsno) OR EMPTY(pn_tag)
	RETURN
ENDIF

lnCount = lblCount * 2
lnCount = getCount(lnCount)
IF lnCount <= 0
	RETURN
ENDIF

SET CONSOLE OFF

SET PRINTER TO c:\RTLabel.txt
SET PRINT ON

?? ALLTRIM(STR(pn_lrsno)) + " - " + ALLTRIM(STR(pn_tag))
? ALLTRIM(pc_plfname) +  " " + ALLTRIM(pc_plfname)
? pc_Descrpt
*!*	?? ALLTRIM(STR(tamaster.lrs_no)) + " - " + ALLTRIM(STR(RECORD.TAG))
*!*	? ALLTRIM(tamaster.name_first) +  " " + ALLTRIM(tamaster.name_last)
*!*	? RECORD.DESCRIPT

SET PRINTER OFF
SET PRINTER TO

SET CONSOLE ON

lcCommand = "h:\release\utils\labels\RtLabels C:\RtLabel.Txt " +;
	ALLTRIM(STR(lnCount))

lcHoldDir = SYS(5)+ALLTRIM(CURDIR())
SET DEFA TO h:\RELEASE\utils\labels

! &lcCommand

SET DEFA TO &lcHoldDir
