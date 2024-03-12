*\\ tiff files from FRX reports wit intermediate PDF format to improve quuality
*--5/31/22 kdl: add resolution parameter [271273]
PARAMETERS cReport,cfpathname,iresolution
IF PCOUNT()<3
	iresolution = 200
ENDIF

*--PARAMETERS cReport,cfpathname


LOCAL xx,cpath,loSession,lnRetVal,nr,n_curarea,bconverted,cFilepath,cStem,cFilename

*--2/25/20 kdl: set variable's intial value
nr=-1

cFilepath = ADDBS(JUSTPATH(cfpathname)) &&( "T:\Softimgs\R_161963\480\"
cStem = JUSTSTEM(cfpathname)
cFilename=ALLTRIM(cFilepath) + cStem

n_curarea=SELECT()
cReport=FULLPATH(cReport)
SET CLASSLIB TO "xfrxlib" ADDITIVE
loSession= xfrx("XFRX#INIT")

*--create the cover page in PDF format
lnRetVal = loSession.SetParams(cFilename + ".pdf",,.T.,,,,"PDF")
IF lnRetVal = 0
	loSession.ProcessReport(cReport)
	loSession.finalize()
ELSE
	GFMESSAGE("ERROR No."+ALLTRIM(STR(nr))+" returned when creating report")
ENDIF

*--6/20/22 kdl: do not make TIFF copy of cover letter if the doc type is PDF [272273]
IF FILE(cFilename + ".pdf") AND NOT ALLTRIM(UPPER(NVL(pc_Inbdoctype,"TIFF")))="PDF"
*--IF FILE(cFilename + ".pdf")
*--split the PDF file to single page tiff files
*--5/31/22 kdl: add resolution parameter [271273]
	IF iresolution = 300
		sParam = '"' + cFilename + ".pdf" + '" "' + cFilename + ".tif" +'" "SINGLE" "' + "FALSE" +  '" "' + "FALSE" + '" ' + "300"
	ELSE
		sParam = '"' + cFilename + ".pdf" + '" "' + cFilename + ".tif" +'" "SINGLE" "' + "FALSE" + '"'
	ENDIF
*--sParam = '"' + cFilename + ".pdf" + '" "' + cFilename + ".tif" +'" "SINGLE" "' + "FALSE" + '"'

	IF pl_Is64bit
		RUN /N "c:\program files (X86)\rts\pdfconverter.exe " &sParam
	ELSE
		RUN /N "c:\program files\rts\pdfconverter.exe " &sParam
	ENDIF

	DO WHILE isrunning("pdfconverter.exe")
		LOOP
	ENDDO
*--set the split TIFF file to the standard file names
	bconverted = .F.
*--6/20/22 KDL: use original file name as the stem for the search andrename if more than 1 file
	nFiles=ADIR(aFiles,ALLTRIM(cFilepath) +  ALLTRIM(cStem) + "*.tif")
*--nFiles=ADIR(aFiles,ALLTRIM(cFilepath) + "m0*.tif")
	IF nFiles > 1
		IF nFiles > 1
			FOR nCnt = 1 TO nFiles
				IF FILE(ALLTRIM(cFilepath) + "4_covrpg" + ALLTRIM(STR(nCnt)) + ".tif")
					ERASE (ALLTRIM(cFilepath) + "4_covrpg" + ALLTRIM(STR(nCnt)) + ".tif")
				ENDIF
				RENAME (ALLTRIM(cFilepath) + aFiles(nCnt,1)) TO ALLTRIM(cFilepath) + ALLTRIM(cStem)+ ALLTRIM(STR(nCnt)) + ".tif"
			NEXT
		ENDIF
		bconverted = .T.
*!*		IF nFiles > 0
*!*			IF nFiles > 1
*!*				FOR nCnt = 1 TO nFiles
*!*					IF FILE(ALLTRIM(cFilepath) + "4_covrpg" + ALLTRIM(STR(nCnt)) + ".tif")
*!*						ERASE (ALLTRIM(cFilepath) + "4_covrpg" + ALLTRIM(STR(nCnt)) + ".tif")
*!*					ENDIF
*!*					RENAME (ALLTRIM(cFilepath) + aFiles(nCnt,1)) TO ALLTRIM(cFilepath) + ALLTRIM(cStem)+ ALLTRIM(STR(nCnt)) + ".tif"
*!*				NEXT
*!*			ELSE
*!*				IF NOT ALLTRIM(UPPER(FILES(1,1)))==ALLTRIM(UPPER(ALLTRIM(cFilepath) + "4_covrpg.tif"))
*!*					IF FILE(ALLTRIM(cFilepath) + "4_covrpg.tif")
*!*						ERASE (ALLTRIM(cFilepath) + "4_covrpg.tif")
*!*					ENDIF
*!*					RENAME (ALLTRIM(cFilepath) + aFiles(1,1)) TO ALLTRIM(cFilepath) + ALLTRIM(cStem) + ".tif"
*!*				ENDIF
*!*			ENDIF
*!*			bconverted = .T.
	ENDIF
*--Remove the pdf file
	IF bconverted = .T.
		ERASE (cFilename + ".pdf")
	ENDIF
ELSE
*--9/29/22 kdl: clear out existing split-out pages [289540]
	nFiles = ADIR(aFiles, ADDBS(ALLTRIM(cFilepath)) + JUSTSTEM(cFilename) + "_*")
	FOR nCnt = 1 TO nFiles
		IF NOT UPPER(ALLTRIM(cFilename + ".pdf"))== UPPER(ALLTRIM(ADDBS(ALLTRIM(cFilepath)) +aFiles(nCnt,1)))
			TRY
				ERASE ADDBS(ALLTRIM(cFilepath)) +aFiles(nCnt,1)
			ENDTRY

		ENDIF
	NEXT
*--6/20/22 kdl: need to split multi-page PDFs [272273]
	sParam ='SYSID|tiffcovPdfSplit PDFSPLIT "' + cFilename + ".pdf" + '" "' + JUSTPATH(cFilepath) + '" TRUE'
	RUN /N "\\sanstor\image\Release\Net\ByteScout\BytescoutProcesses.exe " &sParam
	DO WHILE isrunning("BytescoutProcesses.exe")
		LOOP
	ENDDO
	IF FILE(ADDBS(ALLTRIM(cFilepath)) + JUSTSTEM(cFilename) + "_01.pdf") OR	FILE(ADDBS(ALLTRIM(cFilepath)) + JUSTSTEM(cFilename) + "_page1.pdf")
		DELETE FILE (cFilename + ".pdf")
	ENDIF
ENDIF

SELECT (n_curarea)

*----------------------------------------------
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
IF loProcesses.COUNT > 0
	FOR EACH oProcess IN loProcesses
		TRY
			IF TYPE("oProcess")<> "O"
				LOOP
			ENDIF
			llIsRunning = .T.
			IF lTerminate
				oProcess.TERMINATE(0)
			ENDIF
		CATCH
		ENDTRY
	ENDFOR
ENDIF
RETURN llIsRunning
