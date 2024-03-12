
******************************************************************
** Covlet.prg - Program to add cover letter, add/edit/delete
** admissions. Also allows printing of cover letters.

** Assumes TAMaster.dbf is open and pointing to the current case
** Assumes Record.dbf is open and pointing to the current deponent
** Assumes that gfGetCas and gfGetDep have been called.
****************************************************************
** c_bbdept is used for Berry & Berry Asbestos cases. It contains the
**   one-character code for the hospital department to which the
**   request was originally sent.
**
** l_incoming is true if called for a newly-processed record (from Incoming.prg)
**               false if called for a record that was already
**                    logged into the system (via Deponent Options Menu)
** l_incoming only applies to non-Berry & Berry cases
**
** Comms contains comments to be stored in Comment.dbf
** If l_incoming is .T., comments are also stored in the first admission.
**       Only used when called from Incoming. Only for old-style cover letters

** Autocmd is only used when called from Deponent Options Menu
******************************************************************

PROCEDURE COVLET
PARAMETERS llIncoming, lcComms, lcAutoCmd, lcBBDept, ll1stDocs, lSoftcopycall
LOCAL lloGen

IF TYPE( "lcBBDept") = "U"
   lcBBDept = "M"
ENDIF
IF TYPE("lcAutoCmd") = "U"
   lcAutoCmd = " "
ENDIF
IF TYPE("ll1stDocs") = "U"
   ll1stDocs = .F.                              && do not print 1st-look package docs
ENDIF

IF TYPE("lSoftcopycall") = "U"
	lSoftcopycall = .f.
ENDIF

IF TYPE("oGen")!="O"
   loGen=CREATEOBJECT("transactions.medrequest")
   lloGen=.T.
ENDIF

IF NOT EMPTY(convrtDate(pd_closing))
   DO gfReopen WITH .F., "Adding or editing cover-letter data"
ENDIF

*
*  If no header record exists for this deponent, create it
*  and make it active.  Also assume that there are no admissions
*  entered yet.
*
WAIT WINDOW "Pulling Data.  Please wait...." NOWAIT NOCLEAR 
lcSQLLine="exec dbo.GetCovLet '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_Tag))+"'"
loGen.sqlexecute(lcSQLLine, "viewCovLet")
WAIT CLEAR 

IF RECCOUNT()=0   
   WAIT WINDOW "Pulling Data.  Please wait...." NOWAIT NOCLEAR 
   lcSQLLine="insert into tblCovLet "+;
   "(cl_code,  tag, descript, created, lastAccess, CreatedBy, AccessBy, CountAdm, active, retire)"+;
   " values("+;
   "'"+pc_clcode+"', "+;
   "'"+ALLTRIM(STR(pn_tag))+"', "+;
   "'"+fixquote(pc_descrpt)+"', "+;
   "'"+TTOC(DATETIME())+"', "+;
   "'"+TTOC(DATETIME())+"', "+;
   "'"+goApp.CurrentUser.ntlogin+"', "+;
   "'"+goApp.CurrentUser.ntlogin+"', 0, 1, 0)"
   loGen.sqlexecute(lcSQLLine)
   llIncoming=.T.
   lcSQLLine="exec dbo.GetCovLet '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_Tag))+"'"
   loGen.sqlexecute(lcSQLLine, "viewCovLet")
   WAIT CLEAR
ELSE
   *
   *  If cover letter header record exists, update deponent name to
   *  match the most recent value.
   *
   IF ALLTRIM(UPPER(pc_descrpt))!=ALLTRIM(UPPER(viewCovLet.descript)) OR ;
      EMPTY(ALLTRIM(NVL(viewCovLet.descript,"")))
      lcSQLLine="update tblCovLet set descript='"+fixquote(pc_descrpt)+;
      "', edited='"+TTOC(DATETIME())+"', editedBy='"+goApp.CurrentUser.ntlogin+"' "+;
      "where cl_code='"+pc_clcode+"' and tag='"+ALLTRIM(STR(pn_tag))+"' and active=1"
      loGen.sqlexecute(lcSQLLine)
      IF !EMPTY(convrtDate(pd_closing))
	      WAIT WINDOW "Note: Case is being automatically re-opended." NOWAIT NOCLEAR 
    	  DO gfReOpen WITH .T., "Editing the cover letter data for tag "+ALLTRIM(STR(pn_Tag))
    	  WAIT CLEAR 
      ENDIF 
   ENDIF    
ENDIF 
*/ also send BB NonGeneral cases to the bbcover letter
*IF NOT pl_BBAsb
IF NOT (pl_BBAsb OR pl_NonGBB)  
   createCovLet(llIncoming, lcComms, lCAutoCmd, ll1stDocs)
ELSE
   createBBCovLet(llIncoming, lcComms, lCAutoCmd, ll1stDocs)   
ENDIF 
IF lloGen=.T.
   RELEASE loGen
ENDIF 
RETURN

**********************************************************************
PROCEDURE createCovLet
PARAMETERS llIncoming, lcComms, lcAutoCmd, ll1stDocs
   *
   *    General cover letter/admission handling for cases that are not
   *    Berry & Berry asbestos
   *
   *
   * Examine any existing admissions to see if this record
   * was previously reported via old- or new-style cover letter.
   * If no previous admissions for the record, determine the letter
   * style based on l_newcover flag.
   *
   
LOCAL lnCurArea, lcSQLLine, ll_newcovlet, lloGen, openform
lnCurArea=SELECT()

IF TYPE("oGen")!="O"
   loGen=CREATEOBJECT("transactions.medrequest")
   lloGen=.T.
ENDIF

**10/01/18 SL #109598
*lcSQLLine="select * from tblAdmissn with (INDEX(ix_tblAdmissn_1)) where cl_code='"+
lcSQLLine="select * from tblAdmissn where cl_code='"+;
ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_Tag))+"' and active=1"+;
" order by created"
loGen.sqlexecute(lcSQLLine, "viewAdmissn")
SELECT viewAdmissn 
IF RECCOUNT()>0
   llNewCover=!EMPTY(viewAdmissn.AdmType)
ELSE
   llNewCover=pl_cvrtest
ENDIF 
IF llIncoming AND !llNewCover AND !EMPTY(ALLTRIM(lcComms))
	  *
      *  Create an initial admission for a newly-received record,
      *  using the login comments as the admission text
      *
      *  Not needed once new cover letter is in operation
      *  since initial record categories will be entered in
      *  the incoming.prg routine.      
      *
    lnCountAdm=viewCovLet.CountAdm+1
    lcSQLLine="insert into tblAdmissn "+;
    "(cl_code, tag, admNumber, admission, created, createdby, "+;
    "AdmCode, AdmType, active, retire)"+;
    " values("+;
    "'"+pc_clcode+"', "+;
    "'"+ALLTRIM(STR(pn_tag))+"', "+;
    "'"+ALLTRIM(STR(lnCountAdm))+"', "+;
    "'"+fixquote(lcComms)+"', "+;
    "'"+TTOC(DATETIME())+"', "+;
    "'"+goApp.CurrentUser.ntlogin+"',' ', ' ',1, 0)"
    loGen.sqlexecute(lcSQLLine)
    IF !EMPTY(convrtDate(pd_closing))
       WAIT WINDOW "Note: Case is being automatically re-opened." NOWAIT NOCLEAR 
       DO gfReOpen WITH .T., "Editing the cover letter data for tag " + ;
               + ALLT( STR( pn_Tag)) + "."
       WAIT CLEAR
    ENDIF 
ENDIF
   
lcSQLLine="exec dbo.CountAdmissnCodes '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_Tag))+"'"
loGen.sqlexecute(lcSQLLine, "viewAdmCounts")      
SELECT viewAdmCounts
IF RECCOUNT()>0
   IF viewAdmCounts.totalCounts!=viewCovLet.countAdm     
      lcSQLLine="update tblCovLet set countAdm='"+;
      ALLTRIM(STR(viewAdmCounts.totalCounts))+"', "+;
      "edited='"+TTOC(DATETIME())+"', editedBy='"+goApp.CurrentUser.ntlogin+"' "+;
      " where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+ALLTRIM(STR(pn_Tag))+"'"+;
      " and active=1"
	  loGen.sqlexecute(lcSQLLine)   
	  IF !EMPTY(convrtDate(pd_closing))
          WAIT WINDOW "Note: Case is being automatically re-opened." NOWAIT NOCLEAR 
          DO gfReOpen WITH .T., "Editing the cover letter data for tag " + ;
               + ALLT( STR( pn_Tag)) + "."
          WAIT CLEAR     
      ENDIF 
   ENDIF    
ENDIF 
   
DO CASE 
   CASE EMPTY(ALLTRIM(lcAutoCmd)) AND llNewCover=.T.
        lcSQLLine="exec dbo.GetSpecInsbyClCodeTag '"+ALLTRIM(pc_clcode)+"', '"+ALLTRIM(STR(pn_Tag))+"'"
		loGen.sqlexecute(lcSQLLine, "viewSpecIns")      
		SELECT viewSpecIns
		IF RECCOUNT()>0
		   IF !EMPTY(ALLTRIM(viewSpecIns.spec_inst))
		       llGotBlurb=.T.
		   ENDIF 
		ENDIF 
		WAIT CLEAR 
		openform=createobject("TRANSACTIONS.frmNewCover",ll1stDocs,lSoftcopycall)
		openform.show
		RELEASE openform
		USE in viewSpecIns
   CASE EMPTY(ALLTRIM(lcAutoCmd)) AND llNewCover=.F.
        openform=createobject("TRANSACTIONS.frmCovLet",ll1stDocs,lSoftcopycall)
		openform.show
		RELEASE openform
   CASE ALLTRIM(UPPER(lcAutoCmd))="P"
        DO printcov with llNewCover, .T., ll1stDocs
ENDCASE    

IF USED('viewCovLet')
	USE IN viewCovLet
ENDIF
IF USED('viewAdmissn')
	USE in viewAdmissn
ENDIF
IF USED('viewAdmCounts')
	USE in viewAdmCounts
ENDIF

IF lloGen=.T.
   RELEASE loGen
ENDIF 

SELECT (lnCurArea)
openform=.null.
RETURN
********************************************************************* 
PROCEDURE createBBCovLet
PARAMETERS llIncoming, lcComms, lcAutoCmd, ll1stDocs
   *
   *  Cover letter/admissions screen for Berry & Berry Asbestos cases   
   *  For a new record, preset c_BBType; otherwise, copy from Record 
   *
   
LOCAL lnCurArea, lcSQLLine, lloGen,openform
lnCurArea=SELECT()
IF TYPE("oGen")!="O"
   loGen=CREATEOBJECT("transactions.medrequest")
   lloGen=.T.
ENDIF
IF !EMPTY(convrtDate(pd_closing))
   WAIT WINDOW "Note: Case is being automatically re-opened." NOWAIT NOCLEAR 
   DO gfReOpen WITH .T., "Editing the cover letter data for tag " + ;
   + ALLT( STR( pn_Tag)) + "."
   WAIT CLEAR
ENDIF 

lcSQLLine="update tblCovLet set lastAccess='"+TTOC(DATETIME())+"', AccessBy='"+;
goApp.CurrentUser.ntlogin+"', "+;
"edited='"+TTOC(DATETIME())+"', editedBy='"+goApp.CurrentUser.ntlogin+"' "+;
"where cl_code='"+pc_clcode+"' and tag='"+ALLTRIM(STR(pn_Tag))+"' and active=1"
loGen.sqlexecute(lcSQLLine)

openform=createobject("TRANSACTIONS.frmBBCovLet",ll1stDocs,lSoftcopycall)
openform.show
RELEASE openform
openform=.null.
USE IN viewCovLet
IF lloGen=.T.
   RELEASE loGen
ENDIF 
SELECT(lnCurArea)
RETURN
