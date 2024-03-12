**************************************************************************************
**	EF: part of the QC New Case process.
**  copy all participating attorney info to a new case
**  09/23/2011 EF- added indirect billing data to excels' orders
**************************************************************************************
LPARAMETERS  c_atcode, c_role, c_clcode,  c_acct_mgr, c_sales_per, c_masterid , n_mirror, l_fromMircase

LOCAL OGEN AS OBJECT
OGEN=CREATEOBJECT('medgeneric')
LOCAL lc_response AS STRING, c_today AS STRING, lc_plan_type AS STRING, lc_bill_to AS STRING, lc_AccDate AS STRING, ;
	lc_adjuster AS STRING,		lc_insured AS STRING, 	lc_claim_no AS STRING, lc_file_no AS STRING, l_continue AS Boolean, ;
	lc_ordered_by AS STRING, c_user AS STRING,  c_idplan AS STRING
c_user = ALLTRIM(pc_UserID)
lc_response=IIF(ALLTRIM(c_atcode)=ALLTRIM(pc_rqatcod), 'T','F')
c_today=DTOC(DATE())
lc_plan_type="D"
lc_billcat='F'



STORE "" TO lc_bill_to, lc_adjuster ,lc_insured ,lc_claim_no, lc_file_no ,lc_ordered_by, lc_AccDate
c_sql=""
OGEN=CREATEOBJECT('medgeneric')

c_sql=" EXEC [dbo].[GetBillsByClCodeAtCode] '" + fixquote(c_clcode)+"','" + fixquote(c_atcode)+"'"


OGEN.sqlexecute(c_sql,"tabills")

c_sql=""
c_sql=" exec [dbo].[GetAttyShipbyAtcode] '" + c_atcode + "'"
OGEN.sqlexecute(c_sql,"gtaship")


IF RECCOUNT("tabills")=0
***an atty is new to a case

*!*	*----------------------------------atty ship data
	LOCAL c_idtblBills AS CHARACTER
*----------------------------------atty ship data

	lc_numcopy=ALLTRIM(STR(NVL(gtaship.rpapernum ,0)))


*--------------------------indirect billing data for a participating atty added on a web
	c_sql=""
	OGEN.closealias("BillExtra")
	*-- 04/30/2019 md #132787
	* --c_sql=" exec [dbo].[qc_GetBillToExtraData] '" + STR(pn_lrsno)  + "','" +  c_atcode + "','"   + c_user + "'"
	c_sql=" exec [dbo].[qc_GetBillToExtraData2] '" + STR(pn_lrsno)  + "','" +  c_atcode + "','"   + c_user + "'"
	OGEN.sqlexecute(c_sql,"BillExtra")
	IF USED("BillExtra") AND NOT EOF()

		SELECT BillExtra
		SCATTER MEMVAR
		lc_bill_to= m.billto
		lc_adjuster=m.adjuster
		lc_insured=m.insured
		lc_claim_no=IIF(EMPTY(m.claim), m.lawfirmno, m.claim)
		lc_file_no=m.clientmatter
		lc_ordered_by=m.Orderedby
		IF TYPE("m.AccidentDate")="T"
			lc_AccDate=TTOC(m.AccidentDate)
		ELSE
			lc_AccDate=m.AccidentDate
		ENDIF

	ENDIF

*-----------------------------add atty to a case
	c_sql=""


	IF n_mirror<>0  AND l_fromMircase&& ADD NEW RQ ATTY WHEN MIRROR IS PICKED

		c_sql=" Exec [dbo].[qc_AddMirrorAttyNewCaseQueue] '" + pc_offcode + "','" + pc_litcode + "','" + ALLTRIM(pc_area)  + "','" + ;
			NVL(pc_rqatcod,'') + "','" + c_clcode+"','"+;
			c_atcode+"','" + c_user + "','" + ;
			STR(n_mirror)+ "','" +  lc_adjuster+"','"+;
			lc_insured+"','"+;
			lc_claim_no+"','"+;
			lc_file_no+"','"+;
			lc_ordered_by+"','"+ lc_AccDate + "'"
	ELSE



		c_sql=" exec [dbo].[qc_AddAttyNewCaseQueue]  '" + pc_offcode + "','" + pc_litcode + "','" + ALLTRIM(pc_area)  + "','" + ;
			c_role  + "','" + lc_billcat + "','" + lc_response + "','" + NVL(pc_rqatcod,'')  + "','" + c_clcode+"','"+;
			c_atcode+"','" + c_user + "','" + ;
			c_acct_mgr+ "','" +  c_sales_per + "','" + ;
			lc_bill_to+ "','" +  lc_adjuster+"','"+;
			lc_insured+"','"+;
			lc_claim_no+"','"+;
			lc_file_no+"','"+;
			lc_ordered_by+"','"+ lc_AccDate + "'"

	ENDIF && ADD NEW RQ ATTY WHEN MIRROR IS PICKED
	OGEN.sqlexecute(c_sql,"newtabills")
	IF USED ("newtabills")
		c_idtblBills=newtabills.id_tblBills
	ELSE
		c_idtblBills=""
	ENDIF


&&& 9/9/16- copy ship methods from a mirrored case's/ RQatty level  #47711
	IF n_mirror<>0  AND l_fromMircase  AND  UPPER(ALLTRIM(NVL(pc_rqatcod,'')))=UPPER(ALLTRIM(NVL(c_atcode,'') ))

		IF USED("gtaship")
			SELECT gtaship
			USE
		ENDIF
		c_sql=" exec dbo.GetShipbyMirCaseAtcode '" +  STR(n_mirror)  + "','" + NVL(c_atcode,'')  + "'"
		OGEN.sqlexecute(c_sql,"gtaship")

	ENDIF
&&& 9/9/16- copy ship methods from a mirrored case's/RQatty level

ELSE
**already in  a case
**UPDATE BILLTO


	c_sql=""
	OGEN.closealias("BillExtra")
	*-- 04/30/2019 md #132787
	* --c_sql=" exec [dbo].[qc_GetBillToExtraData] '" + STR(pn_lrsno)  + "','" +  c_atcode + "','"   + c_user + "'"
	c_sql=" exec [dbo].[qc_GetBillToExtraData2] '" + STR(pn_lrsno)  + "','" +  c_atcode + "','"   + c_user + "'"
	OGEN.sqlexecute(c_sql,"BillExtra")
	IF USED("BillExtra") AND NOT EOF()

		SELECT BillExtra
		SCATTER MEMVAR
		lc_bill_to= m.billto
		lc_adjuster=m.adjuster
		lc_insured=m.insured
		lc_claim_no=IIF(EMPTY(m.claim), m.lawfirmno, m.claim)
		lc_file_no=m.clientmatter
		lc_ordered_by=m.Orderedby		
		IF TYPE("m.AccidentDate")="T"
			lc_AccDate=TTOC(m.AccidentDate)
		ELSE
			lc_AccDate=m.AccidentDate
		ENDIF

		c_sql=""
		c_sql="Update tblbill set file_no ='" +NVL(lc_file_no,'') + ;
			"',claim_no ='" + NVL(lc_claim_no,'') + ;
			"',insured ='" + NVL(lc_insured,'') + ;
			"',bill_to ='" + NVL(lc_bill_to,'') + ;
			"',adjuster='" + NVL(lc_adjuster,'') + ;
			"',ordered_by='" + NVL(lc_ordered_by,'') + ;
			"', AccidentDate='" + lc_AccDate + ;			
			"' WHERE cl_code='"+c_clcode+"'"+;
			" and at_code='"+fixquote(c_atcode)+"' and active=1 "
		OGEN.sqlexecute(c_sql,"")


	ENDIF
****12/12/12- update existing ALL atty by the data from a MIRROR case

	c_idtblBills=tabills.id_tblBills


**chcek if atty we are about to update is in theMIrror case or was added later.
**If added separatly then we do not need to update it here - it will be donwe on the 3.1. screen

	IF n_mirror>0
		l_continue=.T.
		OGEN.closealias("MirrChk")
		OGEN.sqlexecute(" select dbo.QC_ChkMirrCaseAtty('"+STR(n_mirror)+"','"+  fixquote(c_atcode)+"' )" ,"MirrChk")
		IF USED("MirrChk")
			SELECT MirrChk

			l_continue =NVL(MirrChk.EXP,.F.)

		ENDIF

		IF l_continue
			c_sql=" exec [dbo].[qc_UpdateMirrorAttyNewCaseQueue]  '" + pc_offcode + "','" + pc_litcode + "','" + ALLTRIM(pc_area)  + "','" + ;
				NVL(pc_rqatcod,'')  + "','" + c_clcode+"','"+;
				c_atcode+"','" + c_user + "','" + STR(n_mirror) + "','"  + ;
				lc_adjuster+"','"+;
				lc_insured+"','"+;
				lc_claim_no+"','"+;
				lc_file_no+"','"+;
				lc_ordered_by+"','"+ lc_AccDate + "'"

			OGEN.sqlexecute(c_sql,"")

&&& 2/5/14- copy ship methods from a mirrored case's setting for RQ atty
			IF USED("gtaship")
				SELECT gtaship
				USE
			ENDIF
			c_sql=" exec dbo.GetShipbyMirCaseAtcode '" +  STR(n_mirror)  + "','" + NVL(c_atcode,'')  + "'"
			OGEN.sqlexecute(c_sql,"gtaship")
*!*			&&& 2/5/14- copy ship methods from a mirrored case's setting for RQ atty
*!*

		ENDIF
	ENDIF
****12/12/12
ENDIF
c_sql=""
**ADD/EDIT SHIPMENT SETTING ON A CASE
SELECT gtaship
IF RECCOUNT("gtaship")>0 AND !EMPTY(c_idtblBills)
	c_sql=" exec [dbo].[InsertShipMethodRecord] '" + c_clcode+"','" + ;
		fixquote(c_atcode)+"','" +;
		NVL(IIF(gtaship.rpapernum > 0, "1", "0"),"0")+"',"+;
		"'"+NVL(IIF(gtaship.rcdnum > 0, "1","0"),"0")+"',"+;
		"'"+NVL(IIF(gtaship.rvsnum > 0, "1","0"),"0")+"',"+;
		"'"+NVL(IIF(gtaship.rdsnum > 0, "1","0"),"0")+"',"+;
		"'"+NVL(IIF(gtaship.rshipftp, "1","0"),"0")+"',"+;
		"'"+NVL(gtaship.rcdtype,'')+"',"+;
		"'"+NVL(gtaship.rdstype,'')+"',"+;
		"'"+NVL(gtaship.rftptype,'')+"',"+;
		NVL(STR(gtaship.rcdincrem),'0')+","+;
		"'"+NVL(gtaship.rcdfile,'')+"',"+;
		NVL(IIF(gtaship.rsinglepg,"1","0"),"0")+","+;
		"'"+NVL(IIF(gtaship.mpapernum > 0, "1", "0"),"0")+"',"+;
		"'"+NVL(IIF(gtaship.mcdnum > 0, "1", "0"),"0")+"',"+;
		"'"+NVL(IIF(gtaship.mvsnum > 0, "1", "0"),"0")+"',"+;
		"'"+NVL(IIF(gtaship.mdsnum > 0, "1", "0"),"0")+"',"+;
		"'"+NVL(IIF(gtaship.mshipftp, "1", "0"),"0")+"',"+;
		"'"+NVL(gtaship.mcdtype,"")+"',"+;
		"'"+NVL(gtaship.mdstype,"")+"',"+;
		"'"+NVL(gtaship.mftptype,"")+"',"+;
		NVL(STR(gtaship.mcdincrem),"0")+","+;
		"'"+NVL(gtaship.mcdfile,"")+"',"+;
		NVL(IIF(gtaship.msinglepg,"1","0"),"0")+","+;
		"'"+c_idtblBills+"','"+;
		c_user+"'"




	OGEN.sqlexecute(c_sql)
ENDIF
RELEASE OGEN
RETURN
