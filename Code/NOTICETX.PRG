PROCEDURE NoticeTX
****************************************************************************
** Reprints the Texas Notice to Counsel form on a local printer
** Called by PrintCov
** Assumes gfGetCas, gfGetDep have been called
****************************************************************************
** 02/23/2006 MD Modified for VFP

LOCAL szAlias, lloGen, lcSQLLine, lloForm

&& Store current workarea
szAlias = ALIAS()

IF TYPE("oGen")!="O"
   oGen=CREATEOBJECT("transactions.medrequest")
   lloGen=.T.
ENDIF
IF TYPE("loForm")!="O"
   loForm=CREATEOBJECT("transactions.frmPStatus")
   loForm.show
   lloForm=.T.
ENDIF    

CREATE CURSOR temprep (textline c(80), groupcode c(1))
CREATE CURSOR temprep2 (textline c(80),textline2 c(80), groupcode c(1))

loForm.Label3.Caption="TX notice"+CHR(13)+;
"Accessing Data"
lcSQLLine="select * from tblTXNotice where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+;
ALLTRIM(STR(pn_tag))+"' and active=1"
oGen.sqlexecute(lcSQLLine, "viewTXNotice")
SELECT viewTXNotice
IF RECCOUNT()=0
   RETURN
ENDIF
USE 

**10/01/18 SL #109598
*lcSQLLine="select * from tblTimeSheet with (INDEX(ix_tbltimesheet)) where cl_code='"+
lcSQLLine="select * from tblTimeSheet where cl_code='"+;
ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"' and active=1"
oGen.sqlexecute(lcSQLLine, "viewTimeSheet")
SELECT viewTimeSheet
IF RECCOUNT()=0
   RETURN
ENDIF
USE 
*8/26/09 switch to a new Deponent rolodex/repalced the sql with a call to a stored proc
*lcSQLLine="select * from tblDeponent with (INDEX(ix_tbldeponent)) where mailid_no='"+;
ALLTRIM(fixquote(pc_MailID))+"' and active=1"
lcSQLLine=" exec dbo.GetDepInf'"+pc_MailID+"'"
oGen.sqlexecute(lcSQLLine, "viewDeponent")
SELECT viewDeponent
IF RECCOUNT()=0
   RETURN
ENDIF
   
SELECT viewDeponent
mRDepName = UPPER(ALLTRIM(Name))
mRDepAddr = ALLTRIM(Add1) + " " + ALLTRIM(Add2)
mRDepCSZ = ALLTRIM(City) + ", " + ALLTRIM(State) + ". " + ALLTRIM(Zip)
USE

loForm.Label3.Caption="TX notice"+CHR(13)+;
"Pulling Special Instructions"
DO addSpecIns IN PrintCov WITH pc_clcode, pn_tag

&& Requesting Attorney Info
loForm.Label3.Caption="TX notice"+CHR(13)+;
"Pulling Attorney Info"
lcSQLLine="exec dbo.GetAttyInfo '"+ALLTRIM(pc_rqatcod)+"'"
oGen.sqlexecute(lcSQLLine, "viewAttyInfo")
SELECT viewAttyInfo
IF RECCOUNT()>0
   lcFor = IIF( NVL(pl_plisrq,.F.), "Plaintiff", "Defendant")
   mRRqName = ALLTRIM(NewFirst) + " " + ALLTRIM(NewLast) + ;
   ", " + ALLTRIM(Title)
   mRRqFirm = ALLTRIM(Firm)                        && Should be Firm name
   mRRqBar = ALLTRIM(BarNumber)                    && Should be Attorney Bar Number   
ENDIF 
USE 

&& Code to go through TABills and print names of all other
&& participating attorneys in this case.
&& Put Plaintiff Attorney into List of Counsel if not Requesting Atty

loForm.Label3.Caption="TX notice"+CHR(13)+;
"Add Attorney's List"
x=0
IF NOT NVL(pl_plisrq,.F.)
   lcSQLLine="exec dbo.GetAttyInfo '"+ALLTRIM(pc_platcod)+"'"
   oGen.sqlexecute(lcSQLLine, "viewAtty")
   SELECT viewAtty
   IF RECCOUNT()>0   
      INSERT INTO temprep2 (textline) values(" 1. "+ALLTRIM(viewAtty.NewFirst) + " " + ;
      ALLTRIM(viewAtty.NewLast))      
      x=1
   ENDIF 
   SELECT viewAtty
   USE
ENDIF

lcSQLLine="exec dbo.GetAttyList '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(pc_platcod)+"', '"+;
ALLTRIM(pc_rqatcod)+"'"
oGen.sqlexecute(lcSQLLine, "viewAttyList")

SELECT viewAttyList
&& Display names of Opposing Counsel
SCAN    
    x=x+1    
    IF x%2=1
       SELECT temprep2
       APPEND blank
       fld="textline"
    ELSE 
       fld="textline2"
    ENDIF
    SELECT temprep2
    REPLACE &fld WITH PADL(ALLTRIM(STR(x)),2," ")+". "+;
    ALLTRIM(viewAttyList.NewFirst) + " " + ALLTRIM(viewAttyList.NewLast)+;
    IIF(EMPTY(ALLTRIM(NVL(viewAttyList.title,""))),"", ", " + ALLTRIM(viewAttyList.Title))    
   SELECT viewAttyList
ENDSCAN
SELECT viewAttyList
USE

**10/01/18 SL #109598
*lcSQLLine="select open_Date from tblRequest with (INDEX(ix_tblrequests_2)) where cl_code='"+
lcSQLLine="select open_Date from tblRequest where cl_code='"+;
ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_tag))+"' and active=1"
oGen.sqlexecute(lcSQLLine, "viewDate")
SELECT viewDate
IF RECCOUNT()>0
   dRqDate = viewDate.open_date
ELSE
   dRqDate=DATE()   
ENDIF
USE 
lcdobssn="DOB: "+alltrim(DTOC(oGen.checkdate(pd_pldob)))+",  SSN: "+alltrim(pc_plssn)
pc_UserOfc=NVL(goApp.CurrentUser.orec.office,"")

&& Print TX Notice - Page 1
SELECT temprep
IF RECCOUNT()=0
   APPEND BLANK 
ENDIF    
GO TOP 
REPORT FORM PrintNoticeTXPg1 TO PRINTER NOCONSOLE 
SELECT temprep
USE 

&& Print the Actual Notice - Page 2
SELECT temprep2
IF RECCOUNT()=0
   APPEND BLANK 
ENDIF    
GO TOP 
REPORT FORM PrintNoticeTXPg2 TO PRINTER NOCONSOLE 
SELECT temprep2
USE 

IF lloGen=.T.
   RELEASE oGEn
ENDIF
IF lloForm=.T.
   RELEASE loForm
ENDIF   
&& Restore to original workarea
IF NOT EMPTY( szAlias)
   SELECT (szAlias)
ENDIF
RETURN
