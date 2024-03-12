*--4/6/21: add option to call the add SC Add Inbound Document screen [227955]
PARAMETERS c_Nid,iRt,iTag,bFirstlook,c_User,c_Doctype,c_Status,iPages

IF myisrunning("SoftCopy_Viewer.exe",.F.)
 	GFMESSAGE("Option not available while Soft-Copy Image/Order Summary Viewer is active.")
	return
ENDIF

PRIVATE cUser
cUser =c_User
SET CLASSLIB TO dataconnection ADDIT
objconn=CREATEOBJECT("dataconnection.cntdataconn")

LOCAL clocviewer,cnetviewer
cnetviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetscviewer", "\"))) &&+"softcopy_viewer.exe"
clocviewer =ADDBS(ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) + "scviewer") &&+"softcopy_viewer.exe"
*--check for program update
*--first look for updated sofcopy viewer exe
IF UpdtLocalFile(cnetviewer + "SCPDF_EXE",clocviewer,"softcopy_viewer.exe") > 0
*--if the sofcopy viewer exe has been updated, then update the DLLs and config file
	ncnt = UpdtLocalFile(cnetviewer+ "SCPDF_DLLs",clocviewer,"*.dll")
	ncnt = UpdtLocalFile(cnetviewer+ "SCPDF_EXE",clocviewer,"SoftCopy_Viewer.exe.config")
ENDIF

cscviewerexe = ADDBS(clocviewer) + "softcopy_viewer.exe"

IF FILE(cScviewerexe)
		cParam = "SCADDINB"
		IF pl_Is64bit
			RUN /N &cscviewerexe. &cParam.
		ELSE
			*--remove support for XP [87505]
			WAIT CLEAR
			gfmessage("Callscaddinb.prg: Unsupported operating system (X32 bit). Notify IT",.F.)
			RETURN
		ENDIF
		*--5/21/21: use internal version of usrunning [238096,238091]
		DO WHILE myisrunning("SoftCopy_Viewer.exe",.F.)
			LOOP
		ENDDO

		WAIT CLEAR
ELSE
	gfmessage("Add Inbound Documents system not available.",.F.)
ENDIF


*******************************************************************************
FUNCTION myisrunning
PARAMETERS tcName, lTerminate

IF PCOUNT() < 2
	lTerminate = .F.
ENDIF

LOCAL loLocator, loWMI, loProcesses, loProcess, llIsRunning
loLocator 	= CREATEOBJECT('WBEMScripting.SWBEMLocator')
loWMI		= loLocator.ConnectServer()

llIsRunning = .F.
TRY
	IF TYPE("loWMI") = "O" THEN
		loWMI.Security_.ImpersonationLevel = 3  		&& Impersonate
		loProcesses	= loWMI.ExecQuery([SELECT * FROM Win32_Process WHERE Name = '] + tcName + ['])
*--		llIsRunning = .F.
		IF TYPE("loProcesses") = "O" THEN
			IF loProcesses.COUNT > 0
				FOR EACH oProcess IN loProcesses
					sOwner = ""
					TRY
						IF TYPE("oProcess")<> "O"
							LOOP
						ENDIF
						oProcess.GetOwner(@sOwner)
						IF UPPER(ALLTRIM(THISFORM.suser)) == UPPER(ALLTRIM(NVL(sOwner,'')))
							llIsRunning = .T.
							IF lTerminate
								oProcess.TERMINATE(0)
							ENDIF
						ENDIF
					CATCH
					ENDTRY
				ENDFOR
			ENDIF
		ENDIF
	ENDIF

CATCH
ENDTRY

RETURN llIsRunning
