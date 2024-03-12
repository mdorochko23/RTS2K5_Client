PARAMETERS nPage, c_file
******************************************************************************
*PROCEDURE AllTIFFS
_SCREEN.MOUSEPOINTER=11
SUSPEND

*c_file=""
IF  EMPTY("c_file")
	c_file=getexcelfile()
ENDIF
SET DELETED ON
USE "&c_file" ALIAS ListIssue IN 0

SELECT ListIssue

SELECT ListIssue
GO TOP
*SET ORDER TO  MAILID
*SCAN FOR   NOT DONEMOVE AND ALLTRIM(ListIssue.w)<>"N" AND  NOT EMPTY(ListIssue.S) 
IF nPage=2
	S_SCAN="ALLTRIM(ListIssue.w)<>'N'  AND TAG<>0 AND  PAGE1 "
ELSE
	 S_SCAN="ALLTRIM(ListIssue.w)<>'N'  AND TAG<>0 AND NOT PAGE1 "
	**S_SCAN =" NOT PAGE1 AND alltrim(ListIssue.w)='Y'  AND alltrim(ListIssue.V)='Y'"
ENDIF
SCAN FOR &S_SCAN
*** do all the TIFF
	IF  alltrim(ListIssue.w)="Y" && case base level authorization
		PN_LRSNO=ListIssue.lrs_no
		pc_lrsno=STR(ListIssue.lrs_no)
			DO movepage  WITH ListIssue.S, ListIssue.TAG,IIF(ALLTRIM(ListIssue.w)="Y",.T.,.F.), nPage
	ENDIF

	SELECT ListIssue

ENDSCAN
IF npage=2
**COPY TO t:\PCX
WAIT WINDOW "Need to copy to T:\PCX"
ENDIF
SELECT * FROM ListIssue WHERE NOT donemove and ListIssue.w<>"N" INTO CURSOR notiff
** the images had not been moved - look at the list notiff

SELECT notiff
IF NOT EOF()
	WAIT WINDOW "Some cases/tags did not have images. Look at y:\avandia\notiff.xls"
	COPY  TO Y:\avandia\notiff.XLS TYPE XLS
ENDIF
SELECT ListIssue
WAIT WINDOW "Done Move Images" nowait
_SCREEN.MOUSEPOINTER=0
RETURN
***************************************************************************************
FUNCTION gettifname
PARAMETERS nPtag
n_Batch=0
*****get the folfer for new images 
l_oK=OMED2.sqlexecute("SELECT top 1 batchnum as num from tblSetupAutomatedIssue order by recordid desc", "TheNumber")
IF  l_oK	
	n_Batch=Thenumber.num+1
	endif			
**5/04/09


F_PCX1="T:\ImgTemp\" + ALLTRIM(STR(n_Batch))+ "\"
n_Lastnum1=1
lcFile =ALLTRIM(STR(PN_LRSNO))+"A*."+PADL(ALLTRIM(STR(nPtag)), 3, "0")
n_Files = ADIR(a_files, F_PCX1 +ALLTRIM(UPPER(lcFile)))
IF n_Files > 0
	=ASORT(a_files)
	n_Lastnum1 =getnumber(a_files(ALEN(a_files,1), 1), LEN(ALLTRIM(STR(PN_LRSNO))))
ENDIF
c_newfile=ALLTRIM(STR(PN_LRSNO))+"A"+ALLTRIM(STR(n_Lastnum1+1)) + "." + PADL(ALLTRIM(STR(nPtag)), 3, "0")
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
*********************************************************************************************
PROCEDURE movepage
PARAMETERS  c_mail, n_tag, l_casebase, n_page
PRIVATE filehand, i, lcLrs, lcSource, lcDest, lcSPath, lcDPath, lFileExt
lFileExt = ".TIF"
creqtype='A'
SET SAFETY OFF
F_PCX=goApp.pcxpath
F_PCXARCH=goApp.pcxarchpath
lcLrs = ALLT( pc_lrsno)
lcSPath = F_PCX + lcLrs
lcDPath = F_PCXARCH + RIGHT(lcLrs,1) + "\" + lcLrs

l_ok= movefiletopcx ( lcLrs,  n_tag, c_mail, l_casebase, n_page)

IF NOT l_ok
	WAIT WINDOW "The authorization was not copied to PCX." NOWAIT
ENDIF


*SET SAFETY ON
RETURN
****************************************************
FUNCTION movefiletopcx
PARAMETERS  cRT,  ntagauth,cmailid,LCASE, nOrdPage
PRIVATE l_done AS Boolean
l_done=.F.
c_path="K:\sharedwp\avandia\TIFF"
&&c_TPath= "T:\pcx\"
c_TPath= "T:\ImgTemp\"
SET DEFAULT TO (c_path)

IF LCASE
**case level
**a) page 1
IF nOrdPage=1
	c_path="T:\img_base\autho\"
	c_parameter=ALLTRIM(cRT)+' '+ ALLTRIM(STR(ntagauth))+' '+"A"+' '+ALLTRIM(cmailid)+' AUTHO X X X P' +' ' +c_TPath
	&& new parameters: '50045','1','A','KIRK','AUTHO','','','','P','your folder path'.
				
	RUN /N c:\vfp\tiffauto2.EXE &c_parameter
	
	REPLACE PAGE1 WITH .t. IN ListIssue
ELSE
**b) page 2
	c_FileNew= gettifname(ntagauth)
	c_filen=cRT +"_2.tif"
	c_path="K:\sharedwp\avandia\TIFF"
	c_file =c_path+"\" + c_filen
	
	IF FILE(c_file) 
		c_TIFfile =c_TPath+c_FileNew
		COPY FILE &c_file TO &c_TIFfile
		l_done=.T.
	ELSE
		**missing _2.tif -check with the AM if the file is needed 
		
		l_done=.f.
	ENDIF


	REPLACE PAGE2 WITH l_done IN ListIssue
ENDIF && page 1 or 2
ENDIF

************************************************************************
FUNCTION getexcelfile

************************************************************************
lnCurArea=SELECT()
lcCURR =SYS(5) + SYS(2003)
lcDefault="t:\avandia-pl\"
SET DEFAULT TO &lcDefault
lcFile=GETFILE("XLS","Load Excel List")

lcFile="'"+ALLTRIM(lcFile)+"'"
IMPORT FROM &lcFile XL5
lcFileName=DBF()
USE
lcFileName="'"+ALLTRIM(lcFileName)+"'"

USE &lcFileName ALIAS TodoFile EXCLUSIVE
INDEX ON S FOR .NOT.EMPTY(S) TAG MAILID ADDITIVE
USE
SELECT (lnCurArea)
SET DEFAULT TO &lcCURR 
RETURN (lcFileName)





RETURN l_done
********************************************************