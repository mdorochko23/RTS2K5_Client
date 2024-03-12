PROCEDURE Print41
*****************************************************************************
* Print41.prg - print No Record Statement
*   Called by PrintCov (deponent level)
*   Calling Parameters:
*      l_newltr will be true if using new-style cover letters
*      c_newcats will contain the new-style categories
*   Prior to the call, PrintCov will have acquired the relevant admission
*   category info for use w/new cover letters. gfGetCas, gfGetDep are
*   assumed to have been called before calling Print41.
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 04/25/2006 - MD changed softcopy output name
* 02/13/2006 - MD converted to vfp
*****************************************************************************
PARAMETER l_newltr, c_newcats

LOCAL lloGen, lcSQLLine, lnCurArea, lnMempWidth

lnCurArea=SELECT()

IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("transactions.medrequest")
   lloGen=.T.
ENDIF
IF NOT PrintStatus()
   oGen.bringmessage("Printer is not ready.  Fix it and try again.", 2)
   oGen.bringmessage("Make sure printer is attached and turned on!", 2)
Return
ENDIF
lnMempWidth=SET('MemoWidth')


Set MemoWidth To 64

c_phone=lookPhone()

lcOutput=(pc_softdir + "9_nrsdoc.txt")

lcSQLLine="exec dbo.getCode41Desc '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_tag))+"'"
oGen.sqlexecute(lcSQLLine,"viewCode41")
SELECT viewCode41
If RECCOUNT()>0
   Do Case
      Case viewCode41.Type = "A"
         DO prnt41A
      Case viewCode41.Type = "B"                           && Undocumented
         DO Prnt41B
      Case viewCode41.Type = "C"                           && Verbal
         DO Prnt41C
      Case viewCode41.Type = "D"                           && Inadequate Attorney Response
         DO Prnt41D
      CASE viewCode41.Type = "E"                           && Same as another deponent
         IF NOT Item_1                          		   && Only print for verbal
            DO Prnt41E                          		   && responses
         ENDIF
      CASE viewCode41.Type = "F"
         DO Prnt41F                             		   && Unresponsive Deponent
      Otherwise
         gfmessage(  "Invalid NRS type: " + viewCode41.type)
   EndCase
Else
   gfmessage( "Could not find tag in code41: " + Alltrim(Str(pn_Tag)))
ENDIF

SELECT viewCode41
USE 
Set MemoWidth To lnMempWidth
SELECT (lnCurArea)

RETURN 
* ---------------------------------------------------------------------------
* Print NRS-A
* ---------------------------------------------------------------------------
Procedure Prnt41A
LOCAL lnCurArea, x
lnCurArea=SELECT()

IF MemLines(viewCode41.Reason)=0
	RETURN
ENDIF

Wait Window "Printing NRS-A detail sheet for " + pc_lrsno ;
   + " Tag: " + Alltrim(str(pn_Tag)) + "." NOWAIT NOCLEAR 

lcNote="NRS-A"
lcTitle="NO RECORD STATEMENT"

SELECT 0
CREATE CURSOR temprep (textline c(80),groupcode c(1))

SET MARGIN TO 7
*!*	For x = 1 To MemLines(viewCode41.Reason)
*!*	    INSERT INTO temprep (textline) values(Mline(viewCode41.Reason, x))
*!*	Next x

DO addMLine WITH viewCode41.Reason

SELECT temprep
IF RECCOUNT()=0
   APPEND BLANK
ENDIF
GO TOP
IF pl_Softimg    
    _ASCIIROWS=58
	REPORT FORM Print41 TO file &lcOutPut ASCII 
ELSE 
    REPORT FORM Print41 TO PRINTER NOCONSOLE 
ENDIF   
SELECT temprep
USE 

* -- reset memo field width since it affects the ? command --
Set MemoWidth To 78
SET MARGIN TO 0
SELECT (lnCurArea)
WAIT CLEAR 
RETURN
* ---------------------------------------------------------------------------
* Print NRS-B
* ---------------------------------------------------------------------------
Procedure Prnt41B
Wait Window "Printing NRS-B detail sheet for " + pc_lrsno ;
   + " Tag: " + Alltrim(str(pn_Tag)) + "." NOWAIT NOCLEAR 

LOCAL lnCurArea,x
lnCurArea=SELECT()   

lcNote="NRS-B"
lcTitle="NO RECORD STATEMENT"

SELECT 0
CREATE CURSOR temprep (textline c(80),groupcode c(1))

SET MARGIN TO 7
IF !EMPTY(ALLTRIM(NVL(viewCode41.Reason,"")))
*!*	   For x = 1 To MemLines(viewCode41.Reason)
*!*	      INSERT INTO temprep (textline) values(Mline(viewCode41.Reason, x))
*!*	   Next x   
   DO addMLine with viewCode41.Reason
ENDIF 

INSERT INTO temprep (textline) values("")
INSERT INTO temprep (textline) values("Please be advised that the following steps have been taken in")
INSERT INTO temprep (textline) values("order to obtain the requested materials:")
INSERT INTO temprep (textline) values("")

If viewCode41.Item_1
   INSERT INTO temprep (textline) values("CONTACTED NATIONAL MEDICAL SOCIETY") 
   INSERT INTO temprep (textline) values("")  
Endif
If viewCode41.Item_2
  INSERT INTO temprep (textline) values("CALLED HOSPITALS & MEDICAL STAFFS WHERE DOCTOR WAS")
  INSERT INTO temprep (textline) values("AFFILIATED")  
  INSERT INTO temprep (textline) values("")
Endif
If viewCode41.Item_3
   INSERT INTO temprep (textline) values("CHECKED IN STATE MEDICAL DIRECTORY")
   INSERT INTO temprep (textline) values("")
Endif
If viewCode41.Item_4
   INSERT INTO temprep (textline) values("CHECKED IN ABMS MEDICAL DIRECTORY")   
   INSERT INTO temprep (textline) values("")
Endif
If viewCode41.Item_5
   INSERT INTO temprep (textline) values(;
      "MAIL SENT TO ADDRESS PROVIDED HAS BEEN RETURNED AS UNDELIVERABLE")  
   INSERT INTO temprep (textline) values("")
Endif
If viewCode41.Item_6
   INSERT INTO temprep (textline) values(viewCode41.other)
   INSERT INTO temprep (textline) values("")
Endif
*!*	If ! Empty(viewCode41.Reason)   
*!*	   For x = 1 To MemLines(viewCode41.Reason)
*!*	      INSERT INTO temprep (textline) values(Mline(viewCode41.Reason, x))
*!*	   Next x   
*!*	Endif
If viewCode41.Item_7
   INSERT INTO temprep (textline) values("CHECKED WITH LOCAL DIRECTORY ASSISTANCE")   
Endif

SELECT temprep
IF RECCOUNT()=0
   APPEND BLANK
ENDIF
GO TOP
IF pl_Softimg    
    _ASCIIROWS=58
	REPORT FORM Print41 TO file &lcOutPut ASCII  
ELSE 
    REPORT FORM Print41 TO PRINTER NOCONSOLE 
ENDIF   
SELECT temprep
USE 

WAIT CLEAR 
SELECT (lnCurArea)
RETURN

* ---------------------------------------------------------------------------
* Print NRS-C
* ---------------------------------------------------------------------------
Procedure Prnt41C
Wait Window "Printing NRS-C detail sheet for " + pc_lrsno ;
   + " Tag: " + Alltrim(str(pn_Tag)) + "." NOWAIT NOCLEAR 
   
LOCAL lnCurArea
lnCurArea=SELECT()   

lcNote="NRS-C"
lcTitle="VERBAL STATEMENT OF NO RECORDS/MATERIALS"

SELECT 0
CREATE CURSOR temprep (textline c(80),groupcode c(1))
INSERT INTO temprep (textline) values("RecordTrak has been informed on "+Dtoc(viewCode41.NRSCDate))
INSERT INTO temprep (textline) values("by: " + Upper(Alltrim(viewCode41.Contact)))
INSERT INTO temprep (textline) values("of: " + Upper(Alltrim( pc_Descrpt)))

lcText =""
IF l_newltr
   INSERT INTO temprep (textline) values("that the " + LOWER( c_NewCats))
ELSE   
   If viewCode41.Item_1
      lcText = lcText + "medical records, "
   Endif
   If viewCode41.Item_2     
      lcText = lcText + "radiology, "      
   Endif
   If viewCode41.Item_3            
      lcText = lcText + "pathology, "
   Endif
   If viewCode41.Item_4           
      lcText = lcText + "medical bills, "
   Endif
   If viewCode41.Item_5      
      lcText = lcText + "updated records, "     
   Endif
   If viewCode41.Item_6      
      lcText = lcText + "photographs, "      
   Endif
   If viewCode41.Item_7      
      lcText = lcText + LOWER(ALLTRIM(NVL(viewCode41.Other,"")))      
   Endif
   If EMPTY(ALLTRIM(lcText))
      INSERT INTO temprep (textline) values("that the materials we requested:")
   ELSE   
      lcText ="that the "+lcText+" we requested:"
      DO lfParsePrt WITH lcText
   ENDIF 
ENDIF

If ! Empty(NVL(viewCode41.Reason,""))   
*!*	   For x = 1 To MemLines(viewCode41.Reason)
*!*	      INSERT INTO temprep (textline) values(Mline(viewCode41.Reason, x))
*!*	   Next x      
   DO addMLine with viewCode41.Reason
ENDIF
SELECT temprep
IF RECCOUNT()=0
   APPEND BLANK
ENDIF
GO TOP
IF pl_Softimg    
   _ASCIIROWS=58
	REPORT FORM Print41 TO file &lcOutPut ASCII 
ELSE 
    REPORT FORM Print41 TO PRINTER NOCONSOLE 
ENDIF   
SELECT temprep
USE
WAIT CLEAR 
SELECT (lnCurArea) 
Return

* ---------------------------------------------------------------------------
* Print NRS-D
* ---------------------------------------------------------------------------
PROCEDURE Prnt41D
Wait Window "Printing NRS-D detail sheet for " + pc_lrsno ;
   + " Tag: " + Alltrim(str(pn_Tag)) + "." NOWAIT NOCLEAR 

LOCAL lnCurArea, lc40String
lnCurArea=SELECT()   
lc40String=""

**10/01/18 SL #109598
*lcSQLLine="select * from tblTimeSheet with (INDEX(ix_tblTimeSheet)) where cl_code='"+
lcSQLLine="select * from tblTimeSheet where cl_code='"+;
ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"'and txn_code=40 and active=1"
oGen.sqlexecute(lcSQLLine,"viewCode40")
SELECT viewCode40
If RECCOUNT()>0   
   SCAN 
   lc40String=lc40String+DTOC(NVL(viewCode40.txn_date,{}))+", "
   ENDSCAN 
Endif
USE
IF !EMPTY(ALLTRIM(lc40String))		
   * remove last comma
   lc40String=SUBSTR(ALLTRIM(lc40String),1,LEN(ALLTRIM(lc40String))-1)
   * add 'and' before last sentence
   IF RAT(",",lc40String)>0
     lc40String=STUFF(lc40String,RAT(",",lc40String),1," and")
   ENDIF   
   lc40String=ALLTRIM(lc40String)+"."
ENDIF    

lcSQLLine="exec dbo.getCode30Desc '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_tag))+"'"
oGen.sqlexecute(lcSQLLine,"viewCode30")
SELECT viewCode30
If RECCOUNT()=0   
   gfmessage( "Could not find Code30:" + pc_clcode + "*" + Str(pn_Tag) )
   USE 
   RETURN 
Endif
lcNote="NRS-D"
lcTitle="NO RECORD STATEMENT"
SELECT 0
CREATE CURSOR temprep (textline c(80),groupcode c(1))

INSERT INTO temprep (textline) values("Dear Counsel,")
INSERT INTO temprep (textline) values(" ")
INSERT INTO temprep (textline) values("RecordTrak has previously contacted counsel on "+Dtoc(viewCode30.Txn_Date)+" due to the")
INSERT INTO temprep (textline) values("fact that the above named deponent requires the following before")
INSERT INTO temprep (textline) values("they would release the materials that have been requested:")
INSERT INTO temprep (textline) values(" ")

If viewCode30.Item_1
   INSERT INTO temprep (textline) values("The above-named deponent requires a fee approval in the")
   INSERT INTO temprep (textline) values("amount of " + ;
   Alltrim(Transform(viewCode30.Fee_Amt, "$$999.99")) + ;
   " for " + Alltrim(viewCode30.Page_Cnt) + ".")
   INSERT INTO temprep (textline) values(" ")
Endif
If viewCode30.Item_2
   INSERT INTO temprep (textline) values("The above-named deponent requires the dates of " + ;
   Lower(Alltrim(viewCode30.Type)))
   INSERT INTO temprep (textline) values("before they can search for the requested material.")
   INSERT INTO temprep (textline) values(" ")
Endif
** DMA  05/05/03  Add HIPAA-compliant Authorization option to Code30 file
IF viewCode30.item_3 OR viewCode30.item_4 OR viewCode30.HIPAA_Auth
   DO CASE
      CASE viewCode30.Item_3
           lcText = "Authorization"
      CASE viewCode30.Item_4
           lcText = "Subpoena"
      CASE viewCode30.HIPAA_Auth
           lcText = "HIPAA-Compliant Authorization"
   ENDCASE      
   INSERT INTO temprep (textline) values(lcText)
   If ! EMPTY(NVL(viewCode30.Comm1,""))
      INSERT INTO temprep (textline) values(Alltrim(viewCode30.Comm1))
   Endif
   If ! EMPTY(NVL(viewCode30.Comm2,""))
      INSERT INTO temprep (textline) values(Alltrim(viewCode30.Comm2))
   Endif
   If ! EMPTY(NVL(viewCode30.Comm3,""))
      INSERT INTO temprep (textline) values(Alltrim(viewCode30.Comm3))
   Endif
   If ! EMPTY(NVL(viewCode30.Comm4,""))
      INSERT INTO temprep (textline) values(Alltrim(viewCode30.Comm4))
   Endif
   If ! EMPTY(NVL(viewCode30.Comm5,""))
      INSERT INTO temprep (textline) values(Alltrim(viewCode30.Comm5))
   Endif
   INSERT INTO temprep (textline) values(" ")
Endif
If viewCode30.Item_5 And ! EMPTY(NVL(viewCode30.Other,""))  
*!*	   For x = 1 To MemLines(viewCode30.Other)
*!*	      INSERT INTO temprep (textline) values(Mline(viewCode30.Other, x))
*!*	   Next x
   DO addMLine WITH viewCode30.Other
   INSERT INTO temprep (textline) values(" ")
ENDIF

IF !EMPTY(ALLTRIM(lc40String))
    lc40String="In addition, follow up reminder letters were sent on "+ALLTRIM(lc40String)
    DO lfParsePrt WITH lc40String
ENDIF 

INSERT INTO temprep (textline) values("To date, RecordTrak has not received a response to our request.")
INSERT INTO temprep (textline) values("And therefore, we have currently terminated our efforts to procure the")
INSERT INTO temprep (textline) values("requested materials. However, upon receipt of your response to this ")
INSERT INTO temprep (textline) values("request, RecordTrak will resume our efforts on your behalf.")
INSERT INTO temprep (textline) values(" ")
INSERT INTO temprep (textline) values(" ")

If ! Empty(NVL(viewCode41.Reason,""))   
*!*	   For x = 1 To MemLines(viewCode41.Reason)
*!*	      INSERT INTO temprep (textline) values(Mline(viewCode41.Reason, x))
*!*	   Next x   
    DO addMLine WITH viewCode41.Reason
ENDIF

lcSQLLine="exec dbo.GetCatInfo '"+pc_clcode+"', '"+ALLTRIM(STR(pn_tag))+"'"
oGen.sqlexecute(lcSQLLine,"viewAdmInfo")
If ! Empty(NVL(viewAdmInfo.n_category,""))   
    DO addMLine WITH viewAdmInfo.n_category
ENDIF
    
INSERT INTO temprep (textline) values(" ") 
SELECT temprep
IF RECCOUNT()=0
   APPEND BLANK
ENDIF
GO TOP
IF pl_Softimg    
    _ASCIIROWS=58
	REPORT FORM Print41 TO file &lcOutPut ASCII 
ELSE 
    REPORT FORM Print41 TO PRINTER NOCONSOLE 
ENDIF   
SELECT temprep
USE   
Select viewCode30
USE 
SELECT viewAdmInfo
USE 
WAIT CLEAR 
SELECT (lnCurArea)
RETURN 

* ---------------------------------------------------------------------------
* Print NRS-E
* ---------------------------------------------------------------------------
Procedure Prnt41E

Wait Window "Printing NRS-E detail sheet for " + pc_lrsno ;
   + " Tag: " + Alltrim(str(pn_Tag)) + "." NOWAIT NOCLEAR 
   
LOCAL lnCurArea
lnCurArea=SELECT()  
lcNote="NRS-E"

*--1/10/18:
imemowith = SET("MemoWidth")
*--3/6/18: FIX TEXT CUT OFF. [81448]
Set MemoWidth To 70
*--Set MemoWidth To 100

*--12/14/17: change document title [75319]
lcTitle="STATEMENT OF NO RECORDS/MATERIALS"
*--lcTitle="VERBAL STATEMENT OF NO RECORDS/MATERIALS"

SELECT 0
*--1/10/18:
CREATE CURSOR temprep (textline c(100),groupcode c(1))
*--CREATE CURSOR temprep (textline c(80),groupcode c(1))
   
If ! Empty(NVL(viewCode41.Reason,""))     
*!*	   For x = 1 TO MemLines(viewCode41.Reason)      
*!*	      INSERT INTO temprep (textline) values(Mline(viewCode41.Reason, x))
*!*	   Next x
   DO addMLine WITH viewCode41.Reason
ENDIF

SELECT temprep
IF RECCOUNT()=0
   APPEND BLANK
ENDIF
GO TOP
IF pl_Softimg    
    _ASCIIROWS=58
	REPORT FORM Print41 TO file &lcOutPut ASCII 
ELSE 
    REPORT FORM Print41 TO PRINTER NOCONSOLE 
ENDIF   
SELECT temprep
USE
WAIT CLEAR 
SELECT (lnCurArea)   
SET MEMOWIDTH TO IIF(NVL(imemowith,0) = 0, 50, imemowith)
RETURN

* ---------------------------------------------------------------------------
* Print NRS-F
* ---------------------------------------------------------------------------
Procedure Prnt41F

Wait Window "Printing NRS-F detail sheet for " + pc_lrsno ;
   + " Tag: " + Alltrim(str(pn_Tag)) + "." NOWAIT NOCLEAR 

LOCAL lnCurArea
lnCurArea=SELECT()
  
lcNote="NRS-F"
lcTitle="NO RECORD STATEMENT"
SELECT 0
CREATE CURSOR temprep (textline c(80),groupcode c(1))

*!*	For x = 1 To MemLines(viewCode41.Reason)  
*!*	    INSERT INTO temprep (textline) values(Mline(viewCode41.Reason, x))
*!*	Next x

DO addMLine WITH viewCode41.Reason

SELECT temprep
IF RECCOUNT()=0
   APPEND BLANK
ENDIF
GO TOP
IF pl_Softimg    
    _ASCIIROWS=58
	REPORT FORM Print41 TO file &lcOutPut ASCII 
ELSE 
    REPORT FORM Print41 TO PRINTER NOCONSOLE 
ENDIF   
SELECT temprep
USE   
WAIT CLEAR 
SELECT (lnCurArea)
RETURN
* ---------------------------------------------------------------------------
Procedure lookPhone

lcPhone = ""
DO CASE
   CASE NOT EMPTY(NVL(pc_amgr_ph,""))
      lcPhone = pc_amgr_ph
   CASE pc_offcode = "M"
      lcPhone = pc_amgr_ph  &&"(800) 845-0413"
   CASE pc_offcode = "C"
      lcPhone = "(800) 220-3200"
   CASE pc_offcode = "S"
      lcPhone = "(888) 877-5770"
   CASE pc_offcode = "T"
      lcPhone = "(800) 305-9900"
   OTHERWISE                                    && Default (used for Phila/Pittsburgh)
      lcPhone = "(800) 355-7400"
ENDCASE
RETURN lcPhone

*****************************************************************************
PROCEDURE lfParsePrt
PARAMETER c_string
PRIVATE c_printme, n_break, n_width
n_width = SET("MEMOWIDTH") - 1
DO WHILE NOT EMPTY(NVL(c_string,""))
   IF LEN( c_string) > n_width
      FOR n_break = n_width TO 1 STEP -1
         IF SUBS( c_string, n_break, 1) = " "              
            INSERT INTO temprep (textline) values(SUBS( c_string, 1, n_break-1))              
            c_string = SUBS( c_string, n_break + 1)
            EXIT
         ENDIF
      ENDFOR
   ELSE        
      INSERT INTO temprep (textline) values(c_string)        
      c_string = ""
   ENDIF
ENDDO
RETURN
**********************************************************************************
PROCEDURE addMLine
LPARAMETERS lcComment
LOCAL lcValue, c, ii, lcLine, lnCurArea, lnCntr
lnCntr=0
lcLine="" 
lnCurArea=SELECT()
For x = 1 To LEN(lcComment)            
    IF SUBSTR(lcComment,x,1)=CHR(13) OR SUBSTR(lcComment,x,1)=CHR(10)
       IF !EMPTY(ALLTRIM(lcLine))
          DO lfParsePrt IN printcov WITH lcLine
       ELSE 
          INSERT INTO temprep (textline) values("")   
       ENDIF    
       lcLine=""       
    ELSE    
       lcLine=lcLine+SUBSTR(lcComment,x,1)       
    endif           
Next x
IF !EMPTY(ALLTRIM(lcLine))
   DO lfParsePrt IN printcov WITH lcLine
ENDIF        
SELECT (lnCurArea)