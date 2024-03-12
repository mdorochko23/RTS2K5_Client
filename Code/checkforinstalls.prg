*--DOT Net version of burn_base system

LOCAL bUseNetversion,oCdcnt
bUseNetversion = .F.
SET CLASSLIB TO dataconnection ADDITIVE
oCdcnt=CREATEOBJECT('cntdataconn')
c_sql = "select [dbo].[fn_getestuser]( '" + ALLTRIM(goApp.CurrentUser.orec.login) + "','NETSCAN')"
nr=oCdcnt.sqlpassthrough(c_sql,'viewrss')
IF nr= .T.
	bUseNetversion = viewrss.EXP
ELSE
	bUseNetversion = .F.
ENDIF
IF USED('viewrss')
	USE IN viewrss
ENDIF
*--test setting
c_sql = "exec [dbo].[getburnbasetest]"
nr=oCdcnt.sqlpassthrough(c_sql,'viewrss')
IF nr= .T.
	bUseTestVersion = viewrss.isBurnbasetest
ELSE
	bUseTestVersion = .F.
ENDIF
IF USED('viewrss')
	USE IN viewrss
ENDIF

IF bUseNetversion
	LOCAL clocviewer,cnetviewer,d_TxtTiff,n_TxtTiff,t_TxtTiff,cstring
	clocviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"burn_baseimage.exe"
	crtsx86 =ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"burn_baseimage.exe"
	cnetviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetburnbase", "\"))) +"burn_baseimage.exe"
	crtsx86test =ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"burn_baseimagetest.exe"
	clocviewertest=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"burn_baseimagetest.exe"
	cnetviewertest=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetburnbase", "\"))) +"burn_baseimagetest.exe"

	clocviewer=IIF(pl_Is64bit,crtsx86,clocviewer)
	clocviewertest=IIF(pl_Is64bit,crtsx86test,clocviewertest)

	LOCAL cPath
	cPath = IIF(pl_Is64bit,"c:\program files (x86)\rts\","c:\program files\rts\")

	IF NOT DIRECTORY(cPath)
		MD (cPath)
	ENDIF
	n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
	IF FILE(clocviewer)
		IF bUseTestVersion
*!*				WAIT WINDOW "Getting latest version of Burn_basimage System..." NOWAIT NOCLEAR
*!*				COPY FILE (cnetviewertest) TO (clocviewertest)
*!*				WAIT CLEAR
			n_TxtTiff = ADIR(a_txtTiff,cnetviewertest)
			d_TxtTiff = a_txtTiff[1, 3]
			t_TxtTiff = a_txtTiff[1, 4]
			n_TxtTiff = ADIR(a_txtTiff,clocviewertest)
			IF n_TxtTiff > 0
				IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
					WAIT WINDOW "Getting latest TEST version of Burn_baseimage System..." NOWAIT NOCLEAR
					COPY FILE (cnetviewertest) TO (clocviewertest)
					WAIT CLEAR
				ENDIF
			ENDIF
			n_TxtTiff = ADIR(a_txtTiff,clocviewer)
			IF n_TxtTiff > 0
				IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
					WAIT WINDOW "Getting latest PRODUCTION version of Burn_baseEimage System..." NOWAIT NOCLEAR
					COPY FILE (cnetviewer) TO (clocviewer)
					WAIT CLEAR
				ENDIF
			ENDIF
		ELSE
			d_TxtTiff = a_txtTiff[1, 3]
			t_TxtTiff = a_txtTiff[1, 4]
			n_TxtTiff = ADIR(a_txtTiff,clocviewer)
			IF n_TxtTiff > 0
				IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
					WAIT WINDOW "Getting latest version of Burn_baseimage System..." NOWAIT NOCLEAR
					COPY FILE (cnetviewer) TO (clocviewer)
					WAIT CLEAR
				ENDIF
			ENDIF
		ENDIF

*--get updated config files
		LOCAL clocviewer,cnetviewer,d_TxtTiff,n_TxtTiff,t_TxtTiff,cstring
		clocviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"burn_baseimage.exe.config"
		crtsx86 =ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"burn_baseimage.exe.config"
		cnetviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetburnbase", "\"))) +"burn_baseimage.exe.config"
		crtsx86test =ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"burn_baseimagetest.exe.config"
		clocviewertest=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"burn_baseimagetest.exe.config"
		cnetviewertest=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetburnbase", "\"))) +"burn_baseimagetest.exe.config"
		clocviewer=IIF(pl_Is64bit,crtsx86,clocviewer)
		clocviewertest=IIF(pl_Is64bit,crtsx86test,clocviewertest)
		LOCAL cPath
		cPath = IIF(pl_Is64bit,"c:\program files (x86)\rts\","c:\program files\rts\")

		n_TxtTiff = ADIR(a_txtTiff,cnetviewertest)
		d_TxtTiff = a_txtTiff[1, 3]
		n_TxtTiff = ADIR(a_txtTiff,clocviewertest)
		IF n_TxtTiff > 0
			IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
				WAIT WINDOW "Getting latest TEST version of Burn_baseimage System..." NOWAIT NOCLEAR
				COPY FILE (cnetviewertest) TO (clocviewertest)
				WAIT CLEAR
			ENDIF
		ENDIF

		n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
		d_TxtTiff = a_txtTiff[1, 3]
		n_TxtTiff = ADIR(a_txtTiff,clocviewer)
		IF n_TxtTiff > 0
			IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
				WAIT WINDOW "Getting latest PRODUCTION version of Burn_baseEimage System..." NOWAIT NOCLEAR
				COPY FILE (cnetviewer) TO (clocviewer)
				WAIT CLEAR
			ENDIF
		ENDIF

	ELSE
*--n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
		IF n_TxtTiff > 0 AND NOT FILE(clocviewer)
			IF n_TxtTiff > 0
				cnetpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetburnbase", "\")))
				cstring=ADDBS(cnetpath) + "setup.exe"
				IF FILE(cstring)
					gfmessage("One-time installation process for " + cstring + " required")
					RUN &cstring
					COPY FILE (cnetviewer) TO IIF(bUseTestVersion,clocviewertest,clocviewer)
				ELSE
					gfmessage("Installation program " + cstring	+ " not found. Please notify Helpdesk.")
				ENDIF
			ENDIF
		ENDIF
	ENDIF
ENDIF

*-- converttxt2tiff.exe
clocviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"converttxt2tiff.exe"
crtsx86 =ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"converttxt2tiff.exe"
cnetviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","converttxt2tiff", "\"))) +"converttxt2tiff.exe"

clocviewer=IIF(pl_Is64bit,crtsx86,clocviewer)
LOCAL cPath
cPath = IIF(pl_Is64bit,"c:\program files (x86)\rts\","c:\program files\rts\")

IF NOT DIRECTORY(cPath)
	MD (cPath)
ENDIF

n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
IF FILE(clocviewer)
	d_TxtTiff = a_txtTiff[1, 3]
	t_TxtTiff = a_txtTiff[1, 4]
	n_TxtTiff = ADIR(a_txtTiff,clocviewer)
	IF n_TxtTiff > 0
		IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
			WAIT WINDOW "Getting latest version of Burn_basimage System..." NOWAIT NOCLEAR
			COPY FILE (cnetviewer) TO (clocviewer)
			WAIT CLEAR
		ENDIF
	ENDIF
ELSE
*--n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
	IF n_TxtTiff > 0 AND NOT FILE(clocviewer)
		IF n_TxtTiff > 0
			cnetpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","converttxt2tiff", "\")))
			cstring=ADDBS(cnetpath) + "setup.exe"
			IF FILE(cstring)
				gfmessage("One-time installation process for " + cstring + " required")
				RUN &cstring
				COPY FILE (cnetviewer) TO (clocviewer)
			ELSE
				gfmessage("Installation program " + cstring	+ " not found. Please notify Helpdesk.")
			ENDIF
		ENDIF
	ENDIF
ENDIF

*-- tiffannotate
clocviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"tiffannotate.exe"
crtsx86 =ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"tiffannotate.exe"
cnetviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetrelease", "\"))) +"tiffannotate\tiffannotate.exe"

clocviewer=IIF(pl_Is64bit,crtsx86,clocviewer)
LOCAL cPath
cPath = IIF(pl_Is64bit,"c:\program files (x86)\rts\","c:\program files\rts\")

IF NOT DIRECTORY(cPath)
	MD (cPath)
ENDIF
n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
IF FILE(clocviewer)
	d_TxtTiff = a_txtTiff[1, 3]
	t_TxtTiff = a_txtTiff[1, 4]
	n_TxtTiff = ADIR(a_txtTiff,clocviewer)
	IF n_TxtTiff > 0
		IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
			WAIT WINDOW "Getting latest version of TiffAnnotate System..." NOWAIT NOCLEAR
			COPY FILE (cnetviewer) TO (clocviewer)
			WAIT CLEAR
		ENDIF
	ENDIF

*-- GET ANY UPDATE CONFIGURATION FILES
	clocviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"TiffAnnotate.exe.config"
	crtsx86 =ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"TiffAnnotate.exe.config"
	cnetviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetrelease", "\"))) +"tiffannotate\TiffAnnotate.exe.config"
	clocviewer=IIF(pl_Is64bit,crtsx86,clocviewer)
	cPath = IIF(pl_Is64bit,"c:\program files (x86)\rts\","c:\program files\rts\")

	n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
	d_TxtTiff = a_txtTiff[1, 3]
	n_TxtTiff = ADIR(a_txtTiff,cnetviewer)

*--7/1/16: added error trapping for tiffannotate config file replace
	IF FILE(clocviewer)
		n_TxtTiff = ADIR(a_txtTiff,clocviewer)
		IF n_TxtTiff > 0
			IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
				IF FILE(clocviewer)
					TRY
						ERASE (clocviewer)
					CATCH
					ENDTRY
				ENDIF
				IF NOT FILE(clocviewer)
					WAIT WINDOW "Getting latest version of TiffAnnotate System..." NOWAIT NOCLEAR
					TRY
						COPY FILE (cnetviewer) TO (clocviewer)
					CATCH
						gfmessage("Unable to copy new version of TiffAnnotate.exe.config. Please notify Helpdesk.")
					ENDTRY
					WAIT CLEAR
				ELSE
					gfmessage("Unable to update TiffAnnotate.exe.config. Please notify Helpdesk.")
				ENDIF
			ENDIF
		ENDIF
	ENDIF

ELSE
*--n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
	IF n_TxtTiff > 0 AND NOT FILE(clocviewer)
		IF n_TxtTiff > 0
			cnetpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetrelease", "\")))
			cstring=ADDBS(cnetpath) + "tiffannotate\setup.exe"
			IF FILE(cstring)
				gfmessage("One-time installation process for " + cstring + " required")
				RUN &cstring
				COPY FILE (cnetviewer) TO (clocviewer)
			ELSE
				gfmessage("Installation program " + cstring	+ " not found. Please notify Helpdesk.")
			ENDIF
		ENDIF
	ENDIF
ENDIF

*-- Pdfconvert
clocviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"Pdfconverter.exe"
crtsx86 =ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"Pdfconverter.exe"
cnetviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetrelease", "\"))) +"Pdfconverter\Pdfconverter.exe"

clocviewer=IIF(pl_Is64bit,crtsx86,clocviewer)
LOCAL cPath
cPath = IIF(pl_Is64bit,"c:\program files (x86)\rts\","c:\program files\rts\")

IF NOT DIRECTORY(cPath)
	MD (cPath)
ENDIF

n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
IF FILE(clocviewer)
	d_TxtTiff = a_txtTiff[1, 3]
	t_TxtTiff = a_txtTiff[1, 4]
	n_TxtTiff = ADIR(a_txtTiff,clocviewer)
	IF n_TxtTiff > 0
		IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
			WAIT WINDOW "Getting latest version of Pdfconverter System..." NOWAIT NOCLEAR
			COPY FILE (cnetviewer) TO (clocviewer)
			WAIT CLEAR
		ENDIF
	ENDIF
*--get updated config files
	clocviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","clocprint", "\"))) +"Pdfconverter.exe.config"
	crtsx86 =ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","crtsx86", "\"))) +"Pdfconverter.exe.config"
	cnetviewer=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cnetrelease", "\"))) +"Pdfconverter\Pdfconverter.exe.config"
	clocviewer=IIF(pl_Is64bit,crtsx86,clocviewer)
	cPath = IIF(pl_Is64bit,"c:\program files (x86)\rts\","c:\program files\rts\")
	n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
	IF FILE(clocviewer)
		d_TxtTiff = a_txtTiff[1, 3]
		t_TxtTiff = a_txtTiff[1, 4]
		n_TxtTiff = ADIR(a_txtTiff,clocviewer)
		IF n_TxtTiff > 0
			IF (d_TxtTiff > a_txtTiff[1, 3]) OR (d_TxtTiff = a_txtTiff[1, 3] AND t_TxtTiff > a_txtTiff[1, 4])
				WAIT WINDOW "Getting latest version of Pdfconverter System..." NOWAIT NOCLEAR
				COPY FILE (cnetviewer) TO (clocviewer)
				WAIT CLEAR
			ENDIF
		ENDIF
	ENDIF

ELSE
*--n_TxtTiff = ADIR(a_txtTiff,cnetviewer)
	IF n_TxtTiff > 0 AND NOT FILE(clocviewer)
		IF n_TxtTiff > 0
			WAIT WINDOW "Getting latest version of Pdfconverter System..." NOWAIT NOCLEAR
			COPY FILE (cnetviewer) TO (clocviewer)
			WAIT CLEAR
		ENDIF
	ENDIF
ENDIF
