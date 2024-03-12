
PARAMETERS c_Nid,iRt,iTag,bFirstlook,c_User,c_Doctype,c_Status,iPages

PRIVATE cUser
cUser =c_User
SET CLASSLIB TO dataconnection ADDIT
objconn=CREATEOBJECT("dataconnection.cntdataconn")

*-- call order summary bar code sheet generator system

*--11/19/20: change to new SC Viewer location [207322]
cScviewerexe = "c:\program files (x86)\rts\scviewer\softcopy_viewer.exe"
*--cScviewerexe = IIF(pl_Is64bit,"c:\program files (x86)\rts\softcopy_viewer.exe","c:\program files\rts\softcopy_viewer.exe")
IF FILE(cScviewerexe)
	WAIT WINDOW "Sending Order Summary and Bar Code sheets" NOWAIT NOCLEAR
	c_sql = "exec [dbo].[Tagitemdocstart] " + ;
		ALLTRIM(c_Nid) + ;
		"," + ALLTRIM(STR(iRt)) + ;
		"," + ALLTRIM(STR(iTag)) + ;
		"," + IIF(bFirstlook,"1","0") + ;
		",'" + ALLTRIM(c_User) + "'" + ;
		",'" + ALLTRIM(c_Doctype) + "'" + ;
		",'" + ALLTRIM(c_Status) + "'" + ;
		"," + ALLTRIM(STR(iPages))

	nr= objconn.sqlpassthrough(c_sql,"editnid")
	IF nr=.F.
		WAIT CLEAR
		gfmessage("Error creating Order Summary job",.F.)
		RETURN
	ENDIF
	iNid = 0
	IF RECCOUNT("editnid") > 0
		iNid = editnid.newnid
	ENDIF
	IF USED("editnid")
		USE IN editnid
	ENDIF
	IF iNid <> 0
		cParam = "SCDOC" + " " + ALLTRIM(STR(iNid))
		IF pl_Is64bit
				*--11/4/19: PDF into production [87505]
				RUN /N "c:\program files (X86)\rts\scviewer\softcopy_viewer.exe " &cParam
*!*	*--5/6/19: call test version of the SC Viewer system [87505]
*!*	*--need to see if this test
*!*				LOCAL lTest
*!*				lTest=.F.
*!*				c_sql="[dbo].[GettestrSSimagestate] '"+ALLTRIM(goApp.CurrentUser.orec.login)+"'"
*!*				nr=objconn.sqlpassthrough(c_sql,'viewrss')
*!*				IF USED('viewrss')
*!*					lTest=NVL(viewrss.state,.F.)
*!*				ENDIF
*!*				IF lTest
*!*					RUN /N "T:\Release\Net\softcopy_viewer\Test\softcopy_viewer.exe " &cParam
*!*				ELSE
*!*					RUN /N "c:\program files (X86)\rts\softcopy_viewer.exe " &cParam
*!*				ENDIF
*!*	*--RUN /N "c:\program files (X86)\rts\softcopy_viewer.exe " &cParam
		ELSE
			*--11/4/19: remove support for XP [87505]
			WAIT CLEAR
			gfmessage("Callscdoc.prg: Unsupported operating system (X32 bit). Notify IT",.F.)
			RETURN
			*--RUN /N "c:\program files\rts\softcopy_viewer.exe " &cParam
		ENDIF

		DO WHILE isrunning("softcopy_viewer.exe",.F.)
			LOOP
		ENDDO

		WAIT CLEAR
	ENDIF
ELSE
	gfmessage("Error creating Order Summary sheet. System not available.",.F.)
ENDIF


*******************************************************************************
FUNCTION isrunning
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
		IF TYPE("loProcesses") = "O" THEN
			IF loProcesses.COUNT > 0
				FOR EACH oProcess IN loProcesses
					sOwner = ""
					TRY
						IF TYPE("oProcess")<> "O"
							LOOP
						ENDIF
						oProcess.GetOwner(@sOwner)
						IF UPPER(ALLTRIM(cUser)) == UPPER(ALLTRIM(NVL(sOwner,'')))
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
