PROCEDURE RStatus
*****************************************************************************
* Rstatus.Prg - Recalculate Deponent Status and Related Information
*
*   Assumes that EntryX and Record are open, with Record positioned
*   on the deponent to be recalculated.
*   Reviews all timesheet entries for the deponent to regenerate the
*     information stored in Record.dbf
*
*  Called by MakeRec, DepOpts, DepStat (deponent-level only)
*  Calls gfGetDep, GlobUpd
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 02/16/2009 - EF Update request's Send_Date
* 08/02/2007 - MD Modified to keep status "W" if the record in scanning hold
* 03/22/2006 - MD Modified for VFP

LOCAL lnRecNo, lcEntryN, lcOrder, lcAlias, lcStatus, llHold, lnWitFee, ;
	lnPages, lnCallCnt, llExpedite, ldExpDate, ldFinDate, llIssued, ldIssDate
LOCAL n_Code30, n_Code51, d_lastcall, n_Autofax, l_GotNRS, l_GotRecv, ;
	l_GotInc, c_NRSType, c_IncType, c_RevwStat, d_Open, l_used, d_MailDate
LOCAL  l_Invest, l_Follow, l_Gopher, n_Gopher, n_Pickup, l_Reissue

LOCAL l_Firstlk, c_FlAttyCd

LOCAL lcSQLLine, oTrans
oTrans=CREATEOBJECT("transactions.medrequest")

l_Firstlk = RECORD.first_look
c_FlAttyCd = RECORD.Fl_atty

STORE .F. TO llHold, llIssued, llExpedite, l_GotNRS, l_GotRecv, ;
	l_GotInc, l_Invest, l_Follow, l_Gopher
STORE " " TO c_NRSType, c_IncType, c_RevwStat

lcStatus = "W"

STORE 0 TO lnPages, lnWitFee, lnCallCnt, n_Code30, n_Code51, n_Autofax, ;
	n_Gopher, n_Pickup
STORE d_null TO ldExpDate, ldFinDate, ldIssDate, d_lastcall, d_MailDate
d_Open = oTrans.checkdate(RECORD.Open_Date)
d_MailDate = oTrans.checkdate(RECORD.send_Date)
** 05/28/03 IZ since Reissue is not a 2nd request now, previous
** evaluation based on Entry Transaction is not valid anymore
l_Reissue = RECORD.Reissue
** end IZ
lcAlias = ALIAS()
*-- need to check for received entry in the 1st look table
IF RECORD.first_look
	**10/01/18 SL #109598
	*lcSQLLine="select * from tblFlEntry with (INDEX(ix_tblflentry)) where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+
	lcSQLLine="select * from tblFlEntry where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+;
		ALLTRIM(STR(RECORD.TAG))+"' and deleted is null and active=1"
	oTrans.sqlexecute(lcSQLLine,"flEntry")
	IF USED("flentry")
		SELECT flentry

		SELECT COUNT(*) FROM flentry WHERE txn_code = 1 INTO ARRAY aTxn1
		IF aTxn1 > 0
			l_GotRecv = .T.
		ENDIF
		SELECT COUNT(*) FROM flentry WHERE txn_code = 41 INTO ARRAY aTxn41
		IF aTxn41 > 0
			l_GotNRS = .T.
		ENDIF

		IF l_GotRecv OR l_GotNRS
			lcStatus = "F"
		ENDIF

*!*		IF RECCOUNT()>0
*!*			l_GotRecv = .T.
*!*			lcStatus = "F"
*!*		ENDIF

		USE IN flentry
	ENDIF

ENDIF

**10/01/18 SL #109598
*lcSQLLine="select * from tblTimeSheet with (INDEX(ix_tblTimeSheet)) where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+
lcSQLLine="select * from tblTimeSheet where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+;
	ALLTRIM(STR(RECORD.TAG))+"' and deleted is null order by sequenceid"
oTrans.sqlexecute(lcSQLLine,"TimeSheet")
SELECT TimeSheet
IF RECCOUNT()>0
	SCAN
		IF Txn_Date <= d_Open
			d_Open = Txn_Date
		ENDIF
		DO CASE
		CASE txn_code = 7
			lnWitFee = lnWitFee + Wit_Fee
		CASE txn_code = 19
			llIssued = .F. &&3/27/15 - PER LIZ KEEP AS NOT ISSUED
		CASE txn_code = 11
			llIssued = .T.
			ldIssDate = Txn_Date
			l_Reissue = ( STATUS == "R")
		
		CASE txn_code = 88 AND pc_offcode='P'
			IF NOT l_Firstlk
				l_Firstlk = .T.
				c_FlAttyCd = rq_at_code
			ENDIF
			IF l_GotRecv = .F. AND l_GotNRS = .F.
				lcStatus = "F"
			ENDIF
		CASE INLIST( txn_code, 1, 41)
			DO CASE
			CASE txn_code = 1
				l_GotRecv = .T.
				lcStatus = "R"
				lnPages = lnPages + COUNT
			CASE txn_code = 41
				l_GotNRS = .T.
*--5/13/03 kdl start: block change to status 'N' if there are 1st
*-- look received records
				IF RECORD.first_look AND NOT RECORD.distribute
					lcStatus = 'F'
				ELSE
					lcStatus = IIF( lcStatus = "C" AND pl_BBCase, "C", "N")
				ENDIF
			ENDCASE
			ldFinDate = Txn_Date
		CASE txn_code = 14
			llExpedite = .T.
			ldExpDate = Txn_Date
		CASE txn_code = 21
			lcStatus = "C"
			ldFinDate = Txn_Date
		CASE txn_code = 53
			l_GotInc = .T.
		CASE INLIST( txn_code, 2, 3, 8, 9)
			lnCallCnt = lnCallCnt + 1
			IF INLIST( txn_code, 2, 8)
				d_lastcall = MAX( d_lastcall, Txn_Date)
			ENDIF
		CASE txn_code = 30
* Count number of status-to-counsel letters sent
			n_Code30 = n_Code30 + 1

		CASE txn_code = 51
* Count number of status-to-counsel responses rec'd
			n_Code51 = n_Code51 + 1

		CASE txn_code = 27
* Count pickups that were scheduled
			n_Pickup = n_Pickup + 1

		CASE txn_code = 6
* Count pickups that were completed
			n_Gopher = n_Gopher + 1

		CASE txn_code = 66
* Count number of autofaxes sent
			n_Autofax = n_Autofax + 1

		CASE txn_code = 67
* Track Investigation Flag
			l_Invest = .T.

		CASE txn_code = 68
* Track Follow-Up Flag
			l_Follow = .T.

		ENDCASE
	ENDSCAN
ENDIF
IF ! llIssued AND  lcStatus <> "C"
	lcStatus = "T"
ENDIF
SELECT TimeSheet
USE
* Determine hold status by comparing outgoing and incoming
*  status-to-counsel documents.
llHold = ( n_Code30 > n_Code51)

* Determine pickup status by comparing scheduled to actual
*                pickup attempts
l_Gopher = (n_Pickup > n_Gopher)

* Advanced incomplete processing
IF l_GotInc
	IF l_GotRecv OR l_GotNRS
		**10/01/18 SL #109598
		*lcSQLLine="select * from tblAdmissn with (INDEX(ix_tblAdmissn_1)) where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+
		lcSQLLine="select * from tblAdmissn where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+;
			ALLTRIM(STR(RECORD.TAG))+"' and admtype='I' and active=1 order by created"
		oTrans.sqlexecute(lcSQLLine,"IncCheck")
		SELECT IncCheck
		IF RECCOUNT()>0
			c_IncType = ALLTRIM( IncCheck.AdmCode)
		ENDIF
		USE
	ELSE
* Ignore spurious incomplete if no valid "1" or "41" was found
		l_GotInc = .F.
	ENDIF
ENDIF

SELECT RECORD

* Advanced NRS processing
IF l_GotNRS
	**10/01/18 SL #109598
	*lcSQLLine="select * from tblCode41 with (INDEX(ix_tblCode41_1))where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+
	lcSQLLine="select * from tblCode41 where cl_code='"+ALLTRIM(pc_clcode)+"' and tag='"+;
		ALLTRIM(STR(RECORD.TAG))+"' and active=1 order by created"
	oTrans.sqlexecute(lcSQLLine,"NRSCheck")
	SELECT NRSCheck
	IF RECCOUNT()>0
		c_NRSType = NRSCheck.TYPE
	ENDIF
	USE
	SELECT RECORD
ELSE
	IF l_GotRecv OR l_GotInc
* If an "invisible" NRS was previously logged in Record, retain it
		c_NRSType = RECORD.NRS_Code
		l_GotNRS = RECORD.NRS
	ENDIF
ENDIF

* Review-status recalculation
DO CASE
CASE NOT pl_Review
	c_RevwStat = "N"                          && No review needed
CASE EMPTY( ldFinDate)
	c_RevwStat = "U"                          && Record not received
CASE RECORD.Revw_Stat = "U" AND NOT EMPTY( ldFinDate) ;
		AND (DATE() <= convrtDate(pd_revstop) OR EMPTY(convrtDate(pd_revstop)))
	c_RevwStat = "A"                          && Needs review
OTHERWISE
	c_RevwStat = RECORD.Revw_Stat             && Can't determine, use previous value
ENDCASE
* modified to keep status "W" for scanning hold
IF !EMPTY(ALLTRIM(NVL(RECORD.hstatus,"")))
	lcStatus="W"
ENDIF

lcSQLLine="update tblRequest set "+;
	"Status='"+lcStatus+"', "+;
	"Open_Date="+IIF(EMPTY(NVL(d_Open,{})),"NULL","'"+DTOC(d_Open)+"'")+", "+;
	"Req_Date="+IIF(EMPTY(NVL(ldIssDate,{})),"NULL","'"+DTOC(ldIssDate)+"'")+", "+;
	"Send_Date="+IIF(EMPTY(NVL(d_MailDate,{})),"NULL","'"+DTOC(d_MailDate)+"'")+", "+;  &&"Send_Date=null, "+
"Call_Cnt='"+ALLTRIM(STR(NVL(lnCallCnt,0)))+"', "+;
	"Last_Call="+IIF(EMPTY(NVL(d_lastcall,{})),"NULL","'"+DTOC(d_lastcall)+"'")+", "+;
	"Fin_Date="+IIF(EMPTY(NVL(ldFinDate,{})),"NULL","'"+DTOC(ldFinDate)+"'")+", "+;
	"Wit_Fee=Convert(money, '"+ALLTRIM(STR(NVL(lnWitFee,0),6,2))+"'), "+;
	"Pages='"+ALLTRIM(STR(NVL(lnPages,0)))+"', "+;
	"Expedite="+IIF(llExpedite=.F.,"0","1")+", "+;
	"ExpDate="+IIF(EMPTY(NVL(ldExpDate,{})),"NULL",+"'"+DTOC(ldExpDate)+"'")+", "+;
	"Hold="+IIF(llHold=.F.,"0","1")+", "+;
	"AF_FaxCnt='"+ALLTRIM(STR(NVL(n_Autofax,0)))+"', "+;
	"NRS="+IIF(l_GotNRS=.F.,"0","1")+", "+;
	"NRS_Code='"+NVL(c_NRSType,"")+"', "+;
	"Inc="+IIF(l_GotInc=.F.,"0","1")+", "+;
	"Qual='"+IIF(EMPTY(NVL(c_IncType,"")),NVL(pc_IncCode,""), c_IncType)+"', "+;
	"Investig="+IIF(l_Invest=.F.,"0","1")+", "+;
	"ExtFolwUp="+IIF(l_Follow=.F.,"0","1")+", "+;
	"Pickup="+IIF(l_Gopher=.F.,"0","1")+", "+;
	"Reissue="+IIF(l_Reissue=.F.,"0","1")+", "+;
	"Revw_Stat='"+NVL(c_RevwStat,"")+"', "+;
	"First_look="+IIF(l_Firstlk=.F.,"0","1")+", "+;
	"Fl_atty='"+NVL(c_FlAttyCd,"")+"', "+;
	"edited='"+TTOC(DATETIME())+"', "+;
	"editedBy='"+goApp.CurrentUser.ntlogin+"' "+;
	IIF(c_NRSType = "F", ", AM_Resp=0 ","")+;
	"where id_tblRequests='"+RECORD.id_tblRequests+"' and active=1"
oTrans.sqlexecute(lcSQLLine)

pl_GotDepo = .F.
DO gfGetDep WITH pc_clcode, RECORD.TAG
RELEASE oTrans
IF NOT EMPTY(lcAlias)
	SELECT (lcAlias)
ENDIF
WAIT CLEAR
RETURN
