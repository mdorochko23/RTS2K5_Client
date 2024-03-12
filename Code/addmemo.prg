
PARAMETERS c_typememo
Local l_Cancel as Boolean, lcMemo as String
lcMemo=""
l_Cancel=.f.
IF c_typememo = "R"
			    n_txn_code = 4
				c_descript = REQUEST.DESCRIPT
				c_cl_code = REQUEST.cl_code
				c_mailid_no = REQUEST.mailid_no
				n_tag = REQUEST.TAG
				c_Type=""
*!*				DO ReqMemo.spr
				c_Memo= "Transaction deleted by " + ;
					ALLTRIM(pc_UserID) + " on " + DTOC(DATE()) + "."	
					
			lcMemo= goApp.OpenForm("casedeponent.frmreqmemo",  ;
			"M", timesheet.id_tblrequests , timesheet.id_tblrequests, ;
			master.lrs_no, n_tag, c_descript, master.name_full )
			
				
					
endif					
         
IF NOT ISNULL(lcMemo)                
         
DO AddStcTxn WITH  ;
	c_DESCRIPT, c_cl_code, n_txn_code, n_tag, ;
	c_mailid_no, c_type, pc_UserID ,Timesheet.id_tblrequests, c_Memo+ " " + lcMemo, .t.

ELSE
	=gfmessage("The operation was canceled by user")
*--=MESSAGEBOX("The operation was canceled by user",64, "Delete Transaction")
l_Cancel=.t.
ENDIF

RETURN l_Cancel
		
	