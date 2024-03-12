** Function  TxSFile
**09/25/2017: TX :CheCk for any "s" scanned subp files
**
PARAMETERS ntagn, cdoctype
LOCAL lcLrs AS STRING, lcSPath AS STRING, lcDPath AS STRING,  lcDest AS STRING, lc_pcxfile as String
lcLrs = ALLT( pc_lrsno)
lc_pcxfile=""
lc_pcxfile=searchpcx(ntagn, cdoctype)

RETURN IIF(EMPTY(lc_pcxfile),.F.,.T.)
*************************
FUNCTION searchpcx
PARAMETERS c_tag, c_type
LOCAL  c_name AS String
 c_name=""
 FOR npage=1 TO 9
 c_name=SUBRIDERPCX	(c_TAG, c_type,npage )
IF !EMPTY(ALLTRIM(c_name))
	EXIT
endif

NEXT


RETURN c_name




