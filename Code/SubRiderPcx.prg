**06/06/2016- Added CA office #40514
**6/26/2013- Rider for a scanned subp for a KOP Generic - can be few pages nPage
*FUNCTION SubRiderPcx
******************************************************************************************************************************************************
PARAMETERS ntagn, cdoctype, nPage

LOCAL lcLrs AS STRING, lcSPath AS STRING, lcDPath AS STRING
lcLrs = ALLT( pc_lrsno)
*!*	lcSPath = ADDBS(ALLTRIM(goApp.pcxpath))
*!*	lcDPath =ADDBS(ALLTRIM( goApp.pcxarchpath ))+ RIGHT(lcLrs,1) + "\"
*-- 04/26/2021 MD #235077 make sure we are checking the right folder
IF RIGHT(ALLTRIM(UPPER(pc_clcode)),1)="C"
	PL_OFCOAK=.T.
ENDIF 
*--	
lcSPath=IIF(PL_OFCOAK,  ADDBS(ALLTRIM(GOAPP.CAPCX)) , ADDBS(ALLTRIM(goApp.pcxpath)))	
lcDPath=IIF(PL_OFCOAK,ADDBS(ALLTRIM( goApp.CAPCXARCH ))+ RIGHT(lcLrs,1) + "\",ADDBS(ALLTRIM( goApp.pcxarchpath ))+ RIGHT(lcLrs,1) + "\")


lcSource =lcSPath +  lcLrs  + cdoctype+  ALLTRIM(STR(nPage)) +"." + TRANS(ntagn, "@L 999")
lcDest   =ADDBS(ALLTRIM(lcDPath)) +  lcLrs  +cdoctype +ALLTRIM(STR(nPage)) +"." + TRANS(ntagn, "@L 999")
IF  NOT FILE(lcDest )
	lcDest =lcSource
ENDIF

IF  NOT FILE(lcDest )
	lcDest =""
ENDIF

RETURN lcDest
******************************************************************************************************************************************************
