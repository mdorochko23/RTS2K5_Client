**************************************************************
*FUNCTION wcabimg
PARAMETERS c_rtnum , n_tagnum

LOCAL l_found as Boolean, l_found1 AS Boolean, l_founD2 AS Boolean, l_found3 AS Boolean, l_found4 AS Boolean
STORE .F. TO l_found, l_found1, l_found2, l_found3, l_found4

	** l_archive=.t. and c_doctype="S"
l_found1= getimgfile  (c_rtnum , n_tagnum, .t., "S")
	** l_archive=.f. and c_doctype="S"
l_found2= getimgfile  (c_rtnum , n_tagnum, .f., "S")

** l_archive=.t. and c_doctype="B"
l_found3= getimgfile  (c_rtnum , n_tagnum, .t., "B")
	** l_archive=.f. and c_doctype="b"
l_found4= getimgfile  (c_rtnum , n_tagnum, .f., "B")



IF l_found1=.T. OR l_found2=.T. OR l_found3 =.T. OR l_found4 =.T.
l_found=.T.
ENDIF




RETURN l_found

************************************************************
function getimgfile

PARAMETERS c_rt , ntag, l_arch, c_type

LOCAL lc_path AS STRING, l_lfound AS Boolean,icnt AS INTEGER, lc_srch as String, lc_Imgs AS STRING
l_lfound=.F.

IF l_arch
	lc_Imgs = ADDBS(MLPriPro("R", "RTS.INI", "Data","PcxArch", "\"))
	lc_Path = lc_Imgs + RIGHT(c_rt,1) + "\" + c_rt
ELSE
	lc_Imgs = ADDBS(MLPriPro("R", "RTS.INI", "Data","PCX", "\"))
	lc_Path = lc_Imgs + c_rt
	

ENDIF


FOR icnt = 1 TO 9
	lc_srch = lc_Path + c_type + TRANS(icnt, "9") + "." + TRANS(ntag, "@L 999")
	IF FILE(lc_srch)
		l_lfound=.T.
		EXIT
	endif
ENDFOR





RETURN l_lfound

***************************************************
