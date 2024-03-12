*****************************************************
** Develop directory tree using file scripting
*****************************************************
PRIVATE c_filetype,dtdate,d_date,n_subfolders,nfoldercnt,n_primelevel,lcbratonpath
LOCAL nscanpages
*lcbratonpath=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","BRAYTONFLPath", "\")))

lcbratonpath="\\Imagesvr\RTDOCS\BRAYTON\"

odate=CREATEOBJECT ('utility.frmjustgetdate')
odate.CAPTION='Brayton "New" Date'
odate.SHOW
l_continue=IIF(odate.exit_mode='SAVE',.T.,.F.)
dtdate=odate.d_date
odate.RELEASE
c_start=(lcbratonpath)
c_filetype='xxx'
CREATE CURSOR dirtree(nLEVEL N(2),cPATH c(60),cfile c(25),ddate DATETIME)

loTherm=CREATEOBJECT("app.appfrmthermometer")
GetTreeUsingFSO(ADDBS(c_start))

*\\generate report
WAIT CLEAR
WAIT WINDOW "Creating report of new Brayton First-Look tags" NOWAIT NOCLEAR
CREATE CURSOR braytags (lrs_no INT,TAG INT,PAGES INT,add_date DATE,COMMENT c(50))
obmed=CREATEOBJECT('medgeneric')
SELECT * FROM dirtree WHERE AT('\',ALLTRIM(cPATH),7)>0 INTO CURSOR thecount
n_rec=0
n_totrecs=RECCOUNT('thecount')
IF n_totrecs>0
*!*		loTherm=CREATEOBJECT("app.appfrmthermometer")
*!*		loTherm.updatedisplay( 1,n_totrecs+10 , "Creating report of new Brayton First-Look tags", "Please wait")
	SELECT dirtree
	lcOakConn=SQLSTRINGCONNECT("dsn=OaklandScan")
	IF lcOakConn<0
		gfmessage('Page number data not available for report.')
	ENDIF 
	SCAN FOR AT('\',ALLTRIM(cPATH),7)>0
		n_rec=n_rec+1
*!*			IF TYPE('loTherm')='O'
*!*			loTherm1.updatedisplay(n_rec,n_totrecs+10, ;
*!*				"Creating report of new Brayton First-Look tags", "Processed "+;
*!*				ALLTRIM(STR(n_rec))+" from "+ALLTRIM(STR(n_totrecs)))
*!*			ENDIF
		clrs=ALLTRIM(STR(VAL(SUBSTR(cPATH,AT('\',ALLTRIM(cPATH),6)+1,8))))
		ctag=STR(VAL(SUBSTR(cPATH,AT('\',ALLTRIM(cPATH),7)+1,3)))
		c_sql="exec dbo.getmasterbyrt &clrs."
		nr=obmed.sqlexecute(c_sql,"viewmaster")
		nscanpages=0
		IF lcOakConn>0
			lcSQLLine="select * from tblscanrecords where srt="+ALLTRIM(clrs)+" and ntag="+;
				ALLTRIM(ctag)+" and bkopsync=1 and slasterror is null"
			SQLEXEC(lcOakConn,lcSQLLine,"viewCAScan")
			SELECT viewCAScan
			IF RECCOUNT()>0
				GO TOP
				nscanpages=nPages
			ENDIF
			USE IN viewCAScan
		ENDIF
		INSERT INTO braytags VALUES (VAL(clrs),VAL(ctag),nscanpages,dirtree.ddate,ALLTRIM(viewmaster.COMMENT))
		SELECT dirtree
	ENDSCAN
	IF lcOakConn>0
	SQLDISCONNECT(lcOakConn)
	ENDIF 
ENDIF
WAIT CLEAR
IF RECCOUNT('braytags')>0
	SELECT braytags
	INDEX ON STR(lrs_no)+STR(TAG) TAG LRS_TAG
	SET ORDER TO LRS_TAG IN braytags
	oRep=CREATEOBJECT("app.rt_frm_repoutput","Brayton_FirstLook", "New Brayton First Look Tags", "braytags")
	oRep.SHOW
ELSE
	gfmessage("No new Brayton first-look tags found since selected date")
ENDIF
RETURN

*****************************************************
FUNCTION GetTreeUsingFSO
LPARAMETERS tcBaseFolder
IF VARTYPE(tcBaseFolder) # 'C' OR ! DIRECTORY(FULLPATH(tcBaseFolder))
	tcBaseFolder = FULLPATH(CURDIR())
ENDIF
LOCAL oFSO
oFSO = CREATEOBJ('Scripting.FileSystemObject')
ofldcnt=oFSO.GetFolder(tcBaseFolder)
n_subfolders=ofldcnt.subfolders.COUNT
n_primelevel=OCCURS('\',ofldcnt.PATH)
nfoldercnt=0
IF TYPE('loTherm')='O' AND NOT ISNULL(loTherm )
	loTherm.updatedisplay( 1, n_subfolders, "Searching for new Brayton First-Look tags", "Please wait")
ENDIF

RecurseSubFoldersUsingFSO(oFSO.GetFolder(tcBaseFolder))

ENDFUNC
*****************************************************
FUNCTION RecurseSubFoldersUsingFSO
*\\ folder level
LPARAMETERS toFolderObj
LOCAL n_level

n_level=OCCURS('\',toFolderObj.PATH)
IF n_level=n_primelevel+1
	nfoldercnt=IIF(nfoldercnt<=n_subfolders-2,nfoldercnt+1,nfoldercnt)
	IF TYPE('loTherm')='O' AND NOT ISNULL(loTherm )
		loTherm.updatedisplay(nfoldercnt,n_subfolders, ;
			"Searching for new Brayton First-Look tags", "Processed "+;
			ALLTRIM(STR(nfoldercnt))+" from "+ALLTRIM(STR( n_subfolders)))
	ENDIF
ENDIF

INSERT INTO dirtree VALUES (n_level,toFolderObj.PATH,'',toFolderObj.Datecreated)

getfileslist(toFolderObj,n_level+1)

FOR EACH oFolder IN toFolderObj.subfolders
	IF oFolder.Datecreated>=dtdate
		RecurseSubFoldersUsingFSO(oFolder)
	ELSE
		n_level=n_primelevel+1
		IF n_level=n_primelevel+1
			nfoldercnt=IIF(nfoldercnt<=n_subfolders-2,nfoldercnt+1,nfoldercnt)
			IF TYPE('loTherm')='O'  AND NOT ISNULL(loTherm )
				loTherm.updatedisplay(nfoldercnt,n_subfolders, ;
					"Searching for new Brayton First-Look tags", "Processed "+;
					ALLTRIM(STR(nfoldercnt))+" from "+ALLTRIM(STR( n_subfolders)))
			ENDIF
		ENDIF
	ENDIF
ENDFOR

RETURN
ENDFUNC
*****************************************************
FUNCTION getfileslist
*\\ file level
PARAMETERS oFolder,n_cnt
oFiles = oFolder.FILES
IF oFolder.FILES.COUNT > 0
	FOR EACH oFile IN oFiles
		IF c_filetype=='*' OR (UPPER(JUSTEXT(ALLTRIM(oFile.NAME)))==c_filetype)
			INSERT INTO dirtree VALUES (n_cnt,oFolder.PATH,oFile.NAME,oFolder.Datecreated)
		ENDIF
	ENDFOR
ENDIF
RETURN

ENDFUNC
