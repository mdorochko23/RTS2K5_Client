*--merge a folders PDF, TIFF and TXT files into a single PDF
PARAMETERS sfolder,smergepdf,ldelsnglpg

*--test settings
*!*	sfolder="C:\temp\r_161963\517"
*!*	smergepdf="C:\temp\r_161963\517\SC_Pages.pdf"
*!*	ldelsnglpg=.T.
*!*	pl_Is64bit=.T.
*--test settings

LOCAL ncnt, nfiles,sfile, snewtiff,scrlf,smergetxt
*--set up name for merge PDF and remove any existing copies
smergetxt ="c:\temp\mergelistxyz.txt"
IF FILE(smergetxt)
	TRY
		ERASE (smergetxy)
	CATCH
	ENDTRY
ENDIF
WAIT WINDOW "Creating SC pges file..." NOWAIT

scrlf = CHR(13)+CHR(10)
nfiles=0
sfolder = ADDBS(ALLTRIM(sfolder))
IF NOT DIRECTORY(sfolder)
	MESSAGEBOX("Folder not found")
*--gfmessage("Directory not found: " + sfolder
	RETURN
ENDIF

ndir=ADIR(afiles, sfolder + "*.*")

*--build text file listing files to merge
FOR ncnt = 1 TO ndir
	sfile=UPPER(sfolder+ ALLTRIM(afiles(ncnt,1)))
	IF INLIST( UPPER(JUSTEXT(sfile)) , 'PDF', 'TIF', 'TXT')
		IF UPPER(JUSTEXT(sfile))=='TXT'
			snewtiff= STRTRAN(sfile,".TXT", ".TIF")
			txt2tiff(sfile, snewtiff)
			IF FILE(snewtiff)
				sfile=snewtiff
			ELSE
				RETURN
			ENDIF
		ENDIF
		nfiles=nfiles+1
		ladditive = IIF( ncnt=1, .F.,.T.)
		STRTOFILE(sfile + scrlf, smergetxt,ladditive)
	ENDIF
ENDFOR

*--merge the files into a PDF
IF nfiles > 0
	cParam = "SYSID|RTSMERGE TEXTLIST2PDF " + '"'+smergetxt+'"' + ' ' + '"'+smergepdf+'"'
	RUN /N "T:\Release\Net\AmyProcesses\AmyuniProcesses.exe" &cParam.
	DO WHILE isrunning("AmyuniProcesses.exe")
		LOOP
	ENDDO
*--delete the single page files
	IF FILE(smergepdf) AND ldelsnglpg=.T.
		ndir=ADIR(afiles, sfolder + "*.*")
		FOR ncnt = 1 TO ndir
			sfile=UPPER(sfolder+ ALLTRIM(afiles(ncnt,1)))
			IF NOT ALLTRIM(UPPER(sfile)) == ALLTRIM(UPPER(smergepdf))
				TRY
					ERASE (sfile)
				CATCH
				ENDTRY
			ENDIF
		ENDFOR
	ENDIF
ENDIF
WAIT CLEAR
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
FUNCTION isrunning
PARAMETERS tcName, lTerminate

IF PCOUNT() < 2
	lTerminate = .F.
ENDIF

LOCAL loLocator, loWMI, loProcesses, loProcess, llIsRunning
loLocator 	= CREATEOBJECT('WBEMScripting.SWBEMLocator')
loWMI		= loLocator.ConnectServer()
loWMI.Security_.ImpersonationLevel = 3  		&& Impersonate

loProcesses	= loWMI.ExecQuery([SELECT * FROM Win32_Process WHERE Name = '] + tcName + ['])
llIsRunning = .F.
IF TYPE("loProcesses") = "O" THEN
	IF loProcesses.COUNT > 0
		FOR EACH oProcess IN loProcesses
			sOwner = ""
			TRY
				IF TYPE("oProcess")<> "O"
					LOOP
				ENDIF
				oProcess.GetOwner(@sOwner)
				IF UPPER(ALLTRIM(GETENV("USERNAME"))) == UPPER(ALLTRIM(NVL(sOwner,'')))
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

RETURN llIsRunning
