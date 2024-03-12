PROCEDURE WaitScr
* Called by DepOpts, Outstand, RdxFind, RoloFind, RoloInfo, RoloUtil,
*           SelServ, assorted routines within Procedure file FLProc
parameters waitstr


set cursor off
IF NOT WEXIST("waitwin")
   DEFINE WINDOW waitwin ;
      FROM INT((SROW()-5)/2),INT((SCOL()-54)/2) ;
      TO INT((SROW()-5)/2)+4,INT((SCOL()-54)/2)+53 ;
      TITLE " RecordTrak Message " ;
      NOFLOAT ;
      NOCLOSE ;
      SHADOW ;
      NOMINIMIZE ;
      COLOR SCHEME 1
ENDIF

IF WVISIBLE("waitwin")
   ACTIVATE WINDOW waitwin SAME
ELSE
   ACTIVATE WINDOW waitwin NOSHOW
ENDIF
@ 1,2 SAY waitstr ;
   SIZE 1,49 ;
   COLOR G+/B*

IF NOT WVISIBLE("waitwin")
   ACTIVATE WINDOW waitwin
ENDIF
RETURN
