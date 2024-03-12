**************************************************************************
** EF 10/28/2009 - called for a Follow Up with Edited Blurbs option
FUNCTION Edit2Req
**************************************************************************
PARAMETERS nlrs, tag2req, cdept, lFaxDocs
pl_1st0tag = .F.

LOCAL omed AS medtimesheet OF timesheet
omed = CREATEOBJECT("medtimesheet")
l_cancel=.F.
&& Allow user to pick the deponent that will receive the request
bselect = IIF(bNotcall,.T.,.F.)
l_Reprint=.F.
n_ReqButt = 1
n_PickReq = 1

*!*	**2/11/16- A spec handlig page for !pl_EditReq created at reppdf-START
*!*	IF NOT lFaxDocs  &&& request was picked as a fax earlier
*!*		STORE .F. TO l_Prt2Req, l_Fax2Req,  l_Reprint, l_ViewReq
*!*		ln_Pick = goApp.OpenForm("issued.frmReq2type", "M", timesheet.txn_date, timesheet.txn_date)
*!*		IF ln_Pick=0 THEN
*!*			gfmessage("Canceled a Follow Up Request.")
*!*			RETURN .T.
*!*		ENDIF
*!*		DO CASE
*!*		CASE ln_Pick=1
*!*			l_Prt2Req=.T.
*!*		CASE ln_Pick=2
*!*			l_Fax2Req=.T.
*!*		OTHERWISE

*!*			L_CANCEL=.T.
*!*		ENDCASE
*!*	ELSE
*!*		STORE .F. TO l_Prt2Req,  l_Reprint, l_ViewReq
*!*		l_Fax2Req=.T.

*!*	ENDIF



IF NOT L_CANCEL

*!*		IF LEN(ALLTRIM(pc_depofile.fax_no))=10 AND NOT l_Prt2Req
*!*				lc_message = "Do you want to print a Fax Cover Sheet?"
*!*				o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
*!*				o_message.SHOW
*!*				l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
*!*				o_message.RELEASE
*!*				IF l_Confirm
*!*					l_Fax2Req=.T.
*!*					l_Prt2Req=.F.
*!*					l_Canc2Fax= FAX2REQST (tagreq)
*!*				ELSE
*!*					l_Fax2Req=.F.
*!*					l_Prt2Req=.T.
*!*	* 11/23/2009 - FRK - Fatal RTS Error RT# 197609/Tag # 12/JAMES_EN - 11/23/2009 - 12:12PM					
*!*					l_Canc2Fax = .F.
*!*				ENDIF
*!*				IF l_Canc2Fax

*!*					l_Fax2Req=.F.
*!*					l_Prt2Req=.T.
*!*				ENDIF
*!*				szfaxnum= cleanfax ( ALLTRIM(pc_depofile.fax_no))
*!*			ENDIF



*!*	IF l_Prt2Req AND !pl_EditReq
*!*	l_spechand = .F.
*!*			IF (NOT l_Fax2Req   )
*!*				l_Confirm=gfmessage("Do you want to add Special Handling Instructions?",.T.)
*!*				IF l_Confirm
*!*					l_spechand = .T.
*!*					DO SpecHand	IN subp_pa
*!*				ENDIF
*!*			ENDIF
*!*	ENDIF
*!*	**2/11/16- A spec handlig page for !pl_EditReq created at reppdf -END

	IF pl_zicam
		ln_req =2
		pl_AllDate = .F.
		DO gfAlldat WITH ln_req
	ENDIF

	IF n_ReqButt = 1

* Get the requested instructions!!
		szrequest = ""
		SELECT Spec_Ins
		IF RECCOUNT()>0
			llRepRec=.F.
			creqType = UPPER(ALLT(Spec_Ins.TYPE))
			szrequest = Spec_Ins.Spec_Inst
			sztxndate = CTOD(RIGHT(DTOC(Spec_Ins.Txn_date),10))
			pc_CertTyp = Spec_Ins.cert_type
			IF NOT EMPTY( Spec_Ins.dept) AND (ALLTRIM(cdept)<>'Z')
				IF  (ALLTRIM(Spec_Ins.dept) <> cdept)
					llRepRec= IIF (pc_deptype='H' AND Spec_Ins.TYPE="S",.T.,llRepRec)

				ENDIF
			ENDIF

		ELSE
			creqType = "S"
			szrequest = ""
			pc_CertTyp=""
		ENDIF



&&1) PRINT Folowup letter
		DO reppdfreq IN reppdf WITH nLRS, tag2req, .F. , pc_IssType, CTOD(timesheet.Txn_date), NVL(Spec_ins.dept,"Z"), UPPER(ALLT(timesheet.DESCRIPT))
		PRIVATE l_pdfparam AS Boolean
		l_pdfparam=.F.
		&&2/5/15 : stop using  followup with pdfs
*!*			l_pdfparam=pl_PdfReprint

&&1) PRINT request
&&Get the latest rxn 44 /txn11 transaction
IF USED("LatestReq")
	SELECT LatestReq
	USE
ENDIF
omed.sqlexecute("Exec [dbo].[GetTheLatestFollowUp]  '" + timesheet.CL_code + "',' " + STR(tagreq) + "'", "LatestReq")


	c_retvalue=""
		IF NOT EMPTY(NVL(LatestReq.ID_TBLTimesheet,""))
			c_retvalue=goApp.OpenForm("casedeponent.frmRequestDetails", "M", LatestReq.id_tblRequests, ;
				LatestReq.id_tblRequests,LatestReq.ID_TBLTimesheet, creqType, .T., "M", ;
				"SecReq",pl_RushCas)
		ENDIF

		IF ISNULL(c_retvalue)
			l_Cancel=.T.
			MV=""
			STORE .F. TO l_Fax2Req, l_Prt2Req
			RETURN
		ENDIF
		*DO editspecinst

	ENDIF
ENDIF
*pl_2ndQue = .F.
RELEASE omed


RETURN  l_cancel
*******************************************************************************************************************************

PROCEDURE editSpecinst
LOCAL omed1 AS medtimesheet OF timesheet
omed1 = CREATEOBJECT("medtimesheet")
IF TYPE("pcPublicBlurb")!="C"
	pcPublicBlurb=""
ENDIF
c_request= fixquote(IIF(!EMPTY(ALLTRIM(pcPublicBlurb)),pcPublicBlurb,szrequest))
**insert new specinst and edit psnotice
l_specid=AddSpec_ins( timesheet.Id_tblTimesheet, Timesheet.cl_code, tag2req,  ALLTRIM(TImesheet.DESCRIPT), Timesheet.TYPE,Timesheet.mailid_no, cdept,c_request)
IF l_specid


	C_STR="Update tblPSnotice SET EDITED='"+ DTOC(DATE()) +"', EDITEDBY ='" + pc_UserID + "',  Spec_Inst ='" + c_request + ;
		"' Where cl_code = '" +FIXQUOTE(timesheet.CL_CODE) + "' AND" + ;
		"  Tag = '" + STR(timesheet.TAG) +"'"
	l_PSnotUpd = oMed1.sqlexecute(C_STR,"")
	IF NOT l_PSnotUpd
		gfmessage("Special Instruction did not get to the Notices File")
	ENDIF

ELSE
	gfmessage("Special Instruction was not stored")

ENDIF

RELEASE OMED1




RETURN
*!*	*******************************************************************
FUNCTION allowfax
PARAMETERS d_txn11
l_FaxAllow=.F.
IF pl_CAVer
	l_FaxAllow = l_Fax2Req

ELSE


	IF creqType = "S"                && and gnHold<>0  'Subpoenas-hold cases
		ln_HoldFax = 0
		ln_HoldFax = IIF(pl_WaivRcvd OR pl_Reissue, 0, gnHold)
		l_FaxAllow = (d_today >= d_txn11 + ln_HoldFax)

	ELSE

		l_FaxAllow = .T.


		IF pl_PropPA OR pl_PropNJ
			FOR ln_Count = 1 TO 14
				ld_Busdate = d_txn11 + ln_Count
				ld_Busdate = gfChkDat( ld_Busdate, .F., .F.)
			NEXT
			l_FaxAllow = IIF( d_today > ld_Busdate, .T., .F.)
		ENDIF
	ENDIF


	IF INLIST (pc_Litcode, "E  ", "Q  ") AND pl_FromRev
		l_FaxAllow = ( d_today >= d_txn11 + 10)

	ENDIF

	IF pc_Litcode == "D  "
		l_FaxAllow = ( d_today >= d_txn11 + 15)
	ENDIF

ENDIF






RETURN l_FaxAllow

