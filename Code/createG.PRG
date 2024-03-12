PARAMETERS  lcPdfFolder
** create  'G' type image  from loaded pdfs and an excel list Zen#24124: 12/08/15
PUBLIC lcRTSDIR AS STRING
LOCAL  nTg AS NUMBER
lcRTSDIR=SYS(5)+SYS(2003)

SELECT 0
IF USED('Todo2')
	SELECT Todo2
	USE
ENDIF
** temp surssor to hold the data for report that we'll email at the end of the process
CREATE CURSOR Todo2 (Lrs_No  N(6) , TAG N(4), OrigSubp  c(100), PcxFile c(100), Done L NULL)

IF USED("g2pcx")
	SELECT g2pcx && assume it is opened alreday
	SET DELETED ON
	GO TOP
	nall=RECCOUNT()
	SCAN
		SCATTER MEMVAR
		nrec1=RECNO()

		IF TYPE("g2pcx.lrs_no")="C"
			nrt=VAL(g2pcx.Lrs_No)
		ELSE
			nrt=m.Lrs_No
		ENDIF

		PN_LRSNO=nrt
		pc_lrsno=STR(nrt)

		IF TYPE("g2pcx.TAG")="C"
			nTg=VAL(g2pcx.TAG)
		ELSE
			nTg=m.tag
		ENDIF
		WAIT WINDOW  "Working on case #" + ALLTRIM(pc_lrsno) + "."+ ALLTRIM(STR(nTg)  ) NOWAIT

		IF !EMPTY(ALLTRIM(m.OrigSubp))
			l_ok= movefiletopcx (STR(nrt),  nTg,lcPdfFolder, .F., 1, ALLTRIM(m.OrigSubp))
		ELSE
			WAIT WINDOW "One of the rt/tag has no subpoena name(OrigSubp)..Fix and try again" NOWAIT
			RETURN
		ENDIF
		SELECT g2pcx

	ENDSCAN

ELSE
	WAIT WINDOW "No rt/tags to process.." NOWAIT

ENDIF
** email a report back to user
DO EResults


_SCREEN.MOUSEPOINTER=0
RETURN
***************************************************************************************
FUNCTION gettifname
PARAMETERS nPtag

n_Lastnum1=0
lcFile =ALLTRIM(STR(PN_LRSNO))+"g*."+PADL(ALLTRIM(STR(nPtag)), 3, "0")
n_Files = ADIR(a_files, F_PCX +ALLTRIM(UPPER(lcFile)))
IF n_Files > 0
	=ASORT(a_files)
	n_Lastnum1 =getnumber(a_files(ALEN(a_files,1), 1), LEN(ALLTRIM(STR(PN_LRSNO))))
ENDIF
c_newfile=ALLTRIM(STR(PN_LRSNO))+"g"+ALLTRIM(STR(n_Lastnum1+1)) + ".TIF"    &&PADL(ALLTRIM(STR(nPtag)), 3, "0")
RETURN c_newfile

*****************************************************************************************
FUNCTION getnumber
PARAMETER c_Document, n_Lencase
LOCAL n_Pos , c_Num
n_Pos = AT( ".", c_Document)
n_Lencase = n_Lencase + 2
c_Num = SUBSTR(c_Document, n_Lencase, n_Pos - n_Lencase)
RETURN VAL(c_Num)
******************************************************************************************

FUNCTION movefiletopcx
PARAMETERS  cRT,  ntagauth,cFolder,LCASE, nOrdPage, cPdfName
PRIVATE l_done AS Boolean
l_ok =.F.
PRIVATE filehand, i, lcLrs, lcSource, lcDest, lcSPath, lcDPath, lFileExt
lFileExt = ".TIF"
SET SAFETY OFF
F_PCX=goApp.pcxpath
F_PCXARCH=goApp.pcxarchpath
lcLrs = ALLT( pc_lrsno)
lcSPath = F_PCX + lcLrs
lcDPath = F_PCXARCH + RIGHT(lcLrs,1) + "\" + lcLrs
c_path= F_PCX
SET DEFAULT TO (lcRTSDIR)
LOCAL loRequest AS OBJECT
c_Folder=cFolder
loRequest=CREATEOBJECT("medGENERIC")
lcTemp=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","cTemp", "\"))) + "origsub.pdf"
fso2= CREATEOBJECT("Scripting.FileSystemObject")
IF (FILE(lcTemp))
	fso2.DeleteFile(lcTemp)
ENDIF
lcNewpath='C:\LoadGSub' && we may change it later to some other folder
IF  NOT fso2.FolderExists(lcNewpath)
	fldr = fso2.CreateFolder(lcNewpath)
ENDIF

lcSearch =cFolder   + cPdfName
l_continue =.F.

IF NOT EMPTY(cFolder)
	IF (FILE(lcSearch))
		l_continue =.T.
	ENDIF

ENDIF

**
IF l_continue  && found an original ... continue
	c_TIFfile2=""
	c_FileNew= gettifname(ntagauth) && 'g' file name, chcek if already exists
	lconverted= .F.
	loRequest.CLOSEALIAS( "Hasg")
	C_SQL="SELECT  dbo.ChkReturnSubp ('"  +cRT + "','" + ALLTRIM(STR(ntagauth) )+ "')"
	loRequest.Sqlexecute(C_SQL, "Hasg")
	IF USED('Hasg')
		SELECT HASG
		IF  !EOF()
			lconverted= IIF(VAL(HASG.EXP)>=1, .T.,.F.)
		ENDIF
	ENDIF


	IF NOT lconverted && NOT YET HAS A 'G' FILE
		c_TIFfile2=ConvertPDF ( cFolder, 	c_FileNew, cPdfName, ALLTRIM(cRT), lcRTSDIR, ntagauth)
		IF FILE(c_TIFfile2) && GOT A FILE
			l_ok= InsertScn  (ALLTRIM(cRT) ,  STR(ntagauth) ,'G' , c_TIFfile2, lcSearch)
		ENDIF

		SELECT Todo2 &&get the data for a report
		INSERT INTO Todo2  (Lrs_No, TAG, OrigSubp,PcxFile, Done)   VALUES ( PN_LRSNO, ntagauth, cFolder+ cPdfName, c_TIFfile2, IIF(EMPTY(c_TIFfile2),.F.,.T.))
	ENDIF

ELSE
&& did not find a folder with original pdfs
	WAIT WINDOW "No original pdfs found...." NOWAIT

ENDIF

RELEASE loRequest

RETURN 	l_ok

********************************************************

FUNCTION ConvertPDF
LPARAMETERS lcpath, lcfilename, cPdfName, LCRT, lcCurDir, lnTg
LOCAL lcCurDir, lcline, lcinfile, lcoutfile, c_pdf2tif

IF !DIRECTORY("C:\PDF2Image_win\")
	gfMessage("Can't convert PDF to TIF."+CHR(13)+"File PDF2Img_win.exe doesn't exist.")
	RETURN
ENDIF
WAIT WINDOW "Converting PDF to TIFF. Please wait...." NOWAIT NOCLEAR
fso_exc = CREATEOBJECT("Scripting.FileSystemObject")

lcinfile=ADDBS(ALLTRIM(NVL(lcpath,"")))  +ALLTRIM(NVL(cPdfName,""))
lcinfile2= "C:\LoadGSub\"+ALLTRIM( cPdfName)
lcoutfile2="C:\LoadGSub\" + lcfilename&&+".TIF"
lcoutfile=ADDBS(ALLTRIM(NVL(F_PCX,"")))+lcfilename&&+".TIF"
IF !FILE(lcinfile)
	gfMessage("Can't find PDF file at " + lcinfile)

	RETURN ""
ENDIF

IF FILE(lcinfile2)
	DELETE FILE &lcinfile2
ENDIF

*COPY FILE &lcinfile TO &lcinfile2
fso_exc.CopyFile( lcinfile, lcinfile2)
SET DEFAULT TO "C:\PDF2Image_win"

lcline='RUN pdf2img.exe -$ "VERYPDF-PDF2IMAGE-20120712753" -f 0 -l 1 '+lcinfile2+" "+lcoutfile2  && conefrt only 1st page
&lcline
SET DEFAULT TO (lcRTSDIR)
&&ADD TAG TO A NAME
lc_pcxg=""
lc_pcxg=F_PCX + JUSTSTEM(lcoutfile )+ "." + PADL(ALLTRIM(STR(lnTg)), 3, "0")
IF FILE(lcoutfile2)
	fso_exc.CopyFile( lcoutfile2, lc_pcxg )
ELSE
	gfMessage("Can't find " +lcoutfile2)
	RETURN ""
ENDIF

IF FILE(lcoutfile2)
	DELETE FILE &lcoutfile2
ENDIF
IF FILE(lcinfile2)
	DELETE FILE &lcinfile2
ENDIF
RELEASE fso_exc
RELEASE loRequest1
WAIT CLEAR

RETURN   lc_pcxg
*************************************************************************************************************************************\
PROCEDURE EResults

PRIVATE   fso AS OBJECT, OMED AS OBJECT
fso = CREATEOBJECT("Scripting.FileSystemObject")
LOCAL lcAlias AS STRING
lcAlias= ALIAS()
_SCREEN.MOUSEPOINTER=11
lcDate=DTOC(DATE())

**check cur directory here- make sure we are back to rts app


OMED=CREATEOBJECT("generic.medgeneric")
lcTemp=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","CTemp", "\")))

lCTEMPFILE=lcTemp + "ReturnedSubps_2PCX_on" + STRTRAN(lcDate,"/","") + ".xls"
IF   fso.FileExists(ALLTRIM(lCTEMPFILE))
	fso.DeleteFile (lCTEMPFILE)
ENDIF


IF USED('Todo2')
	SELECT Todo2

	SELECT  Lrs_No, TAG, OrigSubp, PcxFile FROM  Todo2 WHERE    Done=.T.   INTO CURSOR  data2  ORDER BY Lrs_No, TAG
	SELECT data2
	GO TOP

	IF NOT EOF()
		COPY TO (STRTRAN(lCTEMPFILE,"'","")) TYPE XL5
		OMED.CLOSEALIAS("UserAcct")
		OMED.Sqlexecute("exec  DBO.[GetUserByLogin] '" +	ALLTRIM( PC_USERID) + "'", "UserAcct")
		SELECT UserAcct
		IF NOT EOF()

			c_SendTo=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_CopyTo="rtverifyoutbound@recordtrak.com"
			c_FromName=ALLTRIM(UserAcct.FULLNAME )
			c_FromEmail=STRTRAN(ALLT( UserAcct.Email),";",",")
			c_Subject=ALLTRIM("Returned Subpoenas added on " + lcDate + "."   )
			c_Message=ALLTRIM("Please, see attached excel file.")
			STORE "" TO c_attachment,c_bCCList
			c_attachment=lCTEMPFILE

			
DO sendwwemail WITH c_FromEmail, c_FromName, c_SendTo,c_CopyTo, c_bCCList, c_Subject, c_Message, c_attachment
*!*	*********************************
*!*	  #DEFINE olMailItem 0
*!*			LOCAL loMailItem AS Outlook.MailItem
*!*				loOutlook = CREATEOBJECT('Outlook.Application')
*!*				loNameSpace = loOutlook.GetNamespace("MAPI")
*!*				loNameSpace.Logon
*!*				loMailItem = loOutlook.CreateItem( olMailItem ) && This creates the MailItem Object
*!*				llShowItem = .T.
*!*				lcSubject =c_Subject
*!*				WITH loMailItem
*!*					.Importance = 1
*!*					.Subject =  lcSubject
*!*					.Recipients.ADD(c_SendTo)
*!*					.cc.aDD(c_CopyTo)
*!*					.Body =c_Message				
*!*					.Attachments.Add(c_attachment)
*!*					.SEND && Calling this will cause a Security Dialog
*!*				ENDWITH


*********************************



		ENDIF
		gfMessage("Please check your Inbox for the " + lCTEMPFILE + " excel fie.")
	ENDIF

ENDIF
RELEASE OMED
RELEASE fso
IF NOT EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF

_SCREEN.MOUSEPOINTER= 0
