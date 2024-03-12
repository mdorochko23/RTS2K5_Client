Procedure HIPAASET
** EF 11/10/2017: Added a tag level  'h'  files for the TX cases
** EF  08/02/2017 - added a TXHIPAA page for the Pl_txcourt
** EF 05/30/2017 - call for pl_TxCourt
** EF 04/13/2017 - edit CA dates  #60985
** EF  02/29/2012 - The same USDC form for all KOP litigations
** EF  09/17/2009 - USDC like courts follow the same rule
** EF  02/27/2007 - Edit the dates for the KOP Second Requests.
** EF  12/02/2005 - Switced to sql
*------------------------------------------------------------------------------
** DMA 01/20/2005 - Remove use of Worker field in Comment.dbf
** DMA 07/22/2004 - Eliminate unneeded parameters; use more global variables
** DMA 07/19/2004 - ARGroup no longer in use
** EF  02/12/2004 - Add a separate HIPAA for K O P office
** EF  08/26/2003 - Add a scanned AM signature to the page
** EF  08/12/2003 - Generalize for use by K O P and MD office
** EF  04/10/2003 - Add a Special handling page
** EF  04/02/2003 - Initial release
*------------------------------------------------------------------------------
** Prints HIPAA Notice Set
** Assumes gfGetCas, gfGetDep have already been called
** Called by: Subp_PA, Depopts
** Calls: gfAddtxn, gfAddCom
** Calls CAConNtc, CAConPOS in Subp_CA
** Calls SpecHand in Subp_PA
*****************************************************************************
Parameters L_CHOICE
**l_Choice = .F.  - called from DepOpts to print documents as
**               a separate print job ( MD/CA offices)
**l_Choice = .T.  - called from Subp_PA to print documents as
**               part of a complete notice/subpoena set ( KOP Civil cases)

Private LCALIAS, LDDEPDATE, LLHS, LDISSDATE, LSPECHAND, LC_HIPAA, LN_STORETAG

*--- 08/14/2018 MD #98879 Do not print for ABl/MDL
IF ALLTRIM(UPPER(pc_LitCode))=="ABL" AND ALLTRIM(UPPER(pc_Area))="MDL"
   RETURN
ENDIF   

IF TYPE ('mv')="U"
Public MV
ENDIF
Local OMEDHIP As Object
MV = Iif( Not L_CHOICE, "", MV)
If (Type('pc_mailid') <> 'U')
	MID = PC_MAILID
Endif
If (Type('pc_descrpt') <> 'U')
	C_DEPONT = PC_DESCRPT
Endif
If (Type('pc_TrimTag') <>"C")
	PC_TRIMTAG=Alltrim(Str(PN_TAG))
Endif
If Val(Str(PN_TAG))<>Val(PC_TRIMTAG)
	PC_TRIMTAG= Str(PN_TAG)
Endif
LN_STORETAG=Val(PC_TRIMTAG)

If (Used('timesheet'))
	If (Type('ntag') = 'U')
		NTAG = TIMESHEET.Tag
	Endif
Endif
OMEDHIP = Createobj("generic.medgeneric")

L_PRTFAX = .F.
LC_HIPAA = ""
LCALIAS = Select()
If Used("PSNotice")
	If PSNOTICE.Tag <> PN_TAG
		Select PSNOTICE
		Use
	Endif
Endif
C_CLCODE=OMEDHIP.CLEANSTRING(PC_CLCODE)
N_TAG = Iif( PL_REISSUE, PN_SUPPTO, PN_TAG)


Local C_TAGTYPE As String,  LL_TXREISSUE As BOOLEAN
LL_TXREISSUE=.F.
LL_TXREISSUE=Nvl(PL_REISSUE,.F.)  && keep an new tag's reissue status

If Used ('RECORD') And Record.Tag <>N_TAG
	Select Record
	Use
	_Screen.MousePointer= 11
	Wait Window " Getting Records.. wait" Nowait Noclear
	PL_GOTDEPO = .F.
	Do GFGETDEP With FIXQUOTE(PC_CLCODE),N_TAG
	C_TAGTYPE=  Nvl(Record.Type,"A")
	If PN_TAG<>LN_STORETAG
		PN_TAG =LN_STORETAG
	Endif
	PL_REISSUE= LL_TXREISSUE
	_Screen.MousePointer= 0

Else

	OMEDHIP.CLOSEALIAS("TagIs")
	C_SQL = " SELECT [dbo].[TagIssueType] (" +C_CLCODE + ",'" +Str(N_TAG) +"')"
	L_OK= OMEDHIP.SQLEXECUTE (C_SQL,"TagIs")
	If Used("TagIs")
		C_TAGTYPE=  Nvl(TAGIS.Exp,"A")
	Endif

Endif

**09/27/2017 : Do not print with Old TX follow-up ( old= before 9/22)
If PL_TXCOURT
	If Type('c_tagtype')<>"C"
		C_TAGTYPE="A"
	Endif
	If  C_TAGTYPE="S"
		If OLDISSUE (PN_LRSNO, N_TAG )
			Return
		Endif
	ENDIF
**11/10/2017 - Print tag level scanned certs "H"  for tags issued after 9/22/17
	If  TxSFile (n_Tag,"H")
		Do TXPages With "H",n_Tag , MID
		Return
	ENDIF	
ENDIF

*-- 02/03/2022 MD #263701 don't print HIPAA if requesting is plaintiff
	IF pl_plisrq=.T.
	   RETURN
	ENDIF 
*-- 02/03/2022 MD #263701

*** print progrqammed page below

If !Used("PSNotice")
	Select 0
	L_DONE=OMEDHIP.SQLEXECUTE("Exec dbo.GetCaseTagNotice " + C_CLCODE + ",'" + Str(N_TAG) + "'", "PsNotice")
	
	**7/03/2018, SL, Zendesk #92636
	**If no data is returned exit out gracefully instead of crashing
	IF(EOF("PsNotice"))
		gfMessage("No HIPAA Compliant Statement can be generated for this request.  Please contact your manager with questions.")
		Return
	ENDIF
	
Endif

Select PSNOTICE
If Not L_CHOICE
	MV = ""
** Add a special handling page
	LSPECHAND = .F.
	MCLASS = "HipaaSet"
	LC_MESSAGE = "Do you want to add Special Handling Instructions?"
	O_MESSAGE = Createobject('rts_message_yes_no',LC_MESSAGE)
	O_MESSAGE.Show
	L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
	O_MESSAGE.Release
	If L_CONFIRM

		L_SPECHAND = .T.
		Do SPECHAND In SUBP_PA
	Endif
Endif
Do Case
Case Type('due_date')='C'
	LDDEPDATE = Ctod(Left(DUE_DATE,10))
Case Type('due_date')='T'
	LDDEPDATE = Ttod(DUE_DATE)
Otherwise
	LDDEPDATE = Ttod(DUE_DATE)
Endcase

**5/29/2018, SL, Zendesk# 92636
**The line 'LLHS = HS_NOTICE causes a crash if PSNOTICE is not the active cursor
**To make it, and everything below it happy, reselect PSNOTICE
Select PSNOTICE

LLHS = HS_NOTICE
Do Case
Case Type('txn_date')='C'
	LDISSDATE = Ctod(Left(TXN_DATE,10))
Case Type('txn_date')='T'
	LDISSDATE = Ttod(TXN_DATE)
Otherwise
	LDISSDATE = Ttod(TXN_DATE)
Endcase

**06/01/12 - added as a double check
If Not L_CHOICE Or Type('pd_Maild') <>"D"

	OMEDHIP.CLOSEALIAS("MailDt")
	C_SQL = " SELECT [dbo].[GetTagMailDate] (" +C_CLCODE + ",'" +Str(N_TAG) +"')"
	L_OK= OMEDHIP.SQLEXECUTE (C_SQL,"MailDt")

	If L_OK And Not Eof()
		PD_MAILD =Ctod(Left(Dtoc(MAILDT.Exp),10))
	Else
		PD_MAILD =LDISSDATE
	Endif

Endif


Do Case
Case PL_CAVER And PC_COURT1<>"USDC"
	If LDDEPDATE > D_TODAY
		GFMESSAGE("The Deposition date is " + ;
			DTOC(LDDEPDATE) + "." + Chr(13) + ;
			"You cannot print a HIPAA set today.")
		Use
		Select (LCALIAS)
		Return
	Endif

Case PL_OFCMD
	If (D_TODAY - LDISSDATE) < 7
		GFMESSAGE("You cannot print a HIPAA set today.")
		Use
		Select (LCALIAS)
		Return
	Endif
Endcase

Wait Window "Printing HIPAA Notice." Nowait Noclear

Local L_FRDHIPAA As BOOLEAN
L_FRDHIPAA=.F.
Do Case

Case PL_TXCOURT

	* -- LC_HIPAA='TXHIPAA' && 12/14/2021 MD #253039 use standard form
	L_FRDHIPAA=.F.	
	LC_HIPAA ="HIPAANEW4"
	
&&Added a new page #53154
Case PL_KOPVER And  (Left( Alltrim(PC_COURT1), 4) = "USDC"  Or PL_NJSUB  )
	*-- 10/11/2021 MD #253039 use hipaaNew3 for USDC/NJ
*!*		LC_HIPAA = "FRDHIPAA"
	L_FRDHIPAA=.T.
	LC_HIPAA ="HIPAANEW4"
Case PL_CAVER
* CA Offices
	LC_HIPAA = Iif(Left( Alltrim(PC_COURT1), 4) = "USDC" ,"USDCHIPA","Hippa")
Case PL_OFCMD
* MD Office
	LC_HIPAA = "HIPAAPage"

Otherwise
** KoP/Pgh/TX offices**
**07/09/2013 - added a new form for requests with waivers: HIPAAWAIVR
	*-- 06/11/2021 MD changed to HIPAANEW2 from HIPAANEW
	*-- 10/11/2021 MD #253039 use new hipaaNew3
	LC_HIPAA ="HIPAANEW4"
Endcase

Do PRINTGROUP With MV, LC_HIPAA

Do PRINTFIELD With MV, "Loc", PC_OFFCODE

**10/31/2017: #70884 Skip Holidays for TX issues : GFCHKDAT

If pl_TxCourt
	Do PRINTFIELD With MV, "IssueDate", Dtoc( GFCHKDAT(LDISSDATE,.F.,.F.))
Else

	Do PRINTFIELD With MV, "IssueDate", Dtoc( LDISSDATE)
Endif


If PL_TXCOURT
	LC_BARNUM=Nvl(PC_BARNO,"")
	Do PRINTFIELD With MV, "BarNo", LC_BARNUM
Endif
*-- 05/24/2021 MD #236459 
*-- 06/11/2021 MD changed to HIPAANEW2 from HIPAANEW
*-- 10/11/2021 MD #253039 use hipaaNew3
*-- 12/14/2021 MD #253039 use hipaaNew4
IF ALLTRIM(UPPER(LC_HIPAA)) =="HIPAANEW2" OR ALLTRIM(UPPER(LC_HIPAA)) =="HIPAANEW3" OR ALLTRIM(UPPER(LC_HIPAA)) =="HIPAANEW4"
		DO PRINTGROUP WITH MV, "Plaintiff"
		DO PRINTFIELD WITH MV, "FirstName", ALLTRIM( PC_PLNAM)
		DO PRINTFIELD WITH MV, "MidInitial", ""
		DO PRINTFIELD WITH MV, "LastName", ""
		IF TYPE('pd_pldob')<>"C"
			PD_PLDOB=DTOC(PD_PLDOB)
		ENDIF
		IF LEN(LTRIM(RTRIM(PD_PLDOB)))>0
			DO PRINTFIELD WITH MV, "DOB",  "DOB: "+LEFT(ALLTRIM(PD_PLDOB),10)
		ENDIF 
		IF TYPE('pc_plssn')<>"C"
			pc_plssn=""
		ENDIF
		IF LEN(LTRIM(RTRIM(pc_plssn)))>0
			DO PRINTFIELD WITH MV, "SSN",  "SSN: "+ALLTRIM(pc_plssn)
		ENDIF 
		LOCAL leadfirmName, leadBarNo,leadNameInv,;
		leadAdd1,leadAdd2,leadAddcsz,leadAddcsz,leadPhone
		STORE "" TO leadfirmName,leadBarNo,leadNameInv,leadAdd1,leadAdd2,leadAddcsz,leadAddcsz,leadPhone
		oMEDHip.closealias("viewDefName")
		SELECT 0
		oMEDHip.sqlexecute("exec dbo.AttyDefInfo '" + fixquote(pc_clcode)+ "', "+ALLTRIM(STR(N_TAG))+", '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
		IF USED("viewDefName")			
		   	GO TOP 
		   	leadNameInv=ALLTRIM(NameInv)
		   	leadBarNo=ALLTRIM(BarNo)		   	
		   	leadfirmName=ALLTRIM(AttyFirm)
		   	leadAdd1=ALLTRIM(add1)
		   	leadAdd2=ALLTRIM(add2)
		   	leadAddcsz=ALLTRIM(Addcsz)
		   	leadPhone=ALLTRIM(Phone)
		   			   			   	
		Endif	
		oMEDHip.closealias("viewDefName")		
		Do PrintField With mv, "FirmName", leadfirmName		
		IF PL_TXCOURT=.F.		
			Do PrintGroup With mv, "Atty"
			Do PrintField With mv, "Name_inv", leadNameInv
			Do PrintField With mv, "Ata1", leadAdd1
			Do PrintField With mv, "Ata2", leadAdd2
			Do PrintField With mv, "Atacsz", leadAddcsz
			Do PrintField With mv, "Phone", leadPhone
			Do PrintField With mv, "Attn","" && 12/14/2021 MD #253039  to Accommodate TX fields
			Do PrintField With mv, "BarNo", leadBarNo	
		ENDIF 
				
ENDIF 
*-- 05/24/2021 MD #236459 

If PL_WAIVRCVD
*****waiver 07/09/2013 for KOP Generic
	OMEDHIP.CLOSEALIAS("WaiverDt")
	C_SQL = " SELECT [dbo].[GetWaiverDate] (" +C_CLCODE + ",'" +Str(N_TAG) +"')"
	L_OK= OMEDHIP.SQLEXECUTE (C_SQL,"WaiverDt")


Else
**04/13/2017 #69985 CA use depo date
	Do PRINTFIELD With MV, "DepoDate", Iif (PL_OFCMD Or PL_CAVER  ,;
		DTOC( GFCHKDAT(LDDEPDATE, .F., .F.)), Dtoc( PD_MAILD))
Endif

**

C_TEXT=""

Do Case

*-- 11/08/2021 MD #253039 for past due date requests change last sentence
*-- Case   (L_FRDHIPAA OR pl_ILCook=.T.) AND LDDEPDATE<=DATE() && 12/14/2021 MD #253039 added tx court
Case   (L_FRDHIPAA OR pl_ILCook=.T. or PL_TXCOURT=.T.) AND LDDEPDATE<=DATE()
		C_TEXT="Written notice of the request for protected medical information was given to the plaintiff’s attorney who is authorized to accept all legal notices to the plaintiff in this matter on "  +  Chr(13) +  ;
		DTOC( LDISSDATE)  + ". (copy attached)" + Chr(13) + Chr(10) + Chr(13) + Chr(10)+ ;
		"The notice included sufficient information to permit the individual to raise an objection." + Chr(13) +  Chr(10) + Chr(13) + Chr(10)+;
		"The time for the individual to raise objections to the court has elapsed without objection or all objections have been resolved."
		
*-- Case   L_FRDHIPAA OR pl_ILCook=.T.  && usdc /nj sub && 12/14/2021 MD #253039 added tx court
Case   L_FRDHIPAA OR pl_ILCook=.T. or PL_TXCOURT=.T. && usdc /nj sub
	** --- 08/05/2020 MD #173172 added pl_ILCook=.T.
	C_TEXT="Written notice of the request for protected medical information was given to the plaintiff’s attorney who is authorized to accept all legal notices to the plaintiff in this matter on "  +  Chr(13) +  ;
		DTOC( LDISSDATE)  + ". (copy attached)" + Chr(13) + Chr(10) + Chr(13) + Chr(10)+ ;
		"The notice included sufficient information to permit the individual to raise an objection." + Chr(13) +  Chr(10) + Chr(13) + Chr(10)+;
		"Unless notified otherwise, by the date specified for production in the attached subpoena, the time for the individual to raise objections to the court will have elapsed without objection or will have been waived."

Otherwise

	If PL_WAIVRCVD
		Select WAIVERDT
		C_TEXT="On " + Dtoc( LDISSDATE) + "  RecordTrak provided written notice of the request for protected health information to the Plaintiff's attorney, who is authorized to accept all legal notices on behalf of the Plaintiff in this matter.  A copy of the notice is attached. " + Chr(13) + Chr(10) + ;
			"The above notice included sufficient information about the litigation in which the protected health information is requested to permit the Plaintiff to raise an objection to the Court." + Chr(13) + Chr(10) + ;
			"On " +  Left(Dtoc(WAIVERDT.Exp),10) + " ,  Plaintiff waived all objections to the request for protected health information."

	Else
		C_TEXT=" Written notice of the request for protected medical information was given to the plaintiffs attorney, who is authorized to accept all legal notices to the plaintiff in this matter on  " +  Chr(13) +  ;
			DTOC( LDISSDATE)  + " (copy attached)" + Chr(13) + Chr(10) + + Chr(13) + Chr(10) + ;
			"The notice included sufficient information to permit the individual to raise an objection." + Chr(13) +  Chr(10) +;
			"The time for the individual to raise objections to the court has elapsed without objection or all objections have been resolved."

	Endif
Endcase

Do PRINTFIELD With MV, "MainText", C_TEXT
**

If PL_TXCOURT
	Store "" To C_NAMEINV, C_NAMEINVP, C_RATADD1P, C_RATADD2P, C_RATCSZP, ;
		C_ATTYINFO, C_RATADD1, C_RATADD2, C_RATCSZ, C_PLTCAP, C_ATNAME, C_EMAILADD, C_ATYFAX

	If Not Empty( PC_RQATCOD)
		PL_GETAT = .F.
		Do ATYMIXED With FIXQUOTE(PC_RQATCOD), "M", .T.
		C_ATNAME = PC_ATYNAME
		C_NAMEINV = PC_ATYSIGN
		C_RATADD1 = PC_ATY1AD
		C_RATADD2 = PC_ATY2AD
		C_RATCSZ = PC_ATYCSZ
		C_PHONE = PC_ATYPHN
		C_FIRM = PC_ATYFIRM
		C_ATYFAX=PC_ATYFAX
		C_EMAILADD= TXRQEMAIL(0,PC_RQATCOD)
	Endif


	Do PRINTGROUP With MV, "Atty"
	Do PRINTFIELD With MV, "Name_inv", C_NAMEINV
	If PL_TXCOURT
		Do PRINTFIELD With MV, "Ata1", C_RATADD1 + Iif(Empty(C_RATADD2),"",", " + C_RATADD2)
		Do PRINTFIELD With MV, "Ata2", ""

	Else

		Do PRINTFIELD With MV, "Ata1", C_RATADD1
		Do PRINTFIELD With MV, "Ata2", C_RATADD2
	Endif

	Do PRINTFIELD With MV, "Atacsz", C_RATCSZ
	Do PRINTFIELD With MV, "Phone", C_PHONE
	Do PRINTFIELD With MV, "Ata3", 	C_FIRM
	Do PRINTFIELD With MV, "Attn", C_EMAILADD 
	Do PRINTFIELD With MV, "FaxNo", C_ATYFAX				
Endif

Do PRINTGROUP With MV, "Control"
**03/01/12- DO NOT PRINT DATE ON ANY USDC HIPAA PAGES
**02/29/12- use the USDC form for all KOP litigations

****reissue uses a suplm tag's dates 12/23/13
Local D_SEND As Date

OMEDHIP.CLOSEALIAS("SendDocs")
If PL_REISSUE
	C_STR="exec  [dbo].[getSendDate] " +C_CLCODE+ ",'" + Str(PN_SUPPTO) + "'"
	L_OK=OMEDHIP.SQLEXECUTE (C_STR,"SendDocs")

	If Not L_OK
		D_SEND=PD_RPSPRINT
	Else
		D_SEND= SENDDOCS.SEND_DATE
	Endif
Else
	D_SEND=PD_RPSPRINT
Endif
****reissue uses a suplm tag's dates 12/23/13
**10/31/2017: #70884 Skip Holidays for TX issues : GFCHKDAT
**04/13/17 : CA use today as a Print date #60985

*-- 12/15/2021 MD #253039 removed TX rule
*!*	If pl_TxCourt
*!*		Do PRINTFIELD With MV, "Date", Dtoc( GFCHKDAT(D_SEND,.F.,.F.))
*!*	ELSE
*-- 12/15/2021 

	*-- 10/11/2021 MD #253039 use hipaaNew2 for USDC/NJ
	*-- Do PRINTFIELD With MV, "Date", Iif(( Left( Alltrim(PC_COURT1), 4) = "USDC" ),"",Dtoc( Iif( PL_OFCMD Or PL_CAVER  , D_TODAY, D_SEND)))	
	*--- 11/12/2021 MD #
	*-- Do PRINTFIELD With MV, "Date", Iif(( Left( Alltrim(PC_COURT1), 4) = "USDC" ),Dtoc( GFCHKDAT(D_SEND,.F.,.F.)),Dtoc( Iif( PL_OFCMD Or PL_CAVER  , D_TODAY, D_SEND)))
	IF (L_FRDHIPAA OR pl_ILCook=.T. OR pl_TxCourt=.T.) AND LDDEPDATE<=DATE()
		Do PRINTFIELD With MV, "Date", Dtoc( GFCHKDAT(LDDEPDATE+1,.F.,.F.))
	ELSE 
		Do PRINTFIELD With MV, "Date", Iif(( Left( Alltrim(PC_COURT1), 4) = "USDC" ),Dtoc( GFCHKDAT(D_SEND,.F.,.F.)),Dtoc( Iif( PL_OFCMD Or PL_CAVER  , D_TODAY, D_SEND)))
	ENDIF 
*!*	Endif

*Do PRINTFIELD With MV, "Date", Iif(( Left( Alltrim(PC_COURT1), 4) = "USDC" ),"",Dtoc( Iif( PL_OFCMD Or PL_CAVER  , ;
D_TODAY, D_SEND)))

Do PRINTFIELD With MV, "Tag", ;
	"(RT #: " + PC_LRSNO + " Tag: " + PC_TRIMTAG + ")"
Do PRINTGROUP With MV, "Deponent"
If PL_TXCOURT
	If Not Isdigit( Left( Allt( PC_MAILID), 1))
		PC_DEPTYPE = Left( Allt( PC_MAILID), 1)
	Else
		PC_DEPTYPE = "D"
	Endif
	If  PC_DEPTYPE = "H"
		C_DEPTYPE=DEPTBYDESC(Alltrim(TIMESHEET.Descript))
	Else
		C_DEPTYPE="Z"
	Endif
** print old way -all CAP .f. below
	L_MAIL=DEPODATA(PC_MAILID,C_DEPTYPE,.F.)
	=CursorSetProp("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")

	Do PRINTFIELD With MV, "Name", Alltrim(PC_DEPOFILE.Name)
Else
	Do PRINTFIELD With MV, "Name", PSNOTICE.Descript
Endif



Do PRINTGROUP With MV, "Case"
Do PRINTFIELD With MV, "Plaintiff", Allt( PC_PLCAPTN)
Do PRINTFIELD With MV, "Defendant", Allt( PC_DFCAPTN)

If PL_TXCOURT
	Do PRINTFIELD With MV, "AttyType", Iif( PL_PLISRQ, "P", "D")
	Do PRINTFIELD With MV, "AttyName", Alltrim(C_NAMEINV)
ENDIF

** ---  01/29/2021 MD #222170 
* -- 12/14/2021 MD #253039 print 12/14/2021 MD #253039  for all courts
*-- IF PL_TXCOURT
*-- 04/28/2022 exclude CA 
IF PL_CAVER=.F.
	LOCAL inDefendantName
	STORE "" TO inDefendantName	
	oMEDHip.closealias("viewDefName")
	SELECT 0
	oMEDHip.sqlexecute("exec dbo.AttyDefInfo " + ALLTRIM(C_clcode)+ ", "+ALLTRIM(convertToChar(n_Tag,1))+", '"+Iif( pl_plisrq, "P", "D")+"'", "viewDefName")
	IF USED("viewDefName")			
	   	GO TOP 		   
	   	inDefendantName=ALLTRIM(DefendantName) 		   
	Endif	
	oMEDHip.closealias("viewDefName")
	Do PrintField With mv, "DefendantName", ALLTRIM(inDefendantName)	
ENDIF 
** ---  01/29/2021 MD #222170 


Do Case

Case PL_CAVER And Left( Alltrim(PC_COURT1), 4) <> "USDC"

	Wait Window "Printing notice to consumer and proof of service." Nowait Noclear
	Do CACONNTC In SUBP_CA With LDISSDATE, LLHS, LDDEPDATE, ;
		C_DEPONT, MID
	Do CACONPOS In SUBP_CA With LDISSDATE, LLHS, LDDEPDATE
	LNTXNID = 0
	LCCOMMENT = "A HIPAA-compliant statement was sent to the deponent."

*--11/01/06 kdl change-
	C_DESC=OMEDHIP.CLEANSTRING(PC_DESCRPT)
	CCL_CODE=OMEDHIP.CLEANSTRING(PC_CLCODE)
	LNTXNC=4
*
	C_STR= "Exec dbo.gfAddTxn '" + Dtoc(Date())+  " ', " ;
		+ Alltrim(C_DESC) + " ," + CCL_CODE + ",' " ;
		+ Alltrim(Str(LNTXNC)) + "','"  + Alltrim(PC_TRIMTAG) + "','" ;
		+ PC_MAILID + "','" + Str(0) + "','" ;
		+ Alltrim(Str(0)) + "','" +  "" + "','" ;
		+ Alltrim(Str(LNTXNID)) + "', '"  + "" + "','" ;
		+ '' + "','" ;
		+ Alltrim(PC_USERID) + "','" ;
		+ Request.ID_TBLREQUESTS +"'"
	L_DONE=OMEDHIP.SQLEXECUTE(C_STR,"")

	If L_DONE
		If Used('EntryID')
			Select ENTRYID
			Use
		Endif
*
		L_ENTRYID= OMEDHIP.SQLEXECUTE("select dbo.fn_GetID_tblTimesheet (" + CCL_CODE + ",'" ;
			+ Alltrim(PC_TRIMTAG) +"','" + Str(LNTXNC)+ "','" +Dtoc(Date()) +"')", "EntryId")
		If L_ENTRYID


			L_COMM=OMEDHIP.SQLEXECUTE("Exec dbo.gfAddCom '" + Dtoc(Date())+  " ', " ;
				+ C_DESC+","+CCL_CODE+",'" ;
				+ Alltrim(Str(LNTXNC)) + "','"  + Alltrim(PC_TRIMTAG) + "','" ;
				+ PC_MAILID + "','" + Str(0) + "','" ;
				+ LCCOMMENT+ "','"  ;
				+ Alltrim(Str(0)) + "','"  ;
				+ Alltrim(PC_USERID) + "','" + ENTRYID.Exp +"'")
		Endif
	Endif



Otherwise
* 08/26/03 Print the scanned AM signature
*-- 06/11/2021 MD changed to HIPAANEW2 from HIPAANEW
	If Not PL_CAVER And !PL_TXCOURT AND ALLTRIM(UPPER(LC_HIPAA))<>"HIPAANEW2" AND ALLTRIM(UPPER(LC_HIPAA))<>"HIPAANEW3" AND ALLTRIM(UPPER(LC_HIPAA))<>"HIPAANEW4"
		Do PRINTFIELD With MV, "Id", PC_SCANSG
		Do PRINTFIELD With MV, "RTRep", PC_AMGR_NM
*!*	ELSE

*!*		DO PrintField WITH mv, "CACounty", IIF( pl_OfcPas, ;
*!*			"Los Angeles Co. No. XO241", "Alameda County No. 22")
*!*
	Endif
Endcase

Select (LCALIAS)

If Not L_CHOICE
	GNRPS = 0
	GNTAG = PN_TAG
	MCLASS = "HipaaSet"
	Do PRINTENQ In TA_LIB With MV, MCLASS, "2"
Endif


If  LN_STORETAG<>N_TAG &&restore original tag's for the rest of docs
	If Used('RECORD')
		Select Record
		Use
	Endif
	_Screen.MousePointer= 11

	Wait Window " Getting Records.. wait" Nowait Noclear
	PL_GOTDEPO = .F.
	Do GFGETDEP With FIXQUOTE(PC_CLCODE),LN_STORETAG
	_Screen.MousePointer= 0

Endif
Release  OMEDHIP
Wait Clear
Return
