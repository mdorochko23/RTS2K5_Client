*--create tblburnbaselog row, call the burn_baseimage system, and return results of the run

PARAMETERS nLrsno,nTag,cMailid,cReqtype,cDirectory,cOffice,cUser,cParameter,bDoccreated,cNewdoc,cError

LOCAL c_sql,iNid,nr,bUseTestVersion,c_running

SET CLASSLIB TO dataconnection ADDITIVE
oCdcnt=CREATEOBJECT('cntdataconn')

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

IF EMPTY(cuser)
	cuser = GETENV('USERNAME')
ENDIF

iNid = 0
c_sql = "exec [dbo].[Burnbasestart] " + ;
	ALLTRIM(STR(nLrsno)) + ;
	"," + ALLTRIM(STR(nTag)) + ;
	",'" + gfstrclean(cMailid) + "'" + ;
	",'" + NVL(cReqtype,"#") + "'" + ;
	",'" + NVL(cDirectory,"#") + "'" + ;
	",'" + cOffice + "'" + ;
	",'" + gfstrclean(cParameter) + "'" + ;
	",'" + cUser + "'"
nr=oCdcnt.sqlpassthrough(c_sql,"burnnid")

IF RECCOUNT("burnnid") > 0
	iNid = burnnid.newnid
ENDIF
IF USED("burnnid")
	USE IN burnnid
ENDIF

cParameter= cParameter + " " + ALLTRIM(STR(iNid))
c_running = "burn_baseimage.exe"

DO CASE
CASE bUseTestVersion = .F. AND pl_Is64bit
	cParameter = "c:\program files (x86)\rts\burn_baseimage.exe " + cParameter
CASE bUseTestVersion = .T. AND pl_Is64bit
	c_running = "burn_baseimagetest.exe"
	cParameter = "c:\program files (x86)\rts\burn_baseimagetest.exe " + cParameter
CASE bUseTestVersion = .F.
	cParameter = "c:\program files\rts\burn_baseimage.exe " + cParameter
CASE bUseTestVersion = .T.
	c_running = "burn_baseimagetest.exe"
	cParameter = "c:\program files\rts\burn_baseimagetest.exe " + cParameter
ENDCASE

RUN /N &cParameter

*--wait for each call to complete to prevent document conflicts
DO WHILE isrunning(c_running)
	LOOP
ENDDO
*--update parameters for return to calling program
IF iNid > 0
*-- retrieve data from the burn_basedocumnet system
	c_sql = "exec [dbo].[Burnbasedone] " + ;
		ALLTRIM(STR(iNid))
	nr=oCdcnt.sqlpassthrough(c_sql,"burnnid")
	bDoccreated = .F.
	STORE "" TO sDocnew,sError
	IF nr
		IF RECCOUNT("burnnid") > 0
			bDoccreated = burnnid.bDoccreated		&& was run completed (document created)
			cNewdoc = burnnid.sDocnew				&& name of created document
			cError = burnnid.sError					&& returned error
		ENDIF
	ENDIF
	IF USED("burnnid")
		USE IN burnnid
	ENDIF
ENDIF

*----------------------------------------------------------------------
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
	FOR EACH loProcess IN loProcesses
		llIsRunning = .T.
		IF lTerminate
			loProcess.TERMINATE(0)
		ENDIF
	ENDFOR
ENDIF
RETURN llIsRunning
