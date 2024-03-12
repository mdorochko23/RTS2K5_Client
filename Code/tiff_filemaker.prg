*\\ tiff files from FRX reports
PARAMETERS cReport,cfpathname
LOCAL xx,cpath,loSession,lnRetVal,nr,n_curarea
n_curarea=SELECT()
creport=FULLPATH(creport)

*!*	cPath=SET('path')
*!*	IF NOT UPPER('xfrx')$UPPER(cPath)
*!*		xx=SET('PATH')+";"+"\program files\xfrx"+";"+"\program files\xfrx\xfrxlib"
*!*		SET PATH TO '&xx' ADDITIVE
*!*	ENDIF 
SET CLASSLIB TO "xfrxlib" ADDITIVE
loSession = EVALUATE("xfrx('XFRX#INIT')")
loSession.setPaperSize(85000,110000)
loSession.pictureDPI = 200
lnRetVal =loSession.SetParams(,,,,,,"XFF")
IF lnRetVal = 0
	loSession.ProcessReport(cReport)
	LOCAL loXFF
	loXFF = loSession.finalize()
	LOCAL lnI
	SELECT (loxff.cxfFALIAS)
	FOR lnI = 1 TO loXFF.PAGECOUNT
		IF lnI = 1
			nr=loXFF.SAVEPICTURE(cfpathname+".tif", ;
				"tif",lnI,lnI,16)
		ELSE 
			nr=loXFF.SAVEPICTURE(cfpathname+ALLTRIM(STR(lnI))+".tif", ;
				"tif",lnI,lnI,16)
		ENDIF 
		IF nr<0
			gfmessage("ERROR No."+ALLTRIM(STR(nr))+" returned when creating report") 
		ENDIF 	
	ENDFOR
ENDIF
SELECT (n_curarea)
*SET DEFAULT TO &lc_default
