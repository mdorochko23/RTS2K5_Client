****************************************************************************
** Depstat.prg - Deponent transaction edit/delete program
**
** Called by Plaintif (for Tag 0 or Case-level display)
** Called by DepOpts (for single-deponent display)
** Called by FLEdit [in FLProc] to allow display/edit of transactions
**           during first-look review processing.

** Calls DefCalc, View41, SetRec, RStatus
**
** Uses Screens EditWFee, EditEnt, EditComm, ServInfo
**
** Modifications:
** 04/27/05 EF   Fixed a bug for Texas checks [ctrl+c] option
** 04/14/05 IZ   Added report for printing Timesheet transactions (DEPSTAT.FRX)
** 07/07/04 DMA  Limit access to Ctrl-S Timesheet option to CA offices
** 04/27/04 dma  Display new-format RCA Number for timesheet display
** 04/20/04 kdl  Clear our 88 transaction dates fron the recspec table when
**                   deleting 88 transactions
** 02/23/04 EF   Add deletion of a Waiver
** 02/02/04 DMA  Add message when printer is unavailable
** 01/15/04 IZ   Do not allow edit Code30 comments when hitting <F3>,
**               now it should be done through <Ctrl-F3>
** 12/29/03 DMA  Add automatic reopening of a closed case if user makes
**               changes to any transaction data. Screens EditWFee and
**               EditEnt were changed for this operation.
** 11/27/03 DMA  Rename internal routines Cancl, DeletIt, etc.
**               to make them distinct from internals in other programs
** 09/25/03 kdl  Modified 88 transaction deletion process to update the
**    disttodo.dbf remove fields instead of deleting the record
** 09/18/03 EF   display driver's name and make it editable for AM
** 08/12/03 kdl  added first-look code for use in substituting
**  the hidden first-look entry and comment tables for the production
**  tables.  This process is done by a call to the flnalias procedure
**  in the flproc.prg.  The procedure opens either first-look or production
**  tables in appropriate work areas, using appropriate aliases based on the
**  passed parameters.
** 10/01/03 kdl Block deletion of 1 and 88 transactions of
**              released 1st look records.
*  09/25/03 kdl Update remove fields in disttodo.dbf instead of delete record
*               when deleting a first-look 88 transaction
** 07/17/03 IZ  Added a call for "Required Memo" procedure.
**              Parameter "R" - tag level memo for the deleted transactions
** 03/20/03 EF  Reset Pickup flag
** 02/25/03 kdl Reset defa color of scheme 1 for edit screens
** 10/15/02 DMA Correct bug when NRS transaction is being deleted
** 09/25/02 kdl Adjust brows headings to accomodate service centers when linked to deponent
** 09/24/02 DMA EditWFee, EditEnt screens changed to handle unknown SSNs
** 09/20/02 DMA Remove combined Received/NRS change per Liz D
** 08/30/02 DMA Add handling for combined Received/NRS records in SetArr
** 08/20/02 DMA EditWFee screen changed to permit negative amounts
**              up to -$9999.99
** 08/06/02 DMA Fix witness fee type editing bug
** 07/11/02 DMA Add exit w/o save option to Ctrl-S screen
** 06/21/02 DMA Switch access control to public variables
** 06/19/02 DMA Replace mlogname with pc_UserID
** 06/18/02 DMA Block editing of issue date in 11 transactions
** 06/05/02 DMA Fill in EditedBy field in comment/entry when editing.
**              When an NRS comment is edited, update Code41.Reason to match.
**              Prevent deletion of an NRS comment; must delete full Txn.
**              Updated screens EditEnt, EditComm
** 05/30/02 DMA Ensure all hot-keys are restored when exiting CACtrl_S
** 05/23/02 kdl Corrected bug with record table pointer positioning
** 05/08/02 KDL Added error trap to make sure record.dbf is open and record pointer
**          is properly positioned prior to calling rstatus
** 05/03/02 DMA Add <F8> print capability (for timesheets only)
** 02/25/02 DMA Replace internal display code with ServInfo screen
** 01/31/02 DMA Update Record status info when a transaction is edited
** 01/24/02 DMA Replace variable choice with n_whichdep
** 01/21/02 DMA Block modifications to Record.dbf unless lnTagLevel = 3
** 01/21/02 DMA Add ability to edit witness fee type
** 01/08/02 DMA Update CovLet when admission categories are deleted
** 12/04/01 DMA Delete of 1 txn now removes NRS info; clean up Ctrl-S code
** 10/30/01 DMA Delete new-style admission categories when associated
**              1, 41, or 53 transaction is deleted.
** 10/29/01 HN  Use UserCtrl table for DelFunc, UnitMgr access
**              (Part of Access Control Changes)
** 10/24/01 DMA When 1/21 Txn is deleted, update record review status
** 09/12/01 EF  3-char. litigation code
** 08/02/01 DMA Add memo width control for display of comments.
** 04/26/01 DMA Clean up use of RLOCK function
** 03/23/01 DMA For Case-level display of all tags, use date/tag order
**              For Tag 0 or tag-level display, use tag/date order
** 03/20/01 DMA Don't display blank lines in Comment.Comment,
**              match comment to precise id.
** 01/29/01 DMA When a 53 (Incomplete Records) transaction is deleted,
**              update the inc and qual fields in the record file.
** 01/02/01 DMA To handle situation where files were manually
**              repaired, pre-sort transaction list by tag,
**              transaction date, transaction ID, and line #.
**              Widened display of subpoena/autho. instructions
** 08/24/00 DMA Expand check number to 7 digits
** 08/15/00 DMA Eliminate separate MD checks file for office merger
** 11/30/99 DMA Don't display DP any more. Don't show tag when
**              displaying a single deponent's entries.
**              Change window title for single-deponent display
**              Add column titles to check-browse window
** 08/20/99 DMA Change date fields to 4-digit years for Y2K
** 02/12/98 HN  Add lnTagLevel
** 10/01/97 Mark Rizzo - PROCEDURE EDIT_TXN:
**    add condition to update description in RECORD.DBF when
**    description changed for 11 transaction
**
**
*   lnTagLevel = 1
*      Displays only Tag 0 items for entire case
*   lnTagLevel = 2
*      Displays all transactions for entire case
*   lnTagLevel = 3
*      Displays chronological list of transactions for one deponent
*
**************************************************************************
PROCEDURE DepStat
*--8/12/03 kdl start: added new parameter
PARAMETERS lnTagLevel, l_1stlook
IF PARAMETERS() < 2
   l_1stlook = .F.
ENDIF
*--8/11/03 kdl end:

PRIVATE n_memowid, subreccnt, n_wftype, llrecused, lsCurArea, lnRecNum
n_wftype = 1
subreccnt = 0
SET INTENSITY ON
n_memowid = SET("MEMOWIDTH")
IF TYPE("gnFrDays") = "U"
   PUBLIC gnFRDays
ENDIF
gnFRDays = gfFRDays(tamaster.litigation)        && From Review Days in Lit

IF TYPE("gnIssDays") = "U"
   PUBLIC gnIssDays
ENDIF
gnIssDays = gfIssDay(tamaster.litigation)       && Issue Days in Lit

CLEAR
WAIT WINDOW "Loading Transaction History." + CHR(13) + "Please wait." NOWAIT NOCLEAR 
IF WEXIST( "w_pickdep")
   HIDE WINDOW w_pickdep
ENDIF
IF WEXIST( "w_depopts")
   HIDE WINDOW w_depopts
ENDIF

ACTIVATE SCREEN

wstr = SPACE(90)
wstr = STUFF(wstr, 1, 4, "Date")
wstr = STUFF(wstr, 12, 4, "Code")
wstr = STUFF(wstr, 22, 14, "Work Completed")
wstr = STUFF(wstr, 68, 3, "Mts")
IF lnTagLevel <> 3
   wstr = STUFF(wstr, 72, 3, "Tag")
ENDIF
IF pl_CAVer
* 04/27/04 DMA Use new-format RCA number and proper indenting
   wstr = STUFF(wstr, IIF( lnTagLevel <> 3, 76, 72), 5, "RCA #")
ENDIF

head = wstr

******************************
commused = gfuse("comment")
*--8/11/03 kdl start: substitute first-look comment table
*-- if editing first-look disposition transactions
IF l_1stlook
   DO flnalias WITH "COMM", "FL"
ENDIF
*--8/11/03 kdl end

DO defkeys
DO makebrow                                     && Get all entries for edit/delete
DO topbox
DO botbox
DO browit
DO relkeys

*--8/11/03 kdl start:
IF l_1stlook
   DO flnalias WITH "COMM", "PR"
ENDIF
*--8/11/03 kdl end:

= gfunuse("comment",commused)
SET MEMOWIDTH TO n_memowid
WAIT CLEAR 
RETURN
*******************************************************
PROCEDURE TS_Cancl

*** Cancel out
RELEASE WINDOW w_browwin
DO CASE
   CASE lnTagLevel = 1
      RELEASE WINDOW " Tag 0 Items for Case "
   CASE lnTagLevel = 2
      RELEASE WINDOW " All Transactions for Case "
   CASE lnTagLevel = 3
      *--8/13/03 kdl start: add first-look window
      IF l_1stlook
         RELEASE WINDOW " First-Look Review Transactions for this Deponent "
      ELSE
         RELEASE WINDOW " Chronological List of Transactions for this Deponent "
      ENDIF
      *--KDL OUT 8/13/03: RELEASE WINDOW " Chronological List of Transactions for this Deponent "
      *--8/13/03 kdl end:
ENDCASE
IF WEXIST( "new4scr")
   SHOW WINDOW new4scr
ENDIF
IF WEXIST( "w_depopts")
   SHOW WINDOW w_depopts
ENDIF

SHOW GETS
DO ColorDef
CLEAR
RETURN
****************************************************
PROCEDURE TopBox
CLEAR
** Draw box on top of screen and show case/deponent info

@ 0,0 TO 3,79 DOUBLE
@ 1,2 SAY "RT #: " COLOR GR+/B
@ 1,8 SAY pn_lrsno PICT "@B" COLOR R+/B
@ 1,16 SAY "Plaintiff: " COLOR GR+/B
* 04/16/04 DMA Update for long plaintiff name
@ 1,27 SAY pc_plnam COLOR R+/B
*@ 1,26 SAY pc_plnam + " [" + alltrim( pc_clcode) + "]" COLOR R+/B
IF lnTagLevel = 3
   @ 2,2 SAY "Tag: " COLOR GR+/B
   @ 2,7 SAY pn_Tag PICT "@B" COLOR R+/B
   @ 2,14 SAY pc_Descrpt COLOR R+/B
ELSE
   pn_Tag = 0
ENDIF
RETURN
****************************************************
PROCEDURE BotBox

** Draw the bottom box

@ 21,0 TO 24,79 DOUBLE
DO CASE
   CASE lnTagLevel = 1
      @ 22,1 SAY "<F3> Edit     <F5> Top   <F8>  Add Memo" + ;
         "                                 " COLOR GR+/B
      @ 23,1 SAY "<F4> Delete   <F6> End   <F10> Exit     " + ;
         "                                " COLOR GR+/B
   CASE lnTagLevel = 2
      @ 22,1 SAY "<F5> Top      <F8>  Add Memo            " + ;
         "                                " COLOR GR+/B
      @ 23,1 SAY "<F6> End      <F10> Exit                " + ;
         "                                " COLOR GR+/B
   CASE lnTagLevel = 3
      *--8/12/03 kdl start: change options for first-look entries edit
      IF l_1stlook
         @ 22,1 SAY " <F3> Edit    <F5> Top  <F8> Print  <F10> Exit" COLOR GR+/B
         @ 23,1 SAY " <F4> Delete  <F6> End  <Ctrl+F4> Code 41" COLOR GR+/B
      ELSE
         @ 22,1 SAY " <F3> Edit  <F5> Top <Ctrl+F3> Code 30 " + ;
            "<Ctrl+R> Rolo. <F8> Print <F10> Exit" COLOR GR+/B
         * 07/07/04 DMA Ctrl-S option for CA offices only
         IF pl_CAVer
            @ 23,1 SAY " <F4> Delete <F6> End <Ctrl+F4> Code 41  " + ;
               "<Ctrl+C> Checks <Ctrl+S> Notice Info" COLOR GR+/B
         ELSE
            @ 23,1 SAY " <F4> Delete <F6> End <Ctrl+F4> Code 41  " + ;
               "<Ctrl+C> Checks                     " COLOR GR+/B
         ENDIF
      ENDIF
ENDCASE
RETURN
****************************************************
PROCEDURE Browit
** Browse the txn information

PRIVATE lcTitle

@ 3,0 TO 21,79 DOUBLE
@ 3,0 SAY "Ì"
@ 3,79 SAY "¹"
DO CASE
   CASE lnTagLevel = 1
      lcTitle = " Tag 0 Items for Case "
   CASE lnTagLevel = 2
      lcTitle = " All Transactions for Case "
   CASE lnTagLevel = 3
      *--8/1/03 kdl start:
      IF l_1stlook
         lcTitle = " First-Look Review Transactions for this Deponent "
      ELSE
         lcTitle = " Chronological List of Transactions for this Deponent "
      ENDIF
      *--kdl out 8/11/03: lcTitle = " Chronological List of Transactions for this Deponent "
      *--8/11/03 kdl end:
ENDCASE

DEFINE WINDOW w_browwin FROM 3,0 TO 21,79 ;
   TITLE lcTitle NOZOOM NOMINIMIZE NOGROW NOCLOSE NOFLOAT COLOR SCHEME 1
@ 21,0 SAY "Ì"
@ 21,79 SAY "¹"

ACTIVATE WINDOW w_browwin
DO Color1
WAIT CLEAR
CLEAR TYPEAHEAD
DO SetKey WITH "DEPSTAT"
SELECT MTrans
GO TOP
BROW FIELDS Main :R :H=head NOAPPEND NOEDIT NODELETE IN WINDOW w_browwin ;
   COLOR SCHEME 1
DO ColorDef
RETURN
****************************************************
PROCEDURE DefKeys
*** Define function keys used on screen
PUSH KEY CLEAR
DO DefCalc
RETURN
****************************************************************
PROCEDURE f5key
SELECT MTrans
GO TOP
RETURN
****************************************************************
PROCEDURE f6key
SELECT MTrans
GO BOTTOM
RETURN
****************************************************
PROCEDURE RelKeys
POP KEY ALL
RETURN
*****************************************************
PROCEDURE MakeBrow
** Creates the temporary browse file with all entries

PRIVATE dbTemp, nTxn_ID, lFound, nTxn_Code, n44Count, haveit, specused, ;
   n_memline

IF lnTagLevel = 3
   MDes = pc_Descrpt
   mTag = pn_Tag
   MID  = pc_MailID
ENDIF
IF lnTagLevel = 1
   pn_Tag = 0
ENDIF

SELECT Comment
SET ORDER TO ClTag

specused = gfuse("spec_ins")

SELECT F
szPath = IIF( NOT EMPTY(SYS(2023)), SYS(2023), (f_tmpfile))
szFile = "\mtrans.dbf"
szPFile = szPath + szFile
CREATE CURSOR MTrans (main C(90), recnum N(10), reccomm N(10), delent L, ;
   TagNo N(4), TranDate D, TransID N(10), TranCode N(3), SubRecNo N(3))
SELECT MTrans
IF lnTagLevel = 2
   INDEX ON DTOS(Trandate) + STR( TagNo, 4) + ;
      STR( TransID, 10) + STR( SubRecNo, 3) ;
      TAG Chrono
ELSE
   INDEX ON STR( TagNo, 4) + DTOS( Trandate) + ;
      STR( TransID, 10) + STR( SubRecNo, 3) ;
      TAG Chrono
ENDIF
** reccomm = Record number of comment entry.
** Subrecno = Subsidiary record counter

n44Count = 0

SELECT f
cmdstr = ""
DO CASE
   CASE lnTagLevel = 1
      SET ORDER TO ClTag
      SEEK pc_clcode + "*" + STR(0)
      cmdstr = "f.Cl_code + '*' + STR(f.Tag) = pc_clcode + '*' + STR(0)"

   CASE lnTagLevel = 2
      SET ORDER TO Cl_Code
      SEEK pc_clcode
      cmdstr = "f.Cl_code = pc_clcode"

   CASE lnTagLevel = 3
      SET ORDER TO ClTag
      SEEK pc_clcode + "*" + STR(mTag)
      cmdstr = "f.Cl_code + '*' + STR(f.Tag) = pc_Depokey"
ENDCASE

IF FOUND()
   SCAN WHILE &cmdstr
      wstr = SPACE(90)
      mwit_fee = wit_fee
      mcount = count
      DO setarr WITH wstr
      SubRecCnt = 0
      DO addmtran with wstr, RECNO("f"), 0, f.tag, f.txn_date, ;
         f.txn_id, f.txn_code

      haveit = .f.
      SELECT Comment
      IF SEEK ( pc_clcode + STR(f.tag) + STR(f.txn_id))
         SCAN WHILE Comment.cl_Code = pc_clcode AND ;
               Comment.Tag = F.Tag AND ;
               Comment.Txn_ID = F.Txn_ID
            IF LEN(ALLTRIM(Comment.comment)) > 0
               SET MEMOWIDTH TO 62
               FOR n_memline = 1 TO MEMLINES(Comment.comment)
                  DO addmtran WITH ;
                     SPACE(5) + MLINE( Comment.comment, n_memline), ;
                     0, RECNO( "comment"), f.tag, f.txn_date, ;
                     f.txn_id, f.txn_code
               ENDFOR
               SET MEMOWIDTH TO n_memowid
            ENDIF
         ENDSCAN
      ENDIF

      IF lnTagLevel = 3
         */ Display Special instructions for 11 (issue) & 44 (re-issue)
         SELECT f
         IF INLIST( txn_code, 11, 44)
            nTxn_ID = txn_id
            nTxn_code = txn_code
            IF nTxn_Code == 44
               n44Count = n44Count + 1
            ENDIF
            lFound = .F.
            dbTemp = ALIAS()
            SELECT Spec_Ins
            SET ORDER TO Txn_ID
            */ look for transaction ID
            If ! EMPTY( nTxn_ID) AND SEEK( str( nTxn_ID))
               IF cl_code = pc_clcode AND tag = pn_tag
                  lFound = .T.
               ENDIF
            ENDIF
            IF NOT lFound
               */ pre-txnID deponents
               SET ORDER TO ClTag
               */ look for deponent
               IF SEEK( pc_clcode + "*" + ALLTRIM(STR(pn_tag)))
                  IF nTxn_Code = 11
                     lFound = .T.
                  ELSE
                     */ search for n'th instance of deponent
                     SKIP n44Count
                     IF (cl_Code = pc_clcode) AND (tag = pn_tag)
                        lFound = .T.
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF
            */ skip for empty instructions
            IF lFound
               lFound = .F.
               FOR nLoop = 1 TO MEMLINES( Spec_Ins.spec_inst)
                  IF NOT EMPTY( ALLTRIM( MLINE( Spec_Ins.spec_inst, nLoop)))
                     lFound = .T.
                     EXIT
                  ENDIF
               ENDFOR
            ENDIF
            */ add instructions with box
            IF lFound
               SET MEMOWIDTH TO 68
               DO AddMtran WITH ;
                  " ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Instructions " + ;
                  "ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿", 0, 0, ;
                  f.tag, f.txn_date, f.txn_id, f.txn_code
               FOR nLoop = 1 to MEMLINES( Spec_Ins.spec_inst)
                  */ skip for blank line
                  IF NOT EMPTY( ALLTRIM( MLINE( Spec_Ins.spec_inst, nLoop)))
                     x = PADR(" ³ " + ;
                        ALLTRIM( MLINE( Spec_Ins.spec_inst, nLoop)), ;
                        72, " ") + " ³"
                     DO AddMtran WITH x, 0, 0, ;
                        f.tag, f.txn_date, f.txn_id, f.txn_code
                  ENDIF
               ENDFOR
               DO AddMtran WITH " ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ" + ;
                  "ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ", 0, 0, ;
                  f.tag, f.txn_date, f.txn_id, f.txn_code
               SET MEMOWIDTH TO n_memowid
            ENDIF
         ENDIF
         */ ----------------- End special instructions section
      ENDIF                                     && lnTagLevel = 3
      SELECT F
   ENDSCAN
   DO addmtran WITH PADC(" End of Timesheet Transactions ",76,"_"), 0, 0, ;
      9999, {  /  /    }, 0, 0
ELSE
   DO AddMTran WITH PADC(" No Timesheet Transactions Found ", 76, "_"), 0, 0, ;
      9999, {  /  /    }, 0, 0
ENDIF

*--8/12/03 kdl start:  call procedure to add 88 and 53 transactions
IF l_1stlook
   DO flgetpr IN flproc
ENDIF

SELECT F
SET ORDER TO Cl_Code
= gfunuse("spec_ins", specused)
RETURN
****************************************************************
PROCEDURE ChkBrow
PRIVATE fileused, mcl, mtag, chkcnt
FileUsed=.f.
IF lnTagLevel <> 3
RETURN
ENDIF
DO SetKey WITH "CHECKS"

mcl = record.cl_code
mtag = record.tag

WAIT WINDOW "Looking up check information. Please wait." NOWAIT NOCLEAR 

if pl_OfcHous 
 use(F_CHECKTX) alias checks in 0
else
 FileUsed = gfUse("Checks") 
endif

SELECT * FROM Checks INTO CURSOR chktemp ;
   WHERE Cl_Code + "*" + STR(Tag) = pc_depokey ;
   ORDER BY Tag, Check_Date
chkcnt = _TALLY

=gfunuse("checks", fileused)

WAIT CLEAR

IF chkcnt > 0
   SELECT chktemp
   DEFINE WINDOW w_ChkBrow FROM 1,0 TO 12,79 ;
      TITLE " Checks (Press <F7> or <F10> to exit) ";
      PANEL CLOSE GROW COLOR SCHEME 10

   *--9/25/02 kdl start: change headings to payee and add descrip field to accomodate
   *-- service center payments
   BROWSE WINDOW w_ChkBrow;
      FIELDS Check_No :H="Check #", Check_Amt :H=" Amount " :P="$$$$,$$$.99", ;
      Check_Date :H="Issued On", ;
      ClearInfo = IIF( NOT Cleared, "  No", DTOC(Clear_Date)) :H=" Cleared", ;
      VoidInfo  = IIF( NOT Void, "  No", DTOC(Void_Date)) :H="  Voided", ;
      Deponent :H="Payee Name", Add1 :H="Payee Address 1", ;
      Add2 :H="Payee Address 2", ;
      PrePaid = IIF( PrePay, "Yes", "No") :H="Pre-payment", ;
      Invoice_No :H="   Invoice #", Attention :H="Sent to Attn. of", ;
      CreatedBy :12 :H=" Created By", EditedBy :12 :H="  Edited By" ;
      NOAPPEND NOEDIT NODELETE  WIDTH 79

   *--kdl out 9/25:   BROWSE WINDOW w_ChkBrow;
      FIELDS Check_No :H="Check #", Check_Amt :H=" Amount " :P="$$$$,$$$.99", ;
      Check_Date :H="Issued On", ;
      ClearInfo = IIF( NOT Cleared, "  No", DTOC(Clear_Date)) :H=" Cleared", ;
      VoidInfo  = IIF( NOT Void, "  No", DTOC(Void_Date)) :H="  Voided", ;
      Deponent :H="Deponent Name", Add1 :H="Deponent Address 1", ;
      Add2 :H="Deponent Address 2", ;
      PrePaid = IIF( PrePay, "Yes", "No") :H="Pre-payment", ;
      Invoice_No :H="   Invoice #", Attention :H="Sent to Attn. of", ;
      CreatedBy :12 :H=" Created By", EditedBy :12 :H="  Edited By" ;
      NOAPPEND NOEDIT NODELETE  WIDTH 79
   *--9/25/02 kdl end:

   RELEASE WINDOW w_ChkBrow

ELSE
   gfmessage("There are no checks for this tag.")
ENDIF

=gfclose("chktemp")
DO SetKey WITH "DEPSTAT"
RETURN

****************************************************************
PROCEDURE a_changeD
**do ChangeDate

****************************************************************
PROCEDURE a_code41
**do code41vw

*****************************************************
PROCEDURE AddMtran
* Updated 6/5/2002 DMA to add transaction code for control
*                      of edit/deletion of critical comments
*
*  Updated 1/2/2001 DMA to add tag, transaction date, ID, and
* line number for more accurate sorting of transactions

PARAMETERS thestr, recE, recC, recTag, recD, recID, recXCode

** Add the Entry/Comment/Spec. Inst. string to file
** and add the record number of the source file
** (for editing or deleting later)
PRIVATE c_currfile
c_currfile = ""
IF EMPTY( thestr)
RETURN
ENDIF
c_currfile = ALIAS()
SubRecCnt = SubRecCnt + 1
INSERT INTO mtrans (Main, RecNum, RecComm, TagNo, ;
   TranDate, TransID, TranCode, SubRecNo) ;
   VALUES( thestr, recE, recC, ;
   recTag, recD, recID, recXCode, SubRecCnt)
IF NOT EMPTY( c_currfile)
   SELECT (c_currfile)
ENDIF

RETURN
*****************************************************
PROCEDURE Edit_Txn
* 06/05/2002  DMA  Fill in EditedBy field in Comment and Entry files
PRIVATE tagswitch, c_order, c41used

tagswitch = .F.
c_order = ""
IF Mtrans.recnum = 0 AND Mtrans.reccomm = 0
RETURN
ENDIF

*--8/12/03 kdl start: call first-look change alias procedure
IF l_1stlook AND NOT (pl_Unitmgr)
   = gfmsg("Unit manager access rights required for this feature.")
RETURN
ENDIF
IF l_1stlook AND INLIST(mtrans.TranCode, 88, 53)
   DO flnalias WITH "ENTRY", "PR"
   DO flnalias WITH "COMM", "PR"
ENDIF
*--8/12/03 kdl end:

DO SetKey WITH "EDIT_TXN"
*--2/25/03 kdl start: reset defa color of scheme 1 for edit screens
DO colordef
*--2/25/03 kdl end:
DO CASE
   CASE NOT EMPTY(mtrans.recnum)                && Edit the actual entry
      SELECT F
      c_order = ORDER()
      GO mtrans.recnum
      SCATTER MEMVAR
      IF F.txn_code = 7
         IF NOT pl_UnitMgr
            gfmessage("This action is only allowed for Unit Managers." )
            DO SetKey WITH "DEPSTAT"
            RETURN
         ENDIF
      ENDIF
      * DMA 12/29/03 Issue re-opening warning for a closed case.
      IF NOT EMPTY( convrtDate(pd_closing))
         DO gfReopen WITH .F., "Editing transaction information"
      ENDIF
      okcan = 1
      IF F.Txn_Code = 7
         * Edit a witness fee transaction
         DO CASE
            CASE F.Type = "M"
               n_wftype = 1
            CASE F.Type = "X"
               n_wftype = 2
            CASE F.Type = "Y"
               n_wftype = 3
         ENDCASE
         DO editwfee.spr
         DO CASE
            CASE n_wftype = 1
               m.Type = "M"
            CASE n_wftype = 2
               m.Type = "X"
            CASE n_wftype = 3
               m.Type = "Y"
         ENDCASE
      ELSE
         * Edit a standard transaction
         IF F.Txn_Code = 1
            DO CASE
               CASE F.O = "O"
                  n_recvtype = 1
               CASE F.O = "C"
                  n_recvtype = 2
               CASE F.O = "M"
                  n_recvtype = 3
               OTHERWISE
                  n_recvtype = 4
            ENDCASE
         ENDIF
         DO editent.spr
      ENDIF
      IF okcan = 1
         SELECT F
         GO mtrans.recnum
         IF m.Txn_Code = 1
            DO CASE
               CASE n_recvtype = 1
                  m.O = "O"
               CASE n_recvtype = 2
                  m.O = "C"
               CASE n_recvtype = 3
                  m.O = "M"
               OTHERWISE
                  m.O = " "
            ENDCASE
         ENDIF
         IF m.txn_code = 7 AND (m.tag <> F.tag)
            ** Tag switched by admin
            DO FixWFee WITH F.tag, m.tag, m.wit_fee, m.count
            tagswitch = .T.
         ENDIF
         IF lnTagLevel = 3
            nSelect = SELECT()
            SELECT Record

            */ update data in record.dbf and public variables when
            */ editing individual transaction requires global effects

            */ Date or description in 11 transaction was changed.
            */ 06/18/02 DMA Date editing blocked per Julie McCabe
            IF m.txn_code = 11
               IF m.cl_code == Record.cl_code AND m.tag = Record.tag
                  DO WHILE NOT RLOCK()
                  ENDDO
                  REPLACE descript WITH m.descript
                  *                  REPLACE req_date WITH m.txn_date
                  UNLOCK
                  pc_Descrpt = m.descript
                  *                  pd_ReqDate = m.txn_date
               ENDIF
            ENDIF

            IF m.txn_code = 1 AND (m.count <> F.count)
               ** Page Count changed.
               IF m.cl_code == Record.cl_code AND m.tag = Record.Tag
                  DO WHILE NOT RLOCK()
                  ENDDO
                  REPLACE pages WITH pages - F.count + m.count
                  UNLOCK
               ENDIF
            ENDIF

            IF INLIST( m.txn_code, 1, 41) AND ;
                  (m.txn_date <> F.txn_date)
               ** Record receipt or NRS date changed
               IF m.cl_code == Record.cl_code AND m.Tag = Record.Tag
                  DO WHILE NOT RLOCK()
                  ENDDO
                  REPLACE Fin_Date WITH m.Txn_Date
                  UNLOCK
               ENDIF
            ENDIF
            DO SetRec WITH n_whichdep, holddays, gnFRDays, gnIssDays
            SELECT (nSelect)
         ENDIF

         SELECT F
         SET ORDER TO c_order
         GO mtrans.recnum
         m.EditedBy = pc_UserID
         DO WHILE NOT RLOCK()
         ENDDO
         GATHER MEMVAR
         UNLOCK ALL

         wstr = SPACE(90)
         DO SetArr WITH wstr
         REPLACE mtrans.main WITH wstr
      ENDIF

   CASE NOT EMPTY(reccomm)
      SELECT comment
      GO Mtrans.reccomm
      hldcomm = Mtrans.reccomm
      SCATTER MEMO MEMVAR
** 01/15/04 IZ do not allow edit Code30 comments here, it should be done through <Ctrl-F3> now
      IF m.txn_code = 30
         = gfmsg("Please use <Ctrl-F3> on the transaction line to edit the blurbs.")
      ELSE
         okcan = 1
         * DMA 12/29/03 Issue re-opening warning for a closed case.
         IF NOT EMPTY( convrtDate(pd_closing))
            DO gfReopen WITH .F., "Editing transaction comments"
         ENDIF
         DO EditComm.spr
         IF okcan = 1
            SELECT Comment
            m.EditedBy = pc_UserID
            DO WHILE NOT RLOCK()
            ENDDO
            GATHER MEMO MEMVAR
            UNLOCK ALL
            SELECT Mtrans
            LOCATE FOR reccomm = hldcomm           && Find the first line
            IF FOUND()
               FOR i = 1 TO MEMLINES(Comment.comment)
                   IF Mtrans.reccomm = hldcomm
                      REPLACE main WITH SPACE(14) + MLINE( Comment.comment, i)
                   ENDIF
                   IF NOT EOF()
                      SKIP
                   ENDIF
               ENDFOR
            ** If the comment was associated with an NRS transaction, update
            ** information in the Code41 file. This ensures that update will
            ** be printed on NRS forms which go directly to Code41 for data.
            ** 06/05/2002 DMA
               IF Comment.Txn_Code = 41
                  c41used = gfUse( "Code41")
                  SELECT Code41
                  SET ORDER TO Txn_ID
                  IF SEEK( Comment.Txn_ID)
                     IF Code41.Cl_Code = pc_clcode AND Code41.Tag = pn_tag
                        DO WHILE NOT RLOCK()
                        ENDDO
                        REPLACE Code41.Reason WITH Comment.Comment
                        UNLOCK
                        = gfUnUse( "Code41", c41Used)
                     ENDIF
                  ENDIF
               ENDIF
             ** End of NRS Comment processing
            ENDIF  && if found()
         ENDIF  && okCan = 1
      ENDIF  && txn_code = 30
ENDCASE

IF tagswitch
   SELECT Mtrans
   REPLACE main WITH STUFF(main, 10, 68, PADC(" MOVED ", 68, "*"))
   REPLACE recnum WITH 0
ENDIF
DO SetKey WITH "DEPSTAT"
*--2/25/03 kdl start: reset custom color settings of scheme 1
DO color1
*--2/25/03 kdl end:
*--5/08/02 kdl start: need to make sure record.dbf is open
*-- original code was the call to RStatus
IF mtrans.tagno <> 0
   lsCurArea = SELECT()
   llrecused = .T.
   IF NOT USED('record')
      llrecused = gfuse('record')
   ENDIF
   SELECT record
   *--5/23/02 kdl start: save current position in record table
   m.lnRecNum = RECNO()
   *--5/23/02 kdl start:
   SET ORDER TO cltag
   *--only call rstatus if tag found in record table
   IF SEEK(pc_clcode + '*' + str(mtrans.tagno))
      DO RStatus
   ENDIF
   *--5/23/02 kdl start: return to saved position in record table
   SELECT record
   GO (m.lnRecNum)
   *--5/23/02 kdl start:
   =gfunuse('record',llrecused )
   SELECT (lsCurArea)
ENDIF
*--5/08/02 kdl end:
*--8/12/03 kdl start: call first-look procedure
IF l_1stlook AND INLIST(mtrans.TranCode, 88, 53)
   DO flnalias WITH "ENTRY", "FL"
   DO flnalias WITH "COMM", "FL"
ENDIF
*--8/12/03 kdl end:

RETURN
*****************************************************
PROCEDURE Del_Txn
*--8/13/03 kdl start: added private variable
PRIVATE fileused, l_Usedist, l_recspec, n_Curarea

IF NOT pl_DelFunc
   gfmessage( "Access to this option denied.")
RETURN
ENDIF
* DMA 12/29/03 Issue re-opening warning for a closed case.
IF NOT EMPTY( convrtDate(pd_closing))
   DO gfReopen WITH .F., "Deleting transaction information"
ENDIF
*--8/12/03 kdl start: call first-look procedure to change tables
*-- assigned aliases
IF l_1stlook AND INLIST(mtrans.TranCode, 88, 53)
   DO flnalias WITH "ENTRY", "PR"
   DO flnalias WITH "COMM", "PR"
ENDIF
*--8/12/03 kdl end:

DO SetKey WITH "DEL_TXN"
IF NOT EMPTY(Mtrans.recnum)
   SELECT F
   GO Mtrans.recnum
   IF RECNO() = Mtrans.recnum
      IF INLIST( f.txn_code, 7, 11)
         gfmessage("11 and 7 transactions cannot be deleted. " )
         SELECT Mtrans
         DO SetKey WITH "DEPSTAT"
         RETURN
      ENDIF

      *--9/26/03 kdl start: block deletion of 1 and 88 transactions of
      *-- released 1st look records.
*!*	      IF pl_FrstLook AND pl_Distrib AND ;
*!*	            INLIST( F.txn_code, 1, 88)
*!*	            gfmessage("1 and 88 transactions for released" + ;
*!*	            CHR(13) + "first-look tags cannot be deleted." )
*!*	         SELECT Mtrans
*!*	         DO SetKey WITH "DEPSTAT"
*!*	         RETURN
*!*	      ENDIF
      *--9/26/03 kdl end:
 *-----------------------------------------------------------------------------      
      *-- 05/22/2017 - MD #54247, 52875
		*!*	      IF pl_FrstLook AND pl_Distrib AND ;
		*!*	            INLIST( F.txn_code, 1, 88)
		*!*	            gfmessage("1 and 88 transactions for released" + ;
		*!*	            CHR(13) + "first-look tags cannot be deleted." )
		IF NVL(pl_frstLook,.F.) AND NVL(pl_Distrib,.F.) AND INLIST(f.txn_code,1,41,88)
				gfmessage("Transaction can not be deleted for released/objected first look tags."+CHR(13)+;
				"Please contact Helpdesk to remove transactions",2)	
				SELECT Mtrans
         		DO SetKey WITH "DEPSTAT"
         		RETURN
		ENDIF
		*-----------------------------------------------------------------------------    
      IF NOT yesorno("Delete this transaction ? (Y/N) ")
         SELECT Mtrans
         DO SetKey WITH "DEPSTAT"
         RETURN
      ENDIF
      hldtxnid = f.txn_id
      hldcode = f.txn_code
      lPick = .F.
      ** 07/17/03 IZ added the system message "Memo required".
      IF INLIST( hldcode, 1, 41)
         IF NOT yesorno("A memo is required when deleting a 1 or 41 " ;
               + "transaction. Proceed? (Y/N)")
            SELECT Mtrans
            DO SetKey WITH "DEPSTAT"
            RETURN
         ENDIF
      ENDIF
      ** end IZ

		*--4/20/04 kdl start: clear our 88 transaction dates fron the recspec table
		IF hldcode = 88
      	n_Curarea = SELECT()
      	l_recspec = gfuse("recspec")
      	SELECT recspec
      	SET ORDER TO cltagfld
			IF SEEK( pc_Depokey + "DATEDLV_88")
				DO WHILE NOT RLOCK()
				ENDDO
				DELETE
				UNLOCK
			ENDIF
			IF SEEK( pc_Depokey + "DATEDUE_88")
				DO WHILE NOT RLOCK()
				ENDDO
				DELETE
				UNLOCK
			ENDIF
			=gfunuse("recspec", l_recspec)
			SELECT (n_Curarea)
		ENDIF
		*--4/20/04 kdl end:

      DO WHILE NOT RLOCK()
      ENDDO
      && EF Pickup
      IF hldcode = 27 AND NOT Active
         lPick = .T.
         gfmessage(" You cannot delete txn 27 before the txn 6.")
         RETURN
      ENDIF
      && EF Pickup

      * 12/29/03 DMA Auto-open a closed case when change is made
      IF NOT EMPTY( convrtDate(pd_closing))
         WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR 
         DO gfReOpen WITH .T., "deleting a transaction for tag " + ;
            ALLT( STR( Record.tag)) + "."
         WAIT CLEAR 
      ENDIF
      DELETE
      UNLOCK

      * 10/15/02 DMA Track previous NRS status
      l_PrevNrs = .F.
      IF lnTagLevel = 3
         * Recalculate record status and other related information

         *--5/08/02 kdl start: need to make sure record.dbf is open
         *-- original code was the call to RStatus
         IF mtrans.tagno <> 0
            lsCurArea = SELECT()
            llrecused = .t.
            IF NOT USED('record')
               llrecused = gfuse('record')
            ENDIF
            SELECT record
            *--5/23/02 kdl start: save current position in record table
            m.lnRecNum = RECNO()
            *--5/23/02 kdl start:
            SET ORDER TO cltag
            *--only call rstatus if tag found in record table
            IF SEEK( pc_clcode + '*' + STR( mtrans.tagno))
               * 10/15/02 DMA Track previous NRS status for later use
               l_PrevNRS = Record.NRS
               DO RStatus
            ENDIF
            *--5/23/02 kdl start: return to saved position in record table
            SELECT record
            GO (m.lnRecNum)
            *--5/23/02 kdl start:
            =gfunuse('record',llrecused )
            SELECT (lsCurArea)
         ENDIF
         *--5/8 kdl out         DO RStatus
         *--5/08/02 kdl end:

         DO SetRec WITH n_whichdep, holddays, gnFRDays, gnIssDays
      ENDIF
      *
      *   Special processing for specific transaction types
      *
      DO CASE

         CASE hldcode = 1
            * 10/15/02 DMA Only process 1 transactions here
            * Process deletion of a received-record transaction

            *         CASE hldcode = 1 OR hldcode = 41
            *            * Process deletion of a 1 (received records) or
            *            * 41 (no-record statement) transaction.
            *            IF hldcode = 1
            *               * For received txn only, remove received record categories

            ** 07/17/03 IZ added "Required memo call". Parameter "R" for the tag-level memo.
            *--8/13/03 kd start: set comment table to production for this comment enttry
            IF l_1stlook AND NOT INLIST(hldcode, 88, 53)
               DO flnalias WITH "ENTRY", "PR"
               DO flnalias WITH "COMM", "PR"
            ENDIF
            DO ColorDef
            IF NOT MemoTxn( "R", .F.)
               SELECT F
               RECALL
               SELECT Mtrans
               DO SetKey WITH "DEPSTAT"
               DO Color1
               RETURN
            ENDIF
            *--8/13/03 kd start: set comment table to back to first-look
            IF l_1stlook AND NOT INLIST(hldcode, 88, 53)
               DO flnalias WITH "ENTRY", "FL"
               DO flnalias WITH "COMM", "FL"
            ENDIF

            DO Color1
            ** end IZ

            DO DelAdmit WITH "R"
            *            ENDIF
            * If an NRS was recorded, remove all NRS data.
            * This handles the fact that, in Incoming.prg, when a request
            * is partly received and partly NRS, only the 1 transaction is
            * stored in the timesheet, but all other NRS info is still stored
            * in Record, Code41, etc.
            * Use local flag to spot previous NRS
            * (Global flag may have been reset by RStatus)
            IF l_PrevNrs
               fileused = gfuse("code41")
               SET ORDER TO ClTagDate
               IF SEEK ( pc_depokey)
                  SCAN WHILE Code41.cl_code + "*" + STR( Code41.Tag) ;
                        + "*" + DTOS(Code41.Txn_Date) = pc_depokey
                     DO WHILE NOT RLOCK()
                     ENDDO
                     DELETE
                     UNLOCK
                  ENDSCAN
                  SELECT Record
                  DO WHILE NOT RLOCK()
                  ENDDO
                  REPLACE Record.NRS WITH .F.
                  REPLACE Record.NRS_Code WITH " "
                  UNLOCK
                  pl_HasNRS = .F.
                  pc_NRSType = " "
               ENDIF
               =gfunuse( "code41", fileused)
               DO DelAdmit WITH "N"
               SELECT MTrans
            ENDIF

         CASE hldcode = 4 AND Record.WaivRcvd

            **EF 02/23/04 Remove a Waiver date and a qualifier
            IF NOT USED( 'holdreq')
               USE (f_holdreq) IN 0
            ENDIF
            SELECT Holdreq
            SET ORDER TO MEMOTXN_ID
            SEEK ( STR( HLDTXNID))
            IF FOUND() AND NOT EMPTY( waivr_date)
               REPLACE Holdreq.Waivr_Date WITH {  /  /    }, ;
                  MEMOTXN_ID WITH 0
               USE
               SELECT RECORD
               REPLACE record.waivrcvd WITH  .F.
            ENDIF

         CASE hldcode = 11 OR hldcode = 44
            * Remove special instructions for a deleted issue or 2nd request
            fileused = gfuse("spec_ins")
            SET ORDER TO Txn_ID
            IF SEEK( STR( hldtxnid))
               IF Spec_Ins.cl_code = pc_clcode ;
                     AND Spec_Ins.tag = pn_tag
                  DO WHILE NOT RLOCK()
                  ENDDO
                  DELETE
                  UNLOCK
               ENDIF
            ENDIF
            =gfunuse( "spec_ins", fileused)
            SELECT MTrans

         CASE hldcode = 30
            * Remove data from Code 30 file for a deleted hold transaction
            fileused = gfuse( "Code30")
            SET ORDER TO Txn_ID
            IF SEEK( hldtxnid)
               IF Code30.cl_code = pc_clcode ;
                     AND Code30.tag = pn_tag
                  DO WHILE NOT RLOCK()
                  ENDDO
                  DELETE
                  UNLOCK
               ENDIF
            ENDIF
            =gfunuse( "Code30", fileused)
            SELECT MTrans

         CASE hldcode = 41
            ** 07/17/03 IZ added "Required memo call". Parameter "R" for the tag-level memo.
            DO ColorDef
            IF NOT MemoTxn("R", .F.)
               SELECT F
               RECALL
               SELECT Mtrans
               DO SetKey WITH "DEPSTAT"
               DO Color1
               RETURN
            ENDIF
            DO Color1
            ** end IZ
            * Remove NRS information from Code 41 and Record files
            fileused = gfuse("code41")
            SET ORDER TO Txn_ID
            IF SEEK( hldtxnid)
               IF Code41.cl_code = pc_clcode ;
                     AND Code41.tag = pn_tag
                  DO WHILE NOT RLOCK()
                  ENDDO
                  DELETE
                  UNLOCK
               ENDIF
               IF lnTagLevel = 3
                  SELECT Record
                  DO WHILE NOT RLOCK()
                  ENDDO
                  REPLACE Record.NRS WITH .F.
                  REPLACE Record.NRS_Code WITH " "
                  pl_HasNRS = .F.
                  pc_NRSType = " "
                  UNLOCK
               ENDIF
            ENDIF
            =gfunuse( "code41", fileused)
            DO DelAdmit WITH "N"
            SELECT MTrans

         CASE hldcode = 53 AND Record.Status <> "I" AND lnTagLevel = 3
            * Clear related information from Record for situation where
            * part of request was incomplete, and part was NRS or rec'd
            SELECT Record
            DO WHILE NOT RLOCK()
            ENDDO
            REPLACE record.inc WITH .F.
            REPLACE record.qual WITH " "
            UNLOCK
            pl_incompl = .F.
            pc_IncCode = " "
            DO DelAdmit WITH "I"
            SELECT MTrans

         CASE hldcode = 6
            && Pickup close
            SELECT F
            lcOrder = Order()
            SET ORDER TO cltag
            IF SEEK( Record.cl_code + "*" + STR( Record.Tag))
               * 07/23/03 DMA Switch to SCAN, add record locking
               SCAN WHILE F.cl_code = Record.cl_code AND F.Tag = Record.Tag
                  IF txn_code = 27
                     DO WHILE NOT RLOCK()
                     ENDDO
                     REPLACE Active WITH .T.
                     UNLOCK
                  ENDIF
               ENDSCAN
               *                  SKIP
               *               ENDDO
            ENDIF
            SET ORDER TO (lcOrder)

            SELECT Record
            DO WHILE NOT RLOCK()
            ENDDO
            REPLACE Record.Pickup WITH .T.
            UNLOCK

         CASE hldcode = 27 AND NOT lPick
            SELECT Record
            DO WHILE NOT RLOCK()
            ENDDO
            REPLACE Record.Pickup WITH .F.
            UNLOCK

            *--8/12/03 kdl start: need to clear out distribution serv to-do requests
         CASE hldcode = 88 AND pc_Flship = "E"
            l_Usedist = gfuse("Disttodo")
            SELECT disttodo
            SET ORDER TO lrs_tag IN disttodo
            IF SEEK(STR(pn_lrsno) + STR(pn_tag), "disttodo")
               SELECT disttodo
               SCAN WHILE disttodo.lrs_no = pn_lrsno AND ;
                     disttodo.tag = pn_tag
                  DO WHILE NOT RLOCK()
                  ENDDO
                  *--9/25/03 kdl start: update new remove fields instead of
                  *-- delete todo request.
                  REPLACE disttodo.rem_by WITH pc_UserId, ;
                     disttodo.rem_date WITH d_today, ;
                     disttodo.rem_time WITH TIME()
                  *--kdl out 9/25/03: DELETE
                  UNLOCK
               ENDSCAN
            ENDIF
            = gfunuse("Disttodo", l_Usedist)
            SELECT record
            *-- 8/12/03 kdl end:
      ENDCASE
      *
      *   If a received or incomplete transaction is being deleted
      *   update the record-review status accordingly.
      *
      IF lnTagLevel = 3
         IF NOT INLIST( Record.Status, "R", "I")
            REPLACE Record.Revw_Stat WITH " "
         ENDIF
         DO CASE
            CASE NOT pl_Review
               pc_RevStat = "N"
            CASE NOT EMPTY( Record.Revw_Stat)
               pc_RevStat = Record.Revw_Stat
            CASE NOT INLIST( Record.Status, "N", "R", "I", "C")
               pc_RevStat = "U"
            OTHERWISE
               pc_RevStat = " "
         ENDCASE
         pc_RevLine = RevwStat( pc_RevStat)
      ENDIF
      *
      *  Remove deleted txn record from mtrans (temporary display file)
      *
      SELECT Mtrans
      DELETE
      SKIP
      *
      *  If there was an associated comment for the transaction,
      *  remove it from both mtrans and Comment file.
      *
      IF NOT EMPTY(Mtrans.reccomm)              && This is in the comment file
         hldcomm = mtrans.reccomm
         SELECT Comment
         GO hldcomm
         IF RECNO("comment") = hldcomm
            DO WHILE NOT RLOCK()
            ENDDO
            DELETE
            UNLOCK
         ENDIF
         SELECT Mtrans
         SCAN WHILE Mtrans.reccomm = hldcomm
            DELETE
         ENDSCAN
      ELSE
         ** Remove any associated special instruction information
         ** from mtrans file
         SCAN WHILE Mtrans.reccomm = 0 AND Mtrans.recnum = 0
            DO WHILE NOT RLOCK()
            ENDDO
            DELETE
            UNLOCK
         ENDSCAN
      ENDIF
   ENDIF
ELSE

   ** Delete only the comment associated with the txn, not the actual txn.
   IF MTrans.TranCode = 41
      gfmessage("NRS explanatory text cannot be directly deleted." + ;
         CHR(13) + "Delete NRS (41) transaction instead.")
      DO SetKey WITH "DEPSTAT"
      RETURN
   ENDIF
   ** End of NRS Test
   IF NOT yesorno("Delete this comment? (Y/N) ")
      DO SetKey WITH "DEPSTAT"
      RETURN
   ENDIF
   IF NOT EMPTY(mtrans.reccomm)
      * 12/29/03 DMA Auto-open a closed case when change is made
      IF NOT EMPTY( convrtDate(pd_closing))
         WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR 
         DO gfReOpen WITH .T., "deleting a transaction comment for tag " + ;
            ALLT( STR( Record.tag)) + "."
         WAIT CLEAR 
      ENDIF
      SELECT Comment
      GO Mtrans.reccomm
      IF RECNO("comment") = Mtrans.reccomm
         DO WHILE NOT RLOCK()
         ENDDO
         DELETE
         UNLOCK
         SELECT Mtrans
         DELETE
      ENDIF
   ENDIF
ENDIF

*--8/12/03 kdl start: call first-look procedure
IF l_1stlook AND INLIST( hldcode, 88, 53)
   DO flnalias WITH "ENTRY", "FL"
   DO flnalias WITH "COMM", "FL"
ENDIF

SELECT Mtrans
DO SetKey WITH "DEPSTAT"
   RETURN
*****************************************************
PROCEDURE DelAdmit
* Removes new-style admission records from both Admissn and GAdmissn
* for transactions that are being deleted, then updates CovLet to match.
PARAMETER c_txntype
PRIVATE c_covkey, c_admkey, l_covused, l_admused, l_gadmused, ;
   n_prevfile, n_admits
n_admits = 0
n_prevfile = SELECT()
c_covkey = pc_clcode + STR(pn_Tag)
c_admkey = c_covkey + c_txntype
l_admused = gfuse( "Admissn")
SET ORDER TO ClTagTyp
IF SEEK( c_admkey)
   SCAN WHILE Admissn.cl_code + STR(Admissn.Tag) + ;
         Admissn.AdmType = c_admkey
      DO WHILE NOT RLOCK()
      ENDDO
      DELETE
      UNLOCK
   ENDSCAN
ENDIF
COUNT TO n_admits FOR Admissn.cl_code + STR(Admissn.Tag) + Admissn.AdmType = ;
   c_covkey
= gfunuse( "Admissn", l_admused)
l_gadmused = gfuse( "Gadmissn")
SET ORDER TO ClTagTyp
IF SEEK( c_admkey)
   SCAN WHILE GAdmissn.cl_code + STR(GAdmissn.Tag) + ;
         GAdmissn.AdmType = c_admkey
      DO WHILE NOT RLOCK()
      ENDDO
      DELETE
      UNLOCK
   ENDSCAN
ENDIF
= gfunuse( "GAdmissn", l_gadmused)
l_covused = gfuse( "CovLet")
SET ORDER TO ClTag
IF SEEK( c_covkey)
   DO WHILE NOT RLOCK()
   ENDDO
   IF n_Admits = 0
      DELETE
   ELSE
      REPLACE CovLet.CountAdm WITH n_Admits
   ENDIF
   UNLOCK
ENDIF
= gfUnUse( "CovLet", l_covused)
SELECT (n_prevfile)
RETURN
*****************************************************
PROCEDURE SetArr
PARAMETERS lwstr
PRIVATE x

lwstr = STUFF(lwstr, 1, 10, DTOC(txn_date))
lwstr = STUFF(lwstr, 12, 3, TRANSFORM(txn_code,"999"))
lwstr = STUFF(lwstr, 16, 49, LEFT(descript+space(49), 49))
lwstr = STUFF(lwstr, 67, 3, TRANSFORM(units*60,"999"))
IF lnTagLevel <> 3
   lwstr = STUFF(lwstr, 72, 3, TRANS(tag,"999"))
ENDIF
IF pl_CAVer
* 04/27/04 DMA Use new-format RCA number and proper indenting
*   lwstr = STUFF(lwstr, 76, 10, rca_no)
   lwstr = STUFF( lwstr, IIF( lnTagLevel <> 3, 76, 72), 10, ;
      pc_plbbASB + "." + ASB_Round)
ENDIF

x = ""
DO CASE

   CASE Txn_code = 14
      x = "CtOrder:" + ALLTRIM( TRANSFORM( wit_fee, "999.99"))

   CASE Txn_code = 31
      x = "Pages: 0 "

   CASE Txn_code = 41
      x = "Pages:" + ALLTRIM( TRANSFORM( count, "999999"))

   CASE Txn_code = 26
      x =  "AddsAmt:" + ALLTRIM( TRANSFORM( wit_fee, "9999.99"))

   CASE txn_code = 77
      x = "Atty: " + ALLTRIM(rq_at_code) +  "  Amount:" + STR(wit_fee, 7, 2)

   CASE INLIST( Txn_code, 15, 19)
      x = "Courier:" + ALLTRIM( TRANSFORM( wit_fee, "999.99"))

   CASE inlist( Txn_code, 10, 13, 16, 20)       && x-rays, microfilm, photos,pathology
      x = "Count:" + ALLTRIM( TRANSFORM( count, "999999"))

   CASE INLIST( Txn_code, 7, 18)
      x = "Fee:" + ALLTRIM( TRANSFORM( wit_fee, "9999.99"))
      x = x + " Ck#:" + ALLTRIM( TRANSFORM( count, "9999999"))

      * 09/20/02 DMA Cancel 8/30/02 change per Liz Donegan
      * 08/30/02 DMA Show page count for incomplete records
      *   CASE INLIST( Txn_code, 1, 71, 53)
   CASE INLIST( Txn_code, 1, 71)
      x = "Pages:" + ALLTRIM( TRANSFORM( count, "999999"))
      * 08/30/02  DMA  Indicate "hidden" NRS when appropriate
      *      IF NOT EMPTY( Record.NRS_Code) AND Txn_Code = 1
      *         x = x + "+" + IIF( pl_CAVer, ;
         *            IIF( Record.Type = "S", "10",  "6"), "4")
      *      ENDIF
      x = x + " " + O
ENDCASE

lwstr = STUFF(lwstr, 50-LEN(x)+15, LEN(x), x)
RETURN
*********************************************************
PROCEDURE Color1
** Set a special color for scheme 1
SET COLOR OF SCHEME 1 TO "B/W,W+/W,BG/N,BG/N,BG/N,W+/W,W+/W,N+/N,BG/N,B"
RETURN
*********************************************************
PROCEDURE ColorDef

** Set scheme 1 to default
SET COLOR OF SCHEME 1 TO "W+/B,W+/BG,GR+/B,GR+/B,R+/B,W+/GR,GR+/RB,N+/N,GR+/B,R+/B,+"
RETURN
************************************************************************
PROCEDURE RoloProc

DO SetKey WITH "ROLOPROC"

IF EMPTY(Record.mailid_no)
   gfmessage(;
      "This deponent has not been assigned a Mail ID yet. " + chr(13) + ;
      "After it is issued, it will be assigned a Mail Id" + chr(13) + ;
      "and associated with a rolodex entry. At that time" + chr(13) + ;
      "<Ctrl+R> will show the rolodex information.")
ELSE
   DO ColorDef
   DO ShowRolo WITH Record.mailid_no
   DO Color1
ENDIF
DO SetKey WITH "DEPSTAT"
RETURN
*********************************************************
PROCEDURE View30
DO SetKey WITH "CODE30"
DO Print30 WITH .T.
DO SetKey WITH "DEPSTAT"
RETURN
*********************************************************
PROCEDURE FixWFee
** Transfer the witness fee amount from oldtag to newtag
** Subtract from oldtag and add to newtag
** Update Checks file

PARAMETERS oldtag, newtag, amt, lnChkNo
PRIVATE llChecks

SELECT Record
IF SEEK( pc_clcode + "*" + STR(newtag))
   IF Record.cl_code = pc_clcode AND Record.tag = newtag
      DO WHILE NOT RLOCK()
      ENDDO
      REPLACE Record.wit_fee WITH Record.wit_fee + amt
      UNLOCK
   ENDIF
ENDIF

SELECT Record
IF SEEK( pc_clcode + "*" + STR(oldtag))
   IF Record.cl_code = pc_clcode AND Record.tag = oldtag
      DO WHILE NOT RLOCK()
      ENDDO
      REPLACE Record.wit_fee WITH Record.wit_fee - amt
      UNLOCK
   ENDIF
ENDIF

llchecks = gfuse( "Checks")
SET ORDER TO Check_No

IF SEEK( lnChkNo)
   IF ALLTRIM(cl_code)==ALLTRIM(pc_clcode) AND ;
         tag = oldtag AND check_no = lnChkNo
      DO WHILE NOT RLOCK()
      ENDDO
      REPLACE tag WITH newtag
   ELSE
      gfmessage("Check " + ALLT( STR( lnChkNo)) + " NOT FOUND." + ;
         CHR(13) + " Please contact IT Dept. with details.")
   ENDIF
ELSE
   gfmessage("Check " + ALLT( STR( lnChkNo)) + " NOT FOUND." + ;
      CHR(13) + " Please contact IT Dept. with details.")
ENDIF

= gfunuse( "Checks", llchecks)
SELECT Record
RETURN
****************************************************
PROCEDURE SetKey
*** Define function keys used for each screen screen
PARAMETERS Scrn

CLEAR TYPEAHEAD
DO ClrKey

DO CASE
   CASE scrn = "DEPSTAT"
      ON KEY LABEL "F10"     DO TS_Cancl        && Cancel
      ON KEY LABEL "F7"      DO TS_Cancl        && Cancel
      ON KEY LABEL "F5"      DO F5Key           && Top
      ON KEY LABEL "F6"      DO F6Key           && Bottom

      IF lnTagLevel = 3                         && Single deponent only
         *--8/12/03 kdl start: adjust key asignments for first-look screen
         IF l_1stlook
            ON KEY LABEL "F8"      DO PrintTS   && Print timesheet
            ON KEY LABEL "Ctrl+F4" DO LView41 ;
               WITH Record.tag                  && View NRS information
         ELSE
            ON KEY LABEL "Ctrl+R"  DO RoloProc  && Rolodex lookup
            ON KEY LABEL "Ctrl+C"  DO ChkBrow   && Browse checks
            ON KEY LABEL "Ctrl+F3" DO View30    && View Code 30 letter
            ON KEY LABEL "Ctrl+F4" DO LView41 ;
               WITH Record.tag                  && View NRS information
            IF pl_CAVer
               ON KEY LABEL "Ctrl+S"  DO cactrl_s  && View subpoena
            ENDIF
            ON KEY LABEL "F8"      DO PrintTS   && Print timesheet
         ENDIF

      ENDIF

      IF INLIST( lnTagLevel, 1, 3)
         ON KEY LABEL "F3"      DO Edit_Txn     && Edit entry
         ON KEY LABEL "F4"      DO Del_Txn      && Delete entry
      ENDIF

      IF INLIST(lnTagLevel, 1, 2)
         ON KEY LABEL "F8"      DO AddMemo      && Add a tag 0 memo
      ENDIF

   CASE scrn = "CODE30"
      ON KEY LABEL "Ctrl+W"
      ON KEY LABEL "ESC"

   CASE scrn = "ROLOPROC"
      ON KEY LABEL "F10"     KEYBOARD "{Ctrl+W}" PLAIN

   CASE scrn = "CHECKS"
      ON KEY LABEL "Ctrl+W"
      ON KEY LABEL "ESC"
      ON KEY LABEL "F10"     KEYBOARD "{CTRL+W}" PLAIN
      ON KEY LABEL "F7"      KEYBOARD "{CTRL+W}" PLAIN

   CASE scrn = "SERVICE"
      ON KEY LABEL "Ctrl+W"
      ON KEY LABEL "ESC"

   CASE scrn = "EDIT_TXN"
      ON KEY LABEL "F10"     KEYBOARD "{Ctrl+W}" PLAIN

   CASE scrn = "DEL_TXN"
      *** Nothing so far
ENDCASE
RETURN
*************************************************************
PROCEDURE ClrKey                                && Clear all keys

ON KEY LABEL "ESC"     KEYBOARD ""
ON KEY LABEL "Ctrl+R"  KEYBOARD ""
ON KEY LABEL "Ctrl+C"  KEYBOARD ""
ON KEY LABEL "Ctrl+E"  KEYBOARD ""
ON KEY LABEL "Ctrl+S"  KEYBOARD ""
ON KEY LABEL "Ctrl+W"  KEYBOARD ""
ON KEY LABEL "Ctrl+F3" KEYBOARD ""
ON KEY LABEL "Ctrl+F4" KEYBOARD ""
ON KEY LABEL "F3"      KEYBOARD ""
ON KEY LABEL "F4"      KEYBOARD ""
ON KEY LABEL "F5"      KEYBOARD ""
ON KEY LABEL "F6"      KEYBOARD ""
ON KEY LABEL "F7"      KEYBOARD ""
ON KEY LABEL "F8"      KEYBOARD ""
ON KEY LABEL "F10"     KEYBOARD ""
RETURN
*************************************************************
PROCEDURE LView41
PARAMETERS mtag

DO SetKey WITH "CODE30"
DO View41 WITH mtag
DO SetKey WITH "DEPSTAT"
RETURN
***********************************************************
PROCEDURE AddMemo
** 07/21/03 IZ change "DO MemoTxn" into "=MemoTxn(...)"
= MemoTxn( "C", .F.)
RETURN
***********************************************************
&& CACtrl_S.PRG
&& This program displays information about the subpoena or autho

PROCEDURE CACtrl_s

PRIVATE bCUsed, szWrkArea, dbInit, l_GotTag, n_SaveServ, ;
   d_ServDate, c_Service, c_ServeTo, c_Comment
n_SaveServ = 2
DO SetKey WITH "SERVICE"

WAIT WINDOW "Locating request information. Please wait." NOWAIT NOCLEAR 

&& Store current workarea!!
dbInit = SELECT()

SELECT 0
USE (f_psnotice) AGAIN ORDER cl_code ALIAS Details
l_GotTag = .F.
IF SEEK( ALLTRIM( pc_clcode))
   SCAN WHILE Details.cl_code == pc_clcode
      IF Details.Tag = pn_Tag
         l_GotTag = .T.
         EXIT
      ENDIF
   ENDSCAN
ENDIF
IF NOT l_GotTag
   WAIT CLEAR
   && Tag not found!! Need to exit section!!
   *   ?? CHR(7)
   gfmessage("Request details for tag " + ALLTRIM( STR( pn_Tag)) + ;
      " were not found." )
   SELECT Details
   USE
   SELECT (dbInit)
   DO SETKEY WITH "DEPSTAT"
RETURN
ENDIF

&& Get Deponent Information!!
DO CASE
   CASE pc_DepType == "A"
      SELECT 0
      USE (f_MailA) AGAIN ORDER MailID_No
   CASE pc_deptype == "E"
      SELECT 0
      USE (f_MailE) AGAIN ORDER MailID_No
   CASE pc_deptype == "H"
      SELECT 0
      USE (f_MailH) AGAIN ORDER MailID_No
   OTHERWISE
      SELECT 0
      USE (f_MailD) AGAIN ORDER MailID_No
ENDCASE
IF NOT SEEK( Details.MailID_No)
   *   ?? CHR(7)
   gfmessage("Incorrect Mail ID Number.")
   USE
   SELECT Details
   USE
   IF NOT EMPTY( szWrkArea)
      SELECT (szWrkArea)
   ENDIF
   DO SETKEY WITH "DEPSTAT"
RETURN
ELSE
   szDepAdd1 = ALLTRIM(Add1)
   szDepAdd2 = ALLTRIM(Add2)
   szDepAdd3 = ALLTRIM(City) + ", " + ALLTRIM(State) + " " + ALLTRIM(Zip)
   szPhone = Phone
   szFax = Fax_no
ENDIF
WAIT CLEAR
USE

SELECT Details
d_ServDate = Details.ServDate
c_Service = Details.Service
c_ServeTo = Details.ServeTo
c_Comment = Details.Comment
pc_ServNam = IIF( pl_CAVer, Details.Serv_Name, "N/A")

* DMA 12/29/03 Issue re-opening warning for a closed case.
IF NOT EMPTY( convrtDate(pd_closing))
   DO gfReopen WITH .F., "Editing service information"
ENDIF
DO ServInfo.SPR

IF n_SaveServ = 1
* 11/13/03 DMA Auto-open a closed case when change is made
IF NOT EMPTY( convrtDate(pd_closing))
   WAIT WINDOW "NOTE: Case is being automatically re-opened." NOWAIT NOCLEAR 
   DO gfReOpen WITH .T., "changing request's service information for tag " + ;
      ALLT( STR( pn_tag)) + "."
   WAIT CLEAR 
ENDIF
   DO WHILE NOT RLOCK()
   ENDDO
   REPLACE Details.ServDate WITH d_ServDate, ;
      Details.Service WITH c_Service, ;
      Details.ServeTo WITH c_ServeTo, ;
      Details.Comment WITH c_Comment, ;
      Details.serv_name with pc_ServNam
   UNLOCK
ENDIF
SELECT Details
USE
SELECT (dbInit)
DO SETKEY WITH "DEPSTAT"
RETURN

*********************************************************************
PROCEDURE PrintTS
PRIVATE n_CurrLine

IF PRINTSTATUS()
   SET PRINTER TO LPT1:
   SET CONSOLE OFF
   SET PRINT ON
   n_CurrLine = RECNO()
   WAIT WINDOW "Printing..." NOWAIT NOCLEAR 
   SELECT Mtrans
   GO TOP
** 04/14/05 IZ calling report form instead
   REPORT FORM depstat TO PRINT 
** end IZ   
*   ? "------------------------------------------------------------------------------"
*   ? "RT No: " + pc_lrsno at 2, "Case Name: " + pc_plnam at 17
*   ? "------------------------------------------------------------------------------"
*   ? "Tag: " + ALLT( STR( pn_Tag)) + " " + pc_descrpt AT 2
*   ? "------------------------------------------------------------------------------"
*   SCAN
*      ? MTrans.Main AT 2
*   ENDSCAN
   WAIT CLEAR
   EJECT
   SET PRINT OFF
   SET PRINTER TO
   GO n_CurrLine
ELSE
   * 02/02/04 DMA Add message when printer is unavailable
   gfmessage("Printer not available. Please correct and re-try.")
ENDIF
WAIT CLEAR
RETURN
***************************************************
