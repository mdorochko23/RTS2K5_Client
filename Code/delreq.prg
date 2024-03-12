****************************************************************************
*** Delreq.prg - Delete a record and all associated transactions
***                      OR
***             Restore a passed tag and all associated transactions
*** undel - logical - Undelete tag ?  ( when .f., deletes txn's)
***************************************************************************
PROCEDURE DELREQ
PARAMETERS mcl, mtag, undel
LOCAL lnCurArea, lcSQLLine, nrec
lnCurArea=SELECT()
oTrans=CREATEOBJECT("Transactions.medrequest")

c_sql="exec dbo.getrequestbylrsno "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(mtag))
nr=oTrans.sqlexecute(c_sql,'request')

IF request.first_look=.T.
	lcSQLLine="select * from chon_rtfl..tbldocuments with (nolock) where ntag="+ALLTRIM(STR(mtag))+" AND "+;
		"npatientid=(select npatientid from chon_rtfl..tblpatients with (nolock) WHERE smrn="+ALLTRIM(STR(pn_lrsno))+")"
ELSE
	lcSQLLine="select * from chon_rts..tbldocuments with (nolock) where ntag="+ALLTRIM(STR(mtag))+" AND "+;
		"npatientid=(select npatientid from chon_rts..tblpatients with (nolock) WHERE smrn="+ALLTRIM(STR(pn_lrsno))+")"
ENDIF
oTrans.sqlexecute(lcSQLLine,'viewimage')
IF USED('request')
	USE IN request
ENDIF 
nrec=RECCOUNT('viewimage')
IF USED('viewimage')
	USE IN viewimage
ENDIF 
IF nrec>0
	gfmessage("Access to this option denied - Scanned images exist")
	RETURN
ENDIF

IF undel
   IF NOT pl_Admin
      *      IF !gfAccess( pc_UserID, "Admin")
      oTrans.bringmessage("This function is only allowed for Administrators!",2) 
      RELEASE oTrans          
      SELECT (lnCurArea)
      RETURN
   ENDIF       
ELSE 
   IF NOT pl_UnitMgr
      *      IF !gfAccess( pc_UserID, "UnitMgr")
      oTrans.bringmessage("This function is only allowed for Unit Managers!",2)           
      RELEASE oTrans 
      SELECT (lnCurArea)
      RETURN
   ENDIF    
   oTrans.bringmessage("You must provide a memo when deleting a tag.", 2)   
ENDIF
 
IF !EMPTY(convrtDate(pd_closing))
   DO gfReopen WITH .F., "Deleting or recalling a tag "
ENDIF

IF oTrans.bringmessage("Are you absolutely sure?",1)=.F.
   RELEASE oTrans 
   SELECT (lnCurArea)
   RETURN
ENDIF

IF !EMPTY(convrtDate(pd_closing)) 
   WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR 
   DO gfReOpen WITH .T., "deleting or recalling a tag from the case."
   WAIT CLEAR 
ENDIF

IF undel=.F.
   IF NOT MemoTxn("S",.F.)
      RELEASE oTrans 
      SELECT (lnCurArea)
      RETURN
   ENDIF
ENDIF
IF NOT undel
   **************** Check entries for witness fee txn (7,13) **************************************
   WAIT WINDOW "Checking for Witness fees. Please wait" NOWAIT NOCLEAR 
   lcSQLLine="select * from tblTimeSheet with (nolock) where cl_code='"+;
   ALLTRIM(UPPER(mcl))+"' and tag='"+ALLTRIM(STR(mtag))+"' and deleted is null and txn_code in (7,13)"
   oTrans.sqlexecute(lcSQLLine,"viewWitFee")
   SELECT viewWitFee
   IF RECCOUNT()>0
      oTrans.bringmessage("A witness fee has been issued." + CHR(13) + ;
      "The tag cannot be deleted." + CHR(13),2)
      USE 
      RELEASE oTrans 
      SELECT (lnCurArea)
      RETURN
   ENDIF 
   USE   
   WAIT CLEAR     
   **************** Check entries for Nurse Review txn (48,49) **************************************
   WAIT WINDOW "Checking for Nurse Review Txns. Please wait" NOWAIT NOCLEAR 
   lcSQLLine="select * from tblTimeSheet with (nolock) where cl_code='"+;
   ALLTRIM(UPPER(mcl))+"' and tag='"+ALLTRIM(STR(mtag))+"' and deleted is null and txn_code in (48,49)"
   oTrans.sqlexecute(lcSQLLine,"viewNurseRev")
   SELECT viewNurseRev
   IF RECCOUNT()>0
      oTrans.bringmessage("A Nurse Review Txn has been issued." + CHR(13) + ;
      "The tag cannot be deleted." + CHR(13),2)
      USE 
      RELEASE oTrans 
      SELECT (lnCurArea)
      RETURN
   ENDIF 
   USE   
   WAIT CLEAR     
ENDIF

**************** Timesheet Entries **************************************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Timesheet Entries." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblTimeSheet"
**************** Cover Letters ************************************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Cover letters." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblCovLet"   
**************** Admissions/Record Categories *****************************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Admissions / Record Categories." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblAdmissn"   
**************** X-rays ************************************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   + "X-Rays." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblXRay"   
**************** Pathology Specimens ************************************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Pathology Specimens." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblPathol"   
**************** Photographs ************************************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Photos." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblPhoto"   
**************** Comments************************************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Comments and Memos." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblComment"   

**************** Notices **************************************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Notices." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, IIF(pl_ofcHous,"tblTXNotice", "tblPSNotice")
**************** Special Instructions *********************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Special Instructions." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblSpec_Ins" 
**************** Attorney orders from order.dbf *********************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Orders." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblOrder" 
*************** Request *********************************************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Request." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblRequest" 

**************** Code30 *********************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   + "Status to Counsel requests." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblCode30" 
**************** Code41 *********************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "NRS information." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblCode41" 
************ Holdreq.dbf **************************************
WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
   "Court Filing Letter." NOWAIT NOCLEAR 
DO doWork WITH undel, mcl, mtag, "tblHoldReq" 
************************* Texas Court Notices File ************
IF pl_ofcHous
   WAIT WINDOW IIF( undel, "Recalling ", "Deleting ")+"Court Notices." NOWAIT NOCLEAR 
   DO doWork WITH undel, mcl, mtag, "tblCrtNotic" 
ENDIF
********************** Subpoena file CA ***********************
IF pl_CAVer
   WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
      "Subpoenas." NOWAIT NOCLEAR 
   DO doWork WITH undel, mcl, mtag, "tblSubpoena" 
********************** Declarations ***************************
   WAIT WINDOW IIF( undel, "Recalling ", "Deleting ") + ;
      "Declarations." NOWAIT NOCLEAR 
   DO doWork WITH undel, mcl, mtag, "tblDecl" 
ENDIF

*--remove eservice jobs if there are any
c_sql="exec dbo.getrequestbylrsno "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(mtag))
nr=oTrans.sqlexecute(c_sql,'request')
IF UPPER(request.login_id)='ESERVE'
	c_sql="exec dbo.removeeservice "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(mtag))
	nr=oTrans.sqlexecute(c_sql)
ENDIF

**- remove a job from Phone queue

   WAIT WINDOW IIF( undel, "Recalling ", "Deleting ")+"Phone Queue Job." NOWAIT NOCLEAR 
  c_sql="exec dbo.removephonequeuejob "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(mtag)) +",'" + pc_UserID + "',"  + IIF(undel=.t., STR(1), STR(0) )
 nr=oTrans.sqlexecute(c_sql)


** 10/07/2010 EF- remove QC issue jobs

 WAIT WINDOW IIF( undel, "Recalling ", "Deleting ")+"QC Issue Queue Job." NOWAIT NOCLEAR 
  c_sql="exec dbo.removeqcissuejob "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(mtag)) +",'" + ALLTRIM(pc_UserID) + "',"  + IIF(undel=.t., STR(1), STR(0) )
 nr=oTrans.sqlexecute(c_sql)

** 10/07/2010 EF- remove QC issue jobs


** 03/07/2012 MD- remove STCQUEUE

 WAIT WINDOW IIF( undel, "Recalling ", "Deleting ")+"STC Queue Job." NOWAIT NOCLEAR 
  c_sql="exec dbo.removeSTCQueueJob "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(mtag)) +",'" + ALLTRIM(pc_UserID) + "',"  + IIF(undel=.t., STR(1), STR(0) )
 nr=oTrans.sqlexecute(c_sql)

** 03/07/2012 MD- remove STCQUEUE

** 03/18/2013 EF- remove RPS Job (if on hold): "HoldPrint" Project.
 WAIT WINDOW IIF( undel, "Recalling ", "Deleting ")+"RPS Hold Job." NOWAIT NOCLEAR 
 c_sql="exec dbo.removerpsjob "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(mtag)) +",'" + ALLTRIM(pc_UserID) + "',"  + IIF(undel=.t., STR(1), STR(0) )
 nr=oTrans.sqlexecute(c_sql)
** 03/18/2013 EF- remove RPS Job (if on hold)

** 04/09/2013 EF- remove not done job from the QC Similar Dep Serach : "Similar Deponent Search Automation Project" Project.
 WAIT WINDOW IIF( undel, "Recalling ", "Deleting ")+"Similar Deponent Search Queue ." NOWAIT NOCLEAR 
 c_sql="exec dbo.removesimsearchjob "+ALLTRIM(STR(pn_lrsno))+","+ALLTRIM(STR(mtag)) +",'" + ALLTRIM(pc_UserID) + "',"  + IIF(undel=.t., STR(1), STR(0) )
 nr=oTrans.sqlexecute(c_sql)
** 04/09/2013 EF-end


WAIT CLEAR 
RELEASE oTrans 
gfmessage(IIF(undel=.T.,"Recalling","Deleting")+" is completed.")
SELECT (lnCurArea)
RETURN

**************************************************

PROCEDURE DoWork
LPARAMETERS llRecall, lcClCode, lnTag, lcTable
* Replaces all "&delrec" in above routines
LOCAL lcAddTag, lcCond1, lcCond0
lcAddTag=""
IF ISNULL(lnTag)=.F.
   lcAddTag="and tag='"+ALLTRIM(STR(lnTag))+"' "
ENDIF    
lcCond1=" and active=1"
lcCond0=" and active=0"
IF ALLTRIM(UPPER(lcTable))=="TBLTIMESHEET"
   lcCond1=" and deleted is null"
   lcCond0=" and deleted is not null"
ENDIF    
IF llRecall=.F.
   lcSQLLine="update "+ALLTRIM(lcTable)+" set active=0, deleted='"+TTOC(DATETIME())+"', "+;
   "deletedBy='"+goApp.currentUser.NtLogin+"' where cl_code='"+ALLTRIM(lcClCode)+"' "+;
   lcAddTag+lcCond1   
ELSE 
   lcSQLLine="update "+ALLTRIM(lcTable)+" set active=1, deleted=null, deletedBy=null, "+;
   "edited='"+TTOC(DATETIME())+"', "+;
   "editedBy='"+goApp.currentUser.NtLogin+"' where cl_code='"+ALLTRIM(lcClCode)+"' "+;
   lcAddTag+lcCond0  
ENDIF 
oTrans.sqlexecute(lcSQLLine)            
RETURN
