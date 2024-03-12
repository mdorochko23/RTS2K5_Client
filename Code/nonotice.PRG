** NoNotice.prg - Check to see if notices will print for subpoenas
** or authos. For subpoenas, if found in table, notices do NOT print
** For authos, if found in table, notices DO print.

parameters marea, mlit, mcourt, stype, llFromRev

private curfile, llNoNotice
curfile = alias()

marea = upper(alltrim(marea))
mlit  = upper(alltrim(mlit))
mcourt = upper(alltrim(mcourt))

if stype = "7"
   stype = "S"
else
   stype  = "A"
endif

private foundit,usednotc
**oMed = CREATEOBJECT("generic.medgeneric")													&&04/23/2021 WY #234875
**oMed.opentable("NoNotice")																&&04/23/2021 WY #234875
IF USED("Nonotice") = .f.																	&&04/23/2021 WY #234875
	LOCAL lcNonotice  																		&&04/23/2021 WY #234875
	lcNonotice=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","KOP", "\")) + "Nonotice")   	&&04/23/2021 WY #234875
	USE (lcNonotice) IN 0 SHARED															&&04/23/2021 WY #234875
ENDIF 																						&&04/23/2021 WY #234875

SELECT NoNotice
*llNoNotice = gfuse("NoNotice")

foundit = .f.

if !llFromRev
   select * from nonotice into cursor junk where ;
      (upper(alltrim(nonotice.area))==marea or alltrim(nonotice.area)=="*") and;
      (upper(alltrim(nonotice.lit))==mlit or alltrim(nonotice.lit)=="*") and ;
      (upper(alltrim(nonotice.court))==mcourt or alltrim(nonotice.court)=="*") and ;
      nonotice.type == stype
   if _tally > 0
      foundit = .t.
   endif
else
   select * from nonotice into cursor junk where ;
      (upper(alltrim(nonotice.area))==marea or alltrim(nonotice.area)=="*") and;
      (upper(alltrim(nonotice.lit))==mlit or alltrim(nonotice.lit)=="*") and ;
      (upper(alltrim(nonotice.court))==mcourt or alltrim(nonotice.court)=="*") and ;
      nonotice.type == stype and nonotice.FromRev
   if _tally > 0
      foundit = .t.
   endif
endif
SELECT nonotice
use
*=gfunuse("NoNotice",llNoNotice)

select junk
use

if not empty(curfile)
   select (curfile)
endif

if stype = "S"
return foundit
else
return !foundit
endif
