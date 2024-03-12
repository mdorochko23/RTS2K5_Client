PARAMETERS  c_file, n_batchnum
******************************************************************************************************
*EF - 03/08/10 -Get recolumed excel
*EF - 05/26/09 -USE T:\PCX\ TO CREATE THE IMAGES
*EF - 05/01/09 - creates base authos for a list of cases in an excel file
******************************************************************************************************
_SCREEN.MOUSEPOINTER=11
PRIVATE S_SCAN as String


IF type("PC_LITCODE") ="L" OR empty(PC_LITCODE)
	GOAPP.OPENFORM("issued.frmpicklit", "S")
ENDIF
DO closeexcel WITH "Excel.EXE"
IF  EMPTY(c_file)
	c_file=getexcel()
ELSE
	c_file="'"+ALLTRIM(c_file)+"'"
ENDIF
IF (EMPTY(c_file)) &&  Fatal Error - 4/09/2010 - 11:47AM - Error Log - Susan_sh - Susan Shaner                                      
  _SCREEN.MOUSEPOINTER=0
  RETURN
ENDIF
SET DELETED ON
********	get the folfer for new images 	
Use &c_file alias ListIssue in 0
SELECT ListIssue
SET ORDER TO  lrs_No
GO TOP
S_SCAN=""
*S_SCAN="ALLTRIM(ListIssue.w)<>'N'  AND NOT PAGE1  "
IF TYPE("ListIssue.AI")="C"
S_SCAN="ALLTRIM(ListIssue.w)<>'N'  AND  ai ='F' " &&PAGE1
ELSE
S_SCAN="ALLTRIM(ListIssue.w)<>'N'  AND NOT ai  " &&PAGE1
ENDIF

SCAN FOR &S_SCAN
*** do all the TIFFS
	IF  alltrim(ListIssue.w)="Y" && case base level authorization
*!*			PN_LRSNO=ListIssue.lrs_no
*!*			pc_lrsno=STR(ListIssue.lrs_no)
IF TYPE("ListIssue.ad")="C"
		PN_LRSNO=VAL(ListIssue.ad) &&rs_no
		pc_lrsno=ListIssue.ad
ELSE
	PN_LRSNO=ListIssue.ad &&Lrs_no
	pc_lrsno=STR(ListIssue.ad)
ENDIF
		
		
			DO callbase  WITH pc_lrsno,  ListIssue.af, ListIssue.S, .T., n_batchnum			
			**DO callbase  WITH pc_lrsno,  ListIssue.TAG, ListIssue.S, .T., n_batchnum			
	ENDIF

	SELECT ListIssue

ENDSCAN
IF TYPE("ListIssue.AI")="C"
	SELECT * FROM ListIssue WHERE NOT ai="F" and ListIssue.w<>"N" INTO CURSOR notiff readwrite
ELSE
*!*	SELECT * FROM ListIssue WHERE NOT page1 and ListIssue.w<>"N" INTO CURSOR notiff readwrite
	SELECT * FROM ListIssue WHERE NOT ai and ListIssue.w<>"N" INTO CURSOR notiff readwrite
ENDIF
** the images had not been moved - look at the list notiff
SELECT notiff
IF NOT EOF()
lc_PATH=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","AUTOMATEDISSUE", "\")))
	WAIT WINDOW "Some cases/tags did not have images. Look at " + lc_PATH + "notiff.xls"
	COPY  TO  lc_PATH + "notiff.xls" TYPE XLS
ENDIF
SELECT ListIssue
	
**5/29/09- combine the third step into a second one
l_Continue=.f.
lc_message = "Do you want to ISSUED the TAGS now?"
		o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
		o_message.SHOW
		l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
		o_message.RELEASE
		IF l_Confirm
			l_Continue=.T.
		ENDIF

IF l_Continue
	DO ISSUEPROCESS WITH &c_file, .f. 
endif
	
**5/29/09- combine the third step into a second one
	
_SCREEN.MOUSEPOINTER=0
RETURN
*******************************************************************
FUNCTION callbase 
PARAMETERS cRT, ntagauth, cmailid, LCASE, n_Batch
LOCAL c_parameter as String
c_parameter=""
**04/13/2010 - removed a path param per Kirk's email
**5/26/09 create images at T:\pcx + copy the latest
if FILE('c:\vfp\tiffauto.exe')
			DO lfupTiff IN subp_pa
endif
c_TPath="T:\pcx\"
** ------create a folder to store img files 
fso = CREATEOBJECT("Scripting.FileSystemObject")
IF  NOT fso.FolderExists(c_TPath)
	fldr = fso.CreateFolder(c_TPath)
ENDIF
**case level
**a) page 1
	c_path="T:\img_base\autho\"	
	IF TYPE ("ntagauth") ="C"
	c_parameter=ALLTRIM(cRT)+' '+ ALLTRIM(ntagauth)+' '+"A"+' '+ALLTRIM(cmailid)+' AUTHO X X X P' &&+' ' +c_TPath
	ELSE
	c_parameter=ALLTRIM(cRT)+' '+ ALLTRIM(STR(ntagauth))+' '+"A"+' '+ALLTRIM(cmailid)+' AUTHO X X X P' &&+' ' +c_TPath
	ENDIF
	RUN c:\vfp\tiffauto.EXE &c_parameter

	IF TYPE("ListIssue.AI")="C"
	REPLACE AI WITH "t" IN ListIssue
	ENDIF
	*REPLACE PAGE1 WITH .t. IN ListIssue


RETURN 
******************************************
FUNCTION getexcel
PRIVATE l_addnew as Boolean
************************************************************************
lnCurArea=SELECT()
lcCURR =SYS(5) + SYS(2003)
lcDefault=ALLTRIM(ADDBS(MLPriPro("R", "RTS.INI", "Data","AUTOMATEDISSUE", "\")))
l_addnew=.f.
SET DEFAULT TO &lcDefault
lcFileName = '' && Fatal Error - 4/09/2010 - 11:47AM - Error Log - Susan_sh -Susan Shaner                                      
lcFile=GETFILE("XLS","Load Batch List")
IF NOT EMPTY(lcFile)
	*lcFile="'"+ALLTRIM(lcFile)+"'"
LOCAL n_div as Integer, c_dir as String
 n_div=0
 c_dir =""
 n_div =RAT("\",lcfile,1) 
 c_dir =LEFT(lcfile, n_div)
 lcFile="'"+ALLTRIM(lcFile)+"'" 
******
SET DEFAULT TO &lcCURR 
  IF LOADEXCEL(&lcFile, c_dir, "2")=.F.
    IF NOT EMPTY(lnCurArea)
      SELECT (lnCurArea)  
    endif 
    RETURN ""
  ENDIF    

******
*IMPORT FROM &lcFile TYPE XL5
lcFileName=DBF()
USE
lcFileName="'"+ALLTRIM(lcFileName)+"'"
USE &lcFileName ALIAS TodoFile EXCLUSIVE

GO TOP
*!*	FOR lnII=1 TO AFIELDS(laFlds)
*!*	    IF ALLTRIM(UPPER(laFlds[lnII,1]))=="AD"    
*!*	       l_addnew =.t.
*!*	    ENDIF 
*!*	    IF ALLTRIM(UPPER(laFlds[lnII,1]))=="AF"
*!*	       l_addnew =.t.
*!*	    ENDIF 
*!*	NEXT     

DELETE NEXT 1
*!*	ALTER TABLE TodoFile ADD COLUMN page1 L
*!*	ALTER TABLE TodoFile ADD COLUMN page2 L
*!*	SELECT TodoFile

*!*	IF l_addnew
*!*	SET DEFAULT TO &lcCURR 
*!*	ALTER TABLE TodoFile ADD COLUMN lrs_no n(6)
*!*	ALTER TABLE TodoFile ADD COLUMN caseexist n(6)
*!*	ALTER TABLE TodoFile ADD COLUMN tag n(4)
*!*	ALTER TABLE TodoFile ADD COLUMN ISSUEDEP c(50)
*!*	ALTER TABLE TODOFILE ADD COLUMN ISSUED L
*!*	SELECT TodoFile

*!*	REPLACE ALL LRS_NO WITH VAL(STR(VAL(ALLTRIM(AD)),6,0))  IN TODOFILE
*!*	REPLACE ALL TAG WITH VAL(STR(VAL(ALLTRIM(AF)),3,0))  IN TODOFILE
*!*	ENDIF

GO TOP
**
INDEX ON s TAG MAILID ADDITIVE
*INDEX ON lrs_no TAG lrs_no ADDITIVE
INDEX ON AD TAG lrs_no ADDITIVE
USE
ENDIF &&& EMPTY FILE

SELECT (lnCurArea)
SET DEFAULT TO &lcCURR 
RETURN (lcFileName)
