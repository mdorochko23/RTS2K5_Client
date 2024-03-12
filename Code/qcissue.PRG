*********************************************************************************************
** Makes an issue from the QC forms: Web/excel/mf2 orders processing
*********************************************************************************************
*05/12/2021 added llIsDraft #237035
Parameters n_tag, c_type, c_depart, l_issuestc, c_medprovid, l_stopprtiss, c_txn19memo, scanDocsOnly, hiTech, tlIsDraft
Local l_releasej As boolean, l_qcstc As boolean,cMailid, c_Sql
Store .F. To l_fax2req,l_prt2req , l_canc2fax, pl_noticng, l_releasej, l_qcstc, pl_UpdHoldReqst
b1streq=1
pl_dupltag=.F.
n_supplem=0
Store .F. To pl_2ndque,l_releasej
ld_today=Date()
If Type( "mv")="U"
	Public mv
Endif
If Type( "mclass")="U"
	Public mclass
Endif
If Type( "mgroup")="U"
	Public mgroup
ENDIF
If Type( "mvScanDocsOnly")="U"
	Public mvScanDocsOnly
ENDIF

Store "" To mv, mclass, mvScanDocsOnly
o_mediss=Createobject("medmaster")
pc_isstype=c_type
pn_tag=n_tag

Create Cursor ifcancel (tblname Char(15),tblkey Char(36), action Char(1))

If Used("RECORD") &&Save a record pointer to delete if canceled
	Select ifcancel
	Do  doifcancel With "IfCancel","Record",Record.id_tbldeponents, "U"
Endif


********************************************************************************************************
l_releasej= issuefirst (  1, n_tag,c_type, c_depart, c_medprovid, scanDocsOnly, hiTech)
********************************************************************************************************
If Not l_releasej
	o_mediss.closealias('F2STC')
	o_mediss.sqlexecute("exec [dbo].[qc_ExtraTagSTCData] '" + Alltrim(pc_lrsno) + "','" + Str(n_tag) + "'", "F2STC")
	If Used('F2STC') And Not Eof()
		l_qcstc=.T.
	Endif
&&12/08/2014 -added effexor to zol
&&03/05/2014 -ZOL NEEDS STC
&&02/28/12 pl_StopPrtIss  REMOVED PER ALEC - FROM NOW ON SUPRESS PRINTING DOES NOT NEED STC
	If (l_issuestc And Not Empty(pc_f2stccat)) Or  (pl_ZOLEFF And !Empty( Alltrim(c_txn19memo)))
		IF tlIsDraft = .f. &&05/12/2021 added llIsDraft #237035
		** Call STC letter
		*--------------------------------------------------------------------------------------------------------
			o_mediss.closealias("record")
			o_mediss.sqlexecute(" exec dbo.GetPartialRequestInfo '" + fixquote(Alltrim(pc_clcode)) + "','" +Str(n_tag) +"'", "Record")
		*--------------------------------------------------------------------------------------------------------

			csql=""
			csql="exec [dbo].[STCAddNewTxn] '"+Alltrim(Record.cl_code)+"', "+Alltrim(Str(Record.Tag))+","+;
				"'"+Dtoc(Date())+"', '"+Alltrim(Upper(pc_f2stccat))+"', '"+fixquote(Alltrim(pc_f2stcblurb))+"',"+;
				"'"+Alltrim(Upper(goapp.currentuser.ntlogin))+"'"
			o_mediss.sqlexecute (csql,"stc30")
			If Used("stc30") And Not Eof()
				Store "" To csql, lcrogpages, lcgenpages
				csql="exec dbo.addSTCToQueueInit '"+Alltrim(stc30.id_tblcode30)+"', '"+fixquote(Alltrim(Record.cl_code))+;
					"', "+Alltrim(Str(Record.Tag))+", '"+Alltrim(stc30.id_tbltimesheet)+"', '"+;
					fixquote(Alltrim(goapp.currentuser.ntlogin))+"',"+;
					IIF(Empty(Alltrim(lcrogpages)),"NULL",Alltrim(Str(viewroglist.nid)))+", '"+Alltrim(lcrogpages)+"', '"+;
					ALLTRIM(lcgenpages)+"', '"+Alltrim(pc_f2stccat)+"'"
				o_mediss.sqlexecute (csql,"")
			Endif
		ENDIF &&05/12/2021 added llIsDraft #237035
*01/27/2012 - call new STC - add txn 30 and a record to the STC queue
*--------------------------------------------------------------------------------------------------------
	Endif

	If pc_offcode="P"&&KOP Only
		If Not Inlist( pc_platcod, "A14604P", "A14622P", "A14637P", ;
				"A14638P", "A14753P", "A16078P", "A16124P", "A16486P")
			If pl_prtnotc And Not pl_civsubp && 4/26/2011 wait till the end of the day to generate the KOP civil notices
				If Used('UserCtrl')
					Select userctrl
					c_ssnlst4=Right( userctrl.ssn, 4)
				Endif

				Do issuenotc With c_ssnlst4, ld_today
			Endif
		Endif
	Endif

**Add a  Confirmation Call*********************************************************************************************************
	Do addconfrmcall
**Add a  Confirmation Call*********************************************************************************************************

	=gfmessage("A request has been issued" + Iif( l_stopprtiss , ", but won't be printed.","." ))
Else
**07/21/2011 -ADDED A BACK TO QC BUTTON ON THE CHECK FOR DUPLICATE TAGS SCREEN- KEEP AN ISSUER IN THE QC
	If Not pl_backtoqc
		=gfmessage("An issue has been canceled. A job is not processed." )
	Endif
Endif
Return l_releasej
Release o_mediss
***********************************************************************************************************************************
Function issuefirst
Parameters   n_1streq, n_isstag,   c_isstype, c_hdept, c_medid, scanDocsOnly, hiTech
Local o_base As Object, ldtxndate As Datetime, c_blurb As String, lc_dist As String, n_jobseq As Integer, ;
	lcclcode As String,  lokdup As boolean, l_alreadyrush As boolean, c_entryid As String
*ON ERROR DO GET_ErrorSkip WITH ERROR(), 'QcIssue'
Private c_alias2 As String, c_tscode As String, omedqc As Object, l_origpdf As boolean, l_cancel As boolean, c_bborder As String, ;
	l_notiss As boolean, c_action As String, lnnotcnt As Integer, lncomply As Integer, dduedate As Datetime, duedate As Datetime, ;
	l_ptime As boolean

gdblankdt={  /  /    }
Store .F. To l_origpdf,l_cancel, l_notiss, l_supplem, l_cancel, pl_prtorigsubp
Store "" To  c_action, c_blurb, lc_dist, c_bborder
Store gdblankdt To dduedate, duedate , ldtxndate

Store 0 To lnnotcnt, lncomply
omedqc = Createobject("generic.medgeneric")

If PC_LITCODE='AV1' && spec processing of the wider blurbs
	Set Memowidth To 126
Else
	Set Memowidth To 68
Endif

*****RESET TO PREISSUE********************************************************************
If n_1streq=1
	c_action =Iif( c_isstype="S","7","8")
	c_action =isisstype( c_action, pn_req_by)
	c_isstype =Iif(c_action="7","S","A")
	pc_isstype=c_isstype
*----------------------------------------------------------------------
	If Empty(Alltrim(c_action))
		l_cancel=.T.
		l_notiss= updpreiss("1", Alltrim(Record.Descript), Record.cl_code, Record.Tag, pc_userid)
		If Not l_notiss
			gfmessage("Cannot Cancel. Contact IT dept.")
		Endif

		Return .T.
	Endif
Endif
If chkamsignature() =.F.
	gfmessage("Cannot Issue, an account manager does not have a scanned signature stored in the files. Either contact IT dept or edit a case to have another Account Manager.")
	Return .T.
Endif


*******RESET TO PREISSUE*******************************************************************
If Type( "gnHold") = "U"
	Public gnhold
Endif
If Type( "gnFrDays") = "U"
	Public gnfrdays
Endif
If Type( "gnIssDays") = "U"
	Public gnissdays
Endif

&&01/13/2012 -KEEP RUSH FROM THE TAG LEVEL
l_alreadyrush=.F.
l_alreadyrush =pl_rushcas

pl_gotcase=.F.
Do gfgetcas

pl_rushcas=l_alreadyrush
&&01/13/2012 -KEEP RUSH FROM THE TAG LEVEL

gnhold = Iif( pl_nohold, 0, pn_c1hold)
haveform = pl_c1form
Store "" To lcround	,c_bbloc, c_civadd1, c_civadd2, c_oldrca, c_newrca, lc_court
lc_court = pc_court1
lc_court= chkcourt(lc_court)
If Upper(Alltrim(lc_court))<>Upper(Alltrim(pc_court1))
** re-assign a right court to a public variable here 11/14/2011
	pc_court1=lc_court
Endif

****11/20/14- None    and  Not in Suit  cannor be used for Subp Issues -stope here
If Inlist( Alltrim(Upper(lc_court)), 'NONE', 'NOT IN SUIT')  And c_action = "7"
	gfmessage("Invalid Court. Cannot be used for a subpoena issue.")
	Return .T.
Endif
****11/20/14- None    and  Not in Suit  cannor be used for Subp Issues -stope here


** re-assign a right court to a public variable here 11/14/2011
mgroup = "1"
bnotcall=.F.
mcounty = pc_c1cnty
mcourt = pc_court1
mcourt2 = pc_court2
gnfrdays = pn_litfday
gnissdays = pn_litiday
llfromrev = Iif(pl_fromrev, pl_fromrev,Iif (gnfrdays<>0, .T.,.F.))

curproc = Set("proc")
Set Procedure To ta_lib Additive
lcpdist = ""
lcpdiv = ""
lncomply=0

If c_action = "7"                              && Subpoena
	l_cancel =chkcaptions()
	Local l_cancel2 As boolean, l_cancel3 As boolean
	l_cancel2=.F.
	l_cancel2=	pldef1at	(Record.cl_code)
	l_cancel3=.F.
	IF NOT PL_REISSUE	&& 3/13/19 YS Allow the tag to be issued for reissue when all the plaintiff attys are being inhibited #129185
		l_cancel3=	plnonotice(Record.cl_code)	&& 1/9/2019 YS Checking for plaintiff attys being inhibited #121772
	ENDIF
**05./02/2012 - check for 1 plaintiff and 1 defense atty in a case
	If l_cancel Or l_cancel2 OR l_cancel3
		l_notiss= updpreiss("2", Alltrim(Record.Descript), Record.cl_code, Record.Tag, Alltrim(pc_userid))
		If Not l_notiss
			gfmessage("Cannot Cancel. Contact IT dept.")
		Endif
		Return .T.
	Endif
Else
	If Not nonotice( pc_area, PC_LITCODE, pc_court1, c_action, .F.)
		l_cancel= chkcaptions()
		If l_cancel
			l_notiss= updpreiss("3", Alltrim(Record.Descript), Record.cl_code, Record.Tag, Alltrim(pc_userid))
			If Not l_notiss
				gfmessage("Cannot Cancel. Contact IT dept.")
			Endif
			Return .T.
		Endif
	Endif
Endif

&&EDITABLE TXN11 LINE
c_dep =pc_qctxn11


**05/11/2011- check for duplicate tags
lokdup=.F.  && ok if a dupilcate, continue to issue
lcclcode=pc_clcode
lokdup= shwduptag (lcclcode, c_dep, Master.id_tblmaster, Record.id_tblrequests)
If lokdup
	Return .T.
Endif

** TO MATCH WITH OLD PROGRAMS HAVE TO ASSING THE MID variable
mid=pc_mailid
pl_2ndque = .F.
c_pltreq = .F.

&&&&Blurb -----------------------------------------------------------------------------------------------------
c_blurb=fixquote(pcpublicblurb)
&&&&Blurb -----------------------------------------------------------------------------------------------------



If pc_offcode="P"&&KOP Only

	If Left( Alltrim(pc_court1), 4) = "USDC" And c_isstype="S" && Add DISTRICT selection to the USDC subpoena issues
*!*			gfmessage("Please pick a District for an issue." )
*!*			lc_dist=districtlist()
*!*			lc_dist=IIF(UPPER(ALLTRIM(lc_dist))="NONE","",lc_dist) &&05/19/2010 STORE "" FOR NONE
*!*			IF NOT EMPTY(ALLTRIM(lc_dist)) AND TYPE("pc_tagdist")="C"
*!*				pc_tagdist= lc_dist
*!*				IF  USED('record')
*!*					REPLACE district WITH lc_dist IN RECORD
*!*				ENDIF
*!*				IF  USED('Request')
*!*					REPLACE district WITH lc_dist IN REQUEST
*!*				ENDIF
*!*			ENDIF
**01/21/2015- use case's level DISTRICT data on all USDC tags
		If  Type("pc_distrct")="C" And !Empty(Alltrim(pc_distrct))

			pc_tagdist=pc_distrct
			If  Used('record')
				Replace district With pc_distrct In Record
			Endif
			If  Used('Request')
				Replace district With pc_distrct In Request
			Endif
		Endif
	Endif




	If Not pl_reissue And Not nonotice( pc_area, PC_LITCODE, pc_court1, c_action, .F.)
		lnnotcnt = gfdefcnt( .T.)
	Endif

	l_supplem = .F.
*!*		 removed on 3/8/12 per Alec's request :
*!*		IF INLIST(pc_Litcode,"2  ","EVR","RPD");
*!*				OR (pc_litcode='DGT' AND pc_area="Tucker")

*!*			l_new4scr=.F.
*!*			 DO lpgetsup IN subp_pa
*!*		ENDIF

	lncomply = Iif( pn_c1cmply>0, gnhold + pn_c1cmply, 10) 

	*11/17/2021 WY #255663 (hijack lncomply replace with tblcourt.financialHold)
	*lncomply could be tblcourt.comply + tblcourt.hold or tblcourt.financialHold  
	IF IsPureTx(pc_Court1) AND c_isstype ="S"
*!*			LOCAL lnTxFinHold
*!*			lnTxFinHold = GetFinancialHold(pn_lrsno, n_tag, pc_Court1)
*!*			IF lnTxFinHold <> 0
*!*				*APPLY TX FINANCIAL SETTINGS 
*!*				lncomply = lnTxFinHold 
*!*				pn_c1Cmply = lnTxFinHold && for txnot1.prg chardays
*!*				gnHold = 0 && for iif below (hold is for comply NOT TX financial)  
*!*			ENDIF 
		*255675 WY 12/19/2021 apply tx hold days from frmIssue1 grid
		LOCAL lnTxHoldVar
		lnTxHoldVar = GetTxHoldDays (pn_lrsno, n_tag, pc_Court1)
		IF lnTxHoldVar <> 0
			lncomply = lnTxHoldVar 
			pn_c1Cmply = lnTxHoldVar && for txnot1.prg chardays
			gnHold = 0 && for iif below (hold is for comply NOT TX financial)  
		ENDIF 

	ENDIF 
	
	lncomply = Iif( pl_proppa Or pl_propnj, 0, lncomply)
	ldbusonly = d_today
	If pl_michcrt
		ldbusonly = miduedat( d_today + 1)
	Endif
	If c_isstype = "A"
		For i = 0 To 13
			ldbusonly = ldbusonly + 1
			ldbusonly = gfchkdat( ldbusonly, .F., .F.)
		Next
	Endif
**** due date calculations************************************************************


**#49176 use 18 calendar days for Il-Cook
	*-- 08/17/2021 MD #245094 rmove business days check. !!use calendar days only!!
	*--l_usebussdays=Iif(pl_proppa Or pl_propnj Or pl_michcrt , .T.,.F.)
	l_usebussdays=.F.
	*-- 08/17/2021
	
	dduedate = Iif(l_usebussdays, ldbusonly, d_today) + ;
		IIF( gnhold=0, Iif( pl_michcrt, 0, lncomply), gnhold)

	If c_isstype = "A" And ( pl_dietdrg Or pl_mdlhold)
		dduedate = d_today + 15
	Endif

	If llfromrev And pl_ddrug2 And c_isstype = "A"
		dduedate = d_today + 10
	Endif

	dduedate = gfchkdat( dduedate, .F., .F.)

	If pl_reissue
		mdate = d_today
		duedate = d_today + 10
		dduedate = d_today + 10
	Endif
	pd_depsitn=dduedate
Endif &&& KOP only
***********************************************************************************************************************
***CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA
***********************************************************************************************************************
If pc_offcode="C"&&CA Only

	pl_skipbatchprt=.T. && RPS Batch - skip this RPS for the CA issues
	f_subpoena=Iif(pl_ofcpas,goapp.psdatapath,goapp.cadatapath)	+ "\Subpoena"
	f_decl=Iif(pl_ofcpas,goapp.psdatapath,goapp.cadatapath)	+ "\Decl"
	If Not Used('Subpoena')
		Use (f_subpoena) In 0
	Endif
	If Not Used('Decl')
		Use (f_decl) In 0
	Endif

	ldhandserve =Iif(pc_court1 = "USDC", d_today,getservd(d_today, pl_handsrv )     )
	pd_casrvdt=ldhandserve
	If c_type='A' Or Dtoc(pd_depsitn)="  /  /  "
        * ------04/04/2018 MD #77675	    
	    *pd_depsitn =gfchkdat(ldhandserve +15, .F.,.F.)	    
		IF Left( Alltrim(PC_COURT1), 4) == "USDC"
			pd_depsitn =gfchkdat(ldhandserve +20, .F.,.F.)	 
		ELSE
			*-- 03/13/2019 MD #126908
		    *pd_depsitn =gfchkdat(ldhandserve +15, .F.,.F.)	 
		    *-- 04/08/2019 MD ##126908 added check for handserv
		    IF pl_handsrv
			    pd_depsitn =gfchkdat(ldhandserve +15, .F.,.F.)	
			ELSE
			   pd_depsitn =gfchkdat(ldhandserve +16, .F.,.F.)	
			ENDIF 
		ENDIF 
		*------------------------------
**06/27/2012 - allow to pick it through QC main for the Subpoena

	Endif
	pl_prntnot = .T.                          && Print notice?
	pc_subptyp = "D - Default Subpoena"       && Subpoena format to be used
	c_bborder = pc_bbwebno              && Berry & Berry Web order Number
	lcq_round = "RCD"
	lcsubtype = pc_subptyp
	llhs_notice = pl_handsrv
	lddepdate = pd_depsitn
	ldhandserve=pd_casrvdt

	If (pc_rqatcod="BEBE  3C") And 	(PC_LITCODE == "A  ")
		lcround = "RCD" &&ALLTRIM(pc_plbbASB) + "." + pc_BBRound
	Endif
	If Empty( pc_mailnam)
		pc_mailnam=getcasigner(d_today,pc_offcode)
	Endif
	If Empty( pc_servnam)
		pc_servnam=getcadeliv(pc_offcode,d_today,pc_clcode)
	Endif
	lnnotcnt = gfdefcnt( .T.)
Endif

&&CA Only ---end **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA **CA---end

************************BOTH OFFICES************************************************************************************************
**Get a Mail Date for the Hold Requests
If Not pl_reissue
	If Not Used('HoldRulz')
*ln_holdrulz =omedqc.sqlexecute("exec DBO.GetHoldRulz", "Holdrulz")
**#51529 - removed litigation rules for "S" when calculating a hold and comply
		ln_holdrulz= HoldRulzA()
*ln_holdrulz =omedqc.sqlexecute("exec DBO.GetHoldRulzAOnly", "Holdrulz")
		If !ln_holdrulz
*!*				=CURSORSETPROP("KeyFieldList", "Office, Litigation", "HoldRulz")
*!*				INDEX ON office+ALLTRIM(litigation) FOR ACTIVE TAG offlit ADDITIVE
*!*				INDEX ON office+ALLTRIM(litigation) FOR isstype="A" TAG TYPEA ADDITIVE

*!*			ELSE
			gfmessage("No HoldRulz data. See IT.")
			Return .T.
		Endif
	Endif



************************
	If ( pc_isstype='A'  And pl_RisPCCP )
		gnhold=1
	Endif
*********************

	If gnhold=0
		ld_hdays =d_today
	Else
		ld_hdays = gf_hrule( d_today, c_isstype)
	Endif

	d_maildate= ld_hdays
Else
	d_maildate=d_today
Endif

**06/12/12 -ADD TXN19 -CLIENT MEMO
l_lstopissue=.F.
l_lstopissue= Iif(Empty(Alltrim(c_txn19memo)) , .F.,.T.)
If l_lstopissue And Not l_stopprtiss
	l_stopprtiss=l_lstopissue
Endif
**06/12/12- END

pl_rushcas=l_alreadyrush
If (Not pl_stopprtiss) And (Not l_lstopissue)
	Do Case
	Case pl_mailfax
		l_prt1req = .F.
		l_fax1req=.T.
		l_prtfax  =.F.
	Otherwise
		l_prt1req = .T.
		l_fax1req=.F.
		l_prtfax  =.F.
	Endcase
Else
&&SUPRESS- ONLY GENERATE pdf- SEND TO 'NOPRINT' QUEUE
	l_prt1req = .T.
	l_fax1req=.F.
	l_prtfax  =.F.

Endif


***Fax or Mail a Request (Supress here too)
*-- 2/26/19 YS Moved "BASE DOCS" code under "ADD SPEC INST" for the problem with "request language" stamp at the time of issue #122235
*!*	*************************************************** BASE DOCS *************************************


*!*	If Type('creqType')<>'C'
*!*		creqtype=pc_isstype
*!*	Endif

*!*	If Empty(Alltrim(c_txn19memo))  &&3/5/14- do not look at images when we have txn 19
*!*	&&skip base image selection when we have supresss printing in QC 1/25/17 #56993 l_stopprtiss

*!*	&&#56993 - Do not show BASE Selection if STC or Supress is picked
*!*		Local l_stopBase As boolean
*!*		l_stopBase =Iif(l_stopprtiss  Or l_issuestc, .T.,.F.)

*!*		**12/03/18, SL, #120367
*!*		If pl_usebase And !l_stopBase AND ALLTRIM(pc_AuthType) != "P"

*!*			Store "" To c_parameter,c_direct,c_storedb
*!*			omedqc.sqlexecute(" Exec [dbo].[qc_GetBaseImgFolder] '" + Alltrim(pc_lrsno)+ "','" +Str(n_isstag) + "'","ExtraTag")
*!*			c_direct="#"
*!*			If Used('ExtraTag')
*!*				c_storedb=Nvl(extratag.baseimgfolder,'')
*!*				c_direct=qcbasefile(Alltrim(pc_lrsno),c_storedb)

*!*			Endif
*!*	*----------------------------------------------------------
*!*	* 08/16/2016 - MD #46927
*!*			Local llBaseSelected
*!*			llBaseSelected=.F.
*!*			If Empty(Alltrim(Nvl(c_direct,"")))
*!*				C_CURDBF=Select()
*!*				Wait Window "Display a selection of the available base documents" Nowait
*!*				o_base=Createobject('request.frmselectbasedocs')
*!*				o_base.Show
*!*				Select  base_categ
*!*				Scan
*!*					If Alltrim(base_categ.c_select)=='Y'
*!*						llBaseSelected =.T.
*!*						Exit
*!*					Endif
*!*				Endscan
*!*				If Not Empty(C_CURDBF)
*!*					Select (C_CURDBF)
*!*				Endif
*!*				o_base.Release
*!*				If llBaseSelected =.F.
*!*					O_MESSAGE = Createobject('rts_message_yes_no',"No base image selected. Do you want to select a base? Choose yes to select or no to cancel the tags issue.")
*!*					O_MESSAGE.Show
*!*					L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
*!*					O_MESSAGE.Release
*!*					If L_CONFIRM
*!*						C_CURDBF=Select()
*!*						Wait Window "Display a selection of the available base documents" Nowait
*!*						o_base=Createobject('request.frmselectbasedocs')
*!*						o_base.Show
*!*						Select  base_categ
*!*						Scan
*!*							If Alltrim(base_categ.c_select)=='Y'
*!*								llBaseSelected =.T.
*!*								Exit
*!*							Endif
*!*						Endscan
*!*						If Not Empty(C_CURDBF)
*!*							Select (C_CURDBF)
*!*						Endif
*!*						o_base.Release
*!*						If llBaseSelected =.F.
*!*							l_cancel=.T.
*!*							Return l_cancel
*!*						Endif
*!*					Else
*!*						l_cancel=.T.
*!*						Return l_cancel
*!*					Endif
*!*				Endif
*!*			Else
*!*	*----------------------------------------------------------
*!*	******07/05/2016: #38672 - stop using tifauto- use burnbase instead

*!*				cMailid = Alltrim(Nvl(pc_mailid,""))
*!*				cMailid = Iif( Empty(cMailid),"X",cMailid)

*!*				c_parameter=Alltrim(pc_lrsno)+' '+Alltrim(Str(n_isstag))+' '+c_isstype+' '+Alltrim(cMailid)+ ;
*!*					' '+Alltrim(c_direct)+ ' X X X' +Iif(pl_ofcoak,' C',' P')

*!*				nJobRt = pn_lrsno
*!*				nJobTag = n_isstag
*!*				cJobmailid = gfstrclean(cMailid)
*!*				bProcessed = .F.
*!*				cNewDoc = ""
*!*				cError = ""
*!*				Do call_burnbase With nJobRt,nJobTag,cJobmailid,Nvl(c_isstype,"#"), Nvl( c_direct,"#"),Iif(pl_ofcoak,'C','P'),Alltrim(goapp.currentuser.orec.login) ,c_parameter,bProcessed,cNewDoc,cError
*!*			Endif


*!*		Endif

*!*	Endif &&3/5/14- do not look at images when we have txn 19
*!*	*************************************************** BASE DOCS *************************************

*************************************************** ADD TXN11 *************************************

l_txn11=.F.
*****************************************************************************************************************************

If Used("Record")
	Select Record
	Use
Endif
omedqc.sqlexecute("exec dbo.GetPartialRequestInfo '"+ fixquote(Alltrim(pc_clcode)) + "','" +Str(n_isstag)+ "'", "Record")

If  Empty(Nvl(pc_mailid,""))
	l_cancel=.T.
	Return l_cancel
Endif
c_entryid=""
&&09/25/2017 - Check  DWQ from the MF2
&&TX dwq #60359 -store with txn 11/19
c_quest=""

If Empty(Nvl(PC_TXQUEST,'') ) AND  pl_txcourt
	omedqc.closealias ('TxDWQ')
	omedqc.sqlexecute("exec [dbo].[GetMF2_TXDWQ] '" + fixquote(Alltrim(pc_clcode)) + "','" +Str(n_isstag)+ "'", "TxDWQ")

	If Used('TxDWQ')
		Select TxDWQ
		If Reccount("TxDWQ")>0
			c_quest=ALLTRIM(Nvl(TxDWQ.char_fld,''))
		Endif
	Endif


Else

	c_quest =Iif(pl_txcourt And  c_isstype ="S",Alltrim(Nvl(PC_TXQUEST,'')),"")
Endif


c_str= "Exec dbo.gfAddTxn '" + Dtoc(Date())+  " ', '" ;
	+ Alltrim(Nvl(fixquote(c_dep)  ,"")) +  "','" + fixquote(pc_clcode) + "',' " ;
	+ Iif( l_lstopissue,Alltrim(Str(19)),Alltrim(Str(11))) + "','"  + Alltrim(Str(n_isstag)) + "','" ;
	+ Nvl(Alltrim(pc_mailid),"") + "','" + Str(0) + "','" ;
	+ Alltrim(Str(lnnotcnt )) + "','" +  "" + "','" ;
	+ Alltrim(Str(0)) + "', '"  + c_quest + "','" ;
	+ c_isstype + "','" ;
	+ Alltrim(pc_userid) + "','" ;
	+ Record.id_tblrequests +"'"

l_txn11=omedqc.sqlexecute(c_str,"")
If Used('EntryID')
	Select entryid
	Use
Endif

l_entryid= omedqc.sqlexecute("select dbo.fn_GetID_tblTimesheet ('" + fixquote(pc_clcode) + "','" ;
	+ Str(n_isstag) +"','" + Iif( l_lstopissue, Str(19), Str(11))+ "','" +Dtoc(Date()) +"')", "EntryId")


If l_entryid
	Select entryid
	c_entryid=entryid.Exp
Endif

Do  doifcancel With "IfCancel","tblTimesheet","", "D"

**06/12/12- ADD TXN19 -MEMO IS ADDED HERE
If l_lstopissue
	Select 0
	l_ret=.T.
	l_ret=memotxn("O",.F.)
	If  Not l_ret
		Return .T. &&CANCEL AS A MEMO WAS CANCELED
	Endif

Endif


**07/09/2021 WY 240165 (QUESTION NO LONGER NEEDED USER ALWAYS SELECT NO)
*!*	** add txn 37: 6.23.15 for wcab subpoenas
*!*	If (PL_WCABKOP And c_isstype= "S" )
*!*		L_CONFIRM=.F.
*!*		LC_MSSG = "Do you want to add Original Subpoena Preparation Fee (txn 37)?"
*!*		O_MSSG = Createobject('rts_message_yes_no',LC_MSSG)
*!*		O_MSSG.Show
*!*		L_CONFIRM=Iif(O_MSSG.EXIT_MODE="YES",.T.,.F.)
*!*		O_MSSG.Release
*!*		PL_FEE37 =L_CONFIRM

*!*	Endif
** add txn 37: 6.2915

**03/13/2013 add txn37 for orig sub requests : "HoldPrint" Project.
If   l_entryid And Not  l_lstopissue And (PL_FEE37 And c_isstype="S")
	c_str=""

	c_str= "Exec dbo.gfAddTxn4 '" + Dtoc(Date())+  " ', '" ;
		+ Alltrim(Nvl(fixquote(c_dep)  ,"")) +  "','" + fixquote(pc_clcode) + "',' " ;
		+ Alltrim(Str(37)) + "','"  + Alltrim(Str(n_isstag)) + "','" ;
		+ Nvl(Alltrim(pc_mailid),"") + "','" + Str(0) + "','" ;
		+ Alltrim(Str(0)) + "','" +  "" + "','" ;
		+ Alltrim(Str(0)) + "', '"  + "" + "','" ;
		+ c_isstype+ "','" ;
		+ Alltrim(pc_userid) + "','" ;
		+ Record.id_tblrequests + "','',10"



	l_txn37=omedqc.sqlexecute(c_str,"txn37")
Endif
**03/13/2013 add txn37 for orig sub requests

*************************************************** ADD SPEC INST *************************************
If l_entryid
	l_specid=.F.
	l_specid=addspec_ins( c_entryid, pc_clcode, n_isstag, c_dep, c_isstype, pc_mailid, c_hdept,c_blurb)
	If Not l_specid
		gfmessage("No record has been added to the tblSpec_ins")
		l_cancel=.T.
	Else
		Do  doifcancel With "IfCancel","tblSpec_Ins","", "D"
	Endif
Endif

*-- 2/26/19 YS Moved "BASE DOCS" code under "ADD SPEC INST" for the problem with "request language" stamp at the time of issue #122235
*************************************************** BASE DOCS *************************************

If Type('creqType')<>'C'
	creqtype=pc_isstype
Endif
If Empty(Alltrim(c_txn19memo))  &&3/5/14- do not look at images when we have txn 19
&&skip base image selection when we have supresss printing in QC 1/25/17 #56993 l_stopprtiss

&&#56993 - Do not show BASE Selection if STC or Supress is picked
	Local l_stopBase As boolean
	l_stopBase =Iif(l_stopprtiss  Or l_issuestc, .T.,.F.)

	&&--- **12/03/18, SL, #120367
	&&--- If pl_usebase And !l_stopBase AND ALLTRIM(pc_AuthType) != "P"
	&&--- 05/08/2019 MD #133220 call burn_base for STC or noPrint issues
	
	&&--- If pl_usebase AND ALLTRIM(pc_AuthType) != "P"
	&&--- 09/20/2019 MD #143475 do not force TO CALL BURN_BASE for Autho None (A) and Autho Specific (P)
	
	If pl_usebase AND !INLIST(ALLTRIM(UPPER(pc_AuthType)),"P" , "A")
		Store "" To c_parameter,c_direct,c_storedb
		omedqc.sqlexecute(" Exec [dbo].[qc_GetBaseImgFolder] '" + Alltrim(pc_lrsno)+ "','" +Str(n_isstag) + "'","ExtraTag")
		c_direct="#"
		If Used('ExtraTag')
			c_storedb=Nvl(extratag.baseimgfolder,'')
			c_direct=qcbasefile(Alltrim(pc_lrsno),c_storedb)

		Endif
*----------------------------------------------------------
* 08/16/2016 - MD #46927
		Local llBaseSelected
		llBaseSelected=.F.
		If Empty(Alltrim(Nvl(c_direct,"")))
			C_CURDBF=Select()
			Wait Window "Display a selection of the available base documents" Nowait
			o_base=Createobject('request.frmselectbasedocs')
			o_base.Show
			Select  base_categ
			Scan
				If Alltrim(base_categ.c_select)=='Y'
					llBaseSelected =.T.
					Exit
				Endif
			Endscan
			If Not Empty(C_CURDBF)
				Select (C_CURDBF)
			Endif
			o_base.Release
			If llBaseSelected =.F.
				O_MESSAGE = Createobject('rts_message_yes_no',"No base image selected. Do you want to select a base? Choose yes to select or no to cancel the tags issue.")
				O_MESSAGE.Show
				L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
				O_MESSAGE.Release
				If L_CONFIRM
					C_CURDBF=Select()
					Wait Window "Display a selection of the available base documents" Nowait
					o_base=Createobject('request.frmselectbasedocs')
					o_base.Show
					Select  base_categ
					Scan
						If Alltrim(base_categ.c_select)=='Y'
							llBaseSelected =.T.
							Exit
						Endif
					Endscan
					If Not Empty(C_CURDBF)
						Select (C_CURDBF)
					Endif
					o_base.Release
					If llBaseSelected =.F.
						l_cancel=.T.
						Return l_cancel
					Endif
				Else
					l_cancel=.T.
					Return l_cancel
				Endif
			Endif
		Else
*----------------------------------------------------------
******07/05/2016: #38672 - stop using tifauto- use burnbase instead

			cMailid = Alltrim(Nvl(pc_mailid,""))
			cMailid = Iif( Empty(cMailid),"X",cMailid)

			c_parameter=Alltrim(pc_lrsno)+' '+Alltrim(Str(n_isstag))+' '+c_isstype+' '+Alltrim(cMailid)+ ;
				' '+Alltrim(c_direct)+ ' X X X' +Iif(pl_ofcoak,' C',' P')

			nJobRt = pn_lrsno
			nJobTag = n_isstag
			cJobmailid = gfstrclean(cMailid)
			bProcessed = .F.
			cNewDoc = ""
			cError = ""
			Do call_burnbase With nJobRt,nJobTag,cJobmailid,Nvl(c_isstype,"#"), Nvl( c_direct,"#"),Iif(pl_ofcoak,'C','P'),Alltrim(goapp.currentuser.orec.login) ,c_parameter,bProcessed,cNewDoc,cError
		Endif


	Endif

Endif &&3/5/14- do not look at images when we have txn 19
*************************************************** BASE DOCS *************************************

*************************************************** ADD TXN14 *************************************
**11/13/2012- check rush  case option one more time in case it was edited since the tags was locked in the queue

If Used('Instruct')
	Select Instruct
	Use
	Select 0
Endif
omedqc.sqlexecute("exec DBO.GetInstruct " + fixquote(Record.cl_code), "Instruct")

If Used('Instruct')
	Select Instruct

	If Reccount("Instruct")>0
		pl_rushcas = Instruct.rush
	Endif
Endif
**11/13/2012 -end
***05/28/13- make sure a tag's level still is used even when a case is (no rush)
pl_rushcas=pl_Expdte
***05/28/13- make sure a tag's level still is used even when a case is (no rush)
If pl_rushcas
	lcdescript=""
	lcdescript = Trim( c_dep) + " - " + Allt( pc_platnam)
	Do addstctxn With Left(lcdescript,50), pc_clcode, 14, n_isstag, pc_mailid, c_isstype, pc_userid, Record.id_tblrequests, "", .F.
Endif
*************************************************** ADD TXN5 (Excel orders) *************************************
l_ptime=.F.


*05/02/16: ADDED PARALEGAL TIME TO QC #7896- OPEN BELOW TO ALL
c_str=" Select   [dbo].[Excl_ParalegalTime]  ('" + pc_bbwebno + "', '" + pc_lrsno + "','" + Str(n_isstag) + "')"

l_ptime= omedqc.sqlexecute(c_str  , "PrlglTime")
If l_ptime
	If prlgltime.Exp<>0
		Do addtxn5exclorder With 5, n_isstag, Left(c_dep,50),pc_mailid, prlgltime.Exp, Record.id_tblrequests
	Endif
Endif
*************************************************** ADD ORDERS *************************************

***Create orders for all associated attorneys in the case
*DO SetOrdTg WITH n_IssTag
*DO  doIfcancel WITH "IfCancel","tblOrder","", "D"
*************************************************** ADD NOTICES *************************************


If Not l_lstopissue && 06/12/12 - txn19 -skip issuing
*************

	If pl_reissue
		pl_prtnotc = .F.
	Else
**05/23/2011 - add the notices for CA always and just some for KOP
**4/25/2011 - check the nonotice settings for KOP only
		If  pc_offcode="P"
			If Not nonotice( pc_area, PC_LITCODE, pc_court1, c_action, .F.)
				pl_prtnotc= Iif( pl_txabex Or pl_njspec, .F., .T.)

			Endif
		Else
			pl_prntnot=.T.
			pl_prtnotc=.T. &&CA cases
		Endif
	Endif
	If pl_prtnotc &&05/23/2011 - add the notices for CA always and just some for KOP
		l_cancel= addnotice ( n_isstag, c_isstype, c_dep, pc_offcode, c_blurb)
		Do  doifcancel With "IfCancel","tblNotice","", "D"
	Endif
**07/11/2013--- NEW RELEASE DATE (21) "HOLD_PRINT" new spec

	If pc_offcode="P"
		If Not pl_reissue

			If ld_hdays <> d_today
** 11/28/16 : #51529 - Add nonprog tags as printed  ( replaced dbo.InsertHoldReqRecord with dbo.InsertHoldReq
				lc_str=""
				lc_str =" exec dbo.InsertHoldReq '"  + fixquote(pc_clcode)+ "', '" ;
					+ Str(n_isstag)+  "','" +c_isstype + "','"  ;
					+ Dtoc(ld_hdays) + "','" + Dtoc(pd_depsitn ) + "','" ;
					+ Alltrim( pc_court1 )+ "','" + pc_mailid + "','" + Alltrim(pc_userid)  + "','"  + Dtoc(d_today) + "'"

				omedqc.sqlexecute(lc_str, "")

				Do  doifcancel With "IfCancel","tblHoldReq","", "D"

			Endif && NOT hold REQUEST
		Endif
	Endif

Endif &&& 06/12/12 - skip issuing for txn19



*************************************************** generate paper work here ************************************************
**before we print :
***get the latest request's data*********************************************************************************************
If Used("Spec_ins")
	Select spec_ins
	Use
Endif
omedqc.sqlexecute("Exec [dbo].[GetTheLatestBlurb] '" + fixquote(pc_clcode) + "',' " + Str(n_isstag) + "'", "Spec_ins")
***************************************************************************************************************************
**update REQUEST'S DATA with a user's selections/edites from the QC screen
Wait Window "Changing a Tag to a 'Wait' Status ..." Nowait
lcsqlline=""
If pl_frstlook And Empty(pc_flatty)
	pc_flatty=pc_platcod
Endif
lcsqlline=""

&&06/12/12  txn19- client memo: ADDED dbo.QC_UpdateRequestTagRequest
&&04/09/12 ADDED dbo.QC_UpdateRequest
If Empty(Dtoc(d_maildate)) &&temp test
	Do addlogline  With  n_isstag, "RelesedateEmpty" , "TestChk"
Else
	pd_reqmail=d_maildate
Endif

If  pc_offcode="P" And gnhold>0   && Hold_print new spec
&& #45883 - FIX RPS/PCCP SO THEY HAVE 5 BUSNESS DAYS - DO NOT ADD EXTRA
	If pc_isstype ='S' && OR ( pc_isstype='A'  AND pl_RisPCCP )
		d_maildate= gfchkdat(d_maildate+1, .F., .F.)
	Endif
Endif

*#255663 checkout pd_depsitn
**07/11/2013- use new Release date (21)
lcsqlline=" exec  dbo.QC_UpdateTagRequest " + Iif(l_stopprtiss, Str(1),Str(0)) + ;
	",'" + Dtoc(ld_today) + "','" + Dtoc(d_maildate)+ "','" + lc_dist+ "'," + Iif(pl_rushcas, Str(1), Str(0)) + ;
	"," + Iif(pl_resrch, Str(1),Str(0)) + ",'" + Iif(l_supplem, Str(n_supplem ), Str(0)) + "'," + ;
	IIF(pl_frstlook, Str(1), Str(0)) + ",'"  + Iif(pl_frstlook, pc_flatty, "") + "','" + ;
	LEFT(fixquote(c_dep) ,50)  + "','" +Left(c_bborder,10)+ "','" + ;
	LEFT(Alltrim(lcround),3) +"','" + Left(c_bbloc,6) + "','" + c_newrca+ "'," + ;
	IIF(pl_fromrev, Str(1), Str(0)) + ",'" + 	Dtoc(pd_depsitn)+ "','"  + Record.id_tblrequests+"','"  + Iif(l_lstopissue, 'T', 'W')  + "'"
**07/11/2013- use new Release date (21)


omedqc.sqlexecute(lcsqlline,"")


**extra data for excel orders 11/16/2010
*** med provider -start

omedqc.closealias('ChkType2')
lcsqlline=""
lcsqlline=" select [dbo].[isTagTypeChanged] ('" + fixquote(pc_clcode)+ "','" + Str(n_isstag)  + "','" + creqtype+ "')"

omedqc.sqlexecute(lcsqlline,'ChkType2')

If Nvl(chktype2.Exp,"0")="1"

	lcsqlline="update tblRequest set  TYPE='"  +creqtype ;
		+ "' where id_tblrequests='"  + Record.id_tblrequests + "' and active =1"
	omedqc.sqlexecute(lcsqlline,"")

Endif


If !Empty(Alltrim(c_medid))
	c_extradata="MedProvId"
	lcsqlline="update tblRequest set  char_fld='" +Alltrim(c_medid) + "',fld_name='" + c_extradata  ;
		+ "' where id_tblrequests='"  + Record.id_tblrequests + "' and active =1"

	omedqc.sqlexecute(lcsqlline,"")
Endif
*** med provider- end

**03/28/2016-  Added a record to the tblJobcall for a newly issued tag#36492

If  ! l_lstopissue
	lcsqlline=" exec [dbo].[AddJobCallviaTagIssue] '"+ pc_lrsno + "','" + Str(n_isstag)  + "','"+  Nvl(Record.mailid_no,'')  + "','" +  Record.id_tblrequests  + "','" +  creqtype + "'"
	omedqc.sqlexecute(lcsqlline,"")
Endif'
**03/28/2016- Added a record to the tblJoball for a newly issued tag


***get the latest request's data*********************************************************************************************
Do getrequest With pc_clcode, n_isstag

***************************************************************************************************************************
**get the latest deponent data
Do getdeponent With pc_mailid, c_hdept

***************************************************************************************************************************
**get txn11/19 from Timesheet
**06/12/12- txn19-
If l_lstopissue
	l_ok= get19txn( pc_clcode, n_isstag)
Else

	l_ok= get11txn( pc_clcode, n_isstag)
Endif

If Not l_ok
	gfmessage("Cannot continue now as the txn 11 was not found. Try again or check a Transactions list for that tag.")
*DO addlogline  WITH  n_IssTag, "Return #6" , "Cancel"
	Return .T.
Endif
******************************************** Fax Cover *********************************************************************

If pl_mailfax
	l_fax1req=.T.
	szfaxnum= cleanfax ( Alltrim(pc_depofile.fax_no))
	l_canc2fax= fax2reqst (n_isstag)
	If l_canc2fax
		mclass=""
		l_fax1req=.F.
		pl_mailfax=.F.
		pc_spechand=Iif(Empty(Alltrim(pc_spechand)),'SPC',pc_spechand)

	Endif
Endif

If Type ('ldTxnDate')="U"
	ldtxndate =  d_today
Endif
********************************************WIT FEE txn 7  CA Subp issues*********************************************************************
If pl_postfee
**06/07/2011 - Added Witness Fee 3 project-timesheet.frmWitFee2
**11/16/2010 -open that functionality for all requests
*IF c_isstype= "S"  AND pl_PostFee AND pl_ofcoaK
	pnreqcheck = 0
	pnreqfee = 0.00

	lc_chkcancel = goapp.openform("timesheet.frmWitFee2", "M",.Null.,.Null.,Request.id_tblrequests)
	If lc_chkcancel=""
		Do  doifcancel With "IfCancel","tblCheck","", "D"
	Else
**no check was issued
		gfmessage("A check was canceled.")
*!*	&&11/192012- IL-WCC must have a check- exist an issue process
		If   pl_kopver  And  Alltrim(pc_court1)='IL-WCC'  And creqtype = "S" And pl_postfee=.T. And pnreqcheck=0
			pl_postfee=.F.			&&allow cancel a check per Alec/Liz
		Endif

	Endif

Endif

**06/12/12 txn19

If  Not l_lstopissue  &&& 06/12/12 txn19 **********************

    && 08/06/2019 MD #138050  force SP for hitech
    && 08/07/2019 MD #138050 don't force spechand if it goes by fax
***** 01/02/2020 JH #155542 Backout #138050 and 144412.
*	IF ALLTRIM( NVL(record.hitech,""))=="1" AND l_fax1req=.F.	
*	   pc_spechand="SPC"
*	ENDIF 

****Spec Handling
	If Not Empty(Alltrim(pc_spechand))
		Do spechand In subp_pa
		mclass = Alltrim(mclass) &&+ pc_SpecHand &&+ IIF(EMPTY(pc_SpecHand),"",pc_offcode)
	Endif
****Spec Handling

********************************************Assemble Request's package **************************************************************
	If Not l_cancel
		Wait Window "Prepare that request's papers.." Nowait
		Do printreqst With .F., 0, n_isstag, Upper(Allt(c_dep))
	Endif

**********************************************************************************************************************************
	If  Empty(Alltrim(mv))
		l_cancel=.T.
	Endif

	If Not l_cancel
********************************************RPS Queues**************************************************************************
**see what needs to be done for pl_StopPrtIss- supress printing but create pdf file

***********************************************************************
&&03/23/2016 removed  OMRPage #36180
*03/21/2012 added OMRPAGE
*01/17/2013  added it to the IL-cookcounty subps

*!*			LOCAL  l_addomr AS boolean

*!*			l_addomr=addomrpage ( creqtype, l_fax1req )

*!*			IF  l_addomr
*!*				DO omrpage
*!*			ENDIF
&&03/23/2016 removed  OMRPage #36180
***********************************************************************



		If Empty(mclass) Or Alltrim(mclass)="SPC"
			Do getrpsclass With l_fax1req, pl_rushcas, d_maildate
		Endif


		If   pl_kopver And  (  Left( Alltrim(pc_court1), 4) = "USDC" And creqtype='S'  )		  
		   *#70765 11/27/17:  update the print location of first requests for Court beginning "USDC" and office Philadelphia regardless of litigation to print at RPS 2.  		   
		   * --- 08/16/2018 MD #98879 added USDC subpoena for Abilify
    	   IF ALLTRIM(UPPER(pc_litcode))=="ABL" AND ALLTRIM(UPPER(pc_area))=="MDL" AND creqtype='S' AND pl_reissue=.F.
		      mclass="ABLFstSubp"    	
    	   ELSE 
			  mclass="FIRSTUSDC"
		   ENDIF 		  		    
		 *mclass=mclass+ "Civ"
		 
		Endif
**2.19.15- MD subp-1st request send to Hold Printer-Liz -start

		If pl_kopver  And (creqtype=="S") And PL_OFCMD
			mclass ='MDSubReq'
		Endif
**2.19.15-end

*------------------------------------------------------------------------------
* 02/22/2018 MD #78152 replace rps stream with scanned docs only

IF scanDocsOnly=1
    LOCAL SDclCode, SDtag, SDissueType, sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
    sdClCode=pc_clcode
    sdTag=n_isstag
    SDIssueType=creqtype
    sdPrintAll=1
    sdReqDept=ALLTRIM(NVL(c_hdept,""))
    sdReqDescript=ALLTRIM(fixquote(NVL(c_dep,"")))
    sdHiTech=IIF(NVL(hitech,0)=0,"0","1")
    *-- 12/11/2019 #146658 MD added cDept, mDep, record.hitech
	DO printScannedDocs WITH SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
ENDIF 
*------------------------------------------------------------------------------

		Do prtenqa In ta_lib With mv, mclass, mgroup, Iif( l_fax1req, Alltrim( szfaxnum), "")

&& TXWORK- FILINGS FOR EACH ISSUED TAG #60359
		If PL_1ST_REQ And  pl_txcourt  And creqtype="S"
			dep_date=pd_depsitn
			bBalt=.F.
			mCrtDesc=""
			c_mid1=Nvl(pc_mailid, Nvl(Timesheet.mailid_no,''))
			Do txfiling With    n_isstag,  Upper(Allt(c_dep)),   c_mid1, d_today
		Endif


	Else
*** An Issue was canceled-delete all records from the sql here
		Select ifcancel
		Scan For action="D"

			If Alltrim(ifcancel.tblname)='tblTimesheet'
				c_str="Update " +  ifcancel.tblname + " set active=0, deleted='"+Dtoc(Date())+"', " + ;
					"deletedby='QCIssCanceled_"+Alltrim(pc_userid)+"'"+ ;
					" where cl_code='"+fixquote(pc_clcode)+"' and tag ='"+Str(n_isstag)+"'  and txn_code<>4 and DELETED IS NULL"
			Else

				c_str="update " +  ifcancel.tblname + " set active=0, deleted='"+Dtoc(Date())+"', "+;
					"deletedby='QCIssCanceled_"+Alltrim(pc_userid)+"'"+ ;
					" where cl_code='"+fixquote(pc_clcode)+"' and tag ='"+Str(n_isstag)+"' and active =1"
			Endif
			omedqc.sqlexecute(c_str,"")



			Select ifcancel

		Endscan
*** An Issue was canceled-delete all records from the sql here
***Reset back to 'Ready-To-QC'

		n_jobseq=0
		n_jobseq=getjobid(pn_lrsno, n_isstag)
		If n_jobseq<>0
			Do releaseqcjob With  1, n_jobseq, 0
		Endif
***Reset back to 'Ready-To-QC'
	Endif

Endif &&& 06/12/12 txn19 **********************
Do retproc In subp_pa

Release omedqc
Return l_cancel

******************************************************************************************************
Function addnotice
Parameters ntag,  cisstype, cdeploc, coffice, cblurb
Local n_printed As Integer, l_notice As boolean, ldpropdte As Datetime, c_request As String, l_usebussdays  As boolean
Local omed_not As Object
omed_not= Createobject("generic.medgeneric")
c_request=""
n_printed=0
l_notice=.F.
d_today=Date()
ldpropdte=d_today
*-- 08/17/2021 MD #245094 rmove business days check. !!use calendar days only!!
*--l_usebussdays =Iif(pl_proppa Or pl_propnj Or pl_michcrt Or pl_ilcook, .T.,.F.)
l_usebussdays =.F.
*-- 08/17/2021
n_printed = Iif(pl_prntnot,0,1)
If coffice="P"
	If pl_zicam
		ldpropdte =  gfchkdat(d_today+pn_objday, .F., .F.)
	Endif

	If  pl_NJSub &&3/11/14- use calendar days insteda of busness per Liz
		ldpropdte =  gfchkdat(d_today+14, .F., .F.)
	Endif

	If l_usebussdays
		Do Case
		Case pl_ilcook
			ln_count=17
*!*			CASE pl_njsub
*!*				ln_count=8
		Otherwise
			ln_count=13
		Endcase
		For i = 0 To ln_count
			ldpropdte = ldpropdte + 1
			ldpropdte = gfchkdat( ldpropdte, .F., .F.)
		Next
	Endif
Endif
lc_str=""

** -add due date for CA notices
Local d_duenotice As Datetime, l_addnotice As boolean
l_addnotice=.T. && defaul is add notices ( exclude Cambria)
d_duenotice=d_today
If coffice="P"
	d_duenotice=Iif((l_usebussdays Or pl_zicam Or pl_NJSub), ldpropdte, Iif(d_today<>pd_depsitn,pd_depsitn,d_today))
Else
	d_duenotice=pd_depsitn
Endif
**01/11/2011-  ADD CAMBRIA NOTICES FOR ONE TAG ONLY
If pl_cambasb

	omed_not.sqlexecute(" exec dbo.GetNoticeCount '" + fixquote(pc_clcode)+ "'","CambriaNot")
	Select cambrianot
	If cambrianot.cnt3>=1  && ONLY ONE ISSUE GETS NOTICED
		l_addnotice=.F.
	Endif
Else
	l_addnotice=.T.

Endif

pl_prntnot=.T.



If l_addnotice
** ca date pd_Depsitn


	lc_str=""
	lc_str="Exec dbo.sp_AddNotice '" ;
		+ fixquote(pc_clcode) + "','" ;
		+ Str(ntag) + "','" ;
		+ Dtoc(d_today) + "','" ;
		+ Dtoc(d_duenotice) + "','" ;
		+ fixquote(cdeploc) + "','" ;
		+ cblurb + "','" ;
		+ Iif( pl_prntnot, Allt(pc_rqatcod), "no print") + "','" ;
		+ PC_LITCODE + "','" ;
		+ Iif(Alltrim(goapp.currentuser.orec.ssn)='','0',Right(Alltrim(goapp.currentuser.orec.ssn), 4))+ "','" ;
		+ Alltrim(pc_mailid) + "','" ;
		+ cisstype + "'," ;
		+ Iif(coffice="P",Str(0), Str(n_printed)) + " ," ;
		+ Iif(pl_handsrv,Str(1),Str(0)) + "," ;
		+ Iif(pl_handsrv,Str(1),Str(0)) + ", null, '','', '', '" ;
		+ Alltrim(pc_userid) + "'," + Iif (pl_ofchous,Str(1),Str(0)) ;
		+ ",'" + Iif( pl_handsrv, pc_servnam, pc_mailnam) + "'"

	l_notice=omed_not.sqlexecute(lc_str,"")



	*If Not l_notice
	IF NOT NVL(l_notice,.F.)	&& 12/28/2018 YS Added checking for NULL #123165
		*--1/15/18: add display of the transact sql command for debugging [77151]
		gfmessage("No notices have been added. Contact IT  dept.  - " + CHR(13) + CHR(10) + ALLTRIM(NVL(lc_str,"xxxx")))
	Else
		Do Case
		Case coffice="P"
			c_table="tblPsNotice"
		Case coffice="T"
			c_table="tblTXNotice"
		Otherwise
			c_table="tblPsNotice"
		Endcase
		Do  doifcancel With "IfCancel",c_table,"", "D"
	Endif

Else
	l_notice=.T.

Endif
Release omed_not

Return Iif(l_notice,.F.,.T.)

*********************************************************************************************
Procedure getrequest
*********************************************************************************************
Lparameters lcclcode, lntag
If Used("REQUEST")
	Select Request
	Use
Endif
Private omed2 As Object
omed2=Createobject("generic.medgeneric")
omed2.sqlexecute(" exec DBO.GetSingleRequestRecord '"+Alltrim(lcclcode) + "' ,'" + Str(lntag) +"' ", "Request")

Release omed2
Return
**********************************************************************************************
Procedure getdeponent
*********************************************************************************************
Parameters lc_mailid, lcdept
Private omed1 As Object
omed1=Createobject("generic.medgeneric")
Wait Window "Getting Deponent's information" Nowait Noclear
pc_batchrq=""
l_mail=omed1.sqlexecute("exec dbo.GetDepInfoByMailIdDept  '" + Alltrim(lc_mailid)  +"','" + lcdept + "' ", "pc_DepoFile")
Select pc_depofile
If Eof()
	l_mail=omed1.sqlexecute("exec dbo.GetDepInfoByMailIdDept  '" + Alltrim(lc_mailid)  +"','" + lcdept + "' ", "pc_DepoFile")
Endif
pc_batchrq=Iif(Inlist(Nvl(category1,''),'G', 'P'), "RPSBATCH","")
=CursorSetProp("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
_Screen.MousePointer=0
Return
********************************************************************************************************************
Procedure getrpsclass
********************************************************************************************************************
Parameters lfax ,lrush, dmaildate
Private cclass As String
Private o_rps As Object
o_rps=Createobject("generic.medgeneric")
cclass=""
pl_specrpssrv=.F.


Do Case
Case lfax                && Fax 1st Request
	cclass  ="FrstFax"
	pc_spechand=""
&&SET DEFULT RPS
	If pc_offcode="C" And gnrps<>18
		gnrps=12
	Endif
Otherwise
	cclass = Iif(lrush,"FIRSTRUSH", "FIRST") + pc_spechand
	If pc_offcode="C"  And gnrps<>18
		gnrps=6
	Endif
Endcase




If pc_offcode="P"
	l_ok=o_rps.sqlexecute("SELECT dbo.GetRpsQueueNamebyDept ('" + pc_mailid + "','" + Nvl(spec_ins.dept,"Z")+ "','" + pc_offcode +"')", "RpsQ")
	If l_ok
		pl_specrpssrv=Nvl(rpsq.Exp,.F.)
		pc_batchrq=Iif(pl_specrpssrv,"RpsBatch","")

	Endif

	Do Case
	Case !Empty(Nvl(pc_batchrq,""))
		cclass=Alltrim(pc_batchrq) + "_1st"


	Case  Alltrim(Nvl(pc_isstype,""))="S"  And Inlist(Upper(cclass)  ,'FIRST', 'FIRSTSPC','FIRSTRUSH')
		o_rps.closealias("Rpsnum")
		o_rps.sqlexecute("select [dbo].[getrpsbycourt] ('"  + fixquote(Alltrim(pc_court1))+"')" ,"RPSnum")
		If Used('RPSnum')
			gnrps= Nvl(RPSnum.Exp, 0)
			If gnrps>0
				cclass ="First"+ Alltrim(Str(gnrps))
			Endif
		Endif



	Endcase
Endif

If dmaildate>Date()
	mclass="HoldSub"
Else
	mclass=Alltrim(cclass)
Endif







Release o_rps

Return
*******************************************************
Procedure get_errorskip
*********************************************************************************************
Parameters n_error, c_call
If n_error=1152
	Do chkusedfile With "Skipped  error:" + Str(n_error), c_call
	Wait Window "STOP!"

Endif


Return
*********************************************************************************************
***11/09/2010 -paralegal time for Excel Orders****************************************************
Procedure addtxn5exclorder
*********************************************************************************************
Parameters ntxn_code, ntagnum, cdescript,cMailid, ntime, creqsid

Private csql As String, c_txncode As String, c_units As String
n_units=Str(0)
c_units=""


&&10/21/14- TXN5 NEW CALC- 3 MINUTS INCREMENT
If ntxn_code=5
	n_units=Val(calctxn5(1, ntime	,0	))
*n_units=VAL(n_units)*60-- RETURNS MINUTES BACK
	If Type ('n_units')="N"
		c_units=Str(n_units,4,2)
		If n_units=0
			Return
		Endif
	Endif

	If Type ('n_units')="C"
		c_units=n_units
		If Alltrim('n_units')="0"
			Return
		Endif
	Endif



Endif
If Type ('omedqc')<>"O"
	omedqc = Createobject("generic.medgeneric")
Endif

csql =""
csql= "Exec dbo.gfAddTxn '" + Dtoc(Date())+  " ', '" ;
	+ fixquote(cdescript) + "','" + pc_clcode + "',' " ;
	+ Alltrim(Str(ntxn_code)) + "','"  + Alltrim(Str(ntagnum)) + "','" ;
	+ Nvl(Alltrim(cMailid),"") + "','" + c_units + "','" ;
	+ Alltrim(Str(0)) + "','" +  "" + "','" ;
	+ Alltrim(Str(0)) + "', '"  + "" + "','" ;
	+ "A" + "','" ;
	+ pc_userid + "','" ;
	+ creqsid +"'"
omedqc.sqlexecute(csql,"")

Return
**************************************************************************************************
Function getparalegaltime
*********************************************************************************************
Lparameters ln_type, lc_value
Local lsunits, lc_time
If Type('lc_value')="C"
	lc_value=Val(lc_value)
Endif

If ln_type=1
	lsunits=lc_value
	lc_minutes=Alltrim(Str(lsunits-Int(lsunits),10,2))
	If Inlist( Right( lc_minutes, 1), "1", "2", "3", "4")
		lsunits=Round(lsunits,1)+0.1
	Else
		lsunits=Round(lsunits,1)
	Endif
Endif
If ln_type=2
	lsunits=Iif(lc_value>0, lc_value/60, 0)
Endif
Return lsunits
