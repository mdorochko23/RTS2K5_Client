PARAMETERS cpdffile

IF PCOUNT()<1
	RETURN
ENDIF

LOCAL clocviewer,cnetviewer,d_TxtTiff,n_TxtTiff,t_TxtTiff,cstring
*--3/25/20: switch to devExpress PDF viewer[165847]
cnetviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetviewer2", "\")))
clocviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"pdfviewer"

*--check for program update
*--first look for updated pdfviewer_2 exe
IF UpdtLocalFile(cnetviewer + "PDFViewer2_Exe",clocviewer,"pdfviewer_2.exe") > 0
*--if the PDF viewer exe has been updated, then update the DLLs and config file
	ncnt = UpdtLocalFile(cnetviewer+ "PDFViewer2_DLLs",clocviewer,"*.dll")
	ncnt = UpdtLocalFile(cnetviewer+ "PDFViewer2_Exe",clocviewer,"SoftCopy_Viewer.exe.config")
ENDIF

*!*	clocviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"pdfviewer.exe"
*!*	cnetviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetviewer", "\"))) +"pdfviewer.exe"
*!*	crtsx86 =ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"pdfviewer.exe"


*!*	clocviewer=IIF(pl_Is64bit,crtsx86,clocviewer)
*!*	LOCAL cPath
*!*	cPath = IIF(pl_Is64bit,"c:\program files (x86)\rts\","c:\program files\rts\")
*!*	 
*!*	IF NOT DIRECTORY(cPath)
*!*		MD (cPath)
*!*	ENDIF

*!*	n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
*!*	IF n_TxtTiff > 0 AND FILE(clocviewer)
*!*		d_TxtTiff = a_txtTiff[1, 3]
*!*		t_TxtTiff = a_txtTiff[1, 4]
*!*		n_TxtTiff = ADIR(a_txtTiff,clocviewer)
*!*		IF n_TxtTiff > 0
*!*			IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
*!*				COPY FILE (cnetviewer) TO (clocviewer)
*!*			ENDIF
*!*		ENDIF
*!*	ELSE
*!*		IF n_TxtTiff > 0
*!*			gfmessage("One-time installtion process required")
*!*			cnetpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetviewer", "\")))
*!*			cstring=ADDBS(cnetpath) + "setup.exe"
*!*			RUN /N &cstring
*!*			return
*!*		ENDIF
*!*	ENDIF

*--------------------------------------------------------------------
LOCAL iRun ,llRunReturn
FOR iRun=1 TO 100
*--3/25/20: switch to devExpress PDF viewer[165847]
	llRunReturn=ISRUNNING("PDFViewer_2.exe")
	*--llRunReturn=ISRUNNING("PDFViewer.exe")
	
	IF llRunReturn=.F.
	     EXIT
	 ENDIF 
next
*-----------------------------------------------------------------------

*--3/25/20: switch to devExpress PDF viewer[165847]
IF FILE(ADDBS(clocviewer) + "pdfviewer_2.exe ") AND FILE(cpdffile)
*--IF FILE(clocviewer) AND FILE(cpdffile)
	cstring= ADDBS(clocviewer) + "pdfviewer_2.exe TRUE " + ALLTRIM(cpdffile)
	RUN /N &cstring
*!*	 && 04/26/17 - add txn 44 on the PDFViewr
*!*	 && 01/25/17 #56025 - add follow up txn for a re-printed pdf
*!*	*IF checktest("PART3")=.F. 
*!*		*cstring="T:\Release\Net\Pdfviewertest\" + "pdfviewer.exe " + ALLTRIM(cpdffile)
*!*	*ELSE
*!*		cstring= ADDBS(cPath) + "pdfviewer.exe " + ALLTRIM(cpdffile)
*!*	*ENDIF
*!*		*--cstring="c:\program files\rts\pdfviewer.exe " + ALLTRIM(cpdffile)
*!*		RUN /N &cstring
ELSE
	gfmessage("Unable to display request PDF file")
ENDIF
*-----------------------------------------------------------------------------------
FUNCTION ISRUNNING
LPARAMETERS tcName
LOCAL loLocator, loWMI, loProcesses, loProcess, llIsRunning
loLocator 	= CREATEOBJECT('WBEMScripting.SWBEMLocator')
loWMI		= loLocator.ConnectServer() 
loWMI.Security_.ImpersonationLevel = 3  		&& Impersonate
 
loProcesses	= loWMI.ExecQuery([SELECT * FROM Win32_Process WHERE Name = '] + tcName + ['])
llIsRunning = .F.
IF loProcesses.Count > 0
	FOR EACH loProcess in loProcesses
		llIsRunning = .T.
		TRY		&& 08/07/2020, ZD #186727, JH
		   loProcess.Terminate(0)	
		CATCH		&& 08/07
		ENDTRY		&& 08/07
	ENDFOR
ENDIF
RETURN llIsRunning