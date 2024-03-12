PARAMETERS c_rt, c_tag, c_office, c_ReqType, l_skipC as Boolean
LOCAL lc_pathpcx as String, lc_archpcx as String, l_lfound as Boolean,icnt as Integer, l_lpcx as Boolean, l_larch as Boolean
STORE .f. to l_larch,l_lfound, l_lpcx


 DO CASE 
 
 CASE c_office ='P'
 	lc_pathpcx=ADDBS(MLPriPro("R", "RTS.INI", "Data","PCX", "\"))
 	lc_archpcx=ADDBS(MLPriPro("R", "RTS.INI", "Data","PcxArch", "\"))
 OTHERWISE
 	lc_pathpcx=ADDBS(MLPriPro("R", "RTS.INI", "Data","CAPCX", "\"))
 	lc_archpcx=ADDBS(MLPriPro("R", "RTS.INI", "Data","CAPcxArch", "\"))	
 
 ENDCASE
 
**199592A2.007


IF FILE(lc_pathpcx+ ALLTRIM(c_rt) + ".tif")
	l_lpcx=.t.
	
endif


IF FILE(lc_archpcx+  RIGHT(c_rt,1) + "\" + c_rt + ".tif")
	l_larch=.t.
	
ENDIF
*************PCX SEARCH**************
IF getotherimgs("A",c_ReqType, c_tag, ADDBS(lc_pathpcx )+ c_rt )
	l_lpcx=.t.
	
ENDIF

IF getotherimgs("T",c_ReqType, c_tag, ADDBS(lc_pathpcx ) + c_rt )
	l_lpcx=.t.
	
ENDIF
IF NOT l_skipC && Mf2 does not check for that type per Alec (12/13/2011)
	IF getotherimgs("C",c_ReqType, c_tag, ADDBS(lc_pathpcx ) + c_rt )
		l_lpcx=.t.
	
	ENDIF
endif
*************PCX SEARCH**************

*************PCXARCH SEARCH**************
IF getotherimgs("A",c_ReqType, c_tag, lc_archpcx+  RIGHT(c_rt,1) + "\" + c_rt )
	l_larch=.t.
	
ENDIF

IF getotherimgs("T",c_ReqType, c_tag, lc_archpcx+  RIGHT(c_rt,1) + "\" + c_rt )
	l_larch=.t.
	
ENDIF
IF NOT l_skipC && Mf2 does not check for that type per Alec (12/13/2011)
	IF getotherimgs("C",c_ReqType, c_tag, lc_archpcx+  RIGHT(c_rt,1) + "\" + c_rt )
		l_larch=.t.
	
	ENDIF
endif
*************PCXARCH SEARCH**************
 IF l_lpcx OR l_larch
	l_lfound= .t.
	ELSE
	l_lfound=.f.
endif


RETURN l_lfound

**************************************************************************************
function getotherimgs
PARAMETERS c_img,c_Type, n_tag, lc_Path
LOCAL l_gotpcx as Boolean, lc_Search as String
lc_Search =""
l_gotpcx=.f.

FOR i = 1 TO 9
	
	lc_Search   = lc_Path+ c_img + TRANS(i, "9") + ;
		 "." +IIF(c_img="C","TIF", TRANS(n_tag, "@L 999"))
	IF FILE(lc_Search )
		l_gotpcx =.t.
		EXIT
	ENDIF
ENDFOR



RETURN l_gotpcx
