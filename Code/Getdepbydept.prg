
	*  03/18/2010  EF  -called from AIP
	*
	******************************************************************************
	PARAMETERS c_hospdept
	LOCAL n_dec as Integer, omedmail  as Object

	IF pl_Mailnew
		RETURN
	ENDIF
	omedmail = CREATEOBJ("generic.medgeneric")
	STORE "" TO pc_MAdd1, pc_MAdd2, pc_MailCity, pc_MailSt, ;
		pc_MailZip, pc_FaxSub, pc_FaxAuth, pc_GovtLoc, pc_MailFName, ;
		pc_MailLName, pc_RadDpt, pc_PathDpt, pc_EchoDpt, pc_EFaxSub, ;
		pc_EFaxAuth, pc_PFaxSub, pc_PFaxAuth, pc_RFaxSub, pc_RFaxAuth, ;
		pc_BFaxSub, pc_BFaxAuth, pc_MAttn, pc_BatchRq, pc_LocStatus
	STORE 0 TO pn_MailPhn, pn_MailFax, pn_RadFax, pn_PathFax, ;
		pn_EchFax, pn_BillFax
	STORE .F. TO pl_MailFax, pl_FaxOrig, pl_EFax, pl_EFaxOrg, ;
		pl_PFax, pl_PFaxOrg, pl_RFax, pl_RFaxOrg, pl_BfaxOrg, ;
		pl_CallOnly, pl_MCall, pl_BCall, pl_PCall, pl_RCall, ;
		pl_ECall, pl_SpecRpsSrv, pl_HandDlvr,pl_MailOrig, pl_Fee37
		


	pn_MailRec = RECNO()
	

	IF NOT EMPTY( alltrim(pc_MailID))
	
	IF FILE("DepoFile")
	SELECT DepoFile
	USE
	ENDIF
			
		omedmail.sqlexecute("exec dbo.GetDepInfoByMailIdDept '" + ALLTRIM(pc_MailID) + ;
				"','" + NVL(c_hospdept, "Z") + "' ", "DepoFile")

		SELECT DepoFile
		IF EOF()
		&&DEFAULT IF NO ADDRESS FOUND FOR A DEPT)
		omedmail.sqlexecute("exec dbo.GetDepInfoByMailIdDept '" + ALLTRIM(pc_MailID) + ;
				"','" + "Z" + "' ", "DepoFile")
		
		ENDIF
		SELECT DepoFile
		pc_MailDesc = NAME
		pc_MAdd1    = Add1
		pc_MAdd2    = Add2
		pc_MailCity = City
		pc_MailSt   = State
		pc_MailZip  = Zip
		n_dec=SET('DECIMALS')
		SET DECIMALS TO 0
		pn_MailPhn  = IIF(TYPE('Phone')='N',Phone,VAL(Phone))
		SET DECIMALS TO n_dec
		
		IF TYPE('c_hospdept')="U" OR TYPE('c_hospdept')="L" 
			c_hospdept='Z'
		ENDIF
		
		l_oK=omedmail.sqlexecute("SELECT dbo.GetRpsQueueNamebyDept ('" + pc_MailID + "','" + c_hospdept + "','" + pc_offcode +"')", "RpsQ")
		IF l_oK
		 
		 pl_SpecRpsSrv=NVL(RpsQ.exp,.F.)		
		 pc_BatchRq=IIF(pl_SpecRpsSrv,"RpsBatch"	,"")		 
		 
		 SELECT DepoFile
		ENDIF		
		
		pl_FaxOrig  = IIF(EMPTY(pc_BatchRq),FaxOrig,.f.)
		pc_FaxSub   = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
		pc_FaxAuth  = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")		
		pn_MailFax  = IIF(EMPTY(pc_BatchRq),Fax_no,0)
		pl_MailFax  = IIF(EMPTY(pc_BatchRq),Fax,.F.)
		IF TYPE ('pn_MailFax')="C"
		IF EMPTY(ALLTRIM(pn_MailFax )) &&5/13/2011 WE HAVE NO FAX AND LOCATONS MARKES AS ACCEPT FAX??? 
			pL_MailFax=.F.
		ENDIF			
		ENDIF
		IF TYPE ('pn_MailFax')="N"
		IF pn_MailFax =0&&5/13/2011 WE HAVE NO FAX AND LOCATONS MARKES AS ACCEPT FAX??? 
			pL_MailFax=.F.
		ENDIF			
		ENDIF
		
		pc_GovtLoc  = Govt
		pl_CallOnly = Callonly

		pc_MailLName = ""
		pc_MAttn     = ALLTRIM( attn)


		pc_RadDpt   = ""
		pc_PathDpt  = ""
		pc_EchoDpt  = ""
		pn_RadFax   = IIF(EMPTY(pc_BatchRq),Fax_no,0)
		pn_PathFax  = IIF(EMPTY(pc_BatchRq),Fax_no,0)
		pn_EchFax   = IIF(EMPTY(pc_BatchRq),Fax_no,0)
		pl_EFax     = IIF(EMPTY(pc_BatchRq),Fax,.F.)
		pl_EFaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
		pl_PFax     = IIF(EMPTY(pc_BatchRq),Fax,.F.)
		pl_PFaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
		pl_RFax     = IIF(EMPTY(pc_BatchRq),Fax,.F.)
		pl_RFaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
		pc_EFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
		pc_EFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
		pc_PFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
		pc_PFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
		pc_RFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
		pc_RFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
		pn_BillFax  = IIF(EMPTY(pc_BatchRq),Fax_no,0)
		pl_BfaxOrg  = IIF(EMPTY(pc_BatchRq),FaxOrig,.F.)
		pc_BFaxSub  = IIF(EMPTY(pc_BatchRq),Fax_Sub,"")
		pc_BFaxAuth = IIF(EMPTY(pc_BatchRq),Fax_Auth,"")
		pl_MCall    = Callonly
		pl_BCall    = Callonly
		pl_PCall    = Callonly
		pl_RCall    = Callonly
		pl_ECall    = Callonly
		pc_LocStatus =NVL(activeStatus, '')
		pl_HandDlvr= NVL(AskHandDelivery, .F.)
		&&03/03/14 - remove txn 37 for KOP subp with forms (per Liz)
		&& 11/27/12 Add WCAB (per Gina)
		&& 06/21/12 use it only for the KOP PA courts  (per Alec)
		pl_MailOrig= NVL(AskOrigSubp,.F.) and ("PA" $ pc_Court1 OR ALLTRIM(pc_Court1) ="PCCP" or ALLTRIM(pc_Court1) ="WCAB" ) and not Pl_reissue 

**03/13/2013- add txn37 for Orig and kopGeneric sub issues: "HoldPrint" Project.
		DO CASE
		*CASE pl_MailOrig
		*	pl_Fee37= .t.
		CASE  pc_RpsForm="KOPGeneric"
			pl_Fee37= .t.
		OTHERWISE
			pl_Fee37= .f.
		ENDCASE
		**03/13/2013- add txn37 for Orig and kopGeneric sub issues
		ENDIF &&& test cycle

	

	pl_Mailnew = .T.
	RELEASE omedmail
	RETURN


