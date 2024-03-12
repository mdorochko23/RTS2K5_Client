*** 01/05/12 	- Goverment requests print to the RPSGov
*** 09/27/10  	- EMALING NOTICES (added public var)
*** 01/18/10    - edit to print all 'future' requests to the rps17 and get Batch Rps by a dept's category
*** 11/24/09    - remove spec hand and fax cover queues as the stripping of the pdf is now in the RPS
*** 10/05/09    - CA test mode/ remove after the test is done (pl_TestRPS=.t.)/dbo.TestersList
*** 09/14/09    - added pc_faxcover
*** 09/10/09    - added pc_spechand
*** 08/10/09    - create a job record for RPS server
*** Called from Ta_lib and Global

Procedure JOBCREATE
Lparameter Adata, Aclass, LA_GROUP, AADDRESS, C_CLCODE, N_TAG, C_USERID, LCHOOSERPS, LCIDSTC, NoticeAttyCode
*-- 01/21/2022 MD #262708  added NoticeAttyCode parameter
Local  CGROUP, CADDRESS, CALIAS, L_EMAILOK As BOOLEAN
If Parameters()<9
	LCIDSTC=''
ENDIF
*-- 01/21/2022 MD #262708
If Parameters()<10
	NoticeAttyCode=""
ENDIF

CALIAS=Alias()

Local OMEDJOB As Object, L_GOTTEST As BOOLEAN
L_GOTTEST=.F.
L_EMAILOK=.F.
OMEDJOB = Createobject("generic.medgeneric")
***group assigment
If Type('la_Group')<>"C"
	LA_GROUP='1'
Endif
CGROUP   = MAKEALPH(Alltrim(LA_GROUP))
If Empty(CGROUP)
	CGROUP = "1"
Endif
C_GROUP=Iif(Type('cgroup')<>"C",Str(CGROUP),CGROUP)
***class assigment
CCLASS   = Alltrim(Aclass)
***address assigment
CADDRESS = MAKEALPH(Alltrim(AADDRESS))
CADDRESS = Iif( CCLASS <> "ENotice", MAKEALPH( Allt( AADDRESS)), Allt( AADDRESS))
If Empty( CADDRESS)
	CADDRESS = "x"
Endif
* 01/26/2017 MD move the statement abbove IF lChooseRps
* -- reported error through ZD #57110---------
If Type( "l_fax2req") = "U"
	Store .F. To L_FAX2REQ, L_FAX1REQ, L_PRTFAX, L_PRT1REQ
Endif
* 01/26/2017 MD added in case l_fax2req is defined
If Type( "l_fax1req") = "U"
	Store .F. To L_FAX1REQ
Endif
If Type( "l_PrtFax") = "U"
	Store .F. To L_PRTFAX
Endif
If Type( "l_Prt1Req") = "U"
	Store .F. To L_PRT1REQ
ENDIF
*----------------------------------------------------
** -- 01/20/2021 MD #218721 
*-- 01/21/2022 MD #262708		
*-- IF ALLTRIM(UPPER(pc_offcode))=="C" AND 	ALLTRIM(UPPER(CCLASS))=="NOTICE"
IF ALLTRIM(UPPER(pc_offcode))=="C" AND 	(ALLTRIM(UPPER(CCLASS))=="NOTICE" OR ALLTRIM(UPPER(CCLASS))=="ORDVERNOTICE")	
	*--IF LEFT(ALLTRIM(UPPER(adata)),15)<>ALLTRIM(UPPER("00083/CADefNtc/"))  && 03/24/2021 MD #231574 don't email codefendant notice 01/21/2022 remove restriction
		oMedJob.closealias("viewCANoticeClass")
		*--lcCASQLLine="exec dbo.CANoticeClass '"+ALLTRIM(fixquote(C_CLCODE))+"', "+ ALLTRIM(STR(N_TAG)) &&01/21/2022 MD #262708		
		lcCASQLLine="exec dbo.CANoticeClassByAtty '"+ALLTRIM(fixquote(C_CLCODE))+"', "+ ALLTRIM(STR(N_TAG))+", '"+ALLTRIM(convertToChar(NVL(NoticeAttyCode,'')))+"', '"+ALLTRIM(UPPER(CCLASS))+"'"
		oMedJob.sqlexecute(lcCASQLLine,"viewCANoticeClass")
		SELECT viewCANoticeClass
		IF RECCOUNT()>0	
			CCLASS=ALLTRIM(UPPER(NVL(viewCANoticeClass.printClass,"PRINTNOTICE")))			
		ELSE
			CCLASS="PRINTNOTICE"	
		ENDIF 	
		oMedJob.closealias("viewCANoticeClass")		
	*--ENDIF 	
ENDIF 
** -- 01/20/2021 MD #218721 		
*----------------------------------------------------
** -- 09/21/2020 MD #174127			
IF ALLTRIM(UPPER(pc_offcode))=="C"	
	IF pl_1st_Req=.T.
		If Used ('MASTER') And Empty(ALLTRIM(C_CLCODE))
			C_CLCODE=Master.CL_CODE
		Else
			If Type('pc_clcode')="C"
				C_CLCODE=PC_CLCODE
			Endif
		Endif
		If Type('pn_tag')="N"
			N_TAG =Iif(PN_TAG<>0,PN_TAG,N_TAG)
		Endif	
		IF !EMPTY(ALLTRIM(NVL(c_clcode,''))) AND NVL(n_Tag,0)>0	
			lcCASQLLine="exec dbo.qc_getPrinterID '"+ALLTRIM(fixquote(C_CLCODE))+"', "+ ALLTRIM(STR(N_TAG))+",'"+convertToChar(fixquote(PC_USERID),1)+"'"
			oMedJob.sqlexecute(lcCASQLLine,"viewCAPrinterID")
			SELECT viewCAPrinterID										
			GNRPS=NVL(viewCAPrinterID.printerid,0)	
		ENDIF 
	ELSE 
		*-- 09/25/2020 MD force CA users to select printer
		*-- IF ALLTRIM(UPPER(CCLASS))<>"REPRINTNOTICE"						
		*-- 01/20/2021 MD #218721 always sent reprint notices to RPS16
		*-- 01/26/2021 additional classes	
		IF RIGHT(ALLTRIM(UPPER(CCLASS)),6)=="NOTICE" OR RIGHT(ALLTRIM(UPPER(CCLASS)),5)=="NOTIC" OR ALLTRIM(UPPER(CCLASS))=="FAXCODEF"
			* -- do not present printer selection
		ELSE 
			*-- 01/25/2021 MD #218721 additional notice classes
			Do RPS
		ENDIF 
	ENDIF 
ENDIF 
** -- 09/21/2020 MD #174127			

*----------------------------------------------------
If  LCHOOSERPS
	If   PC_OFFCODE  = "C" Or PC_OFFCODE = "S"
		PL_SKIPBATCHPRT=.T.
		PL_OFCOAK = .T.
	Endif


	If Used( "master") And Not PL_STOPPRTISS
		Do Case
		Case Master.LRS_NOCODE = "C" AND INLIST(ALLTRIM(UPPER(CCLASS)),"REPRINTNOTICE","ORDVERNOTICE","PRINTNOTICE","EMAILNOTICE")
			*-- 01/20/2021 MD #218721 sent reprint notices to RPS16
			Store .F. To L_FAX2REQ ,L_FAX1REQ ,	L_PRTFAX
			*--- GNRPS=16 && 01/25/2021 #218721
		Case Master.LRS_NOCODE = "C" &&AND NOT pl_TestRPS
			PL_OFCOAK = .T.
* Special processing for CA end-of-day noticing
			If PL_CANOTC
				PL_SKIPBATCHPRT=.T.
				CCLASS = "Notice"
				Store .F. To L_FAX2REQ ,L_FAX1REQ ,	L_PRTFAX
				GNRPS=16
			Endif
			If Not L_FAX2REQ
				If L_FAX1REQ
					GNRPS =12
				Endif
				If GNRPS = 0                        && RPS not yet selected
					Do RPS
				Endif
			Endif

			If Not PL_AUTOFAX
				If PL_CANOTC And GNRPS<>16
					GNRPS=16
				Endif
&&4/13/2010 - track sec requests' queue for ca for reports
				LCQUE=""
				If Not L_FAX2REQ And GNRPS<>0

					If PL_2NDQUE
						LCQUE="_2nd"
					Endif
					If  PL_1ST_REQ And Not PL_CANOTC
						LCQUE="_1st"
					Endif
				Endif
				CCLASS = Iif ( Not L_FAX2REQ , ;
					"Rps" + Alltrim( Str( GNRPS)) +Iif(!Empty(LCQUE),LCQUE,""), CCLASS) + Iif(PL_CANOTC,"Notic", "")
			Endif

		Otherwise
			If Alltrim(GOAPP.USERDEPARTMENT) = "TRAIN"
				CCLASS = "TrainQ"
			Endif
		Endcase
	Endif


	If Used ('MASTER') And Empty(C_CLCODE)
		C_CLCODE=Master.CL_CODE
	Else
		If Type('pc_clcode')="C"
			C_CLCODE=PC_CLCODE
		Endif
	Endif
	If Type('pn_tag')="N"
		N_TAG =Iif(PN_TAG<>0,PN_TAG,N_TAG)
	Endif


**01/18/10 -All "hold" request -print at the rps17
	If Type ('l_Prt2Req')="U"
		L_PRT2REQ=.F.
	Endif
	If PC_OFFCODE='P'  And L_PRT2REQ
		Local L_RPSHOLD As BOOLEAN, D_REQUEST As Date
		L_RPSHOLD=.F.
		If Type('pd_ReqMail')="T"
			D_REQUEST=Ttod(PD_REQMAIL)
		Endif
		If Type('pd_ReqMail')="C"
			D_REQUEST=Ctod(PD_REQMAIL)
		Endif
		If Type('d_Request')="U"
			D_REQUEST=Date()
		Endif
		If Type('pd_ReqMail')="D"
			D_REQUEST=PD_REQMAIL
		Endif

		If  D_REQUEST>D_TODAY
			L_RPSHOLD=.T.
			CCLASS='HoldFollUp'  &&+ IIF( pl_UpdHoldReqst, '2','') && 11/15/13- the followup for cenceled hold requests will belong to a new class as it need a "FIRST" group to have statusid=9
		Endif
		If PL_UPDHOLDREQST
			L_RPSHOLD=.T.
			CCLASS='HoldFollUp2'
		Endif
	Endif
**01/18/10 -"hold" request -print at the rps17

*-----------------------------------------------------------------
* Select RPSBatch here
* 12/01/2009 - MD
*01/18/10 - get a category for the Deponent's dept

**05/19/2010 - skip cadbatch as they are not really an individual request
**07/19/12- HOLD SUBPS PRINT TO THE 'FUTURE' PRINTER ALWAYS!
** 09/28/2018 MD #109024 send all Subpoena ABL/MDL First requests to rpsemail including Goverment ones 
	If Not Inlist(CCLASS, "HoldSub","HoldFollUp","TXFiling","ABLFstSubp")
		If Not PL_CADBATCH
			If PC_OFFCODE='P' And Empty(PC_BATCHRQ) And Not PL_NOTICNG
				OMEDJOB.SQLEXECUTE("select dbo.GetRpsQueueByClCodeTagDept('"+FIXQUOTE(Alltrim(C_CLCODE))+"', '"+Alltrim(Str(N_TAG))+"','" + PC_OFFCODE +"')","viewRPSName")
				If Used("viewRPSName")
					PL_SPECRPSSRV=Nvl(VIEWRPSNAME.Exp,.F.)
					PC_BATCHRQ=Iif(PL_SPECRPSSRV, "RpsBatch", "")
					Use In VIEWRPSNAME
				Else
					PL_SPECRPSSRV=.F.
				Endif
			Endif

*-----------------------------------------------------------------------
*---------------11/29/07 batch printing
			If PC_OFFCODE='P' And  !Empty(Alltrim(PC_BATCHRQ)) And PL_SKIPBATCHPRT=.F. And Not PL_PRTORIGSUBP
				CCLASS = Alltrim(PC_BATCHRQ) +Iif(PL_1ST_REQ, "_1st", "")
			Endif
		Endif &&*05/19/2010 CADbatch
*---------------11/29/07 batch printing
*-----------------------------------------------------------------------
*---------------1/5/12 goverment requests start + 6/7/12 -added international requests to that RPS + 3/7/16 added Corp Pharm #34447------------------------
&&2/5/15 : stop using  followup with pdfs
		OMEDJOB.CLOSEALIAS("RpsGov")
		OMEDJOB.SQLEXECUTE("select [dbo].[getDepCategory] ('"  + FIXQUOTE(Alltrim(C_CLCODE))+"', '"+Alltrim(Str(N_TAG))+"')" ,"RPSGov")
		If Used("RPSGov")

			If Inlist(Nvl(RPSGOV.Exp,''),'G','I', 'P')  And  PC_OFFCODE='P' And  PL_SKIPBATCHPRT=.F. And Not PL_PRTORIGSUBP And !pl_Noticng
				If Not Inlist(CCLASS, "TXFiling")
					CCLASS= "RpsGov" +Iif(PL_1ST_REQ, "_1st",  	''  )  + Iif  (L_FAX2REQ, '2', '')
				Endif
			Endif
		Endif
	Endif



*---------------1/5/12 goverment requests end ------------------------
**10/10/14 - Start printing Zoloft's Goverment's requst print to the RpsGov

	If PC_LITCODE ='ZOL'   And   Left(Alltrim(Upper(CCLASS)),6 )<> "RPSGOV"  &&AND NOT pl_cont
		If   !PL_NOTICNG
			If PL_1ST_REQ
				CCLASS =Iif (L_FAX1REQ, "FrstFax" ,"Rps5First")

			Else
				Do Case
				Case !L_FAX2REQ
&&2/5/15 : stop using  followup with pdfs
*!*						IF pl_PdfReprint
*!*							cclass ='Rps5fromPdf'
*!*						ELSE
**2/17/15 BabyLetter: cclass ='Rps5'
					CCLASS ='Rps5Second'

*!*						ENDIF

				Otherwise
					CCLASS =CCLASS
				Endcase
			Endif  && 1st request
		Endif
**"Cancel "
		If "Cancel" $ CCLASS
			CCLASS ="Rps5Cancel"
		Endif

		If Inlist(CCLASS, 'AMCode30','Code30','ReprintSTC')
			CCLASS ="Rps5STC"
		Endif
		If PL_NOTICNG And CCLASS<>'FaxNotice'
			CCLASS ="Rps5Notice"
		Endif

	Endif && zol
**ELSE 7/24/14

	If PC_LITCODE ='ZOL'
		If "Cancel" $ CCLASS
			CCLASS ="Rps5Cancel"
		Endif
		If Inlist(CCLASS, 'AMCode30','Code30','ReprintSTC')
			CCLASS ="Rps5STC"
		Endif
	Endif


Endif &&& make all the assigments: end of the lChooseRps if statement

**02/06/2014- zoloft -use rps5 for 1st, 2nd and cancelation-start

*************09/7/2016---- NonProgramed Subps print at the RPS17 #46417
If Type("PC_ISSTYPE")<>"C"
	PC_ISSTYPE="A"
Endif


If PL_SKIPBATCHPRT=.F. And Not PL_PRTORIGSUBP And  !PL_NOTICNG And Alltrim(Nvl(PC_ISSTYPE,""))="S"

	N_RPS=0
	OMEDJOB.CLOSEALIAS("Rpsnum")
	OMEDJOB.SQLEXECUTE("select [dbo].[getrpsbycourt] ('"  + FIXQUOTE(Alltrim(PC_COURT1))+"')" ,"RPSnum")
	If Used('RPSnum')
		N_RPS= Nvl(RPSNUM.Exp, 0)
	Endif
&&09/27/2017: TX  Corporate Pharma subps print at RPS17-exeptions to the rule.

	If  Left(Alltrim(Upper(CCLASS)),6 )= "RPSGOV" And PL_TXCOURT  And  N_RPS<>0
*If    Nvl(RPSGov.Exp,'') ="P" And pl_Txcourt  And  n_rps<>0
		Do Case
		Case  "Cancel" $ CCLASS
**keep printing with other cancelations
		Case  Inlist(CCLASS, 'AMCode30','Code30','ReprintSTC', 'TXFiling', 'SRUCode30', 'TXCode30','Rps5STC')
**keep printing with other stcs
		Otherwise
			CCLASS=""
		Endcase

	Endif

&&11/2/2017: TX   Reissues ( &&And Empty(CCLASS))
&&09/27/2017: TX  Goverments subps print at RPS17-exeptions to the rule.
	If N_RPS<>0  And   Not Inlist( Left(Alltrim(Upper(CCLASS)),6 ), "RPSGOV","TXFILI", "HOLDSU")

		If Type( "l_fax2req") = "U"
			Store .F. To L_FAX2REQ
		Endif

		If PL_1ST_REQ  &&And Empty(CCLASS)
			CCLASS =Iif (L_FAX1REQ, "FrstFax" ,"First") + Alltrim(Str(N_RPS))
		Else

			If !PL_UPDHOLDREQST

				Do Case
				Case !L_FAX2REQ
					If Empty(Alltrim(LCIDSTC))
						Do Case
						Case  "Cancel" $ CCLASS
&& do nothing-skip
						Case  "AMCode30"  $ CCLASS
&& do nothing-skip
						Otherwise
							CCLASS ='Second' + Alltrim(Str(N_RPS))
						Endcase

					Else
&&stc  if no class - use AMcode30, otherwise use from print30
						If Empty(CCLASS)
							CCLASS='AMCode30' && 07/17/17- #65236
						Else
							CCLASS =CCLASS
						Endif
					Endif

				Otherwise
					CCLASS =CCLASS
				Endcase
			Endif
		Endif  && 1st request
	Endif



Endif

*************09/7/2016---- NonProgramed Subps print at the RPS17 #46417

**02/06/2014- zoloft -use rps5 for 1st, 2nd and cancelation-end

**1/21/08 add 'No Print' option

If PL_STOPPRTISS
	If Type('pl_MdSubset')="U"
		PL_MDSUBSET=.F.
	Endif
	CCLASS = Iif(PL_MDSUBSET, "MdSubSet", "NoPrint")
	** YS 05/29/18 RPS No Print Job Logging [#88327]	
	IF ALLTRIM(CCLASS)="NoPrint"
		lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(pc_clcode),1) + "','" + convertToChar(n_tag,1) + "','";
			+ convertToChar(pc_isstype,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','jobcreate.prg(1)','"+ ALLTRIM(CCLASS) +"'"		
		*lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + ALLTRIM(pc_lrsno) + "','" + ALLTRIM(pc_clcode) + "','" + ALLTRIM(STR(n_tag)) + "','";
			+ pc_isstype + "','" + ALLTRIM(PC_USERID) + "','jobcreate.prg(1)','"+ CCLASS +"'"
		OMEDJOB.SQLEXECUTE(lcSQLLine,'')
	ENDIF
ENDIF
*---------------------------------------------------------
*--- 07/25/2018 MD #96619  Sometimes the class sets to second instead of second17.  All TX documents must go to RPS17
IF ALLTRIM(UPPER(CCLASS))=="SECOND" 
   lcSQLLine="select court from tblmaster where lrs_no="+ALLTRIM(convertToChar(pc_lrsno,1))
   OMEDJOB.SQLEXECUTE(lcSQLLine,'viewTXCourt')
   IF LEFT(ALLTRIM(NVL(court,'')),2)="TX"
	   CCLASS="Second17"
   ENDIF 
   USE IN viewTXCourt
ENDIF    

*******************************************************************TEST***************************************************
*******************************************************************TEST***************************************************
If Alltrim(GOAPP.USERDEPARTMENT) = "IT" Then
	CCLASS=Iif(PL_OFCOAK ,'CaRpsTest_IT','KOPTEST_IT')
Endif
*******************************************************************TEST***************************************************
*******************************************************************TEST***************************************************

***10/04/2010 - email notices in  a batch -START************************************
If PL_NOTICNG And PL_ELITNOTICE And Not PL_CRTFLNG
	If Not PL_REPNOTC
		L_EMAILOK= BALKEMAIL ( CCLASS, Adata, CADDRESS, C_CLCODE, N_TAG, C_USERID)
	Endif
Endif
***10/04/2010 - email notices in  a batch-END ************************************
If Not L_EMAILOK && if the email did no go through, then print a notices as the other jobs

**11/03/2010 - restore a tester's queue per Alec

	OMEDJOB.SQLEXECUTE("select  dbo.TestersList('" + C_USERID + "')", "IsTester")
	L_GOTTEST =Nvl(ISTESTER.Exp,.F.)

	If L_GOTTEST  And CCLASS<>'OrigSubp'
		PL_TESTRPS=.T.
		CCLASS=Iif(PL_OFCOAK ,'CaRpsTest', 'KOPTEST') + Iif(GOAPP.CURRENTUSER.OREC.DEPT="IT", "_IT", "")
		GNRPS=100
*!*			IF UPPER( ALLTRIM( c_UserID))= "ELLEN" and !pl_ofcOak
*!*			cclass='TestSet'
*!*			Endif
	Endif
**11/03/2010 - restore a tester's queue per Alec

	ZCLASS=CCLASS



	*-- 01/21/2022 MD #262708 added 	NoticeAttyCode parameter
	Do JOB_ADD With 1, 1, Adata, CADDRESS, C_CLCODE, N_TAG, C_USERID, LCIDSTC,NoticeAttyCode

Endif


If Not Empty(CALIAS)
	Select (CALIAS)
Endif
Release OMEDJOB

Adata = ""
PL_TESTRPS=.F.
Return


*************************************************************************************************
Procedure JOB_ADD
Lparameters AQID, AJOBID, Adata, AADDRESS,C_CLCODE, N_TAG, C_USERID, LCIDSTC,NoticeAttyCode
*-- 01/21/2022 MD #262708 added NoticeAttyEmail parameter
If Empty(Alltrim(Adata))
	Return
Endif
Private STRCLASS As String , LCCLCD As String, LNTAG As String, LCAREA As String , STR_SUBSPRINT As String, NRTPASS As Number
Store "" To STRCLASS,  STR_SUBSPRINT, LCNAME , LCCLCD, LCAREA
LOCAL emailParameter
LCAREA =Alias()
If Type( "gcCl_code") = "C" And Empty(C_CLCODE)
	LCCLCD = Iif(Empty(GCCL_CODE),PC_CLCODE,GCCL_CODE)
Else
	LCCLCD=C_CLCODE
Endif
If N_TAG=0
	If Type( "gnTag") = "N"
		N_TAG = GNTAG
	Endif
Endif

If  Type("c_userid") <>"C"
	If Type( "pc_UserID") = "C"
		C_USERID = PC_USERID
	Else
		C_USERID="Ellen"
	Endif
Endif

If Used ('MASTER') And Type("pn_LRSNO")="U"
	PN_LRSNO   = Iif(Type('Master.lrs_no')='N',Master.LRS_NO,Val(Master.LRS_NO))
Endif

*!*	IF EMPTY(zclass)  AND INLIST(UPPER( ALLTRIM( c_UserID)), "ELLEN", "MARINA")
*!*		zclass='TestJob'
*!*	ENDIF

STRCLASS=ZCLASS
**10/08/2010 - remove prefix for a server


If Not PL_TESTRPS

	If "_1ST"$Upper(ZCLASS) Or "_2ND"$Upper(ZCLASS ) Or "7_"$Upper(ZCLASS ) Or ("_STC"$Upper(ZCLASS ))
		If GNRPS<>0 And PL_OFCOAK
			STRCLASS= "Rps" + Alltrim( Str( GNRPS)) && server name cannot be _1st or _2nd ..

		Endif
	Endif
Endif
**10/08/2010 - remove prefix for a server
NRTPASS=PN_LRSNO


**pc_EmailAdd ADDED FOR EMALING NOTICES 09/27/2010
*-- 01/21/2022 MD #262708
*--Do ADDJOBS With  Alltrim(STRCLASS), Adata+"00000", C_USERID, AADDRESS, Iif(PL_NOTICNG,PC_EMAILADD,''), ;
IIF(PL_NOTICNG,"Rps20",STR_SUBSPRINT), LCCLCD,  N_TAG, NRTPASS, ZCLASS, LCIDSTC
emailParameter=Iif(PL_NOTICNG,PC_EMAILADD,'')
IF Alltrim(UPPER(STRCLASS))=="EMAILNOTICE" AND LEN(ALLTRIM(NVL(NoticeAttyCode,"")))>0
	emailParameter=ALLTRIM(NVL(NoticeAttyCode,""))
ENDIF 

Do ADDJOBS With  Alltrim(STRCLASS), Adata+"00000", C_USERID, AADDRESS, emailParameter, ;
	IIF(PL_NOTICNG,"Rps20",STR_SUBSPRINT), LCCLCD,  N_TAG, NRTPASS, ZCLASS, LCIDSTC

If !Empty(LCAREA )
	Select (LCAREA )
Endif

Return

