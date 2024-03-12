**6/24/2014-Chcek for any scanend images for Zoloft

PARAMETERS ntagn, cdoctype
LOCAL lcLrs AS STRING, lcSPath AS STRING, lcDPath AS STRING,  lcDest AS STRING, lc_pcxfile as String
lcLrs = ALLT( pc_lrsno)
*----------------

LOCAL  omed_img AS OBJECT
omed_img= CREATEOBJECT("generic.medgeneric")
omed_img.closealiAs("ScanDoc")
c_sql=" EXEC [dbo].[ScanDocperTag]  '" +lcLrs+"','" + STR(ntagn) +"'"
omed_img.sqlexecute(c_sql,"ScanDoc")

*--------------

lcSPath = ADDBS(ALLTRIM(goApp.pcxpath))
lcDPath =ADDBS(ALLTRIM( goApp.pcxarchpath ))+ RIGHT(lcLrs,1) + "\"
lcDest=""
lc_pcxfile=""

IF  USED('ScanDoc') AND NOT EOF()
SELECT ScanDoc
scan
nPage=RECNO()
lcSource =lcSPath +  lcLrs  + cdoctype+  ALLTRIM(STR(nPage)) +"." + TRANS(ntagn, "@L 999")
lcDest   =ADDBS(ALLTRIM(lcDPath)) +  lcLrs  +cdoctype +ALLTRIM(STR(nPage)) +"." + TRANS(ntagn, "@L 999")
IF  NOT FILE(lcDest )
	lcDest =lcSource
ENDIF

IF  NOT FILE(lcDest )
	lcDest =""
ELSE
    EXIT 
ENDIF

SELECT ScanDoc
ENDSCAN 
ENDIF 

RELEASE omed_img

**7/10/14- IF TBLSCANLOG DOES NOT HAVE A RECORD LETS CHCEK THE PCX AND PCX DIRECTLY
IF EMPTY(ALLTRIM(lcDest))
	lc_pcxfile=searchpcx(ntagn)
endif
***
RETURN IIF(EMPTY( lcDest),lc_pcxfile, lcDest)
*************************
FUNCTION searchpcx
PARAMETERS c_tag
LOCAL  c_name AS String
 c_name=""
 FOR npage=1 TO 9
 c_name=SUBRIDERPCX	(c_TAG,"A",npage )
IF !EMPTY(ALLTRIM(c_name))
	EXIT
endif

NEXT


RETURN c_name




