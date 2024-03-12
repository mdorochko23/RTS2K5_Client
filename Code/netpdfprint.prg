PARAMETERS cpdffile
IF PCOUNT()<1
	cpdffile=""
ENDIF

LOCAL lcOS, lcPlatform
lcOS = OS(1)
DO CASE
CASE "6.02" $ lcOS AND OS(11) = "1"
	lcPlatform = "WIN8" && win10 and win8 return the same code 
CASE "6.01" $ lcOS AND OS(11) = "1"
	lcPlatform = "WIN7"
OTHERWISE 
	lcPlatform = "WINXP"
ENDCASE 

LOCAL clocprint,cnetprint,d_TxtTiff,n_TxtTiff,t_TxtTiff,cstring, crtsx86
IF lcPlatform="WIN8" OR lcPlatform="WIN7"
	clocprint=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"printpdf.exe"
	*clocprint="c:\program files (x86)\rts\printpdf.exe"
ELSE 		
	clocprint=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"printpdf.exe"
	*clocprint="c:\program files\rts\printpdf.exe"
ENDIF 
	cnetprint=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetprint", "\"))) +"printpdf.exe"
	*cnetprint="t:\release\net\printpdf\printpdf.exe"



IF FILE(clocprint) 
	n_TxtTiff = ADIR(a_txtTiff,cnetprint)
	IF n_TxtTiff > 0 AND FILE(clocprint)
		d_TxtTiff = a_txtTiff[1, 3]
		t_TxtTiff = a_txtTiff[1, 4]
		n_TxtTiff = ADIR(a_txtTiff,clocprint)
		IF n_TxtTiff > 0
			IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
				COPY FILE (cnetprint) to (clocprint)
			ENDIF
		ENDIF
	ENDIF
ELSE
 	*s= "t:\release\net\printpdf\setup.exe"	
 	s=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetprint", "\"))) +"setup.exe"	
 	 RUN &s.
 	
 	WAIT WINDOW "Install in progress.." TIMEOUT 25
ENDIF

IF FILE(cpdffile)
		cstring=ALLTRIM(clocprint)+" " + ALLTRIM(cpdffile)
		RUN /n &cstring
	
		*cstring="c:\program files\rts\printpdf.exe " + ALLTRIM(cpdffile)
		*cstring =clocprint + " " + ALLTRIM(cpdffile)
		*pn_lrsno =300000
		*DO addlogline  WITH  1 , cstring , "NetpdfPrint"	
ENDIF 