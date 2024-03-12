Procedure gfGetCas
*     Fills in critical public variables (declared in Public.prg)
*     when a case's TAMaster record is initially accessed or immediately after
*     it has been edited. The TAMAster file
*     must be open and positioned at the case's record. The routine
*     also gathers relevant data from subsidiary lookup files based
*     on codes stored in the TAMaster record.
*
*     Also ensures that the appropriate time-sheet (EntryX) file, based
*     on the case's client code, is open in area F.
*
*     REMINDER: Changes to this routine should be made in parallel with
*   10/15/12   EF Added LOR for civil /COACH-GALLOVIT
*   04/23/12   EF Added pl_WCABKOP - wcab court's subp issues in the KOP office
*   12/20/11   EF Added pl_SrqDrk and pl_RPDNy
*   08/22/11   EF Added pl_BALsrq
*   06/14/11   EF added pl_HRobins
*   06/07/11   EF Added pl_BPBLit
*   09/23/10   EF Added pl_CambAsb
*   04/15/10   EF Added pl_BalDgtk
*   02/24/10   EF added pl_LevaNJ
*   11/06/09   EF add Ethex and pl_FbtSal
*   10/21/09   EF added TRASYLOL to AYK to print the same LOR
*   08/14/09   EF added pl_FLRHi									&& Flavoring/Hinshaw
*   07/10/09   EF added pl_PAsubp
*   06/29/09   EF Added subpoena BB/Non generic
* 	06/23/09   EF Added pl_AYKAva
*               changes in gfClrCas and Public
* 	04/17/09   EF   pl_AVAPltf								&& Avandia /Plaintiff cases
*
*	 11/06/08  MD   Modified to pull pl_addCredit and pl_Txn23Allow info based on user's settings, not the acct.mgr. settings
*    06/09/08  EF   Added Tabacco/Aylstock
*    09/12/07  EF   Added pl_TRBAngl, pl_THIAngl and pl_AsbAngl
*    07/13/06  MD   Added pc_Initials
*    12/01/06  EF   Synch with the latest Fox version.
*    10/26/06  EF   Added pl_WFSBart
*    09/15/06  EF   Synch with the latest FoxPro vesrion.
*    06/06/06  EF   Synch with the latest FoxPro version
*    03/16/06  EF   Added pl_DfrAng, pl_Anglvx, pl_EvrNJ, pl_BexMot
*	 01/18/06  EF   Added pl_ENEPwl, pl_Clbrx, pl_IRGFL, pl_CivilNY, pl_Zyprx
***********************************************************************************
*	  4/6/06    kdl  Set version variables for conversion
*     12/01/05	DMA  Added optional parameter l_MasterOnly. If .T.,
*                    only data from tblMaster is gathered.
*	  11/30/05  EF   Added Indexes to the court files
*     02/10/05  EF   Added "Zicam" var
*     01/24/05  DMA  Ensure accurate setting of pl_PSGWC
*     01/20/05  DMA  Eliminate use of TAMaster.Worker field
*     11/17/04  EF   Add pl_ENBMot var
*     11/03/04  EF   Add pl_VIXMotl var
*     11/02/04  EF   Use Case Claim No for the Rezulin/RD/MR cases
*     09/23/04  EF   Added pl_civGar (Civil lit -Garfinkel Area cases)
*     09/17/04  EF   Added pl_SRZNot and pl_Motley
*     08/02/04  DMA  Add pl_NYCAsb
*     07/29/04  EF   Added pl_Shelltr and other LOR vars
*     06/29/04  DMA  Add handling for TX special court types (WV and GA)
*     06/15/04  DMA  Correct phrasing on Texas CCL court title
*     05/11/04  DMA  Block timesheet opening for CA end-of-day noticing
*     05/10/04  IZ   Added identification for HRT-Cohen Cases
*     05/10/04  DMA  Add pc_lrsno for printing/display purposes
*     05/06/04  DMA  Fill in pl_GSGWC
*     04/19/04  EF   Use pl_CrtFiling ( Court Filing )
*     04/02/04  kdl  Added 1st look ship NRSs preference
*     03/25/04  DMA  Process new long plaintiff name field
*     03/23/04  EF   Add pl_RezNY: Rezulin lit + NewYork area cases
*     03/08/04  DMA  Pick up scanned-signature info from Client Representative's
*                    record in User Access Control system.
*     02/27/04  EF   Add pl_StDietD for printing an 'Acknowledgment' for 'A' issues
*     02/26/04  DMA  Add pc_BBDock for use in Berry & Berry shares checks
*     02/12/04  EF   All PA state issues must print HIPAA set
*     02/04/04  EF   Add pl_WeldRod
*     12/12/03  kdl  Add new attorney code A24604P to pl_MdAsb definition
*     12/11/03  kdl  Add new attorney code to pl_MdAsb definition
*     12/10/03  IZ   Changed the determination of pl_MichCrt variable
*     11/18/03  IZ   Add pl_MdSumAsb
*     11/12/03  EF   Add pl_Remic
*     11/12/03  EF   Add pl_BIHipaa
*     10/02/03  EF   Add pl_AsbHipaa
*     09/23/03  EF   Add pl_MoldNY (Mold-NY cases)
*     09/18/03  EF   Add pl_mdlhold
*     09/11/03  EF   Treat K O P Maryland cases as real MD cases.
*     08/29/03  EF   Add pl_MdAsb ( Md Asbestos cases)
*     08/26/03  EF   Add a use of the ScanSign file variable
*     08/20/03  EF   Add NYMDL area to use pl_rezMdl
*     08/05/03  EF   Add pl_RezMdl to print plaintiff notice
*     07/07/03  IZ   Add pl_OhioSil variable for Ohio Silica
*     06/27/03  DMA  Eliminate litigations E1, E2, and E3
*     06/26/03  EF   Add pl_Baycol
*     05/12/03  EF   Add pl_hipaa variable
*     05/07/03  dma  New litigation-based image database ID
*     03/25/03  dma  New B&B generic case identifier (not litigation-based)
*     03/13/03  kdl  Add 1st look variables (merged 8/01/03)
*     03/04/03  dma  New Berry & Berry items for SSC/MTA dates, new format ASB
*     12/19/02  kdl  Added variables for subpoena notice ducument names from lit.dbf
*     12/16/02  EF   Add RPS Form variable
*     10/24/02  EF   Add NJ Issues flag
*     10/17/02  EF   Add Michigan Court flag
*     09/05/02  DMA  Add Rezulin/Montgomery flag
*     08/30/02  DMA  Add salesperson data for use on Case Information screen
*     08/28/02  DMA  Add Ohio Asbestos flag; get group info only for Ohio Asb.
*     08/15/02  DMA  Change "Everet" to "Evert" per Jen DiPaolo
*     08/05/02  DMA  Add handling for CreatedBy, EditedBy, Acct_Mgr, Sales_Per
*     06/27/02  DMA  Compute pn_HoldSub -- subpoena hold days
*     06/17/02  DMA  Make all TAMaster references explicit
*     12/05/01  DMA  Add office-specific logical flags
*     11/14/01  DMA  Implement use of pl_GotCase
*     10/29/01  HN   Use UserCtrl table instead of AcctMgr for
*        Account Manager info.
*     Original coding: 5/15/2001 DMA
*
*     Called by CaseWork, CovPage, CaseInfo (after an update),
*        lfPrnBar (in PrintCov), DupCase, CANType
*

* 12/01/05 DMA Add new optional parameter
Lparameters l_MasterOnly
If Parameters() = 0 Then
	l_MasterOnly = .F.
Endif

If pl_GotCase
	Return
Endif
If Eof('master') Or Bof('master')
	Go Top In Master
Endif
Local c_nodate, c_firm
Local oMedGen As Object
LOCAL lsLorAtty as string	&& 07/31/2020, ZD #183629, JH.

c_nodate=Dtoc({})
Private c_saveproc, l_useLit, l_UseCovr, c_near, c_uat_area
oMedGen = Createobject("generic.medgeneric")
c_saveproc = ""
pc_rqatcod=""
*
*    This section transfers data directly from the TAMaster file
*  into matching public variables. Some, but not all, character
*  fields are trimmed of leading and trailing blanks.
*
pn_lrsno   = Iif(Type('Master.lrs_no')='N',Master.lrs_no,Val(Master.lrs_no))
pc_lrsno   = Allt(Str(pn_lrsno))
pc_clcode  = Master.cl_code
c_clcode=oMedGen.cleanstring(Master.cl_code)
pc_offcode = Master.lrs_nocode
pl_testcas = Master.TestCase
pl_TempCas = Master.Template
pl_archive = Master.Archived
pc_litcode = Upper(Master.Litigation)
pc_area    = Master.Area
* 08/02/04 Add "cleaned" area for use throughout program
c_uat_area = Upper( Alltrim( pc_area))
pc_AreaID  = Master.Area_ID
pn_group   = Master.Group
* 03/25/04 DMA Process new long plaintiff name field
pc_fullnam = Allt( Master.Plaintiff)

Store "" To pc_plfname, pc_pllname, pc_plminit, pc_plgiven
If Empty( pc_fullnam)
* Handler for rare situations where the plaintiff field was empty
* (usually due to recall of a deleted record)
	pc_plfname = Alltrim( Master.Name_First)
	pc_pllname = Alltrim( Master.Name_Last)
	pc_plminit = Master.Name_Init
	If Not Empty ( pc_plfname + pc_pllname + pc_plminit)
		pc_plgiven = Allt( Iif( Empty( pc_plfname), "", pc_plfname) + ;
			IIF( Empty( pc_plminit), "", " " + pc_plminit + ;
			IIF( Isalpha( pc_plminit), ".", "")) )
		pc_fullnam = pc_pllname + " ;" + pc_plgiven
		Do While Not Rlock()
		Enddo
		Replace Master.Plaintiff With pc_fullnam
		Unlock
*DO MastUpd WITH MASTER.cl_code
	Endif
Else
	Do gfBrkNam With pc_fullnam, ;
		pc_pllname, pc_plfname, pc_plminit, pc_plgiven
Endif
* 03/25/04 DMA End
pc_pladdr1 = fixquote(Allt( Master.Add1))
pc_pladdr2 = fixquote(Allt( Master.Add2))
pc_executr = Allt( Master.Executor)
pc_fullssn = Iif(Empty(Nvl(Master.soc_sec,'')), '',  Allt(Master.soc_sec))
pc_plssn  = Iif(Empty(Nvl(Master.soc_sec,'')), '', "###-##-" + Right( Allt(Master.soc_sec), 4))
pd_pldob   = Nvl(Master.Brth_date,c_nodate)
pd_pldod   = Nvl(Master.Dth_date,c_nodate)
pc_platcod = Master.Pl_At_Code

pc_rqatcod = Master.Rq_At_Code
**6/13/13- tag level rq atty
If Type('PN_TAG')<>'N'
	PN_TAG=0
Endif
If Not  pl_1st_req And PN_TAG >0
*IF TYPE('pd_dateCourtset')<>"D" && 3/25/14- court set prints current RQ atty on the docs
	oMedGen.closealias('TagRqAt')
	oMedGen.sqlexecute ("Select [dbo].[getRqAttyTagLevel] ('" +  fixquote(Master.cl_code )+ "','" + Str(PN_TAG) + "','" + Master.Rq_At_Code + "')"  ,"TagRqAt")
	If Used("TagRqAt")
		pc_rqatcod=Nvl(TagRqAt.Exp,'')
	Endif
Endif
**6/13/13- tag level rq atty

pc_platnam = Master.Attorney
pc_platini = Master.AttyFirst
pc_amgr_id = Iif( Empty( Master.Acct_Mgr), Master.Sim_Last, ;
	MASTER.Acct_Mgr)
pc_plcnty  = Master.County
pc_docket  = Master.Docket
pc_plcaptn = Master.PlCap
pc_dfcaptn = Master.DefCap
pc_Court1  = Alltrim(Master.Court)
pc_Court2  = Alltrim(Master.Court2)
pc_req_atf = Master.Req_Atf
pc_distrct = Master.District
pc_divisn  = Master.Division
pc_cclnum  = Master.CclNumber
pl_intrrog = Master.Interrog
pc_reqatty = Master.Req_Atty
pc_reqpara = Master.Req_Para
pc_employr = Master.Employ
pd_empstrt = Nvl(Master.SEmpdate,c_nodate)
pd_empend  = Nvl(Master.EEmpdate,c_nodate)
pd_settled = Nvl(Master.Settled,c_nodate)
pl_chosen  = Master.Chosen
pd_trial   = Nvl(Master.Trial_Date,c_nodate)
pd_depo    = Nvl(Master.Depo_Date,c_nodate)
pd_assign  = Nvl(Master.Assn_Date,c_nodate)
pd_request = Nvl(Master.Req_Date,c_nodate)
pc_plcommt = Master.Comment
pn_depcnt  = Master.Subcnt
pc_pldeal  = Master.PlDeal
pc_projcod = Master.Proj_Codec
pn_projnum = Master.Proj_Coden
pc_conditn = Master.Condition
pc_simfrst = Master.Sim_First
pc_maiden1 = Master.Maiden_Nam
pc_maiden2 = Master.Maiden_Na2
pc_mfcture = Master.Manufactur
pc_salesmn = Iif( Empty( Master.Sales_Per), Master.Sex_First, ;
	MASTER.Sales_Per )
pd_term    = Nvl(Master.Term_Date,c_nodate)

*************************************
pc_catgory = Master.Category
pc_lotno   = Master.Lot_No
pc_occpatn = Master.Occupation
pc_devno   = Master.Device_num
pd_casentr = Nvl(Master.Enter_Date,c_nodate)
pd_casedit = Nvl(Master.Edit_Date,c_nodate)
pc_plbbrnd = Master.BB_Rnd
pc_plbbnum = Master.BB_No
* 03/04/03 DMA Start -- new Berry & Berry items
pc_plbbASB = Master.ASB_Case
pd_SSCDate = Nvl(Master.SSC_Date,c_nodate)
pd_MTADate = Nvl(Master.MTA_Date,c_nodate)
* 03/04/03 DMA End -- new Berry & Berry items
pc_billpln = Master.Plan
pc_aliencd = Master.Alien_Code
pc_proccod = Master.Proc_Code
pc_billcod = Master.Bill_Code
pn_wittotl = Master.WF_Amount
pc_Claimno = Master.Claim_No
pd_closing = Nvl(Master.DOL,c_nodate)
*--7/06/06 kdl
pd_closing =Iif(Empty(convrtDate(pd_closing)),c_nodate,convrtDate(pd_closing))
pc_complnt = Master.Complaint
pc_reparea = Master.RepArea
pc_firmcod = Master.Firmcode
pc_casenam = Master.Case
pl_MTAxpct = Master.MTA_Expect
pc_CreaCas = Master.CreatedBy
pc_EditCas = Master.EditedBy
*
*    This section contains public variables whose values are
*  computed directly from the contents of the Master file.
*
* Set pl_plisrq to .T. if plaintiff and requesting attorneys are the same
pl_plisrq  = (pc_platcod == pc_rqatcod)

* 03/25/04 DMA Use new "given-name" information
pc_plnam = Iif( Not Empty( pc_plgiven), pc_plgiven + " ", "") + pc_pllname
pc_plnamrv = Iif( Not Empty( pc_pllname), pc_pllname + ", ", "") ;
	+ pc_plgiven

* 03/25/03 DMA start
pl_BBCase = (pc_rqatcod == "BEBE  3C")
pl_BBAsb = pl_BBCase And pc_litcode == "A  "
pl_NonGBB=.F.
pl_NonGBB = (pc_litcode = "A  " And  c_uat_area =Upper("BB NonGeneral"))

**06/29/09 start: added a 3rd party signature for the CA BB /BB NonGeneral cases
If pl_NonGBB And pl_BBCase
	l_ok=oMedGen.sqlexecute("select  dbo.getattytosign ('" + fixquote(Master.cl_code) + "')" , "AttySign")
	If l_ok And Not Eof()
		pl_BBCase=.F.
		pl_BBAsb =.F.
		pc_rqatcod= Alltrim(AttySign.Exp)
	Endif

Endif
**06/29/09 end: added a 3rd party signature for the CA BB /BB NonGeneral cases

**03/16/2021 WY support increase docket width #225470 
**pc_BBDock = Left( pc_Court1, 4) + " " + Left( pc_docket, 15)
pc_BBDock = Left( pc_Court1, 4) + " " + Left( pc_docket, 75)


*--12/01/05 DMA Moved here from end of program for inclusion in l_MasterOnly section
*--11/02/04 EF Add Rezulin/RD/MR cases
*--6/01/04 kdl Initialize variable indicating if case can include client's
*-- case number
pl_clCasno = (pc_litcode = "C  " And ;
	INLIST( c_uat_area, "AMERCOUN", "RYAN, BROWN") Or ;
	(pc_litcode = "2  ") And Inlist( pc_billpln, "RD", "MR"))
	
** --- 08/04/2020 MD #170629 added plCourtIN
Store .F. To pl_RezWil, pl_Propuls, pl_PropMS, pl_PropPA, pl_PropNJ, pl_PropFed, pl_PropBlk, ;
	pl_NJSpec, pl_TxAbex, pl_FenPhen, pl_PPAPage, pl_BaySch, pl_DietDrg, pl_DDrug2, pl_MerSch, ;
	pl_ThiEve, pl_RezMont, pl_OhioAsb, pl_MichCrt, pl_NJSub, pl_BayCol, pl_OhioSil, pl_RezMdl, ;
	pl_MdAsb, pl_MdlHold, pl_MoldNY, pl_Remic, pl_MdSumAsb, pl_WeldRod, pl_StDietD, pl_RezNY, ;
	pl_STDSed, pl_PSGWC, pl_HRTLor, pl_Shelltr, pl_AsbCon, pl_LotronB, pl_Thimil, pl_PropNon, ;
	pl_A18839P,  pl_PropNJ1, pl_PropDr, pl_NYCAsb, pl_ASBHIPAA, pl_Motley, pl_CivGar, pl_HrtMorg, ;
	pl_VIXMot, pl_ENBMot, pl_Zicam, pl_IRGFl, pl_Zyprx, pl_Clbrx, pl_ENEPwl, pl_BexMot, pl_EvrNJ, ;
	pl_AnglVx, pl_DfrAng, pl_Txn23Allow,pl_GoldenCiv, pl_PxlDech, pl_PhenAng, pl_RNUAngl, pl_HTSMotl ,;
	pl_CRTAngl, pl_DPVAngl, pl_OSCAngl, pl_DfrAyl, pl_LeadMot, pl_WelFmot, pl_CivFeld, pl_WFSBart, ;
	pl_HTSPltf, pl_EclSpch, pl_BiceAlb, pl_TRBAngl, pl_AsbAngl, pl_THIAngl, pl_Popcorn, pl_Popcorn2, ;
	pl_FLRThomp, pl_SrqFed, pl_VXNeblett, pl_TBTAstk, pl_AddCredit, pl_CivilAng  , pl_HRTAstk, ;
	pl_ZDHAstk, pl_BiceFl, pl_AVAPltf, pl_ENEBrist, pl_AYKAva,  pl_PAsubp, pl_FLRHi, pl_ZLNAyl,;
	pl_FbtSal, pl_LevaNJ, pl_AV1Fed, pl_AV1PA, pl_AV1IL, pl_AV1CA, pl_Ava1, pl_BalDgtk, pl_ZcmFed, ;
	pl_CambAsb, pl_ElitNotice, pl_PncFed ,pl_PrtOrigSubp, pl_Garret, pl_Nebltt, pl_RisPCCP, ;
	pl_A044584P, pl_BPBLit, pl_AVACourtOrd, pl_NJAsb, pl_backtoqc, pl_BALsrq, pl_SrqDrk	, pl_RPDNy, ;
	pl_WCABKOP, pl_FooteMey, pl_OutofBus, pl_CivCoach, pl_Solis	, pl_Reilly	, pl_McEwen	, pl_AvaEwe, ;
	pl_BMSLor, pl_CivBeasly, pl_AvaCms, pl_ILCook, pl_CivShMr, pl_CivHelf, pl_Stark, pl_AvaStark, pl_BabLor , ;
	pl_ZDHFae, pl_BIOLor, pl_EisenRoth, pl_GallantPrlw, pl_CivCiecka,  pl_PRLKee, pl_ReedMgn, pl_YazMcEw, ;
	pl_MBCoach, pl_CivSFLOP, pl_Ronan, pl_Thalidmd, pl_CivHang , pl_MRCLetter, pl_CivMess, pl_CivTang, ;
	pl_ZOLMDL , 	pl_CivAnapol, pl_ZolLtr, pl_McEldrew,  pl_ZOLRuleF13, pl_CivMdOhio, pl_CivPion, pl_CivLevyB, ;
	pl_Effexor, pl_MulBrazil, pl_TPXlit , 	pl_CivDT,pl_CivGreat, pl_CivLocks, 	pl_ZnkMdl, pl_Golomb, pl_DurantLaw, ;
	pl_CivParks, pl_ZOLEFF, pl_CivGBass, pl_GRBCiv, pl_CivilNY, pl_MargCiv, 	pl_NJSwny, pl_NJSoriano, pl_XARSch, ;
	pl_TTHPh, pl_Archer, pl_KentBc, pl_CivKBG, pl_Duffy, pl_SchDT, pl_GayCiv, pl_LevinCiv, pl_DtRamsey, pl_BroadCiv, ;
	pl_FreedLrry , pl_RpdAna, pl_XarAna, pl_TeoAna, pl_ZofAna, pl_ActAna, pl_Chartwell, pl_Chasan, pl_Mincey, pl_MDLead, ;
	pl_PharmLocks, pl_SaltzCiv, pl_BuchIn, pl_civMP, pl_CivNLaw, 	pl_MORAng, pl_XARAgl, pl_BenGol, pl_progHub , pl_Parker ,;
	pl_Mccandls, pl_Chubb, pl_AWAC, pl_SwainLaw, pl_Falvello, pl_Zarwin, pl_Green, pl_WebrGall, pl_CivHarris, pl_Mannion , ;
	pl_Pisanch, pl_Saltzmo, pl_WagZofrn, pl_ATraub, pl_AnapFos, pl_Himmel,    pl_dpllor, pl_THolland, pl_Bilotti,  pl_Cozen, pl_FritzG, ;
	pl_CiprCiv, pl_BeglCarl,  pl_AwcRay, 	pl_MarksO, pl_Kovler, pl_Coker, pl_McElree, pl_Kwass, pl_Sater, 	pl_ChSdg , pl_ZofGsk,  ;
	pl_LangEmi, pl_GoldSeg, pl_CivPillgr, pl_Heavens, pl_WadeCNJ, pl_StarkNJ, pl_ARusso, pl_Laddey, pl_IntPaper, pl_Traflet, pl_Chk4Img, ;
	pl_Savage, pl_mr_ri, pl_JANLor, pl_Winegar, pl_Depasq, pl_TBarry, pl_DSheehan, pl_DMPitt,  pl_RasLaw, pl_OBrien, pl_Ostroff, ;
	pl_LittleJ, pl_Feller, pl_Datz,pl_RubinG, pl_Pallante,pl_Zarrow,  pl_PdfOnly, pl_ZWFirm, pl_RdckMs, pl_Johans, pl_Strav, pl_Andre, pl_Weisbrg,  ;
	pl_LambMc, pl_Swartz,  pl_KnightH, pl_Needle, pl_CivBle, pl_CAinKOP, pl_PurchG, pl_Kutak, pl_ExclMI, pl_Delany, pl_Schubert, pl_GoodRich, pl_Wapner, ;
	pl_Lowen, pl_Vidaur, pl_RosenSch, pl_WeberK,  pl_BelloR, pl_GRMN, pl_Naman, pl_VLahr, pl_TozLaw,  pl_Vigorito, pl_VanderV, pl_Soloff, pl_GRANJ, ;
	pl_Strass, pl_YoungCo, pl_Shafer, pl_SchatzS, pl_WilsonGA, pl_Hamilt,  pl_GRCorsi, pl_Daiello, pl_mbart, pl_AllenGooch, pl_CivAspMM, pl_CsltxLor, ;
	pl_Amerilor, pl_GoeLor, pl_CivMcd, pl_CivAspl, pl_BrianMurph, pl_BroadSpire, pl_NardMoore, pl_Chapman, pl_GoldScar, pl_StarrGallo, pl_GRFullertn, ;
	pl_FanelliEvans, pl_FoleyMans, pl_RosenLaw, pl_BroadSp, pl_GRBarnaba, pl_LaffeyPhila, pl_PharmaSim, pl_ShcAsbes, pl_YorkRsk, pl_Haworth, pl_GRLbmb, ;
	pl_FranzDra, pl_GRSwift, pl_Faegre, pl_GoldsegNJ, pl_TexasFran, pl_RyanBrown, pl_AnzaloneLaw, pl_ClarenceBarr, pl_AwacMalaby,pl_Litchfield, ;
	pl_CivSheehy,pl_Litchcavo,pl_OBrien2,pl_civsedg,pl_civcorv,pl_brems,pl_civsacks, pl_Gordon, pl_WeirKest, pl_GrmoSand, pl_BurnWill, pl_JTFox, pl_WilEls, pl_AshGerel, pl_Hawk, ;
	pl_GAIGrem, pl_UHSHPrn, pl_MagKauf, pl_Simon, pl_WCoxPLC, pl_IAhmuty, pl_HSandberg,pl_GNashCon, pl_GAIGMor, pl_WilsonPA,;
	plCourtIN

STORE .F. TO  pl_AshGerel, pl_MYngCon,pl_GAIGrem, pl_Mintzer, pl_MSdMinz, pl_Olearys, pl_McNab, pl_MPCohen, pl_AtlasB, pl_Brooks, pl_Sheeley, pl_OConnor, ;
	pl_VigoriGAR, pl_VigoriVAL, pl_TraubNJ, pl_TraubNY, pl_CovTrans



pn_LORpos = 0

pl_ZOLEFF= Iif(Inlist( pc_litcode, 'ZOL','EFF'),.T.,.F.)
pl_Chk4Img= Iif(Inlist( pc_litcode, 'ZOL','EFF','ZOF'),.T.,.F.)
**12/12/2017 : added LOR for F000004192 for all subpoena and autho tags.#75224
**11/13/2017 : added LOR for Hamilton, Miller & Birthisel #73000
** 09/22/2017: added LOR for Vigorito
** 09/08/2017: added LOR  #68978

*--firm LORs
c_firm=""
If !Empty(Alltrim(Nvl(pc_rqatcod,'')))
	oMedGen.closealias("VLfirm")
	C_STR= "select dbo.GetFirmCode ('" + Alltrim(pc_rqatcod) + "')"
	oMedGen.sqlexecute(C_STR,"VLfirm")
	If Used("VLfirm") And !Eof()
		c_firm=Alltrim(Nvl(VLfirm.Exp,''))
	Endif
 	pl_VLahr= Iif(c_firm="F000020347" , .T.,.F.)
 	pl_Vigorito=Iif(c_firm="F000020274" , .T.,.F.)
 	pl_Hamilt=Iif(c_firm="F000020550" , .T.,.F.) && #73000
	pl_GRCorsi=Iif(c_firm="F000004192" , .T.,.F.)  &&#75224
	*--1/5/18: added firm LOR [#76658
	pl_AllenGooch=IIF(c_firm="F000020454", .T., .F.)
	*--2/1/18: added firm LOR [78124]
	pl_Amerilor = IIF(c_firm="F000012639", .T., .F.)
Endif

** 09/08/2017: added LOR  #68978

*--litigation/area LORs

	pl_use_LOR_Refer = .T.								&& 09/24/2021,  JH

Do Case
*--6/17/19: add the LOR Litigation Railroad Area Bremseth [136442
Case ALLTRIM(UPPER(pc_litcode))="RAI" AND ALLTRIM(UPPER(c_uat_area))="BREMSETH"
	pl_brems=.T.
*--1/29/19: add new LOR for  Lit = Faegre,area= COOK IVC #126227
Case ALLTRIM(UPPER(pc_litcode))="FAE" AND ALLTRIM(UPPER(c_uat_area))="COOK IVC"
	pl_Faegre=.T.
*--2/14/18: add new LOR [80226]
Case pc_litcode="BRI"
	pl_BrianMurph=.T.
*--2/14/18: add new LOR [78361]
Case pc_litcode="GOE"
	pl_GoeLor=.T.
Case ALLTRIM(UPPER(pc_litcode))="MOB" AND ALLTRIM(UPPER(c_uat_area))="HERNIA MESH"
	* litigation- "Morrisbart" and area "Hernia Mesh"   #  76097
	pl_mbart=.t.
Case pc_litcode="JAN"  && Added lor for new lit 1/31/17 ( do bot have a ticket # yet)
	pl_JANLor=.T.
Case pc_litcode="WAG"  And  c_uat_area = "ZOFRAN"
	pl_WagZofrn=.T.
Case  c_uat_area == "STARK&STARK"
	pl_Stark=.T.
Case pc_litcode="BEN"  And  c_uat_area = "GOLOMBHONIK"
	pl_BenGol=.T.
Case pc_litcode="PHR"    And c_uat_area="LOCKSLAW"
	pl_PharmLocks=.T.
Case pc_litcode="ACT"    And c_uat_area="ANAPOL"
	pl_ActAna=.T.
Case pc_litcode="TEO"    And c_uat_area="ANAPOL"
	pl_TeoAna=.T.
Case pc_litcode="ZOF"
	Do Case
	Case c_uat_area="ANAPOL"
		pl_ZofAna=.T.
	Case Inlist( c_uat_area, "GSK" , "GSK STATE")
		pl_ZofGsk=.T.
	Endcase

Case pc_litcode="XAR"
	Do Case
	Case c_uat_area="SCHLICHTER"
		pl_XARSch=.T.
	Case c_uat_area="ANAPOL"
		pl_XarAna=.T.
	Case c_uat_area="ANGELOS"
		pl_XARAgl=.T.
	Endcase

Case pc_litcode="MOR" And c_uat_area="ANGELOS"
	pl_MORAng=.T.

Case pc_litcode="ZNK"  And  c_uat_area="MDL"&&10/20/14- added LOR for lit
	pl_ZnkMdl=.T.
Case  pc_litcode="TPX" &&9/3/14- added LOR for lit
	pl_TPXlit=.T.
Case  pc_litcode="EFF" &&8/12/14- added LOR for lit
	pl_Effexor=.T.
Case  pc_litcode="ZOL"
*pl_MRCLetter=.t.
	Do Case
	Case Inlist( c_uat_area, "MDL" ,"MDL-NON TRIAL")
		pl_ZOLMDL=.T.

	Case Inlist( c_uat_area, 'WEST VIRGINIA',  'NONE'  ,  'MISSOURI'    , ' NEW YORK', 'ALABAMA', 'CALIFORNIA', 'ILLINOIS', 'PENNSYLVANIA'        ) &&5/9/14 added LetterOfRep for three areas in Zoloft
**6/10/14 - add more areas to the list above	adn removed non mdl area at all
		pl_ZolLtr=.T.
		If  Inlist( c_uat_area, 'MISSOURI'   , 'NEW YORK',  'CALIFORNIA', 'ILLINOIS', 'PENNSYLVANIA'         ) &&7/2/14 - new rule to fill a scope for listed areas in F013

			pl_ZOLRuleF13=.T.
		Endif
	Endcase



Case pc_litcode="THA" And c_uat_area=="GSKFEDERAL"
	pl_Thalidmd=.T.
Case   pc_litcode="YAZ" And c_uat_area=="MCEWEN"
	pl_YazMcEw=.T.
Case pc_litcode="PRL" And c_uat_area=="KEEGANBAKER"
	pl_PRLKee=.T.
**08/07/2013- IVC FIlters/BabbitJohnson
Case pc_litcode="IVC" And c_uat_area=="BABBITJOHNSON"
	pl_BIOLor=.T.

**07/30/13- BiometMM LOR

Case  pc_litcode ="BIO"
*--6/11/19: make available to all areas [135977]	
	pl_BIOLor=.T.
*!*		Do Case
*!*		Case Inlist( c_uat_area,"FEDERAL","STATE","NONE", "NOT IN SUIT")

*!*			pl_BIOLor=.T.
*!*		Endcase
Case  pc_litcode ="VAG"
	Do Case
	Case c_uat_area=="CMS/WAGSTAFF"
**04/05/13 added  CMS/Wagstaff to the litigation: Vaginal Mesh
		pl_CMSWag=.T.
	Endcase


**11/28/12- bms lor
Case pc_litcode ="BMS"
	pl_BMSLor=.T.
**10/31/12- Reilly	 lit
Case pc_litcode ="REI"
	pl_Reilly		=.T.
	Do Case
	Case c_uat_area=="TRANSVAG MESH"
**06/24/13 added   Vaginal Mesh
		pl_ReiMesh=.T.
	Case  c_uat_area=="SSRI"		&&10/18/13 added
		pl_ReiSSRI=.T.
	Endcase

Case pc_litcode ="SSR"  And c_uat_area="REILLY"
	pl_Reilly=.T. && added the same LOR as pl_Reilly


**10/24/12- Solis lit
Case pc_litcode ="SOL"
	pl_Solis	=.T.
**3/3/11 Risperdal/pccp
Case     pc_litcode = "RPD"
	Do Case
	Case c_uat_area=="PCCP"
		pl_RisPCCP=.T.
	Case c_uat_area=="NEWJERSEY"
		pl_RPDNy=.T.
	Case 	 c_uat_area=="ANAPOL"
		pl_RpdAna=.T.
	Endcase
**10/19/2010 -Panacryl -Federal
Case     pc_litcode = "PAN" And  c_uat_area== "FEDERAL"
	pl_PncFed=.T.
**04/15/2010
Case pc_litcode ="BAL"
	pl_BPBLit=.T.
	If c_uat_area== "DIGITEK"
		pl_BalDgtk=.T.
	Endif
	If c_uat_area== "SEROQUEL"
		pl_BALsrq	=.T.
	Endif
**3/10/10 -avandia 1 areas
Case pc_litcode ="AV1"
	pl_Ava1 =.T.
	Do Case
	Case c_uat_area== "GSKFEDERAL"
		pl_AV1Fed=.T.
	Case c_uat_area== "GSK CA"
		pl_AV1CA=.T.
	Case c_uat_area== "GSK IL"
		pl_AV1IL=.T.
	Case c_uat_area== "GSK PA"
		pl_AV1PA=.T.

	Endcase
**3/10/10 -avandia 1 areas

Case  pc_litcode ="LQN" And c_uat_area== "NEWJERSEY"
	pl_LevaNJ=.T.
Case   pc_litcode = "FBT" And  c_uat_area== "SALIX"
	pl_FbtSal=.T.
Case   pc_litcode = "ZLN" And  c_uat_area== "AYLSTOCK"
	pl_AYKAva=.T.
Case  pc_litcode ="AYK"  And Inlist( c_uat_area,"AVANDIA", "TRASYLOL", "ETHEX", "STRYKER")
	pl_AYKAva=.T.
Case        pc_litcode = "AVA" And  c_uat_area== "CMS/MCEWEN" &&1/8/2013 - added a court order doc
	pl_AvaCms=.T.
Case        pc_litcode = "AVA" And  c_uat_area== "MCEWEN" &&11/09/2012 - added a court order doc
	pl_AvaEwe=.T.
Case  pc_litcode = "AVA" And  c_uat_area== "STARK&STARK"   &&04/24/2013 -added courtorder
	pl_AvaStark=.T.

Case        pc_litcode = "AVA" And  c_uat_area== "PLAINTIFF"
	pl_AVAPltf=.T.
Case        pc_litcode = "AVA" And  Inlist(c_uat_area,"KIRKENDALL" ,"HEARD ROBBINS", "FOOTE-MEYERS") && Kirkendall and Heard Robbins
	pl_AVACourtOrd=.T.

	If  c_uat_area="FOOTE-MEYERS"

		pl_FooteMey=.T.

	Endif


Case        pc_litcode = "ZDH"

	Do Case
	Case   c_uat_area== "AYLSTOCK"
		pl_ZDHAstk=.T.
	Case  c_uat_area=="FAEGRE"
		pl_ZDHFae=.T.

	Endcase

Case        pc_litcode = "HRT" And  c_uat_area== "AYLSTOCK"
	pl_HRTAstk=.T.
Case        pc_litcode = "TBT" And  c_uat_area== "AYLSTOCK"
	pl_TBTAstk=.T.

Case        pc_litcode = "SRQ"
	Do Case
	Case  c_uat_area== "FEDERAL"

		pl_SrqFed =.T.
	Case c_uat_area=="DRINKER"
		pl_SrqDrk=.T.
	Endcase

Case    pc_litcode = "HAW"		&& 02/10/2020 ZD #161173, JH
	Do Case
	Case  ALLTRIM(UPPER(c_uat_area)) == "PERS INJ"
		pl_Hawk =.T.
	Endcase


Case pc_litcode = "FLR"
	Do Case
	Case  c_uat_area== "HINSHAW"
		pl_FLRHi=.T.
	Case  c_uat_area== "POPCORN2"  And  pc_rqatcod='A037642P'
		pl_Popcorn2 = .T.
	Case  c_uat_area=="THOMPSON"
		pl_FLRThomp=.T.
	Otherwise

	Endcase


**09/12/2007 added vars
Case pc_litcode = "TRB"  And c_uat_area == "ANGELOS"
	pl_TRBAngl = .T.
**2/09/07 bice lit

Case pc_litcode = "BCE"  And c_uat_area == "ALABAMA"
	pl_BiceAlb = .T.

**01/04/2007 -ecoli work
Case pc_litcode = "ECL"  And c_uat_area == "SPINACH"
	pl_EclSpch = .T.


Case  pc_litcode = "WFS"
	Do Case
	Case c_uat_area = "MOTLEY"
		pl_WelFmot=.T.
	Case c_uat_area = "BARTIMUS"
		pl_WFSBart=.T.
	Endcase

Case pc_litcode="MTL"
	pl_LeadMot=.T.
Case pc_litcode = "OSC" And c_uat_area == "ANGELOS"
	pl_OSCAngl=.T.
Case pc_litcode = "DPV" And c_uat_area == "ANGELOS"
	pl_DPVAngl=.T.
Case pc_litcode = "CRT" And c_uat_area == "ANGELOS"
	pl_CRTAngl=.T.
Case  pc_litcode = "HTS"
	Do Case
	Case  c_uat_area = "MOTLEY"
		pl_HTSMotl=.T.
	Case c_uat_area = "PLAINTIFF"
		pl_HTSPltf=.T.
	Endcase

Case pc_litcode = "RNU"  And c_uat_area == "ANGELOS"
	pl_RNUAngl = .T.
Case pc_litcode = "PXL"  And c_uat_area == "DECHERT"
	pl_PxlDech = .T.

Case  pc_litcode = "SHC"
	Do Case
*--10/11/18: Simmons Hanly Conroy area: Hernia Mesh [#111175]
	Case  c_uat_area = UPPER("Hernia Mesh")
		pl_PharmaSim=.T.
*--10/11/18: Simmons Hanly Conroy area: Asbestos [#111175]
	Case  c_uat_area = UPPER("Asbestos")
		pl_ShcAsbes=.T.
	ENDCASE

Case pc_litcode = "C  "						&& CIVIL LITIGATION
	Do Case
*--7/1/19: civil area: SacksWeston #137382
	CASE c_uat_area== UPPER("SacksWeston")
		pl_civsacks=.t.
*--4/9/19: civil area: AWAC-Malaby #131147
	CASE c_uat_area== UPPER("AWAC-Malaby")
		pl_AwacMalaby=.t.
*--3/25/19: civil area: ClarenceBarry #129772
	CASE c_uat_area== UPPER("ClarenceBarry")
		pl_ClarenceBarr=.t.
*--3/7/19: civil area: Anzalone Law   #128913
	CASE c_uat_area== UPPER("Anzalone Law")
		pl_AnzaloneLaw=.t.
*--2/25/19: civil area: Ryan, Brown #128286
	CASE c_uat_area== UPPER("Ryan, Brown")
		pl_RyanBrown=.t.
*--2/7/19: civil area: Texas #126026
	CASE   c_uat_area== UPPER("Texas")
		pl_TexasFran = IIF(c_firm="F000021380", .T., .F.)
*--2/7/19: civil area: GoldbergSeg-NJ [#126835]
	CASE c_uat_area== UPPER("GoldbergSeg-NJ")
		pl_GoldsegNJ=.t.	
*--12/19/18: civil area: GR-GA-Swift [#122624]
	CASE c_uat_area== UPPER("GR-GA-Swift")
		pl_GRSwift=.t.	
*--12/11/18: civil area: FranzblauDratc [#121780]
	CASE c_uat_area== UPPER("FranzblauDratc")
		pl_FranzDra=.t.	
*--10/16/18: civil area: York Risk Svcs [#112174]
	CASE c_uat_area== UPPER("York Risk Svcs")
		pl_YorkRsk=.t.
*--10/09/18: civil area: Laffey/Phila [#110816]
	CASE c_uat_area== UPPER("Laffey/Phila")
		pl_LaffeyPhila=.t.
*--8/17/18: civil area: GR-NJ-Barnaba [#101816]
	CASE c_uat_area== UPPER("GR-NJ-Barnaba")
		pl_GRBarnaba=.t.
*--8/17/18: civil area: Broadspire [#101823]
	CASE c_uat_area== UPPER("Broadspire")
		pl_BroadSp=.t.
*--7/02/18: civil area: RosenLaw [#93276]
	CASE c_uat_area== UPPER("RosenLaw")
		pl_RosenLaw=.t.
*--6/01/18: civil area: FoleyMans-FL  [#89742]
	CASE c_uat_area== UPPER("FoleyMans-FL")
		pl_FoleyMans=.t.
*--6/01/18: civil area: FanelliEvans   [#89272]
	CASE c_uat_area== UPPER("FanelliEvans")
		pl_FanelliEvans=.t.
*--5/31/18: civil area: GR-NY-Fullertn [89180]
	CASE c_uat_area== UPPER("GR-NY-Fullertn")
		pl_GRFullertn=.t.
*--5/31/18: civil area: Starr-NY-Gallo [89159]
	CASE c_uat_area== UPPER("Starr-NY-Gallo")
		pl_StarrGallo=.t.
*--4/12/18: civil area: GoldmanScarlat [84088]
	CASE c_uat_area== UPPER("GoldmanScarlat")
		pl_GoldScar=.t.
*--3/29/18: civil area: NarducciMoore [83161]
	CASE c_uat_area== UPPER("ASP-MN-CHAPMAN")
		pl_Chapman = .t.
*--3/14/18: civil area: NarducciMoore [81824]
	CASE   c_uat_area== UPPER("NarducciMoore")
		pl_NardMoore = .t.
*--2/21/18: civil area: Asplundh [79886]
	CASE   c_uat_area== UPPER("Broadspire-BBB")
		pl_BroadSpire = IIF(c_firm="F000008041", .T., .F.)
*--5/16/19: kdl [133546]
		pl_Litchfield = IIF(c_firm="F000002937", .T., .F.)
*--5/20/19: kdl [133546]
	CASE c_uat_area== "CORVEL-BBB"
		pl_Litchfield = IIF(c_firm="F000002937", .T., .F.)
		pl_WilEls = IIF(c_firm="F000008041", .T., .F.)			&& 12/16/2019, zd #152485, JH

*--6/04/19: kdl [135379]
		pl_civcorv = IIF(c_firm="F000018448", .T., .F.)
*--5/22/19: kdl [134587]
	CASE c_uat_area== UPPER("AWAC-TX-Sheehy")
		pl_CivSheehy = .T.
*--5/24/19: kdl [134621]
	CASE c_uat_area== UPPER("LitchfieldCavo")
		pl_Litchcavo = .T.
*--2/21/18: civil area: Asplundh [79886]
	CASE   c_uat_area== UPPER("Asplundh")
		pl_CivAspl = IIF(c_firm="F000006738", .T., .F.)
*--2/14/18: add new LOR [79083]
	CASE   c_uat_area== UPPER("McDonaldMac")
		pl_CivMcd = .T.
*--1/29/18: add new LOR [77725]
	CASE   c_uat_area=="SMITH LAW-TX"    
		pl_CsltxLor = .T.
*--1/26/18: add new LOR [77772]
	CASE   c_uat_area=="ASP-MO-MORROW"    
		pl_CivAspMM = .t.
	CASE   c_uat_area=="DAIELLOLAW"    
		pl_Daiello=.t.	
	case  c_uat_area=="WILSONELSER-GA"  
		  pl_WilsonGA=.t.	
	Case  c_uat_area=="SCHATZSTEIN"   
		pl_SchatzS=.t.	
	Case  c_uat_area=="KNIGHT-SHAFER" 
		pl_Shafer=.t.
	Case  c_uat_area=="YOUNGCONAWAY"   
		pl_YoungCo=.t.
	Case  c_uat_area=="MAGNA-YOUNGCON"   						&& 02/07/2020, ZD #161332, JH
		pl_YoungCo=.t.
	Case  c_uat_area=="STRASSBURGER"
		pl_Strass=.t.	
	Case  c_uat_area=="GR-A-NJ"
		IF c_firm="F000012524"
			pl_GRLbmb = .T.	&& 12/7/18: added firm LOR [#120813]
		ELSE
			pl_GRANJ=.t.
		ENDIF
	Case  c_uat_area=="SOLOFF & ZERV"
		pl_Soloff=.t.	
	Case  c_uat_area=="VANDERVEEN"
		 pl_VanderV=.t.	
	Case  c_uat_area=="TOZ LAW"
		pl_TozLaw=.T.
	Case  c_uat_area=="HM-NAMANHOWELL"
		pl_Naman=.T.
	Case  c_uat_area=="GR-A-MN"
		pl_GRMN=.T.
	Case  c_uat_area=="BELLOREILLEY"
		pl_BelloR=.T.
	Case  c_uat_area=="WEBER, KRACHT"
		pl_WeberK=.T.
	Case  c_uat_area=="ROSENSCHAFER"
		pl_RosenSch=.T.
	Case  c_uat_area=="HM-VIDAURRI"
		pl_Vidaur=.T.
	Case  c_uat_area=="LOWENTHAL"
		pl_Lowen=.T.
	Case  c_uat_area=="WAPNER"
		pl_Wapner=.T.
	Case  c_uat_area=="GOODRICHGEIST"
		pl_GoodRich=.T.
	Case  c_uat_area=="ALPERNSCHUBERT"
		pl_Schubert=.T.
	Case  c_uat_area=="KNIGHT-DELANY"
		pl_Delany=.T.
	Case  c_uat_area=="HM-KUTAK"
		pl_Kutak=.T.
	Case  c_uat_area=="PURCHASEGEORGE"
		pl_PurchG=.T.
		
*!*		Case  c_uat_area=="BLEVANS MCCALL"
*!*		*--- 01/21/2021 MD #220737
*!*			If checktest("CARASVOD")=.F.
*!*				pl_CivBle=.T.
*!*			Else
*!*				pl_CivBle=.F.
*!*			Endif

	Case  c_uat_area=="NEEDLELAW"
		pl_Needle=.T.
	Case  c_uat_area=="KNIGHT-INHOUSE"
		pl_KnightH=.T.

	Case Inlist(c_uat_area,"SWARTZCULL-PI", "SWARTZCULL-NH")
		pl_Swartz=.T.
	Case  c_uat_area=="ANDREOZZI"
		pl_Andre=.T.
	Case  c_uat_area=="WEISBERG LAW"
		pl_Weisbrg=.T.
	Case  c_uat_area=="LAMB MCERLANE"
		pl_LambMc=.T.
	Case c_uat_area=="STAEHLE-TRAV"
		pl_Strav=.T.
	Case c_uat_area=="HM-JOHANSON"
		pl_Johans=.T.
	Case c_uat_area=="REDDICKMOSS"
		pl_RdckMs=.T.
	Case c_uat_area=="THEWEITZFIRM"
		pl_ZWFirm=.T.
	Case c_uat_area=="LIANZARROW"
		pl_Zarrow=.T.
	Case c_uat_area=="PALLANTE"
		pl_Pallante=.T.
	Case c_uat_area=="RUBINGLICKMAN"
		pl_RubinG=.T.
	Case c_uat_area=="DATZ LAW"
		pl_Datz=.T.
	Case c_uat_area=="FELLERMAN"
		pl_Feller=.T.
	Case c_uat_area=="LITTLETONJOYCE"
		pl_LittleJ=.T.
	Case c_uat_area=="OSTROFFLAW"
		pl_Ostroff=.T.
*!*		CASE INLIST(c_uat_area,"O_BRIEN", "OBRIEN/PITT")
*!*			pl_OBrien=.t.
	Case c_uat_area==UPPER("OBrien/Pitt")		&&1/16/19 YS Reactivated civil area: OBrien/Pitt as per Alec's req  #124960
		pl_OBrien=.t.
*--5/29/19: [134974]	
	Case c_uat_area==UPPER("O_Brien")		&&1/16/19 YS Reactivated civil area: OBrien/Pitt as per Alec's req  #124960
		pl_OBrien2=.t.
*--5/31/19: [134974]	
	Case c_uat_area==UPPER("Sedgwick")		&&1/16/19 YS Reactivated civil area: OBrien/Pitt as per Alec's req  #124960
		pl_civsedg=.t.
	Case  c_uat_area=="AWAC-RASLAW"
		pl_RasLaw=.T.
	Case  c_uat_area=="DICKIEM-PITT"
		pl_DMPitt=.T.
	Case  c_uat_area=="DUNNSHEEHAN"
		pl_DSheehan=.T.
	Case  c_uat_area=="AMTRUST-BARRY"
		pl_TBarry=.T.
	Case  c_uat_area=="DEPASQUALELAW"  && #58608
		pl_Depasq=.T.
	Case  c_uat_area=="WINEGARWILHELM"
		pl_Winegar=.T.
	Case  c_uat_area=="ALLSTATE-RI"
		pl_mr_ri=.T.
	Case  c_uat_area=="SAVAGELAW"
		pl_Savage=.T.
	Case  c_uat_area=="TRAFLETFABIAN"
		pl_Traflet=.T.
	Case  c_uat_area=="LADDEYCLARK"
		pl_Laddey=.T.
	Case  c_uat_area=="INTL PAPER"
		pl_IntPaper=.T.
	Case  c_uat_area=="AMTRUST-RUSSO"
		pl_ARusso=.T.
	Case  c_uat_area=="STARK&STARK-NJ"
		pl_StarkNJ=.T.
	Case  c_uat_area=="WADECLARK-NJ"
		pl_WadeCNJ=.T.
	Case  c_uat_area=="HEAVENS LAW"
		pl_Heavens=.T.
	Case  c_uat_area=="PILLINGER"
		pl_CivPillgr=.T.
	Case  c_uat_area=="GOLDBRGSEGALLA"
		*pl_GoldSeg=.T.
		pl_GoldSeg=.F.	&& 2/27/19 YS Removed LOR for the Area: GOLDBRGSEGALLA #128349
	Case  c_uat_area=="LANGDONEMISON"
		pl_LangEmi=.T.
	Case  c_uat_area="COACH-SEDGWICK"
		pl_ChSdg =.T.
	Case  c_uat_area=="SATER"
		pl_Sater=.T.
	Case  c_uat_area=="SALTZ-KWASS"
		pl_Kwass=.T.
	Case  c_uat_area=="MACELREEHARVEY"
		pl_McElree=.T.
	Case  c_uat_area=="COKER"
		pl_Coker=.T.
	Case  c_uat_area=="KOVLER"
		pl_Kovler=.T.
	Case  c_uat_area="AWAC-MARKSO"
		pl_MarksO=.T.
	Case  c_uat_area="AWAC- RAY"
		pl_AwcRay=.T.
	Case  c_uat_area="BEGLEYCARLIN"
		pl_BeglCarl=.T.
	Case  c_uat_area="CIPRIANI"
		pl_CiprCiv=.T.
	Case  c_uat_area="FRITZGLDNBRG"
		pl_FritzG=.T.
	Case c_uat_area="COZEN"
		pl_Cozen=.T.
	Case c_uat_area="BILOTTI"
		pl_Bilotti=.T.
	Case c_uat_area="THOMASHOLLAND"
		pl_THolland=.T.
	Case c_uat_area="DOUGHERTYLEVEN"
		pl_dpllor=.T.
	Case c_uat_area="HIMMELSTEIN"
		pl_Himmel=.T.
	Case c_uat_area="ANAPOL-FOSAMAX"
		pl_AnapFos=.T.
	Case c_uat_area="AWAC-TRAUB"
		pl_ATraub=.T.
	Case c_uat_area="SALTZ-DUFFY"
		pl_Saltzmo=.T.
	Case c_uat_area="AWAC-MANNION"
		pl_Mannion=.T.
	Case c_uat_area="PISANCHYN"
		pl_Pisanch=.T.
	Case c_uat_area="AWAC-HARRIS"
		pl_CivHarris=.T.
	Case c_uat_area="WEBER GALL"
		pl_WebrGall=.T.
	Case Inlist(c_uat_area,"ZARWIN/NJ"    , "ZARWIN/PHILA"  )
		pl_Zarwin=.T.
	Case  c_uat_area ="GREENLEGAL"
		pl_Green=.T.
	Case  c_uat_area ="FALVELLO"
		pl_Falvello=.T.
	Case  c_uat_area ="SWAINLAW"
		pl_SwainLaw=.T.
	Case  c_uat_area ="AWAC-WIEDNER"
		pl_AWAC=.T.
	Case  c_uat_area ="MCCANDLESS"
		pl_Mccandls=.T.
	Case  c_uat_area ="CHUBB"
		pl_Chubb=.T.
	Case   c_uat_area ="PARKER MCCAY"
		pl_Parker =.T.
	Case   c_uat_area ="PROG-HUBSHMAN"
		pl_progHub=.T.
	Case   c_uat_area =="NICOLSONLAW"
		pl_CivNLaw=.T.
	Case   c_uat_area ="MCCORMICK"
		pl_civMP=.T.
	Case  c_uat_area ="NURSINGHOME/BI"
		pl_BuchIn=.T.
	Case  c_uat_area ="SALTZ, MONG"
		pl_SaltzCiv=.T.
	Case  c_uat_area ="MINCEY"
		pl_Mincey=.T.
	Case  c_uat_area ="SFNJ-CHASAN"
		pl_Chasan=.T.
	Case  c_uat_area ="CHARTWELL-EAGL"
		pl_Chartwell=.T.
	Case  c_uat_area ="FREEDMANLORRY"
		pl_FreedLrry=.T.
	Case  c_uat_area ="BROADSPIRE-BBB"
		pl_BroadCiv=.T.
	Case  c_uat_area ="DT-RAMSEYLAW"
		pl_DtRamsey=.T.
	Case  c_uat_area ="LEVIN FISHBEIN"
		pl_LevinCiv=.T.
	Case  c_uat_area ="GAY & CHACK"
		pl_GayCiv=.T.
	Case  c_uat_area ="DT-SCHNADER"
		pl_SchDT=.T.
	* 05/23/2018 MD #88352 per Alec's instructions LOR was removed for the whole area
	*Case  c_uat_area ="DUFFYPARTNERS"
	*	pl_Duffy=.T.
	Case  c_uat_area ="KATHERMAN"
		pl_CivKBG=.T.
	Case  c_uat_area ="KENT MCBRIDE"
		pl_KentBc=.T.
	Case  c_uat_area ="ARCHER-PHILA"
		pl_Archer=.T.
	Case   c_uat_area ="TT&H - PHILA"
		pl_TTHPh=.T.
	Case   c_uat_area ="SFNJ-SORIANO"
		pl_NJSoriano=.T.
	Case   c_uat_area ="SWEENEY-NJ"
		pl_NJSwny=.T.
	Case  c_uat_area ="GOEHRING"
		pl_GRBCiv=.T.
	Case  c_uat_area ="GALLAGHERBASS"
		pl_CivGBass=.T.
	Case  c_uat_area ="PARKSASSOC"
		pl_CivParks=.T.
	Case  c_uat_area = "DURANTLAW"
		pl_DurantLaw=.T.
	Case  c_uat_area = "GOLOMBHONIK"
		pl_Golomb=.T.
	Case    c_uat_area = "LOCKSLAW"
		pl_CivLocks=.T.
	Case    c_uat_area = "GREATAMERICAN"
		IF c_firm="F000020438"
			pl_Haworth = .T.	&& 10/29/18: added firm LOR [#114488]
		ELSE
			pl_CivGreat=.T.
		ENDIF
	Case    c_uat_area = "DT-BILOTTI"
		pl_CivDT=.T.
	Case    c_uat_area = "MULLERBRAZIL"
		pl_MulBrazil=.T.
	Case    c_uat_area = "LEVYBALDANTE"
		pl_CivLevyB=.T.
	Case    c_uat_area = "PIONNERONE"
		pl_CivPion=.T.
	Case    c_uat_area = "MDWCG/OHIO"
		pl_CivMdOhio=.T.
	Case    c_uat_area = "MCELDREW"
		pl_McEldrew=.T.
	Case    c_uat_area ="ANAPOL"  && pl_CivAnapol 4/28/14
		pl_CivAnapol=.T.
	Case    c_uat_area ="HANGLEY"      &&02/06/14 -added lor
		pl_CivHang =.T.
	Case    c_uat_area ="COACH-RONAN"
		pl_Ronan=.T.
	Case  c_uat_area ="SFNJ-LOPERFIDO"
		pl_CivSFLOP=.T.
	Case  c_uat_area ="REEDMORGAN"
		pl_ReedMgn=.T.

	Case c_uat_area ="CIECKA"
		pl_CivCiecka =.T.
	Case c_uat_area ="TANGLAW"
		pl_CivTang=.T.
	Case c_uat_area ="MESSA"
		pl_CivMess=.T.
	Case c_uat_area ="SFNJ-HELFRICH"
		pl_CivHelf=.T.
	Case c_uat_area ="SHERIDNMURR-PA"
		pl_CivShMr=.T.
	Case c_uat_area = "BEASLEY"  && 12/21/12 - added LOR
		pl_CivBeasly =.T.
	Case c_uat_area == "GOLDENBERG"
		pl_GoldenCiv = .T.
	Case Inlist( c_uat_area, "MARGOLIS/PHILA", ;
			"ME/PHILA/ERIE")
		pl_MargCiv= .T.
	Case c_uat_area == "FELDMAN"
		pl_CivFeld = .T.
**EF 9/9/08- angelos
	Case c_uat_area == "ANGELOS"
		pl_CivilAng  =.T.
	Case c_uat_area=="COACH-GALLOVIT" && 10/15/2012  added for lor
		pl_CivCoach=.T.
	Case  c_uat_area=="EISENBERG ROTH" &&10/09/13 added LOR
		pl_EisenRoth =.T.
	Case  c_uat_area=="GALLANTPARLOW" && added LOR 10/15/13
		pl_GallantPrlw=.T.
	Case  c_uat_area== "COACH-MCHUGH" &&added lor 11/13/13
		pl_MBCoach	=.T.
	Case  c_uat_area== "SMB-GORDON" 	&& JH added lor 10/24/19 ZD #147254
		pl_Gordon = .T.
	Case  c_uat_area== "WEIRKESTNER"	&& JH added lor 11/7/19 ZD #148948
		pl_WeirKest = .T.
	Case  c_uat_area== "GR-MO-SANDBERG"	&& JH added lor 11/12/19 ZD #151040
		pl_GrmoSand = .T.
	Case  c_uat_area== "BURNETT & WILL"	&& JH added lor 11/18/19 ZD #151666
		pl_BurnWill = .T.
	Case  c_uat_area== "SMB-JT FOX" 	&& JH added lor 12/16/19 ZD #154427
		pl_JTFox = .T.
	Case	c_uat_area=="ASHCRAFT&GEREL"	&& 02/20/2020 ZD #160709, JH
		pl_AshGerel = .T.
	Case	c_uat_area=="MAGNA-YOUNGCON"	&& 02/20/2020 ZD #161332, JH
		pl_MYngCon = .T.
	Case	c_uat_area=="M-GAIGREMINGER"	&& 02/27/2020 ZD #163070, JH
		pl_GAIGrem = .T.
	Case	c_uat_area=="M-UHS-HALLPRAN"	&& 02/27/2020 ZD #163074, JH
		pl_UHSHPrn = .T.
	Case	c_uat_area=="M-HM-KAUFMAN"	&& 02/27/2020 ZD #162627, JH
		pl_MagKauf = .T.
	Case	c_uat_area=="GR-NJ-SIMONLAW"	&& 02/27/2020 ZD #163671, JH
		pl_Simon = .T.
	Case	c_uat_area=="M-WEXP-COXPLLC"	&& 03/04/2020 ZD #163369, JH
		pl_WCoxPLC = .T.
	Case	c_uat_area=="M-IAT-AHMUTY"	&& 03/04/2020 ZD #163739, JH
		pl_IAhmuty = .T.
	Case	c_uat_area=="M-HM-SANDBERG"	&& 03/04/2020 ZD #163740, JH
		pl_HSandberg = .T.
	Case	c_uat_area=="M-GAIG-NASHCON"	&& 03/04/2020 ZD #163937, JH
		pl_GNashCon = .T.
	Case	c_uat_area=="M-GAIGMORRISON"	&& 03/11/2020 ZD #164789, JH
		pl_GAIGMor = .T.
	CASE	c_uat_area=="WILSONELSER-PA"	&& 03/24/2020 ZD #166181, JH
		pl_WilsonPA = .T.
	CASE	c_uat_area=="MINTZER & SAR"	&& 04/02/2020 ZD #166848, JH
		pl_Mintzer = .T.
	CASE    c_uat_area=="M-SEDCMS-MINTZ"	&& 04/08/2020 ZD #167197, JH
		pl_MSdMinz = .T.
	CASE    INLIST(C_UAT_AREA, "OLEARY IVC","OLEARY ROUNDUP","OLEARY TSTRN")
		pl_Olearys = .T.		&& 04/08/2020 ZD #167521, JH
	CASE    c_uat_area=="M-PHILA-MCNAB"	&& 06/23/2020, ZD #177673, JH
		pl_McNab = .T.
	CASE	c_uat_area=="M-PHILA-COHEN"		&& 07/21/2020, ZD #182049, JH
		pl_MPCohen = .T.
	CASE	c_uat_area=="M-ATLAS-BARTH"		&& 07/21/2020, ZD #181159, JH
		pl_AtlasB = .T.
	Case Inlist(c_uat_area,"M-PHILA-BROOKS", "M-ATLAS-BROOKS","M-LIBMUTBROOKS")	&& 07/29/2020, ZD #183629, JH
		pl_Brooks=.T.
	CASE	c_uat_area=="M-PHILASHEELEY"		&& 07/29/2020, ZD #183629, JH
		pl_Sheeley = .T.
	CASE	c_uat_area=="M-GUARD-OCONN"		&& 07/29/2020, ZD #183629, JH
		pl_OConnor = .T.
	CASE	c_uat_area=="M-COVTRANSPORT"		&& 08/05/2020, ZD #186305, JH
		pl_CovTrans = .T.
	ENDCASE
	

Case pc_litcode = "DFR" And c_uat_area == "ANGELOS"
	pl_DfrAng = .T.
**ADDED THREE MORE LITIGATION TO THAT CONDITION PER SARAH P. 11/13/08
**Avandia , Avelox ,Ground Water Cont
Case  Inlist(pc_litcode , "VIX" , "AVA", "AVX","WCT") And c_uat_area == "ANGELOS"
	pl_AnglVx = .T.
Case pc_litcode = "EVR" And c_uat_area = "NEW JERSEY"
	pl_EvrNJ = .T.
Case pc_litcode = "BXA" And c_uat_area = "MOTLEY"
	pl_BexMot = .T.
Case pc_litcode="IRG" And c_uat_area ="FLORIDA"
	pl_IRGFl=.T.

Case pc_litcode="ZPX" And c_uat_area ="LEVIN PAPANTO"
	pl_Zyprx=.T.

Case  pc_litcode="CLX" And c_uat_area ="LEVIN PAPANTO"
	pl_Clbrx=.T.

**5/20/09 new ene area added
Case  pc_litcode="ENE"
	Do Case
	Case c_uat_area ="POWELL LAW GRP"
		pl_ENEPwl=.T.
	Case c_uat_area = Upper("Bristol Myers")
		pl_ENEBrist  =.T.

	Endcase
**EF 2/10/05 Zicam Issues
Case  pc_litcode="ZCM"
	Do Case
	Case c_uat_area ="ARIZONA"
		pl_Zicam=.T.

	Case Inlist( c_uat_area, "FEDERAL"	, "STATE")
		pl_ZcmFed=.T.
	Endcase



*EF  11/17/04 ENBREL-Motley cases
Case pc_litcode = "ENB" And c_uat_area = "MOTLEY"
	pl_ENBMot = .T.

*EF 11/03/04 VIX-Motley
**3/13/08 added another area to vix
Case pc_litcode = "VIX"
	Do Case
	Case c_uat_area = "MOTLEY"
		pl_VIXMot = .T.
	Case c_uat_area = "NEBLETT"
		pl_VXNeblett=.T.
	Endcase
* 09/17/04 Serzone Cases

Case pc_litcode = "SRZ" And c_uat_area = "WESTVIRGINIA"
	pl_SRZNot =.T.

* EF 10/15/04 HRT-Morgan
* IZ 05/10/04 HRT-Cohen Cases
Case pc_litcode == "HRT"
	Do Case
	Case c_uat_area = "COHEN"
		pl_HRTLor = .T.
	Case c_uat_area = "MORGAN"
		pl_HrtMorg =.T.
	Endcase

* EF 04/14/04 Stadol/Sedgwick cases
Case pc_litcode == "STD" And c_uat_area = "SEDGWICK"
*CASE pc_litcode == "STD" AND UPPER( pc_area) = "SEDGWICK"
** AND pc_billpln = "SZ" AND pc_rqatcod = "A25465P"
	pl_STDSed = .T.
* 02/27/04 StateDD
Case pc_litcode == "G  "
	pl_StDietD = .T.
&&02/04/04 Add Welding Rod
Case pc_litcode == "WRD"
	pl_WeldRod = .T.

Case  pc_litcode = "RMD"
*09/17/04 Two var for Remicade lit cases
	Do Case
	Case c_uat_area = "NEWJERSEY"
		pl_Remic = .T.
	Case c_uat_area = "MOTLEY"
		pl_Motley =.T.
	Endcase

Case pc_litcode = "MLD" And c_uat_area = "NEWYORK"
	pl_MoldNY = .T.


Case pc_litcode = "2  "
	Do Case

	Case c_uat_area == "WILLIAMS"
		pl_RezWil = .T.

	Case c_uat_area == "MONTGOMERY"
		pl_RezMont = .T.

	Case c_uat_area == "MDL-HOLD"
		pl_MdlHold = .T.

	Case Inlist( c_uat_area, "MDL", "NYMDL")
		pl_RezMdl = .T.

	Case c_uat_area == "NEWYORK"
		pl_RezNY = .T.

	Endcase

Case pc_litcode == "3  "

	Do Case
	Case c_uat_area == "NONE"
		pl_PropNon =.T.

	Case Inlist( c_uat_area, "FEDERAL", ;
			"LA-FEDERAL", "PR-FEDERAL", "FED-SPECIFIC")
		pl_Propuls = .T.

	Case c_uat_area = "MISSISSIPPI"
		pl_PropMS = .T.

	Case c_uat_area = "PENNSYLVANIA"
		pl_PropPA = .T.

	Case c_uat_area = "NEWJERSEY"
		pl_PropNJ = .T.

	Case c_uat_area = "FEDERAL"
		pl_PropFed = .T.

	Case c_uat_area = "BLACKMON"
		pl_PropBlk = .T.

	Case Inlist( c_uat_area, "NJ-SPECIFIC", "PA-NO NOTICE")
		pl_NJSpec = .T.
	Endcase

Case pc_litcode == "A  "
	pl_TxAbex = Inlist( c_uat_area, ;
		"TX-GERMER", "TX_ABEX", "TX_PHICO", "TEXAS", "TX-CIVIL", "TX_AFFIDAVIT")
	pl_OhioAsb = (c_uat_area == "OHIO")
	pl_ASBHIPAA = Inlist( c_uat_area, ;
		"PHILADELPHIA", "PENNSYLVANIA", "PA-NORTHAMPTON")

	If Inlist( c_uat_area, "NYC", "NYC FIFO", "NEWYORK")
*8/19/2011 per Alec :pl_NYCAsb = (c_uat_area = "NYC")
		pl_NYCAsb=.T.
	Endif
	pl_AsbAngl=(c_uat_area == "ANGELOS")

	pl_BiceFl =(c_uat_area == "FLORIDA BICE")

	pl_NJAsb = (Alltrim(Upper(c_uat_area)) = "NEWJERSEY")

	pl_CambAsb =(Alltrim(Upper(c_uat_area)) = "CAMBRIA COUNTY")

Case pc_litcode == "P  " And c_uat_area = "CLASS COUNSEL"
	pl_FenPhen = .T.

Case Inlist( pc_litcode, "5  ", "6  ") And c_uat_area = "LEVIN,FISHBEIN"
	pl_PPAPage = .T.

Case pc_litcode == "8  "
	Do Case
	Case c_uat_area = "SCHIFFRIN"
		pl_BaySch = .T.
	Case c_uat_area = "PHILADELPHIA"
		pl_BayCol = .T.
	Endcase

Case pc_litcode == "D  "
	pl_DietDrg = .T.

Case pc_litcode == "E  "
	pl_DDrug2 = .T.

Case pc_litcode == "MER" And c_uat_area = "SCHIFFRIN"
	pl_MerSch = .T.

Case pc_litcode == "THI"
	Do Case
	Case c_uat_area = "EVERT"
		pl_ThiEve = .T.
	Case c_uat_area = "MILLER"
		pl_Thimil = .T.
	Case c_uat_area = "ANGELOS"
		pl_THIAngl = .T.
	Endcase

Case pc_litcode == "Z  "
	pl_OhioSil = (c_uat_area == "OHIO")
Endcase


pc_Initials=getInitials(pc_amgr_id)

If l_MasterOnly Then
	Return
Endif
*
*   The following subsections store values in public variables
*  by using a Master field as the key to a lookup file.
*
c_near = Set("NEAR")
Set Near Off
*
*  Look up filing office data in Office file
*
Store "" To pc_ofcdesc, pc_ofcstat
If Not Empty( pc_offcode)
	If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
		oMedGen=Createobject("generic.medgeneric")
	Endif
	oMedGen.sqlexecute("exec dbo.GetOfficeListByCode '" + pc_offcode + ;
		"', '" + Master.id_tblmaster + "'", "Office")
	pc_ofcdesc = Allt( Office.Desc)
	pc_ofcstat = Allt( Office.State)

	Store .F. To pl_ofcKOP, pl_ofcMD, pl_ofcPgh, pl_ofcOak, ;
		pl_ofcPas, pl_ofcHous, pl_MdAsb, pl_MdSumAsb
	Do Case
	Case pc_offcode = "P"
		If "MD-" $ pc_Court1
			pl_ofcMD = .T.
		Else
			pl_ofcKOP = .T.
		Endif
	Case pc_offcode = "M"
		pl_ofcMD = .T.
	Case pc_offcode = "G"
		pl_ofcPgh = .T.
	Case pc_offcode = "C"
		pl_ofcOak = .T.
	Case pc_offcode = "S"
		pl_ofcPas = .T.
	Case pc_offcode = "T"
		pl_ofcHous = .F.
	Endcase

Endif

*--4/6/06 kdl: set version variables for conversion
pl_KoPVer=Iif(Not Inlist(pc_offcode,'C','S'), .T., .F.)
pl_CaVer=Iif(Inlist(pc_offcode,'C','S'), .T., .F.)
**04/23/12= KOP WCAB SUBPOENAS
pl_WCABKOP=Iif(pl_KoPVer And Alltrim(pc_Court1)='WCAB'  , .T.,.F.)

** --- 08/03/2020 MD #173172 -----------------------------------
**pl_ILCook=Iif(pl_KoPVer And Alltrim(pc_Court1)='IL-COOKCOUNTY'  , .T.,.F.)
pl_ILCook=Iif(pl_KoPVer And LEFT(UPPER(Alltrim(pc_Court1)),3)="IL-" and ALLTRIM(UPPER(pc_Court1))<>"IL-WCC" , .T.,.F.)
** --- 08/03/2020  #173172 -----------------------------------

** --- 08/04/2020 MD #170629 -----------------------------------
plCourtIN=Iif(pl_KoPVer And LEFT(UPPER(Alltrim(pc_Court1)),3)="IN-", .T.,.F.)
** --- 08/04/2020 MD #170629 -----------------------------------
**md lead

pl_MDLead= Iif(pc_litcode="LEA"  And  pl_ofcMD,.T., .F.)

**EF 09/11/03
*
*    Look up Group-related data in CaseInfo file
* Done only for Ohio Asbestos/Silica cases filed in KoP Office
*
Store "" To pc_grpname, pc_casname, pc_casenum,  pc_BarNo, pc_Suffix
pl_nogroup = .T.




If pl_ofcKOP And (pl_OhioAsb Or pl_OhioSil)
	If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
		oMedGen=Createobject("generic.medgeneric")
	Endif
	oMedGen.sqlexecute("exec DBO.GetCaseInf " + c_clcode, "CaseInfo")
	Select CaseInfo

	If Not Empty( CaseInfo.GroupName + CaseInfo.CaseName + CaseInfo.CaseNum)
		pc_grpname = CaseInfo.GroupName
		pc_casname = CaseInfo.CaseName
		pc_casenum = CaseInfo.CaseNum
		pl_nogroup = .F.
	Endif
Endif
*
*   Look up area-related data in area file
*
Store "" To pc_areamgr, pc_arealit, Area_ID
pc_areanot = .F.
If Not Empty( pc_area)
	If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
		oMedGen=Createobject("generic.medgeneric")
	Endif
	oMedGen.sqlexecute("exec dbo.GetAreaListByArea '" + fixquote(pc_area) + ;
		"', '" + Master.id_tblmaster + "'", "Area")
	Select Area
	pc_areanot = Area.Notice
	pc_areamgr = Area.AcctMgr
	pc_arealit = Area.lit
	pc_AreaID  = Area_ID
Endif

*
*	PULL SETTINGS BASED ON USERS LOGIN, NOT ACCT. MGR LOGIN
*

If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
	oMedGen=Createobject("generic.medgeneric")
Endif
oMedGen.sqlexecute("exec dbo.GetUserCtrlByLogin '" + ;
	fixquote(Alltrim(goApp.CurrentUser.ntlogin)) + "', '" + Master.id_tblmaster + "'", "UserCtrl0")
Select UserCtrl0
pl_Txn23Allow= Nvl(UserCtrl0.txn23access,.F.)
pl_AddCredit=Nvl(UserCtrl0.AddCreditTxn,.F.)
pl_RejectQueue=Nvl(UserCtrl0.ResolvedQueueAcces,.F.)
pl_NoQCIssue=Nvl(UserCtrl0.QCIssue,.F.)
pl_OutofBus =Nvl(UserCtrl0.AccessOutofBusiness,.F.)
*
*  Look up client representative and salesperson info in UserCtrl file
*

Store "" To pc_amgr_nm, pc_amgr_ml, pc_amgr_ph, ;
	pc_sale_nm, pc_sale_ml, pc_sale_ph, pc_ScanSg
Store  .F. To pl_ScanSig
*If  Not Empty( pc_amgr_id)
** YS 05/16/18 Modifed to check if 'pc_amgr_id' is null
 If  Not Empty(NVL(pc_amgr_id,''))
	If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
		oMedGen=Createobject("generic.medgeneric")
	Endif
	oMedGen.sqlexecute("exec dbo.GetUserCtrlByLogin '" + ;
		fixquote(Alltrim( pc_amgr_id)) + "', '" + Master.id_tblmaster + "'", "UserCtrl")
	** YS 05/16/18 Added to check if 'UserCtrl' has value
	If Used("UserCtrl") And Reccount("UserCtrl")>0
		Select UserCtrl

		If ALLTRIM(UPPER(UserCtrl.Login)) = ALLTRIM(UPPER(pc_amgr_id))		&& 6/20/2023, ZD #318311, JH
			pc_amgr_nm = Allt( UserCtrl.FullName)
			pc_amgr_ml = Allt( UserCtrl.Email)
			pc_amgr_ph = Allt( UserCtrl.DirectDial)
	*Pick up scanned signature data, if available
			pc_ScanSg = Allt( UserCtrl.SigFile)
			pl_ScanSig = UserCtrl.ScannedSig
		ENDIF
	ENDIF
Endif

If Not Empty( NVL(pc_salesmn, ""))
*--12/01/05 DMA Corrected to use proper key and unique cursor
	If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
		oMedGen=Createobject("generic.medgeneric")
	Endif
	oMedGen.sqlexecute("exec dbo.GetUserCtrlByLogin '" + ;
		fixquote(Alltrim( pc_salesmn)) + "', '" + Master.id_tblmaster + "'", "UserCtrl2")
	Select UserCtrl2

	If UserCtrl2.SalesPer
		pc_sale_nm = Allt( UserCtrl2.FullName)
		pc_sale_ml = Allt( UserCtrl2.Email)
		pc_sale_ph = Allt( UserCtrl2.DirectDial)
	Endif


Endif



oMedGen.closealias('KOP4Ca')
oMedGen.sqlexecute("select dbo.KOPCases4CaOffice ('" + pc_offcode + "','" + Alltrim(pc_amgr_id) + "','" + pc_litcode + "')","KOP4Ca")
If Used('KOP4Ca') And!Eof()
	pl_CAinKOP=KOP4Ca.Exp
Else
	pl_CAinKOP=.F.
Endif


*pl_CAinKOP=(pl_ofcKOP and pc_litcode == "C  " And pc_amgr_id='MELISSA')




Set Near &c_near
*
*   Look up litigation-based information in Lit file
*
If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
	oMedGen=Createobject("generic.medgeneric")
Endif
oMedGen.sqlexecute("exec dbo.GetLitigationListByCode '" + pc_litcode + ;
	"', '" + Master.id_tblmaster + "'", "Lit")


If Used("Lit") And Reccount("Lit")>0
	Select lit
	pc_litname  = Allt( lit.Desc)
	pn_litiday = lit.IssDays
	pc_litnotc = lit.NoticeName
	pn_litfday = lit.FrDays
	pc_litfnot = lit.FrNotice
**!**pl_litnofx = Lit.NoFax
	pl_litath2 = lit.Autho2
**!**pc_litdcap = Lit.DefCap
	pc_litsnot = lit.Subnotice
	pc_ltsfnot = lit.sfrnotice
* 05/07/03 dma start: new litigation-based image database ID
**!**   pc_imagedb = Lit.ImageDB
* 05/07/03 dma end
Else
	Store 0 To pn_litiday, pn_litfday
	Store .F. To pl_litnofx, pl_litath2
	Store "" To pc_litname, pc_litnotc, pc_litfnot, pc_litdcap, pc_imagedb
Endif


** EF 09/11/03 treat KOP areas Maryland and MD/Summarized as MD office cases
** IZ 11/18/03 assign public for the Phila-Asbestos-MD-Summarized
If pc_litcode = "A  "
	If pl_ofcKOP
		If c_uat_area == "CONNECTICUT"
			pl_AsbCon = .T.
		Endif
		If c_uat_area = "MD/SUMMARIZED"
			pl_MdSumAsb = .T.
		Endif
		If Inlist( c_uat_area, "MARYLAND", "MD/SUMMARIZED")
			pl_ofcMD = .T.
		Endif

	Endif
* DMA 12/13/03 Update next section to use lookup table for attorney codes.
*--12/11/03, 12/12/03 kdl start: added attorney code "A1691P", "A24604P" to list
**EF  12/22/03 Add A20914P to the list
	If pl_ofcMD
		If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
			oMedGen=Createobject("generic.medgeneric")
		Endif
		oMedGen.sqlexecute("exec dbo.GetCovrCtrl", "CovrCtrl")
		Select CovrCtrl
		Index On At_Code Tag At_Code
		Set Order To At_Code
		If Seek( pc_rqatcod)
			pl_MdAsb = CovrCtrl.MD_Asb
		Endif

	Endif
Endif
* 01/24/05 DMA Move flag settting here, after pl_OfcPas has a value.
* 05/06/04 DMA Add Pasadena Groundwater flag
pl_PSGWC = pl_ofcPas And pc_litcode == "GWC"

***10/05/2010 - LITIGTAION RULES FOR EMAIL NOTICES
oMedGen.sqlexecute("select dbo.LitRulesEmailNotice ('" + pc_offcode + "', '" + pc_litcode + "', '" + pc_area + "')", "LitNotice")
pl_ElitNotice= Nvl(LitNotice.Exp,.F.)
***10/05/2010 - LITIGTAION RULES FOR EMAIL NOTICES



*  Look up critical case-instruction information in
*  INSTRUCT File
*
Store .F. To pl_rushcas, pl_scanned, pl_nohold, pl_autscan, pl_review, ;
	pl_bates, pl_sgncert
pc_specbates=""
Store c_nodate To pd_revstop
Store 0 To pn_req_by
If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
	oMedGen=Createobject("generic.medgeneric")
Endif
oMedGen.sqlexecute("exec DBO.GetInstruct2 " + c_clcode, "Instruct")
Select Instruct

If Reccount("Instruct")>0
	pl_rushcas = Instruct.Rush
	pl_scanned = Instruct.ScndFile
	pn_req_by  = Instruct.Req_By
	pl_autscan = Instruct.AuthScnd
	pl_review  = Instruct.Review
	pd_revstop = Nvl(Instruct.Untildate,c_nodate)
	pl_bates   = Instruct.Bates
	pl_sgncert = Instruct.SignedCert
	pl_nohold  = Instruct.NoHold
*--3/13/03 kdl start: add 1st look variables
	pl_CFlook = Instruct.Firstlook               && Case level 1st look
	pc_FlAtty = Nvl(Instruct.Flookatty ,'')              && 1st look attorney
	pn_Fldays = Instruct.Fl_days                 && Case level 1st look review days
	pc_Fltype = Instruct.Flday_type              && Case level 1st look type of review days (Business or Calender)
	pc_Flship = Iif( Empty(Nvl(Instruct.Flshiptype,"")), ;
		"E", Instruct.Flshiptype)                 && Case level 1st look shipment method code
*--4/02/04 kdl start:
	pl_FlNrs  = Instruct.Fl_shipnrs              && 1st look ship NRSs preference
	pc_specbates = Alltrim(Upper(Nvl(Instruct.specBates,"")))
Else
	pl_CFlook = .F.
	pc_FlAtty = ""
	pn_Fldays = 0
	pc_Fltype = ""
	pc_Flship = "E"
	pl_FlNrs = .F.

*--3/13/03 kdl end:
Endif

*
*  Look up Court-specific data in Court or TxCourt file for both
*  primary and secondary courts.
*
Store .F. To pl_c1Form, pl_c1SSubp, pl_c1Notic, pl_c1Prvdr, ;
	pl_c1PrtSc, pl_c1Cert, pl_c2Form, pl_c2SSubp, pl_c2Notic, pl_c2Prvdr, ;
	pl_c2PrtSc, pl_c2Cert, pl_BIHipaa, pl_CrtFlng, pl_WebForm
Store 0 To pn_c1Due, pn_c1Hold, pn_c1Cmply, ;
	pn_c2Due, pn_c2Hold, pn_c2Cmply
Store "" To pc_c1name, pc_c1Desc, pc_c1Cnty, pc_c1Addr1, pc_c1Addr2, ;
	pc_c1Addr3, pc_c1City, pc_c1State, pc_c1Zip, pc_c1Phone, ;
	pc_c2Name, pc_c2Desc, pc_c2Cnty, pc_c2Addr1, pc_c2Addr2, ;
	pc_c2Addr3, pc_c2City, pc_c2State, pc_c2Zip, pc_c2Phone, ;
	pc_TxCtTyp, pc_TxCtLn1, pc_TxCtLn2, pc_TxCtLn3, pc_txCrtType, ;
	pc_TxDist, pc_TxDiv, pc_TxCSZ, pc_TxHold, pc_RpsForm
If pl_ofcHous
	pc_Court2 = Allt( pc_Court2)
	If Empty( pc_plcnty) And pc_Court2 == "US-DOC"
		pc_docket = "OWCP" + Allt( Upper( pc_docket))
	Endif
	If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
		oMedGen=Createobject("generic.medgeneric")
	Endif
	oMedGen.sqlexecute("exec dbo.GetAllTxCourt", "TxCourt")
	pc_TxCtTyp = Subs( pc_Court1, 1, 3)
	Select TxCourt
	CursorSetProp("KeyFieldList", "COURT,CRT_ID,County", "TXCourt")
	Index On Court Tag Court
	Index On CRT_ID Tag CRT_ID
	Index On County Tag County
	Do Case

	Case pc_TxCtTyp = "FED"
		Index On CRT_ID Tag Federal For CRTType = "FED"
		Set Order To Federal
		Seek( pc_Court2)
		pc_TxHold  = "(14) fourteen"
		Do Case

		Case pc_Court2 == "US-DOL"
			pc_TxCtLn1 = "UNITED STATES DEPARTMENT OF LABOR"
			pc_TxCtLn2 = "OFFICE OF ADMINISTRATIVE LAW JUDGES"

* 06/29/04 DMA Copied Georgia/Federal from gfTxCour for consistency
		Case c_uat_area = "GEORGIA"
			pc_TxCtLn1 = ""
			pc_TxCtLn2 = "IN THE SUPERIOR COURT OF FULTON COUNTY"
			pc_TxCtLn3 = "STATE OF GEORGIA"

		Otherwise
			pc_TxCtLn1 = "UNITED STATES DISTRICT COURT"
			pc_TxCtLn2 = Allt( TxCourt.District) + " DISTRICT"
			pc_TxCtLn3 = Allt( TxCourt.Division) + " DIVISION"

		Endcase

	Case pc_TxCtTyp = "CCL"
		Index On County Tag CCL For CRTType = "CCL"
		Set Order To CCL
		Seek pc_plcnty
* 06/15/04 DMA Correct phrasing on court title
		pc_TxCtLn1 = "In the County Civil"
		pc_TxCtLn2 = "Court At Law No. " + Allt( pc_cclnum)
*         pc_TxCtLn1 = "In the County Court"
*         pc_TxCtLn2 = "At Civil Law No. " + ALLT( pc_cclnum)
		pc_TxCtLn3 = Allt( pc_plcnty) + " County, Texas"
		pc_TxHold  = "(20) twenty"

	Case pc_TxCtTyp = "DIS"
		Index On County Tag District For CRTType = "DIS"
		Set Order To District
		Seek pc_plcnty
* 06/29/04 Copied WV handler from gfTXCour for consistency
		pc_TxCtLn1 = "In the " + Upper( Allt( pc_distrct)) + ;
			IIF( c_uat_area = "WESTVIRGINIA", " Circuit", " District")
		pc_TxCtLn2 = "Court In and For "
		pc_TxCtLn3 = Uppe( Allt( TxCourt.County)) + " County, " + ;
			IIF( c_uat_area = "WESTVIRGINIA", "West Virginia", "Texas")
		pc_TxHold  = "(20) twenty"
	Endcase
	pc_c1name  = TxCourt.Court
	pc_c1Desc  = TxCourt.Desc
	pl_c1Form  = TxCourt.HasForm
	pl_c1SSubp = TxCourt.ScanSubp
	pn_c1Due   = TxCourt.Add_Due
	pl_c1Notic = TxCourt.Notice
	pc_c1Cnty  = TxCourt.County
	pn_c1Hold  = TxCourt.Hold
	pn_c1Cmply = TxCourt.Comply
	pl_c1Prvdr = TxCourt.Provider
	pl_c1PrtSc = TxCourt.PrintSC
	pl_c1Cert  = TxCourt.CourtCert
	pc_c1Addr1 = TxCourt.Add1
	pc_c1Addr2 = TxCourt.Add2
	pc_c1Phone = TxCourt.Phone
	pc_c1City  = TxCourt.City
	pc_c1State = TxCourt.State
	pc_c1Zip   = TxCourt.Zip
	pc_TxDiv   = TxCourt.Division
	pc_TxDist  = TxCourt.District
	pc_TxCSZ   = TxCourt.csz
	pc_RpsForm = Alltrim( TxCourt.RpsForm)
	pl_CrtFlng = TxCourt.CrtFiling

Else
	If Type("oMedGen")!="O" Or Isnull(oMedGen)=.T.
		oMedGen=Createobject("generic.medgeneric")
	Endif
	oMedGen.sqlexecute("exec dbo.GetAllCourt", "Court")
	Select Court
	CursorSetProp("KeyFieldList", "COURT", "Court")
	Select Court
	Index On Court Tag Court
	If Not Empty( pc_Court1)
		Select Court
		Scan For Alltrim(Upper(Court.Court)) == Upper(pc_Court1)
			pc_c1name  = Court.Court
			pc_c1Desc  = Court.Desc
			pl_c1Form  = Court.HasForm
			pl_c1SSubp = Court.ScanSubp
			pn_c1Due   = Court.Add_Due
			pl_c1Notic = Court.Notice
			pc_c1Cnty  = Court.County
			pn_c1Hold  = Court.Hold
			pn_c1Cmply = Court.Comply
			pl_c1Prvdr = Court.Provider
			pl_c1PrtSc = Court.PrintSC
			pl_c1Cert  = Court.CourtCert
			pc_c1Addr1 = Court.Add1
			pc_c1Addr2 = Court.Add2
			pc_c1Phone = Court.Phone
			pc_c1City  = Court.City
			pc_c1State = Court.State
			pc_c1Zip   = Court.Zip
			pc_RpsForm = Alltrim( Court.RpsForm)
			pl_CrtFlng = Court.CrtFiling
			pl_WebForm =Nvl(Court.newrule,0)
			pc_txCrtType=Nvl(Court.txCrtType,'')
		Endscan
	Endif
	If Not Empty( pc_Court2)
		Select Court
		Scan For Alltrim(Upper(Court.Court)) == Upper(pc_Court2)
			pc_c2Name  = Court.Court
			pc_c2Desc  = Court.Desc
			pl_c2Form  = Court.HasForm
			pl_c2SSubp = Court.ScanSubp
			pn_c2Due   = Court.Add_Due
			pl_c2Notic = Court.Notice
			pc_c2Cnty  = Court.County
			pn_c2Hold  = Court.Hold
			pn_c2Cmply = Court.Comply
			pl_c2Prvdr = Court.Provider
			pl_c2PrtSc = Court.PrintSC
			pl_c2Cert  = Court.CourtCert
			pc_c2Addr1 = Court.Add1
			pc_c2Addr2 = Court.Add2
			pc_c2Addr3 = Court.Add3
			pc_c2City  = Court.City
			pc_c2State = Court.State
			pc_c2Zip   = Court.Zip
			pc_c2Phone = Court.Phone
			pc_RpsForm = Alltrim( Court.RpsForm)
			pl_CrtFlng = Court.CrtFiling
			pl_WebForm =Nvl(Court.newrule,0)
			pc_txCrtType=Nvl(Court.txCrtType,'')
		Endscan
	Endif

Endif

&&2.11.15-start- pccp follows kopgeneric (almost) with its own form
*!*	IF checktest("NEWPCCP")
*!*		IF pc_RpsForm='WEBFORM'
*!*			IF  pc_Court1 ='PCCP'
*!*				pl_c2Form=.f.  &&test cycle only: update tblcourt when do to  RTS production
*!*			ENDIF
*!*		ENDIF
*!*	ENDIF
&&2.11.15- end-pccp follows kopgeneric (almost) with its own form



**09/21/2017 : Released the TX docs/ removed test mode
**06/08/2017 : TX docs
*!*	If checktest("TXDOCS")=.F.
pl_txcourt= ( Alltrim( Left( pc_Court1, 2)) = "TX")
If  pl_txcourt 
	pc_RpsForm=""
	IF ALLTRIM(NVL(PC_TXCRTTYPE,""))="DISTRICT"
		pc_Suffix=addSuffix()
	ENDIF 
Endif
*!*	Else
*!*		pl_txcourt=.F.
*!*	Endif



pc_BarNo=""
l_BarNum=.F.
If (pl_txcourt And !Empty(Nvl(pc_rqatcod,''))) Or pl_CivBle

	c_rqcode=fixquote(pc_rqatcod)
	oMedGen.closealias("AtBarNo")
	l_BarNum=oMedGen.sqlexecute("SELECT dbo.fn_AttyBarNum('" + c_rqcode+ "')", "AtBarNo")
	pc_BarNo=Iif(l_BarNum,AtBarNo.Exp, "")

Endif
**06/08/2017 : TX docs


pn_HoldSub = Iif( pl_nohold, 0, pn_c1Hold)

pl_MichCrt = ( Alltrim( Left( pc_Court1, 2)) = "MI")
pl_ExclMI=Iif( Alltrim( pc_Court1 ) = "MI-WCAB",.T.,.F.)
pl_NJSub = "New Jersey" $ pc_c1Desc
&&07/10/09 - PA courts
&&06/29/11 -added NJ subps
If "PA" $ pc_Court1 Or Alltrim(pc_Court1) ="PCCP" Or pl_NJSub
	pl_PAsubp= .T.
Endif
*!*	IF pl_NJSub && TEST MODE!! - remove when global updates for courts is done.
*!*		pl_c1SSubp=.F.
*!*	ENDIF

pl_ScanSub = Iif( pl_Propuls And Inlist( pc_Court1, ;
	"MDL", "MDL-1355", "MS-JEFFERSON"), .T., pl_c1SSubp) And pl_ofcKOP

&&11/12/03 Breast Implant hold cases

pl_BIHipaa = pc_litcode = "M  " And pn_HoldSub <> 0
pl_CivilNY = (c_uat_area = "NEWYORK" And pc_litcode="C  ")

** EF  07/29/04 - Variables to identify situations requiring special
** Letters of Representation

pl_Shelltr = (c_uat_area = "SHELLER" And ;
	INLIST( pc_litcode, "C  ", "0  ", "AVX", "FLX", "LQN", "MMR", "CRO", "PPO"))
pl_LotronB = ( c_uat_area = "BEASLEY" And ;
	INLIST( pc_litcode, "LNX" , "VIX", "2  ", "8  "))
pl_A044584P = (Alltrim( pc_rqatcod) = "A044584P")
pl_A18839P = (Alltrim( pc_rqatcod) = "A18839P")

pl_PropNJ1 = ( pl_PropNJ And c_uat_area = "PA-NO NOTICE")
pl_PropDr  = ( pl_Propuls And pc_offcode == "P")
pl_CivGar = (c_uat_area = "GARFINKEL" And pc_litcode="C  ")

&&02/12/04  All PA courts have to print HIPAA sets.
** --- 08/04/2020 MD #170629 added plCourtIN=.T. ----------------------------------- 
pl_Hipaa = pl_ofcMD Or pl_CrtFlng  Or pl_NJSub  Or pl_ILCook    Or pl_txcourt or plCourtIN=.T.
** 10/11/08 add hippa to USDC PA requests
**09/17/09 - USDC like courts follow the same rule
If   Left( Alltrim(Master.Court), 4) = "USDC" &&03/01/12 print the same USDC form for all offices AND pl_ofcKOP
	pl_Hipaa =.T.
Endif
**end 11/10/08


Select Master
pl_GotCase = .T.
Return

