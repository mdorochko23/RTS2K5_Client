*******************************************************************************
**08/16/2017- EF : TX Reissue
**03/21/2012 - EF : use the same USDC form for all KOP and CA office cases
**03/23/2010- Added Ava1 letter
**10/28/2009 - EF : Adapted from subp-pa.prg to work with the FollowUp request
******************************************************************************
Parameters l_pdffile, n_revnumber ,nworktag, c_depont
** l_pdffile=.t. when original pdf exists
** n_revnumber =1 when no orig is exists and =2 when an edited sec req is needed
Private issdate, lcCurArea, lnTxnId, lcType, lcStatus, lnNotcnt, ldWork, lc_Round, ;
	llhs_subp, lnAdd, lcSubType, l_FaxAllow, d_ChkDate, d_Compare, i, nrec, printed, onhold, lNotScan, l_Rpsjob
l_Rpsjob=.T.

If Type ("pnReqCheck")="U"
	Public  pnReqCheck
Endif
If Type ("pnReqFee")="U"
	Public pnReqFee
Endif
If Type ("llNotice")="U"
	Public llNotice
Endif
Private ldHandServe, llRPRSubp, llRPRAff, llReqAff, ;
	llRPAttch, lcReqType, db_Notice, ldTxnDate, l_got11, l_lstopissue,ldPropDte, c_curproc

LOCAL lc_DocName as string,lc_DocName2 as string, lc_Parse_Docname as string, LI_DOC_SEP as int		&& 9/23/2020, ZD #190778, JH.

Local omed3 As medtimesheet Of timesheet
omed3 = Createobject("medtimesheet")
mid= pc_mailid
MDEP=c_depont
If Used("timesheet")
	ntag = timesheet.Tag
Else
	ntag =nworktag
Endif
l_lstopissue=Iif( (pl_1st_Req And ifsupressreq(pc_clcode)),.T.,.F.)
l_Reprint=Iif(pl_1st_Req, .F.,.T.)
Store .F. To llProvider, pl_PrtOrigSubp
ldPropDte = d_today
If Not pl_1st_Req
	l_FaxAllow=.F.
Endif
lnNotcnt = 0                                    && Count of number of Notices to be sent out.
c_IssType=PC_ISSTYPE
creqType=c_IssType
l_autosub=.T.
l_rushdepo = pl_RushCas
onhold = .F.
ldDueDate = gdBlankDt
If Type( "gnHold") = "U"
	Public gnHold
Endif
If Type( "gnFrDays") = "U"
	Public gnFRDays
Endif
If Type( "gnIssDays") = "U"
	Public gnIssDays
Endif

If Not Used("Spec_ins")
	Wait Window "No special instruction data has been found."
	l_Rpsjob=.F.
	Return .F.
Endif
Select Spec_Ins
szrequest =Alltrim( Spec_Ins.Spec_Inst)
pc_CertTyp = Alltrim(Spec_Ins.cert_type)
If Empty(pc_CertTyp)
	pc_CertTyp="R"
Endif
cdept=Alltrim(Spec_Ins.dept)
szadd1=Alltrim(pc_depofile.add1)
szadd2=Alltrim(pc_depofile.add2)
szcity=Alltrim(pc_depofile.city)
szstate=Alltrim(pc_depofile.state)
szzip=Alltrim(pc_depofile.zip)
szattn = Alltrim(pc_depofile.Attn)
szcont = Alltrim(pc_depofile.Contact)
szcomm1 = Alltrim(pc_depofile.Comments)
Store "" To lcSubType, sQuest,c_bborder ,c_bbloc

local lbFileAvail

If pl_CAVer
	f_subpoena=Iif(pl_ofcPas,goApp.psdatapath,goApp.cadatapath)	+ "\Subpoena"
	f_decl=Iif(pl_ofcPas,goApp.psdatapath,goApp.cadatapath)	+ "\Decl"
	If Not Used('Subpoena')
       lbFileAvail = chkFileAvail(f_subpoena)		&& 9/22/2022, ZD #288190, JH
       if lbFileAvail
		  Use (f_subpoena) In 0 SHARED		&& 3/15/2022, zd #266961, JH
       else
		  wait window "Subpoena table could not be located."
		  l_Rpsjob=.F.
		  return .F.
       endif										&& 9/22
    ENDIF
	If Not Used('Decl')
		Use (f_decl) In 0
	Endif
	If Used("PSnotice")
		Select PSnotice
		Use
	Endif
	omed3.sqlexecute("Exec [dbo].[GetCANoticebyTag] '" + fixquote(timesheet.CL_code) + "','" + Str(nworktag) + "'", "PSnotice")
Endif
nspin = 0

If Not Used("timesheet")
	Wait Window "No timesheet data has been found."
	l_Rpsjob=.F.
	Return .F.
Endif

Select timesheet
* Print Cover Letter
If pc_Litcode='AV1'
	Set Memowidth To 126
Else
	Set Memowidth To 68
Endif


szEdtReq = gfAddCR( szrequest)

If Type ('ldTxnDate')="U"
	ldTxnDate = Iif( pl_1st_Req, d_today, Ctod(timesheet.Txn_date))
Endif

If pl_CAVer
	llReqAff = .T.                         && Assume that affidavit is required
	llRPRSubp = .T.                        && Assume that subpoena must be reprinted
	llRPRAff = .T.                         && Assume that affidavit must be reprinted
	llRPAttch = .F.                        && Assume no need to reattach affidavit
	lcReqType = ""
	lc_Round=""

	pl_HandSrv = PSnotice.HS_Notice
	ld_psdate =PSnotice.due_date
	Do Case
	Case Type('ld_psdate')="T"
		pd_Depsitn = Ttod(Nvl(PSnotice.due_date,''))
	Case Type('ld_psdate')="C"
		pd_Depsitn = Ctod(Nvl(PSnotice.due_date,''))
	Endcase

	ldHandServe =Iif(Left( Alltrim(pc_court1), 4) = "USDC",Ctod(PSnotice.Txn_date),getservd(Ctod(PSnotice.Txn_date) , pl_HandSrv )      )
**Find out the check's info 10/09/09
	lc_Round = Iif( (pc_rqatcod="BEBE  3C") And (pc_Litcode == "A  ") And Not Empty(pc_plbbASB), "RCD", "   ")
	If creqType = "S"
		If Used('Checks')
			Select Checks
			Use
		Endif
		If Not pl_1st_Req
			omed3.sqlexecute("Exec [dbo].[GetChecksforPDF] 'C','" + fixquote(timesheet.CL_code) + "','" + Str(nworktag) + "'", "Checks")
			pnReqCheck = 0
			pnReqFee = 0.00
			If Not Eof()
				pnReqCheck = check_no

			Endif
		ENDIF
		*-- 02/10/2021 MD #224406 added check for WCAB
		IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB"
			Do CAAutCov In SUBP_PA With lc_Round, szEdtReq, ldTxnDate, Iif(n_revnumber=1,.T.,.F.)
		ELSE 
			Do CACovLtr In SUBP_PA With lc_Round, pl_HandSrv, pnReqCheck, ldTxnDate, Iif(n_revnumber=1,.T.,.F.)
		ENDIF 
	Else

		Do CAAutCov In SUBP_PA With lc_Round, szEdtReq, ldTxnDate, Iif(n_revnumber=1,.T.,.F.)
	Endif
*****end ca office cover
Else

***MRC cover page 2/15/14 for follow ups that do not use stored pdf
	If pc_Litcode ='ZOL' And pl_MRCLetter
		Local MV_ZOL  As String, n_mrc As Number
		n_mrc= origmrctag(PC_LRSNO,nworktag)

		If n_mrc>0  &&AND NOT pl_ZOLMDL && only call for MRC tags  + 4/15/14: that are not MDL
			n_rtnum=pn_lrsno
			MV_ZOL =mrccover (n_rtnum, timesheet.Tag, timesheet.Descript)
			mv=mv+ MV_ZOL
		Endif
	Endif

*****start KOP office cover
	*-- 12/18/2019 #146658 MD added useHITechForm=.F. parameter	
	mv=kopreqcov2(PC_ISSTYPE, l_Reprint,ldTxnDate,.T., cdept, nworktag, c_depont, Iif(n_revnumber=1,.T.,.F.),.F.)
**************************************************************
	If PL_TXCOURT And Nvl(PC_ISSTYPE,'A')="S"
*08/16/2017 : Reissue needs an original tag's data-PN_SUPPTO
*08/09/2017 : MOVE IN FRONT OF A SUBP PAGE : -Notice and Deposition by Written Questions
		Do Txnot1 With Iif(PL_REISSUE And  PN_SUPPTO<>0 , PN_SUPPTO, ntag) , Alltrim(c_depont), Alltrim(mid)

	Endif
**************************************************************

Endif



lc_DocName=""

*lc_DocName = PrintLOR(creqType)				&& 9/23/2020, ZD #190778, JH.

    LC_PARSE_DOCNAME = PRINTLOR(CREQTYPE)			&& 9/23/2020, ZD #190778, JH.
    LI_DOC_SEP = AT('|',LC_PARSE_DOCNAME)
    IF LI_DOC_SEP > 0
	LC_DOCNAME = SUBSTR(LC_PARSE_DOCNAME,1,LI_DOC_SEP-1)
	LC_DOCNAME2 = SUBSTR(LC_PARSE_DOCNAME,LI_DOC_SEP+1,LEN(LC_PARSE_DOCNAME)-LI_DOC_SEP)
    ELSE
	LC_DOCNAME=LC_PARSE_DOCNAME
	LC_DOCNAME2=""	
    ENDIF							&& 9/23


printed = .F.

issdate =ldTxnDate
If Not l_pdffile
	If creqType == "S"
&& NJ-courts cases need scanned subpoenas ;
&& to be printed along WITH requests.
		If pl_scansub
			lNotScan = .F.

			Do pScnSubp In SUBP_PA
**10/04/2017 #70542 - added a rider  per Christine's H
			Do SUBPATTCH With MV, SZEDTREQ,  PN_TAG, c_depont

			If Not lNotScan
				Do OtherSub In SUBP_PA With Upper(Allt(timesheet.Descript))
			Endif
		ENDIF
*--------------------------------------------------------------	
* --- 03/30/2020 MD	#165570 remove CERTINST
*!*			If pl_MichCrt And pl_KOPVer And  !pl_ExclMI
*!*	&&EF 07/28/2017 - mi-wcab does not need an instruction page #66656
*!*				Do CertInst  In SUBP_PA
*!*			ENDIF
*--------------------------------------------------------------			
             * 04/04/2018 MD added 'AND pl_scansub'  to prevent print certs twice #83549
             * 04/13/2018 should use pl_noSform instead
             * check if scanned certs exist and print it later
        LOCAL foundScanCert
        foundScanCert=findcerts(.T.,nworktag)    
		If pl_KOPVer And Not pl_TxAbex And Not pl_ofcHous  AND foundScanCert=.F.
			If Not Empty( pc_CertTyp)
				If pl_autofax And Not pl_ofcHous
					If Ctod(Spec_Ins.Txn_date) >= {10/19/2000} And Not pl_noticng
						Do PrintCer With tag2req, b1streq, Spec_Ins.id_tblSpec_ins
					Endif
				Else

					If issdate>= {10/19/2000} And Not pl_noticng
						Do PrintCer With nworktag, b1streq, Spec_Ins.id_tblSpec_ins
					Endif
				Endif
			Endif
		Endif
**removed page from IL WCC package #56121
**11/16/2012 - Il-WCC paperwork
*!*			IF pl_KOPVer AND ALLTRIM(pc_court1)='IL-WCC'
*!*				DO ilwcpage1 WITH  MDEP, cdept, issdate
*!*			ENDIF

* This is a subpoena!!
		If Not pl_autofax Or Not l_courtset

			Set Procedure To ta_lib Additive
			Do SpinOpen With "Printing Subpoena!"

		Endif

		If  Type('l_SubBalt')="U"
			If ( pc_c1Name = "MD-BaltimoCity" And creqType="S") &&PL_1ST_REQ
				l_SubBalt=.T.
			Else
				l_SubBalt=.F.
			Endif
		Endif

		If Not pl_scansub  	                       &&not NJ courts

			If  l_SubBalt		  &&05/07/15 :  MD new Balt page:
				mv=mv+ PrtMdNot (Date(),timesheet.CL_code, timesheet.MAILID_NO, timesheet.Tag, timesheet.Descript)

			Endif &&  l_SubBalt	5/7/15: do not need kop certs
			Do thesubp In SUBP_PA


		ENDIF
*--------------------------------------------------------------	
* --- 03/30/2020 MD	#165570 remove MIProff
*!*	&&EF  MI proof of service page : print after a subpoena
*!*			If pl_MichCrt  And !pl_ExclMI
*!*	&&EF 07/28/2017 - mi-wcab does not need a proof page #66656
*!*				Do PrintGroup With mv, "MIProof"
*!*				Do PrintField With mv, "DepDate", Dtoc( d_today)

*!*				Do pDepInfo In SUBP_PA With mid, Proper( c_depont), .F.
*!*				Do PrintGroup With mv, "Case"
*!*				Do PrintField With mv, "Plaintiff", Allt(pc_plcaptn)
*!*				Do PrintField With mv, "Defendant", Allt(pc_dfcaptn)
*!*				Do PrintField With mv, "Docket", pc_docket
*!*			Endif
*--------------------------------------------------------------
		If issdate + gnHold > d_today
			onhold = .T.
		Endif

* Oakland subpoena tag specific documents


		If pl_ofcoaK And Not pl_scansub
			Do PSPECDOC  In SUBP_PA With 'C' && 4/3/14- Print 'case' level docs with the ca subp issues
			Do pScnSubp In SUBP_PA
		Endif

	Else

** Tabacco  Trust Lit cases
		If pl_TBTAstk And creqType = "A"
			Do  TobaccoPages In SUBP_PA
		Endif

&& spec.page for Motley/Lead-RI
		If pl_LeadMot And pl_KOPVer And Inlist(Upper(Alltrim(pc_area)),'LEAD-RI','LEAD-WI')
			Do NotaryIns In SUBP_PA
		Endif





* If needed, print a record certification document for the request
		If pl_autofax And Not pl_ofcoaK

			_Screen.MousePointer=11
			Do PrintCer With tag2req, b1streq, Spec_Ins.id_tblSpec_ins
			_Screen.MousePointer=0

		Else
			If pl_KOPVer And Not pl_TxAbex And Not pl_ofcHous
				If Not Empty( pc_CertTyp)
					If Type( "timesheet.Txn_date") ="C"
						issdate =Ctod(timesheet.Txn_date)
					Else
						issdate=Ctod(Left(Dtoc(timesheet.Txn_date),10))
					Endif

					If issdate>= {10/19/2000} And Not pl_noticng
						_Screen.MousePointer=11
						Do PrintCer With nworktag, b1streq, Spec_Ins.id_tblSpec_ins
						_Screen.MousePointer=0
					Endif
				Endif
			Endif
		Endif


		If Not pl_autofax
			Set Procedure To ta_lib Additive
*DO SpinOpen WITH "Printing Authorization"
		Endif
**05/16/2013 added A049631P-Babbitt LOR
**04/24/2013 - added lor for pl_Star
**3/25/2010 move the printing of teh LORs to after certifications per Julie
** LOR letters
**01/05/2010 added lor for A044203P
**12/21/2010 added LOR for all issues where 'A044119P' is a rq atty.
		pl_Garret= Iif(Nvl(pc_rqatcod,'')='A044119P' And creqType="A", .T.,.F.)
		pl_Nebltt=Iif(Nvl(pc_rqatcod,'')='A044203P' And creqType="A", .T.,.F.)
		pl_HRobins= Iif(Nvl(pc_rqatcod,'')="A045042P" And creqType="A", .T.,.F.)
		pl_McEwen =Iif(Nvl(pc_rqatcod,'')="A048214P" And creqType="A", .T.,.F.)
**8/4/15- removed per zendesk#13294 pl_Stark=IIF(NVL(pc_rqatcod,'')="A049299P" AND creqType="A", .T.,.F.)
		pl_BabLor =Iif(Nvl(pc_rqatcod,'')="A049631P" And creqType="A", .T.,.F.)


&&08/22/11 print bailey /srq rush letter
		If pl_BALsrq
			Do BalSrqRush In SUBP_PA
		Endif
** AVA/Plaintiff CourtOrder
		If pl_AVAPltf Or pl_AV1Fed
			Do getAvaPlOrder
		Endif
*** SRQ Preservation Letter -end
		If pc_Litcode='SRQ'
			Do SrqLetter  With c_depont, cdept, .F.
		Endif
*****06/14/2011 added Court Order for litigations avandia (ava) areas: Kirkendall and Heard Robbins
		If pl_AVACourtOrd
			Do AVACourtOrd In SUBP_PA
		Endif
**11/09/12**************
		If pl_AVAEwe
			Do AVAMcEwen In SUBP_PA
		Endif
******04/24/2013 - added lor for pl_Stark
*8/4/15- removed per zendesk#13294
*!*			IF pl_Stark
*!*				DO StarkLorPage	IN SUBP_PA
*!*			ENDIF

**09/08/2017 : added LOR to all cases in the Vehslage & Lahr's : F000020347

		If pl_VLahr And CREQTYPE="A"
			Do VLLor In Subp_pa
		Endif
**11/13/2017 #73000 :  LOR to the Firm Code F000020550 (Hamilton, Miller & Birthisel)
		If pl_Hamilt  And CREQTYPE="A"
			Do HMBLor In Subp_pa
		Endif



***02/12/14 ADDED MRC COURT ORDER
***05/12/14- MDL area  tags do not get a letter
		If pl_MRCLetter  And pc_Litcode ='ZOL'

			n_mrc=0  && 7/10/14- check if original mrc tag
			n_mrc= origmrctag(PC_LRSNO,nworktag)
			If  pl_ZOLMDL  And  n_mrc>0
				Do MRCLETTER   In SUBP_PA
			Endif
		Endif
******************************************************************************


		If pl_EclSpch &&1/4/07 - PRINT NOTICES FOR ECOLI CASES-START
			Do eclnotice With pc_platcod, pn_tag, (Iif(l_Fax2Req Or l_Fax1Req Or l_PrtFax,.T.,.F.))
		Endif


**3/23/2010- Ava1 letter'

		If pl_Ava1
			Do AV1Letter  With c_depont, cdept
		Endif
**3/23/2010 -end




** 09/25/2017 this LOR to all request issued with firm code F000020274.  Both autho and subpoena. #69833
		If pl_Vigorito
			Do VigorLor In Subp_pa
		Endif




**3/25/2010 move the printing of teh LORs to after certifications per Julie
		If creqType = "A"
			If pl_litAth2
				Do Case
				Case Upper( Allt( pc_pldeal)) == "A"
					Do lfAutho2 In SUBP_PA With "A"
				Case Upper( Allt( pc_pldeal)) == "B"
					Do lfAutho2 In SUBP_PA With "B"
				Endcase
			Endif

			If creqType <> "S" And (pl_ofcHous Or ;
					(pl_ofcKOP And pc_Litcode == "A  " And ;
					INLIST(Upper( Allt( pc_area)) , "TX_ABEX","TX_AFFIDAVIT") ) )

				Select Spec_Ins
				Scatter Memo Memvar
				cdept2 = Allt( m.dept)
				nrec = Len( cdept2)
				i_aff = 1
				Do While  .T.
					If i_aff > nrec
						Exit
					Endif
					cdept = Substr( cdept2, i_aff, 1)
					Do Case
					Case cdept = "E"
						szAffType = "ECHOCARDIOGRAM VIDEOS"
						TheInfo = "ECHO"
						szItem = "VIDEOS"

					Case cdept = "R"
						szAffType = "RADIOLOGY RECORDS"
						TheInfo = "RAD"
						szItem = "FILMS"

					Case cdept = "P"
						szAffType = "PATHOLOGY MATERIALS"
						TheInfo = "PATH"
						szItem = "SLIDES/BLOCKS"

					Case cdept = "B"
						szAffType =  "BILLING RECORDS"
						TheInfo = "BILLS"
						szItem = "PAGES"

					Case cdept = "M"
						szAffType = "MEDICAL RECORDS"
						TheInfo = "MED"
						szItem = "PAGES"

					Case cdept = "S"
						szAffType = "BUSINESS RECORDS"
						TheInfo = "S"
						szItem = "PAGES"

					Case cdept = "G"
						szAffType = ""
						TheInfo = "G"
						szItem = ""

					Otherwise
						szAffType = "RECORDS"
						TheInfo = "NR"
						szItem = "PAGES"
					Endcase
					i_aff = i_aff + 1

					Do PrintGroup With mv, ;
						IIF( cdept=="G", "TX_GenAff", "TX_Affid")
					If pl_autofax

						Select timesheet

					Endif
					Do PrintField With mv, "Attn", Allt( szAffType)
					Do PrintField With mv, "Items", Allt( szItem)
					Do PrintField With mv, "Tag", Str( timesheet.Tag)


					l_ST=omed3.sqlexecute("SELECT dbo.gfState('" + Iif(Empty(Alltrim(pc_depofile.state)),"TX",Alltrim(pc_depofile.state)) + "')", "DepSt")
					lc_State=Iif(l_ST,DepSt.Exp, "")
					lcPrtState = ""

					lcPrtState = Alltrim(Upper( lc_State))
					Do PrintField With mv, "DepState", lcPrtState

&&  court description to an aff. page

					If Not pl_ofcHous

						Select court
						If Seek(pc_court1)
							lcCrtDes = Allt( court.Desc)
							lncnt = At( ",", (Allt(lcCrtDes)), 1)
							If lncnt <> 0
								irest = Len( lcCrtDes)
								lcCrtpart1 = Left( ( Allt(lcCrtDes)), lncnt)
								lcCrtpart2 = Upper( Right( Allt( lcCrtDes), irest-(lncnt)))
							Endif

							Do PrintField With mv, "CourtOf", "" &&ALLT(UPPER(court.County))
							Do PrintField With mv, "County", ;
								IIF( lncnt <> 0, Allt( Upper( lcCrtpart1)), lcCrtDes)
							Do PrintField With mv, "CrtDesc", ;
								IIF( lncnt <> 0, lcCrtpart2, "")
						Endif
					Else
						Do gfTXCour  In SUBP_PA              && IN gftxcour WITH ALLTRIM( TAMaster.court)
					Endif

&&11/26/01 TX federal courts
					If Not pl_ofcHous
						mcounty = Allt( pc_plcnty)
						mDesc = Allt( pc_distrct)  + " DISTRICT"
					Endif

					Select timesheet


					Do PrintGroup With mv, "Case"
					Do PrintField With mv, "Plaintiff", Allt(pc_plcaptn)
					Do PrintField With mv, "Defendant", Allt(pc_dfcaptn)
					Do PrintField With mv, "Docket", pc_docket

					Do PrintGroup With mv, "PlCaption"
					Do PrintField With mv, "FirstName", pc_plnam
					Do PrintField With mv, "MidInitial", ""
					Do PrintField With mv, "LastName", ""

					Do PrintGroup With mv, "Deponent"
					sDname = Allt( Proper( c_depont))
					ncnt2 = At( "(", (Allt(sDname)), 1)
					If ncnt2 <> 0
						irest = Len( sDname)
						sDpart1 = Left( Proper( Allt(sDname)), ncnt2)
						sDpart2 = Upper( Right( Allt(sDname), irest-(ncnt2)))
						c_depont = Proper( sDpart1) + Proper( sDpart2)
					Endif
					Do PrintField With mv, "Name", c_depont
					Do PrintField With mv, "Addr", ;
						PROPER(Alltrim( pc_depofile.add1)) + ' ' + Proper(Alltrim( pc_depofile.add2 ))
					Do PrintField With mv, "City", Proper(Alltrim(pc_depofile.city))
					Do PrintField With mv, "State", Alltrim(pc_depofile.state)
					Do PrintField With mv, "Zip", Alltrim(pc_depofile.zip)
				Enddo                               && affnumb
			Endif



			If pn_LORpos = 1 And Not Empty( lc_DocName) && print a LOR before auth
				Do PrintGroup With mv, lc_DocName
				if not empty(LC_DOCNAME2)				&& 9/23/2020, ZD #190778, JH.
					Do PrintGroup With mv, lc_DocName2
				endif
			Endif



&& attach a letter 6/23/14
			If pl_ReiSSRI
				omed3.closealias("CMSLettr")
				c_sql= "select dbo.AttachReillyCMSLetter ('" + fixquote(timesheet.CL_code) + "','" + Str(nworktag)  + "','" + Dtoc(Date()) + "')"
				omed3.sqlexecute(c_sql, "CMSLettr")
				If Used("CMSLettr")
					If Nvl(CMSLettr.Exp,.F.)=.T. && attach a letter 6/23/14
						Do PrintGroup With mv, "ReillyCMS"
					Endif
				Endif
			Endif
&& attach a letter 6/23/14



			Do pScnAuth   In SUBP_PA                      && print Authos


			If issdate + Iif( llFromRev, gnFRDays, gnIssDays) > d_today
				onhold = .T.
			Endif


		Endif
	Endif

Endif
If pl_CAVer
	lFormExt = .F.
	If Used( "SUBPOENA")
		Select subpoena
		Use
	Endif
	Select 0
	Use (f_subpoena) Again Order cltag
	dbSubp = Alias()
	llDefault = .T.
	If Seek( pc_clcode + Str(nworktag))
		llDefault = .F.
		llNotice = subpoena.Notices
		lFormExt = subpoena.Extra
		Scatter Memo Memvar
	Endif
	d_txn11 = gfChkDat( fOrigIss(nworktag), .F., .F.)
	If Not l_pdffile
		Do Case
		Case Left( Alltrim(pc_court1), 4) = "USDC"
**03/01/2012 -call new page 3 of a usdc form
*DO CAUSDCP2 IN  SUBP_PA WITH d_txn11
**03/27/2012 - since the usd  set has now a copy of a pliantiff's notice we do not need to sent a proof and servive list (per Liz)
**10/24/2017 - added pos back #70800
			Do CAUSPoS In Subp_CA With d_txn11
			If Inlist( Spec_Ins.dept, "P", "R") And pl_ofcoaK &&EF 04/14/03
				Do CABrkDwn In  SUBP_PA With Spec_Ins.dept, nworktag, c_depont, mid
			Endif			
			*---- 04/10/2018 MD #78152, #83678 print scanned affidavits instead of programmed ones
			*--- Do CA_Affid In  SUBP_PA With .F.
			IF findcerts(.F.,nworktag)=.F.	   			
				Do CA_Affid In  SUBP_PA With .F.
			ENDIF 
			
			If creqType = "S"
				Do CAUSDCP2 In  SUBP_PA With d_txn11
			Endif
		Otherwise
*EF   Print Notice to Consumer if autho too.
			If creqType = "S"
				If llRPRSubp
					If lFormExt Or llDefault      && pc_SubpTyp="D"   for default & civil Duces Tecum= .T.
						*--- 12/18/2020 MD #213290
						*--If Not pl_plisrq           && Request from plaintiff's att						
						Do CAConNtc In Subp_CA With d_txn11, ;
							pl_HandSrv, pd_Depsitn, c_depont, mid
						Do CAConPOS In Subp_CA ;
							WITH d_txn11, pl_HandSrv, pd_Depsitn					
						*-- Endif *--- 12/18/2020 MD #213290
					Endif

					If Not llNotice And Not lFormExt && True for Notices and false for not notices

**8/3/09 split POS into two pages
**8/31/09 - only BB Gets new pages
						If Not pl_BBAsb
							Do CAPosNot In Subp_CA  With nworktag, pl_HandSrv, .F., .F., d_txn11
						Else
							Do CAPOSPage With nworktag, pl_HandSrv, .F., .F., d_txn11, "P"
							Do CAPOSPage With nworktag, pl_HandSrv, .F., .F., d_txn11, "D"

						Endif
					Else
						If llNotice And Not lFormExt Or Not llDefault &&pc_SubpTyp$"DP"
**8/3/09
**8/31/2009 only BB get two new pages
							If Not pl_BBAsb
								Do CAPosNot In Subp_CA 	With nworktag, pl_HandSrv, .F., .F., d_txn11
							Else
								Do CAPOSPage With nworktag, pl_HandSrv, .F., .F., d_txn11, "P"
								Do CAPOSPage With nworktag, pl_HandSrv, .F., .F., d_txn11, "D"

							Endif
						Else
							If Not llNotice And Not lFormExt
**8/3/09
&&8/31/09 only BB  gets new pages
								If Not pl_BBAsb

									Do CAPosNot In Subp_CA 	With nworktag, pl_HandSrv, .F., .F., d_txn11
								Else
									Do CAPOSPage With nworktag, pl_HandSrv, .F., .F., d_txn11, "P"
									Do CAPOSPage With nworktag, pl_HandSrv, .F., .F., d_txn11, "D"

								Endif &&8/31/09
							Endif
						Endif
					Endif
				Endif
			Endif                               &&dep.pers

* Personal appearance subpoenas do not need affidavit at all

			If pl_1st_Req
				If Inlist( pc_SubpTyp, "D", "W") And llRPRAff
					If Inlist( Spec_Ins.dept, "P", "R") And pl_ofcoaK &&04/14/03 EF
						Do CABrkDwn In SUBP_PA With Spec_Ins.dept, nworktag, c_depont, mid
					Endif					
					*---- 04/10/2018 MD #78152, #83678 print scanned affidavits instead of programmed ones
					*--- Do CA_Affid  In SUBP_PA With .T.
					IF findcerts(.F.,nworktag)=.F.	   			
						Do CA_Affid  In SUBP_PA With .T.
					ENDIF 
				Endif
			Else
				Select 0
				Use ( f_subpoena) Again Order cltag
				dbSubp = Alias()
				If Inlist( Spec_Ins.dept, "P", "R") And pl_ofcoaK &&EF 04/14/03
					Do CABrkDwn In SUBP_PA With Spec_Ins.dept, nworktag, c_depont, mid
				Endif

				Seek( pc_clcode + Str( nworktag))
				If Not Found() And llRPRAff
					
					*---- 04/10/2018 MD #78152, #83678 print scanned affidavits instead of programmed ones
					*--- Do CA_Affid In SUBP_PA With .F.
					IF findcerts(.F.,nworktag)=.F.	   			
						Do CA_Affid In SUBP_PA With .F.
					ENDIF 
&& reprint attachment- removed on 8/17/09 per Alec/Liz
*!*						IF llRPAttch
*!*							DO ReAttch WITH nworktag, c_depont, mid
*!*						ENDIF
				Endif
			Endif
**EF 08/30/05 - re-print affidavit

			If llRPRAff Or pl_1st_Req
				If pc_SubpTyp = "C" And lFormExt					
					*---- 04/10/2018 MD #78152, #83678 print scanned affidavits instead of programmed ones
					*--- Do CA_Affid In SUBP_PA With .F.
					IF findcerts(.F.,nworktag)=.F.	   			
						Do CA_Affid In SUBP_PA With .F.
					ENDIF 
				Endif
			Endif
			If creqType = "S" And lcSubType <> "W"
&&EF 06/12/02 DO NOT AUTOFAX LAST PAGE OF non-WCAB SUBPOENA
				If Not l_Fax2Req
					If Not pl_autofax             &&EF 06/26/02
						If llRPRSubp
							Do CAPosSub In SUBP_PA
						Endif
					Endif
				Endif                            && AUTOFAX SKIPS THIS PAGE
			Else
				If creqType = "S" And lcSubType = "W"
				*-- 02/10/2021 MD #224406 added CA WCAB call
					*-- gfmessage("No WCAB supoenas" )
					IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 
						DO SubWCAB IN Subp_CA WITH "1", szEdtReq,pd_Depsitn, nworktag, convertToDate(timesheet.Txn_date) && 03/29/2021 #232338 MD changed CTOD to convertToDate 													
					ENDIF 
				*-- 02/10/2021 MD #224406
				Endif
			ENDIF
			IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK AND creqType = "S"
				*-- 03/18/2021 MD #224406 second page
				DO SubWCAB IN Subp_CA WITH "2", szEdtReq, pd_Depsitn, ntag, convertToDate(timesheet.Txn_date) && 03/29/2021 #232338 MD changed CTOD to convertToDate 	
			ENDIF 
		Endcase
	Endif
**08/31/2009 CA
Endif

**08/31/2009 CA
If pl_PropNJ Or pl_PropPA Or pl_zicam
	onhold = Iif( pl_1st_Req, .T., .F.)
Endif



If pl_KOPVer And Not pl_scansub
**07/09/2013 DO NOT PRINT SCANNED SUBPS AS ALREADY DONE BY SUBPPRINT
	If Not l_pdffile
		If Not pl_noticng And Not Empty( creqType)
&&10/26/16- #51529: Non-Programmed Subp HAVE ITS OWN ORDER OF SCANED PAGES
			If !pl_noSform
				If CREQTYPE="S" And PL_TXCOURT
**skip && 09/25/2017- PRINT "s" TYPE AT OTHER SPOT AS THESE DOCS NEEDED AT THE BEGINING OF A SET
				Else

					Do PSPECDOC In SUBP_PA With creqType
				Endif
				Do PSPECDOC In SUBP_PA With "B"
			Endif

		Endif


&&pl_StopPrtIss
&&added Zofran to that rule #56641
		If pl_Chk4Img And creqType="A" And Not pl_StopPrtIss &&'ZOL'  4/2/14 addede pl_stopPrtIss: do not cancel but create 'NOPrint" instead
*IF pc_Litcode ='ZOL'  AND creqType="A" AND NOT pl_StopPrtIss &&'ZOL'  4/2/14 addede pl_stopPrtIss: do not cancel but create 'NOPrint" instead
			
			**09/12/2018, SL, Zendesk #104106
			*L_CANCEL =ValidAuth( PC_LRSNO, pn_tag, pl_UseBase)
			L_CANCEL =ValidAuth(pl_UseBase)
			If L_CANCEL
				mv=""
				l_Rpsjob=.F.
				Wait Window "No Request has been generated. Check for scanned images on that tag."
				Return .F.
			Endif
		Endif &&'ZOL'  2/4/14

		If pl_StDietD And creqType = "A"
			Do PrintGroup With mv, "Ackgment"
		ENDIF
		
		
	**12/12/2017"	 LOR to Firm Code F000004192 for all subpoena and autho tags. . #75224
		If pl_GRCorsi
			Do CorsiLor IN subp_pa
		Endif
	
		
**07/29/04 EF - prints a LOR page after auth/subps
		If Not pl_noticng
			If pn_LORpos=2 And Not Empty(lc_DocName)
				Do PrintGroup With mv, lc_DocName
				if not empty(LC_DOCNAME2)				&& 9/23/2020, ZD #190778, JH.
					Do PrintGroup With mv, lc_DocName2
				endif

				Do Case
				Case pl_WeldRod Or pl_HRTLor
					Do PrintField With mv, "CasePlaintiff", Alltrim( pc_plnam)
				Case pl_STDSed
					Do PrintField With mv, "CasePlaintiff", Alltrim( pc_plnam)
					Do pDepInfo In SUBP_PA With mid, Proper( c_depont), .F.
				Endcase
			Endif
**04/23/12 -WCAP page


			If (pl_wcabkop And creqType = "S" )
				Do WcabPage  In SUBP_PA
			Endif

		Endif

*********05/29/12- start print a hippa pages -the very last -after the special scanned paged
		If pl_Hipaa And Not pl_noticng And Not pl_ofcMD And creqType="S"
			Do AttHIPAA In SUBP_PA
		Endif
*******05/29/12 -end

&&05/07/2015 last page of the new MD request is a service page
		If ( pc_c1Name = "MD-BaltimoCity" And creqType="S" And Not pl_noticng)
			mv =mv + mdservice(	Iif( Type('issdate')="U", Date(), issdate),1)
		Endif
&&05/07/2015 last page of the new MD request is a service page



	Endif

Endif



Release printed, onhold

Do spinclose

Release omed3

Return l_Rpsjob
