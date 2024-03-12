PROCEDURE PUBLIC
#Include App.h

*   PUBLIC.PRG
*
* PUBLIC variable definitions for RTS
*   Variables are defined and, when appropriate, initialized here
*   for repeated use throughout the system.
*
*  Calls: gfGetDat
*  Uses 3rd party libraries NetLib3 and NL1MainU to acquire user ID info
*  from the operating system.
*
*   REMINDER: Changes to this routine may require changes to one or more
*   of the following data-definition routines:
*         gfGetCas and gfClrCas, gfGetDep and gfClrDep
*         gfGetAtt, gfGetLit
*
* 08/25/2021 kdl: added pl_Oak_FL_Type - flag to identify Oakland fist-look login path [247599]
* 09/14/2020 JH Added pl_use_LOR_Refer		&& 9/23/2020, ZD #190778, JH.
* 08/05/2020 JH Added pl_CovTrans
* 07/30/2020 JH Added pl_Brooks, pl_Sheeley, pl_OConnor, pl_VigoriGAR, pl_VigoriVAL, pl_TraubNJ, pl_TraubNY
* 07/21/2020 JH Added pl_AtlasB, pl_MPCohen
* 06/23/2020 jh Added pl_McNab
* 04/08/2020 JH Added pl_Olearys, pl_MSdMIntz
* 04/02/2020 JH	ADded pl_Mintzer
* 03/24/2020 JH Added pl_WilsonPA
* 03/11/2020 JH	Added pl_GAIGMor
* 03/04/2020 JH Added pl_WCoxPLC, pl_IAhmuty, pl_HSandberg, pl_GNashCon
* 02/27/2020 JH Added pl_GAIGrem, pl_UHSHPrn, pl_MagKauf LORS
* 02/10/2020 JH	Added pl_Hawk for LOR
* 02/07/2020 JH	Added pl_AshGerel for LOR
* 12/16/2019 JH	 Added pl_JTFox, pl_WilEls
* 11/18/2019 JH  Added pl_BurnWill
* 11/12/2019 JH	 Added pl_GrmoSand
* 11/07/2019 JH  Added pl_WeirKest
* 10/24/2019 JH  Added pl_Gordon
* 07/25/2017 - MD make case menu font bigger #65636
* 08/22/11  EF   Added pl_BALsrq
* 06/14/11  EF   Added pl_HRobins
* 06/07/11  EF   Added pl_BPBLit
* 03/02/11  EF   Added pl_RisPCCP
* 09/23/10  EF   Added pl_CambAsb
* 08/12/10  MD   Added pl_NJAsb    
* 06/09/10  EF 	 Added pc_LocStatus
* 04/15/10	EF   Added Bailey/Digitek
* 03/10/10  EF   Added Ava1 lit vars
* 02/24/10  EF 	 added pl_LevaNJ
* 11/06/09  EF   Added pl_FbtSal
* 08/14/09  EF   Added pl_FLRHi
* 07/10/09  EF   Added pl_PAsubp
* 06/26/09  EF   Added pl_NonGBB 								&& BBnongeneric cases
* 06/08/09	EF   Added pc_AIPimg
* 04/30/09  MD   Added pl_NoFaxNotice
* 05/17/09  EF   Added pl_AVAPltf								&& Avandia /Plaintiff cases
* 01/16/09  EF   Added Pd_CaSrvDt
* 06/11/08  EF   Added pl_AddCredit
* 06/09/08  EF   Added pl_TBTAstk
* 09/25/07  EF   Added pl_Popcorn
* 09/12/07  EF   Added pl_TRBAngl, pl_THIAngl and pl_AsbAngl vars.
* 08/27/07  EF   Added vars for the Issue from the Deponent Level option.
* 03/28/07  EF   Added pl_CivSubp var
* 02/09/07  EF   Added Bice lit
* 01/19/07  EF   Added Civil/Margolis/Me/Erie
* 01/04/07  EF   Added 'Ecoli' vars.
* 12/01/06  EF   Synch with the latest Fox version.
* 10/26/06  EF   Added  pl_WFSBart
* 09/15/06  EF   Synch with the latest FoxPro vesrion for printing docs.
* 08/07/06  EF   Lead/Motley has been added: pl_LeadMot
* 06/06/06  EF   Added pl_CRTAngl, pl_DVPAngl, pl_OSCAngl + DFR/Aylstock
*                 pl_HTSMotl, pl_RNUAngl, pl_PhenAng, pl_PxlDech
*                 pl_DrinkRMD, pl_GoldenCiv
* 03/16/06  EF   Added pl_DfrAng, pl_AnglVx, pl_EvrNJ,pl_BexMot var to print the new LORs
* 01/18/06  EF   Added pl_ENEPwl, pl_Clbrx, pl_IRGFL, pl_CivilNY, pl_Zyprx
* 02/10/05  EF   Added "ZCM" lit vars
* 01/20/05  DMA  Remove use of Worker field in TAMaster
* 01/05/05  kdl  Added soft image system variables
* 11/17/04  EF   Added pl_ENBMot
* 11/03/04  EF   Added pl_HRTMorg
* 10/14/04  EF   Added pl_HRTMorg
* 09/23/04  EF   Added pl_civGar (Civil lit -Garfinkel Area cases)
* 09/17/04  EF   Added Var to handle Serzone Notices and Remicade-Motley LOR
* 08/02/04  DMA  Add pl_NYCAsb
* 07/29/04  EF   Added pl_Shelltr, and other LOR vars
* 07/08/04  DMA  l_EditMode becomes pl_EditReq
*                szlogpath, oloc, szoloc removed
* 07/07/04  kdl  Added pc_Ordlink variable for use with the DS system
* 06/22/04  DMA  Remove szExt, szWrkName
* 06/10/04  DMA  Add in laser-printer codes from old LASERCODES routines
* 06/08/04  EF   Start using new DATADIR Files
* 05/10/04  IZ   Added logical variable for the area="Cohen" and Litigation = "HRT"
* 04/21/04  kdl  Added pc_Email to hold email address btw DS jobs
* 04/19/04  EF   Added pl_CrtFlng   (Print KOP Court Filing Set)
* 04/16/04  DMA  Added array of certification types
* 04/14/04  EF   Added pl_STDSed for a "Stadol"/"Sedgwick" LOR
* 04/02/04  kdl  Added 1st look Ship NRS
* 03/23/04  EF   Add pl_RezNY : Rezulin-NewYork cases
* 03/18/04  DMA  Add fields for long plaintiff name handling
*                Rename l_prtnotic to pl_PrtNotc
* 03/08/04  DMA  Add new user control items for scanned sigs and research flag
* 02/27/04  EF   Add pl_StDietD for State Diet Drug issues
* 02/26/04  DMA  Add pc_BBDock -- Berry & Berry case-level docket code
*                Add pd_RschDate and pl_Resrch for deponent-level research
* 02/25/04  EF   Add pl_WaivRcvd - Waiver Received
* 02/10/04  kdl  Moved pc_userid set up from rts.prg to public.prg
* 02/04/04  EF   Add pl_WeldRod
* 12/17/03  IZ   Replace selection of datadir with function, since it called from several places
* 12/08/03  DMA  Add pl_testcas, pl_tempcas for test and template cases
* 11/18/03  IZ   Add pl_MdSumAsb
* 11/12/03  EF   Add pl_Remic for Remicade litigation
* 11/12/03  EF   Add pl_BIHipaa for Breast Implant HIPAA
* 10/02/03  EF   Add pl_AsbHipaa for Asbestos HIPAA
* 09/23/03  EF   Add pl_MoldNY  var (Mold-Newyork cases)
* 09/18/03  EF   Add pl_MdlHold var (MDL Rezulin Cases)
* 08/26/03  EF   Add pc_ScanSg var (a path to AM scanned signatures )
* 08/05/03  EF   Add pl_RezMdl variable
* 07/29/03  EF   Add pl_GetAt variable, and pl_PSGWC
* 07/11/03  kdl  Added supplemented tag number holder
* 07/07/03  IZ   Add pl_OhioSil variable for Ohio Silica
* 06/26/03  EF   Add pl_Baycol for Philadelphia Baycol cases
* 06/23/03  KDL  Add variable for check un-voiding access control
* 06/06/03  DMA  Add variables for CA Notice processing
* 05/29/03  DMA  Convert noticing variables to standard naming
*                szservnam -> pc_ServNam
*                szMailPers -> pc_MailNam
* 05/21/03  DMA  Add pl_KoPVer, pl_CAVer
* 05/16/03  EF   Add location's ATTN var
* 05/12/03  EF   Add pl_hipaa for printing a Hipaa notice with subpoenas
* 05/07/03  dma  Add variable for litigation-based image database id
* 03/27/03  kdl  Add variable for ist issue insert tags flag
* 03/25/03  dma  Add variable for generic B&B case (civil or asbestos)
* 03/13/03  kdl  Add 1st look variables (merged 8/01/03)
* 03/11/03  dma  Add variable for new-format RCA number (built from data)
* 03/10/03  dma  Add new Berry & Berry web order number in Record
* 03/04/03  dma  Add new Berry & Berry items for TAMaster, Record
*                and new pickup flag for Record
* 01/27/03  kdl  Add deponent service link rights variable
* 12/23/02  EF   Added pl_FaxSubp variable
* 12/19/02  kdl  Added variables for subpoena notice ducument names from lit.dbf
* 12/16/02  EF   Add  pc_RpsForm (court variable0
* 11/21/02  kdl  Add pl_FaxChg - Fax field change control
* 11/04/02  EF   Add variables for Mail files
* 10/24/02  EF   Add pl_NJSub - NJ -courts' issues
* 10/17/02  EF   Add pl_MichCrt - for Michigan's court issues
* 09/27/02  EF   Add more variables from Record file
* 08/28/02  DMA  Add variable for Ohio Asbestos
* 08/06/02  DMA  pl_CvrTest now initialized in RTS based on office
* 08/05/02  DMA  Add variables for TAMaster CreatedBy, EditedBy
* 07/11/02  DMA  Add variables for litigation/area specific categories
* 06/27/02  DMA  Add pn_HoldSub for computed subpoena hold days
* 06/21/02  DMA  Add variables for user access control system
* 06/19/02  dma  Replace szLogName, mlogname with pc_UserID
* 06/17/02  dma  Add pd_ReqMail for Record file
* 05/23/02  kdl  Added flag to control selection of 2nd (split) print queues
* 03/25/02  DMA  Use office-specific datadir path
* 03/23/01  DMA  Add bar-code character definitions
* 01/19/01  DMA  Add additional laser-printer codes
* 12/01/99  DMPre-Y2K Code removed
* Work begun 8/20/99 DMA
*
*
*--2/10/04 kdl start: need to get the user id here
*PUBLIC pc_UserID                                && User's Login ID name (primary key)
*PUBLIC gcOffCode                               && DMA -- Unused as of 7/7/04

* Get the user's login name and the current time.
* For Windows NT/Pro/XP, use library NETLIB3
* For Novell 3.x or later, use library NL1MainU
*!*	IF pc_nettype = "W"
*!*	   SET LIBR TO NETLIB3.plb
*!*	   mtime = n_t_time()
*!*	   pc_UserID = UPPER( n_t_whoami())
*!*	   SET LIBR TO
*!*	ELSE
*!*	   SET LIBR TO nl1mainu.plb
*!*	   *   set libr to NL1F25.plb
*!*	   mtime = n_time()
*!*	   pc_UserID = UPPER( n_whoami())
*!*	   SET LIBR TO
*!*	ENDIF
LOCAL loCurrentUser AS Meduser OF Security

loCurrentUser = goApp.CurrentUser

PUBLIC pc_UserID, pc_UserHsh, pl_PdfReprint,pl_fakePdf, pl_backtoqc,  pl_Backbtn2, pl_Backbtn3, pl_exitpick, pl_backbtn1

pc_UserID = loCurrentUser.oRec.pc_UserID
pc_UserHsh = loCurrentUser.oRec.pc_UserHsh

** 12/17/03 IZ replace selection of datadir with function, since it called from several places
*PUBLIC gcdatadir                                && File information directory
*gcDataDir = "h:\release\rts\"
*pc_runwher = "P"
*gcdatadir = gfGetDat()
**06/08/04 EF : Removed call to the Filepath() routine
*DO Filepath WITH "P"                            && Build PUBLIC vbls that point to files
**06/08/04 EF: end

*PUBLIC gcoffcompile                             && Office for which program was compiled
*     "P" for KoP/TX, "C" for Oakland/Pasadena; used only in RTS.PRG
PUBLIC pl_KoPVer                                && .T. when gcoffcompile = "P"
PUBLIC pl_CAVer                                 && .T. when gcoffcompile = "C"
&&hold_print2 : added 08/28/2013: remove after test cycle
PUBLIC pl_OrigFilings as Boolean
pl_OrigFilings=.f.
&&hold_print2 : added 08/28/2013: remove after test cycle
PUBLIC d_founded                                && Company's rough founding date
d_founded = DATE(1975, 01, 01)                        &&  (no records older than this)
PUBLIC d_today, c_today,t_today, ct_today                         && Today's date
DO getsqldate
d_today = DATE()
n_year = YEAR(d_today)
*-c_today = DTOC(d_today)
PUBLIC d_null
d_null = CTOD("")                               && Empty date string for comparisons
pl_PdfReprint=.f.
STORE .f. to pl_fakePdf , pl_backtoqc, pl_Backbtn2, pl_Backbtn3, pl_Backbtn, pl_backbtn1
**************************  Public Arrays  *******************************

PUBLIC ARRAY RecArr[1, 4]                       && Deponent info storage array
                                                && used by New4Scr and subsidiary routines
PUBLIC pd_startNot
* 04/16/04 DMA Define certification types here, for use throughout RTS
PUBLIC ARRAY pc_Certs [7,2]
pc_Certs[1,1] = "Billing Records"
pc_Certs[1,2] = "B"
pc_Certs[2,1] = "Cert. of Records"
pc_Certs[2,2] = "R"
pc_Certs[3,1] = "Cert. of Pathology"
pc_Certs[3,2] = "P"
pc_Certs[4,1] = "Cert. of Radiology"
pc_Certs[4,2] = "X"
pc_Certs[5,1] = "Cert. of Echocardiograms"
pc_Certs[5,2] = "E"
pc_Certs[6,1] = "Cert. of Photographs"
pc_Certs[6,2] = "F"
pc_Certs[7,1] = "Cert. of Catheterizations"
pc_Certs[7,2] = "C"
* 04/16/04 DMA End

PUBLIC ARRAY laMonth[12]
laMonth[1] = "January"
laMonth[2] = "February"
laMonth[3] = "March"
laMonth[4] = "April"
laMonth[5] = "May"
laMonth[6] = "June"
laMonth[7] = "July"
laMonth[8] = "August"
laMonth[9] = "September"
laMonth[10] = "October"
laMonth[11] = "November"
laMonth[12] = "December"

PUBLIC ARRAY laYear[3]
laYear[1] = ALLTRIM( STR( n_Year - 1))
laYear[2] = ALLTRIM( STR( n_Year))
laYear[3] = ALLTRIM( STR( n_Year + 1))

PUBLIC ARRAY c_wrdaray[6]
c_wrdaray = ""
*
*   Display-formatting definitions for standardized fields
*
PUBLIC pl_MdSubset
PUBLIC pl_noSform  && 10/26/16 added to track kop non programmed subp #51529
PUBLIC pl_ZOLEFF
PUBLIC pl_Chk4Img
PUBLIC pc_ssnpic
pc_ssnpic = "999-99-9999"
PUBLIC pc_fmtzip, pc_fmtphon, pc_fmtein
pc_fmtzip   = "@R 99999-999999"
pc_fmtphon  = "@R (999) 999-9999"
PUBLIC pl_Is64bit && flag for 46 bit operating systems
pl_Is64bit = getis64bitos()
PUBLIC pl_CAinKOP, pl_CivBle, pl_ExclMI, pc_Suffix
PUBLIC pl_TestRPS, pl_PcxAuth, pl_NoQCIssue, 	pl_NoSimilar, pl_F2DepIss, pl_MRCLetter, pl_ZolLtr, pn_IssChoice
PUBLIC pl_ZOLMDL, pl_ZOLRuleF13, pl_Effexor, pl_MulBrazil, pl_CivGBass, pl_GRBCiv, pn_RpsMerge, pl_MdCourtset
PUBLIC pl_Mannion , pl_Pisanch, pl_Saltzmo, pl_WagZofrn, pl_ATraub, pl_AnapFos, pl_Himmel,    pl_dpllor, pl_THolland, pl_Bilotti, pl_Cozen, pl_FritzG
PUBLIC  pl_BeglCarl, pl_AwcRay, pl_MarksO, pl_Coker, pl_McElree, pl_Kwass, pl_Sater, pl_ChSdg , pl_ZofGsk, pl_LangEmi, pl_GoldSeg, pl_CivPillgr
PUBLIC pl_CiprCiv, pl_Heavens, pl_WadeCNJ, pl_StarkNJ, pl_ARuss, pl_Laddey, pl_IntPaper, pl_Traflet, pl_Savage, pl_MR_RI, pl_JANLor, pl_Winegar
PUBLIC pl_CivHarris, pl_Depasq, pl_TBarry, pl_DSheehan, pl_RasLaw, pl_Ostroff, pl_LittleJ, pl_Feller, pl_Datz, pl_RubinG, pl_Pallante, pl_Zarrow
PUBLIC pl_WebrGall, pl_ZWFirm, pl_RdckMs, pl_TXCourt, pc_BarNo, pl_Johans, pl_Strav, pl_Andre, pl_Weisbrg, pl_LambMc, pl_Swartz, pl_KnightH, pl_Needle, pl_PurchG

PUBLIC pl_Zarwin, pl_Kutak, pl_Delany, pl_Schubert, pl_GoodRich, pl_Wapner, pl_Lowen, pl_Vidaur, pl_RosenSch, pl_WeberK, pl_BelloR, pl_GRMN, pl_Naman, pl_VLahr, ;
	pl_TozLaw, pl_Vigorito, pl_VanderV, pl_Soloff, pl_GRANJ, pl_Strass, pl_YoungCo, pl_Shafer, pl_SchatzS,  pl_WilsonGA,  pl_Hamilt,  pl_GRCorsi, pl_Daiello, pl_mbart, ;
	pl_AllenGooch, pl_CivAspMM, pl_CsltxLor, pl_Amerilor, pl_GoeLor, pl_CivMcd, pl_CivAspl, pl_BrianMurph, pl_BroadSpire, pl_NardMoore, pl_Chapman, pl_GoldScar, pl_StarrGallo, ;
	pl_GRFullertn, pl_FanelliEvans, pl_FoleyMans, pl_RosenLaw, pl_BroadSp, pl_GRBarnaba, pl_LaffeyPhila, pl_PharmaSim, pl_ShcAsbes, pl_YorkRsk, pl_Haworth, pl_GRLbmb, pl_FranzDra, ;
	pl_GRSwift, pl_Faegre, pl_GoldsegNJ, pl_TexasFran, pl_RyanBrown, pl_AnzaloneLaw, pl_ClarenceBarr, pl_AwacMalaby,pl_Litchfield,pl_CivSheehy,pl_Litchcavo,pl_Obrien2,pl_civsedg, ;
	pl_civcorv,pl_brems,pl_civsacks, pl_Hawk, pl_GAIGrem, pl_UHSHPrn, pl_MagKauf, pl_Simon, pl_WCoxPLC, pl_IAhmuty, pl_HSandberg, pl_GNashCon, pl_GAIGMor, pl_WilsonPA, pl_Mintzer, ;
	pl_Olearys, pl_MSdMInz, pl_McNab, pl_AtlasB, pl_MPCohen, pl_Brooks, pl_Sheeley, pl_OConnor, pl_VigoriGAR, pl_VigoriVAL, pl_TraubNJ, pl_TraubNY, pl_CovTran, ;
	pl_use_LOR_Refer,pl_Oak_FL_Type

 
PUBLIC pl_Green
PUBLIC pl_Falvello
PUBLIC pl_SwainLaw && LOR for SwainLaw  10/5/15
PUBLIC pl_AWAC
PUBLIC pl_Chubb
PUBLIC pl_Mccandls
PUBLIC pl_Parker 
PUBLIC pl_ProgHub
PUBLIC pl_BenGol
PUBLIC pl_MORAng
PUBLIC pl_XARAgl
PUBLIC pl_civMP
PUBLIC pl_CivNLaw
PUBLIC pl_BuchIn
PUBLIC pl_SaltzCiv
PUBLIC pl_PharmLocks
PUBLIC pl_GayCiv
PUBLIC pl_SchDT
PUBLIC pl_Duffy
PUBLIC pl_CivKBG
PUBLIC pl_Archer
PUBLIC pl_KentBc
PUBLIC pl_TTHPh
PUBLIC pl_XARSch
PUBLIC pl_NJSwny
PUBLIC pl_NJSoriano
PUBLIC pl_CivLevyB
PUBLIC pl_CivPion
PUBLIC pl_CivMdOhio
PUBLIC pl_CivHang 
PUBLIC pl_YazMcEw
PUBLIC pl_ReedMgn
PUBLIC pl_PRLKee
PUBLIC pl_EisenRoth
PUBLIC pl_GallantPrlw
PUBLIC pl_BabLor  && lor for A049631P req atty
PUBLIC pl_HSubpCourt
PUBLIC pl_CrtSetCook
PUBLIC pl_Fee37 && 03/13/2013 to add txn 37 for Origibal subp and KOP Generic subps
STORE .f. to pl_TestRPS, pl_F2DepIss, pl_HSubpCourt, pl_CrtSetCook, pl_Fee37, pl_MdSubset, pl_MdCourtset
PUBLIC pl_Kovler
PUBLIC pl_BIOLor
PUBLIC pl_CivAnapol
PUBLIC pl_AvaStark
PUBLIC pl_Stark
PUBLIC pl_CMSWag
PUBLIC pl_CivHelf
PUBLIC pl_CivShMr
PUBLIC pl_AvaCms
PUBLIC pl_CivBeasly
PUBLIC pl_BMSLor
PUBLIC pl_AvaEwe
PUBLIC pl_McEwen
PUBLIC pl_Nebltt
PUBLIC pl_Garret
PUBLIC pl_PAsubp
PUBLIC pl_NonGBB
PUBLIC pc_AIPimg && to hold AIP image type processing 
PUBLIC pl_AIPproc
PUBLIC pl_ENEBrist
PUBLIC pl_AddCredit
PUBLIC pl_SrqFed
PUBLIC pl_Txn23Allow
PUBLIC pl_StopPrtIss
pl_StopPrtIss=.f.
PUBLIC pc_BatchRq
pc_BatchRq=""
PUBLIC pc_FaxMemo
PUBLIC pc_ToDoFile
PUBLIC p_DepLevelIssue 
p_DepLevelIssue =.f.
PUBLIC pc_Hospdept 
PUBLIC pl_DLIssueCall
pl_DLIssueCall=.f.
PUBLIC pl_VXNeblett
PUBLIC pl_FLRThomp
PUBLIC pl_Popcorn2
PUBLIC pl_Popcorn
PUBLIC pl_TRBAngl
PUBLIC pl_THIAngl 
PUBLIC pl_AsbAngl
PUBLIC pl_CivSubp
PUBLIC pl_BiceAlb
PUBLIC pl_MargCiv
PUBLIC pl_EclSpch
*07/29/04 Variables for LOR (Letter of Representation) printing
PUBLIC pl_RPDNy
PUBLIC pl_SrqDrk
PUBLIC pl_HTSPltf							
**10/26/06
PUBLIC pl_WFSBart
**09/15/05
PUBLIC pl_CivFeld	
PUBLIC pl_WelFMot
**08/07/06 
PUBLIC pl_LeadMot								&&Motley/Lead areas cases
*** added on 6/6/6
PUBLIC pl_DfrAyl
PUBLIC pl_OSCAngl                      && three new lit+ Angleos area
PUBLIC pl_DPVAngl
Public pl_CRTAngl
PUBLIC pl_HTSMotl                      && Human Tissue/Motley
PUBLIC pl_RNUAngl                      && ReNu/Angelos
PUBLIC pl_PhenAng                          && Phen-Fen/Angelos
PUBLIC pl_PxlDech                         && PXL-Dechert cases
PUBLIC pl_DrinkRMD                        && Drinker../Remicade
PUBLIC pl_GoldenCiv                       && Civil/Goldenberg
***added on 3/16/06
PUBLIC pl_DfrAng								&& Defibrillator/Angelos
PUBLIC pl_Anglvx								&& Angelos/Vioxx
PUBLIC pl_EvrNJ									&& Evra/NewJersey lor
PUBLIC pl_BexMot								&& Bextra/Motley cases
***added as a part of the subp_pa test on 1/18/06
PUBLIC pl_ENEPwl                                && .T. for Environmental Exp. lit and Powell Law Grp area
PUBLIC pl_Clbrx                                 && Celebrex/Levin Papantonio
PUBLIC pl_IRGFL                                 &&.t. for Intergel/FL
PUBLIC pl_CivilNY                               && .t. for Civil lit - NewYork cases
PUBLIC pl_Zyprx                                 && Zyprexa/Levin Papantonio
*****************************************1/18/06
PUBLIC pl_ENBMot                                && ENBREL-Motley LOR
PUBLIC pl_VIXMot                                && VIX-Motley LOR
PUBLIC pl_VIXMot                                && VIX-Motley LOR
PUBLIC pl_CivGar                                && Civil litigation/Garfinkel Area cases
PUBLIC pl_Motley                                && Remicade-Motley LOR
PUBLIC pn_LORpos                                && Position = 1 if a LOR prints before auths and 2 if after
PUBLIC pl_Shelltr                               && .T. for Sheller area and litigations: "AVX", "FLX","LQN","MMR","C","0","CRO","PPO"
PUBLIC pl_AsbCon                                && Asbestos / Connecticut
PUBLIC pl_LotronB                               && Beasley area/lnx-vix-2-8 lit cases
PUBLIC pl_ThiMil                                && 'THI' lit/ Miller area cases
PUBLIC pl_PropNon                               && Propulsid lit /"NONE" area cases
PUBLIC pl_A18839P                               && cases where A18839P is the req atty
PUBLIC pl_PropNJ1                      			&& Propulsid /NewJersey with 'NO PA Notice' area
PUBLIC pl_PropDr                                && Propulsid for "P" office
PUBLIC pl_PPApage                               && .T. for PPA and Sulzer Hip Ligitations +
                                                &&   "LEVIN,FISHBEIN" area
PUBLIC pl_A044584P 								&& Rq atty A044584P   to print a spec LOR                                            
PUBLIC pl_Propuls                               && .T. for Propulsid litigation + Federal areas
                                                && (any of "FEDERAL", "FED-SPECIFIC",
                                                &&  "LA-FEDERAL" or "PR-FEDERAL")
PUBLIC pl_PropMS                                && .T. for Propulsid litigation + "MISSISSIPPI" area
PUBLIC pl_PropPA                                && .T. for Propulsid litigation + "PENNSYLVANIA" area
PUBLIC pl_PropNJ                                && .T. for Propulsid litigation + "NEWJERSEY" area
PUBLIC pl_PropBlk                               && .T. for Propulsid litigation + "BLACKMON" area
PUBLIC pl_NJSpec                                && .T. for Propulsid litigation + "NJ-SPECIFIC" or
                                                &&   "PA-NONOTICE" areas
PUBLIC pl_FenPhen                               && .T. for Fen-Phen ligitation + "CLASS COUNSEL" area
PUBLIC pl_BaySch                                && .T. for Baycol ligitation + "SCHIFFRIN" area
PUBLIC pl_RezMont                               && .T. for Rezulin litigation + Montgomery area
PUBLIC pl_RezWil                                && .T. for Rezulin ligitation + Williams area
PUBLIC pl_MerSch                                && .T. for Meridia litigation + "SCHIFFRIN" area
PUBLIC pl_Remic                                 && .T. for Remicade litigation
PUBLIC pl_ThiEve                                && .T. for Thimerasol litigation + "EVERT" area
PUBLIC pl_MoldNY                                && .T. for Mold litigation + "NewYork" area
PUBLIC pl_STDSed                                && .T. for defense atty "A25465P" in Stadol/Sedgwick cases
PUBLIC pl_WeldRod                               &&  Welding Rod lit cases
PUBLIC pl_HRTLor                                && .T. for area = "Cohen" and Litigation = "HRT"
PUBLIC pl_HRTMorg                               && .T. for Litigation = HRT and area = Morgan
PUBLIC pl_TBTAstk                               && .T. for Litigation = Tabacco Trust and area =Aylstock
PUBLIC pl_HRTAstk                               && .T. for Litigation = HRT and area =Aylstock
PUBLIC pl_CivilAng                               && .T. for Litigation = Civil and area =Angelos
PUBLIC pl_ZDHAstk								&& .T. for Litigation = ZDH and area =Aylstock
PUBLIC pl_BiceFl								&& BiceFlorida cases in Asbestos lit
PUBLIC pl_AVAPltf								&& Avandia /Plaintiff cases
PUBLIC pl_AYKAva								&& Aylstock/Avandia  cases
PUBLIC pl_FLRHi									&& Flavoring/Hinshaw
PUBLIC pl_ZLNAyl								&& “Zelnorm” /”Aylstock” 
PUBLIC pl_LevaNJ
PUBLIC pc_defNotfax
pc_defNotfax=""
PUBLIC pl_NoFaxNotice
PUBLIC pc_TgNotice
pc_TgNotice=""
PUBLIC pl_FbtSal								&& Fulbright/Salix lit 
PUBLIC pl_AV1Fed
PUBLIC pl_AV1PA
PUBLIC pl_AV1IL
PUBLIC pl_AV1CA
PUBLIC pl_Ava1
PUBLIC pl_BalDgtk
PUBLIC pl_BPBLit
PUBLIC pl_HRobins
PUBLIC pl_AVACourtOrd 
PUBLIC pl_BALsrq								&& Bailey/Srq
PUBLIC pl_FooteMey
PUBLIC pl_CivCoach								&& Civil/COACH-GalloVit
PUBLIC pl_Solis									&& Solis litigation
PUBLIC pl_Reilly								&& Reilly litigation
PUBLIC pl_CivMess			
PUBLIC  pl_CivTang	
PUBLIC pl_MBCoach	
PUBLIC pl_CivSFLOP
PUBLIC pl_Thalidmd
PUBLIC pl_Ronan  
PUBLIC pl_CivGreat
PUBLIC pl_CivLocks
PUBLIC pl_ZnkMdl
PUBLIC pl_Golomb
PUBLIC pl_DurantLaw
PUBLIC pl_CivParks
pl_NoFaxNotice=.F.
**07/29/04     -end LORs var

*   Variables for user-access control system
*   Filled in from UserCtrl database in RTS program
*
*--2/10/03 kdl out:PUBLIC pc_UserID             && User's Login ID name (primary key)
PUBLIC pl_AllowUploads					&& True if user can Process the Web Uplodas
PUBLIC pc_PCId                                  && Pc's Id
PUBLIC pc_UserHsh                               && Hash-encoded Login ID for printing
PUBLIC pc_UserNam                               && User's full name
PUBLIC pc_UserFN                                && User's first name
PUBLIC pc_UserLN                                && User's last name
PUBLIC pc_UserMI                                && User's middle initial
PUBLIC pc_UserPhn                               && User's direct-dial phone number
PUBLIC pc_UserExt                               && User's 4-digit phone extension
PUBLIC pc_UserSSN                               && User's SSN
PUBLIC pc_UserEM                                && User's e-mail address
PUBLIC pc_UserOfc                               && User's RecordTrak office location
PUBLIC pc_UserWk                                && User's work-status code
PUBLIC pc_PrtCls                                && User's print class
PUBLIC pc_UserDpt                               && User's department
PUBLIC pc_UWorker                               && User's old-system worker initials
PUBLIC pl_Inactiv                               && True if user name is inactive
PUBLIC pl_RealID                                && True if user name is a real login ID
PUBLIC pl_RealPer                               && True if user name is a real person
PUBLIC pl_ActlMgr                               && True if user is an actual acct. manager
PUBLIC pl_Billing                               && True if user can access billing screens
PUBLIC pl_EditRate                              && True if user can modify rates
PUBLIC pl_CheckVd                               && True if user can void checks
PUBLIC pl_ChckUvd                               && True if user can un-void checks
PUBLIC pl_AcctMgr                               && True if user has Acct. Manager access
PUBLIC pl_UnitMgr                               && True if user has Unit Manager access
PUBLIC pl_DelFunc                               && True if user has tag-deletion access
PUBLIC pl_SalePer                               && True if user has salesperson access
PUBLIC pl_ActlSP                                && True if user IS a salesperson
PUBLIC pl_SaleChg                               && True if user can reassign salesperson
PUBLIC pl_Admin                                 && True if user has administrator access
PUBLIC pl_CredHld                               && True if user can change credit-holds
PUBLIC pl_AMRChg                                && True if user can change AM Resp. flags
PUBLIC pl_AtWebVw                               && True if user can see Atty. web info.
PUBLIC pl_AtWebCg                               && True if user can change Atty. web info.
PUBLIC pl_DelAtty                               && True if user can delete Atty. from case
PUBLIC pl_WOVReps                               && True if user can View reps for web orders
PUBLIC pl_WOVStat
PUBLIC pl_WOVColo
PUBLIC pl_RTARRep
PUBLIC pl_CaseInf                               && True if user can edit case information
PUBLIC pl_Inhibit                               && True if user can inhibit notice print
PUBLIC pl_ResChng                               && True if user can change Research flag
PUBLIC pl_DepLink
PUBLIC pl_FaxChg                                && If true, user can change acc_fax to "N"
PUBLIC pl_FaxSubp                               && True if user can fax subpoena w/notices
PUBLIC pc_MAttn                                 && Mail dbf attn
PUBLIC pc_SSNFull                               && Full User SSN
PUBLIC pc_SSNLst4                               && Last 4 digits of User SSN
PUBLIC pc_EmailAdd								&&Notice email adress
PUBLIC pl_OrdVerSet
pl_OrdVerSet=.f.
PUBLIC pl_MDLead
PUBLIC pn_SetNum
PUBLIC pl_BatchNot				&& KOP Batch Notice Printing
PUBLIC pl_MidQCdata
PUBLIC pl_Gordon				&& LOR Gordon ZD #147254
pl_Gordon = .F.
PUBLIC pl_WeirKest				&& LOR WeirKest ZD #148948
pl_WeirKest = .F.
PUBLIC pl_GrmoSand				&& LOR GrmoSandberg ZD #151040
pl_GrmoSand = .F.
PUBLIC pl_BurnWill				&& LOR Burnett & Will ZD #151666
pl_BurnWill = .F.
PUBLIC pl_JTFox					&& LOR SMB-JTFox ZD #154427 for CA
pl_JTFox = .F.
PUBLIC pl_WilEls				&& LOR Wilson_Elser ZD #152485
pl_WilEls = .F.
PUBLIC pl_AshGerel			&& LOR Ashcraft & Gerel ZD #160709
pl_AshGerel = .F.
pl_YoungCo = .F.				&& 02/07/2020 ZD #161332, JH
pl_GAIGrem = .F.				&& 02/27/2020 ZD #163070, JH
pl_UHSHPrn = .F.				&& 02/27/2020 ZD #163064, JH
pl_MagKauf = .F.				&& 02/27/2020 ZD #162627, JH
pl_Simon = .F.					&& 02/27/2020 ZD #163671, JH
pl_Hawk = .F.					&& 02/10/2020 ZD #161173, JH
pl_WCoxPLC = .F.				&& 03/03/2020 ZD #163379, JH	
pl_IAhmuty = .F.				&& 03/03/2020 ZD #163739, JH	
pl_HSandberg = .F.				&& 03/03/2020 ZD #163740, JH	
pl_GNashCon = .F.				&& 03/03/2020 ZD #163937, JH	
pl_GAIGMor = .F.				&& 03/11/2020 ZD #164789, JH
pl_WilsonPA = .F.				&& 03/24/2020 ZD #166181, JH
pl_Mintzer = .F.				&& 04/02/2020 ZD #166829, JH
pl_Olearys = .F.				&& 04/08/2020 ZD #167521, JH
pl_MSedMIntz = .F.				&& 04/08/2020 ZD #167196, JH
pl_McNab = .F.					&& 06/23/2020 ZD #177673, JH
pl_AtlasB= .F.					&& 07/21/2020 ZD #181159, JH
pl_MPCohen = .F.				&& 07/21/2020 ZD #182049, JH
pl_Brooks= .F.					&& 07/30/2020 ZD #183629, JH
pl_Sheeley = .F.				&& 07/30
pl_OConnor = .F.				&& 07/30
pl_VigoriGAR = .F.				&& 07/30
pl_VigoriVAL = .F.				&& 07/30
pl_TraubNJ = .F.				&& 07/30
pl_TraubNY = .F.				&& 07/30
pl_CovTrans = .F.				&& 08/05/2020 ZD #186305, JH
pl_use_LOR_Refer= .F.			&& 09/14/2020, JH
pl_Oak_FL_Type=.F.				&& 082521 kdl: add flag to identify Oakland fist-look login path [247599]

PUBLIC pc_Inbdoctype			&& 6/20/22 kdl: add holder for soft-copy document type [271273]
pc_Inbdoctype = "TIFF"
				
pl_MidQCdata=.f.
pl_BatchNot	=.f.
pn_SetNum=0
* 07/07/04 DMA Replace msoc_sec, msc_sec with pc_SSNFull, pc_SSNLst4
*PUBLIC msoc_sec, msc_sec                        && Old system variables for user SSN

* 06/11/04 DMA Replace bRepNot with pl_RepNotc
* 06/28/04 DMA Replace bnot with pl_Noticng
* 04/29/04 DMA Replace lcanot with pl_CANotc; remove l_ReqNot
* 05/04/04 DMA Noticing control variables
* 06/30/04 DMA Replace gdbuilt with pc_RTSBld, gcSysMsg with pc_SysMsg
* 07/08/04 DMA Replace l_EditMode with pl_EditReq, gsQuest with pc_TXQuest
PUBLIC pc_RTSBld, pc_SysMsg, pl_EditReq, pc_CurrOff, pc_TXQuest
PUBLIC pl_PrtNotc, pl_Noticng, pl_RepNotc
** --- 08/04/2020 MD #170629  added plCourtIN
PUBLIC pc_CntNot, pc_CaseNot, pl_HandServ, pl_CANotc, pl_WCABKOP, pl_ILCook, plCourtIN
*PUBLIC l_EditMode, gsQuest, pc_curroff, szoloc, oloc
*PUBLIC szlogpath, pl_PrtNotc, pl_Noticng, pl_RepNotc
*STORE .F. TO pl_noticng, l_EditMode
pc_TXQuest = ""                                 && List of TX Subpoena Question forms
pc_CntNot = ""                                  && Index name for counting notices
pc_CaseNot = ""                                 && Index name for counting noticed cases
pl_CANotc = .F.                                 && .T. for CA end-of-day notice
pl_EditReq = .F.                                && .T. if user may edit request blurb
pl_PrtNotc = .F.                                && .T. if notices must be printed
                                                &&     on return to higher-level program
pl_Noticng = .F.                                && .T. if notices are required to
                                                &&     accompany other TX documents
pl_RepNotc = .F.                                && .T. when reprinting notices
pl_HSOnly = .F.                                 && .T. if only printing hand-serves
pl_WCABKOP=.f.									&&  .t. for the wcab court's subp issues in the KOP office
PUBLIC debugit, szfaxnum, szadd2, szadd1, szcity, szstate, szzip, szattn
STORE "" TO szadd2, szadd1, szcity, szstate, szzip, szattn, pc_AIPimg

PUBLIC pc_ServNam, pc_MailNam, pc_CertTyp, pl_1st_Req, pl_AutoFax, pl_PostFee
PUBLIC pc_SubpTyp, pl_NeedAff, pl_HandSrv, pd_Depsitn, pl_PrntNot, pl_TXAffid, pd_CaSrvDt
pc_ServNam = ""                                 && Name of CA Notice hand-server
pc_MailNam = ""                                 && Name of CA Notice signer
pc_CertTyp = ""                                 && String of certification type codes
pl_1st_Req = .F.                                && .T. when generating a first request
pl_AutoFax = .F.                                && .T. when processing an autofax document
pc_SubpTyp = ""                                 && CA Subpoena-type code
                                                &&   W = WCAB, D = Default
                                                &&   C = Civil Subpoena
                                                &&   P = Personal appearance
pl_NeedAff = .F.                                && .T. when CA Civil Subp
                                                &&     requires an affidavit
pl_HandSrv = .F.                                && .T. when CA subp. is hand-served
pd_Depsitn = {//}                               && CA Notice Depo. date
pd_CaSrvDt={//}  
pl_PrntNot = .F.                                && .T. if CA Notice gets printed
pl_TXAffid = .F.                                && .T. when TX request requires affidavit
pl_FaxSubp = .F.                                && .T. if subpoena can be faxed with notices
pl_PostFee=.F.
PUBLIC lFormExt, llDefault, dIssue, gcCl_code, gnTag, glGlobal, gnRPS, ntxnid
gcCl_Code = ""                                  && Client code of case being RPS'ed
gnTag = 0                                       && Tag of deponent being RPS'ed
glGlobal = .F.                                  && .T. if cases are accessed from global tables
gnRPS = 0                                       && RPS printer currently being used
ntxnid = 00                                     && Initial value for txn id
pn_IssChoice=0
PUBLIC pd_Calendar 
pd_Calendar= {//}                                                && assignment in routine GetTxnID
* 07/15/04 DMA lReqNot is no longer used in the system
*lReqNot = .T.

PUBLIC pc_closmem, pl_cvrtest, pl_gotuser, pl_gotcase, pl_gotdepo
pc_closmem = "CLOSING MEMO: "
* 08/06/02 DMA pl_CvrTest is initialized in RTS main program
STORE .F. TO pl_gotuser, pl_gotcase, pl_gotdepo 
*
* HP Printer Control strings for reports and documents
*
PUBLIC pc_esc, pc_eol
pc_esc = CHR( 27)                                && HP Escape code
pc_eol = CHR( 13) + CHR( 10)                      && End-of-line code
PUBLIC cpi12, cpi10, cpi8, c_landscap, c_portrait, c_titlegr, c_endgr
PUBLIC c_MakeBig, c_MakeSmal, c_title10, c_title14, c_title8, c_bigbold
PUBLIC c_regbold, c_smallb, c_lwrtray, c_uprtray, c_reg
cpi8       = pc_esc + CHR( 40) + CHR( 115) + "8" + CHR( 72)
cpi10      = pc_esc + CHR( 38) + CHR( 107) + CHR( 48) + CHR( 83)
cpi12      = pc_esc + CHR( 40) + CHR( 115) + "12" + CHR( 72)
c_landscap = pc_esc + CHR( 38) + CHR( 108) + CHR( 49) + CHR( 79)
c_portrait = pc_esc + CHR( 38) + CHR( 108) + CHR( 48) + CHR( 79)
c_titlegr  = pc_esc + "&l1O" + pc_esc + "&l6D" + pc_esc + "(s12H"
c_endgr    = pc_esc + "E"
c_MakeSmal = pc_esc + "(s16.6H" + pc_esc + "(10U"
c_MakeBig  = pc_esc + "(s10H"  + pc_esc + "(10U"
c_title10  = pc_esc + CHR( 40) + CHR( 115) + "#10#" + CHR( 72)
c_title14  = pc_esc + CHR( 40) + CHR( 115) + "#14#" +CHR( 072)
c_title8   = pc_esc + "&l1O" + pc_esc + "&l8D" + pc_esc + "(s16.6H"
c_bigbold  = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s1p14v0s3b4T"
c_regbold  = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s0p10h12v0s3b3T"
c_reg      = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s0p10h12v0s0b3T"
c_smallb   = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s0p14h12v0s3b3T"
c_lwrtray  = pc_esc + CHR( 38) + CHR( 108) + CHR( 52) + CHR( 72)
c_uprtray  = pc_esc + CHR( 38) + CHR( 108) + CHR( 49) + CHR( 72)

PUBLIC pc_f10, pc_f10b, pc_f12, pc_f12b, pc_f14, pc_f14b, pc_f18, pc_f18b
pc_f10  = pc_esc + "(s0p10v0s0b4T"
pc_f10B = pc_esc + "(s0p10v0s3b4T"
pc_f12  = pc_esc + "(s0p12v0s0b4T"
pc_f12B = pc_esc + "(s0p12v0s3b4T"
pc_f14  = pc_esc + "(s1p14v0s0b4T"
pc_f14B = pc_esc + "(s1p14v0s3b4T"
pc_f18  = pc_esc + "(s1p18v0s0b4T"
pc_f18B = pc_esc + "(s1p18v0s3b4T"
*
*  06/10/04 DMA Merge in additional codes
*  Additional laser-printer codes taken from old LASERCODES routines
*  in procedure files TA_Lib and TX_Lib
*
PUBLIC _PBold, _PReg, _PUndOn, _PUndOff, _PUndFlt, _PNormal, _PItalic
PUBLIC _PFixed, _PProp, _POutLine, _PLwrTray, _PUprTray
PUBLIC _PPt6, _PPt8, _PPt9, _PPt10, _PPt11, _PPt12, _PPt14
PUBLIC _PPt18, _PPt24, _PPt30, _PPt36, _PPt42, _PPt48, _PPt54
PUBLIC _PPt60, _PPt72, _PHelv, _PCourier, _PUnivers
PUBLIC _PHelv, _PRmn8, _PPrnReset, _PTMarg0
PUBLIC _PBigBold, _PRegBold, _PReg2

&& Big Bold
_PBigBold = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s1p14v0s3b4T"
_PReg2 = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s0p10h12v0s0b3T"
_PRegBold = pc_esc + "&l0O" + pc_esc + "(1U" + pc_esc + "(s0p10h12v0s3b3T"

&& Top Margins
_PTMarg0 = pc_esc + "&l0E"

&& Strokes
_PReg = pc_esc + CHR( 40) + CHR( 115) + CHR( 48) + CHR( 66)
_PBold = pc_esc + CHR( 40) + CHR( 115) + CHR( 51) + CHR( 66)

_PUndOn = pc_esc + CHR( 38) + CHR( 100) + CHR( 48) + CHR( 68)
_PUndOff = pc_esc + CHR( 38) + CHR( 100) + CHR( 64)
_PUndFlt = pc_esc + CHR( 38) + CHR( 100) + CHR( 51) + CHR( 68)

_PNormal = pc_esc + CHR( 40) + CHR( 115) + CHR( 48) + CHR( 83)
_PItalic = pc_esc + CHR( 40) + CHR( 115) + CHR( 49) + CHR( 83)
_POutLine = pc_esc + CHR( 40) + CHR( 115) + CHR( 51) + CHR( 50) + CHR( 83)


&& TypeFace
_PCourier = pc_esc + CHR( 40) + CHR( 115) + CHR( 51) + CHR( 84)
_PUnivers = pc_esc + CHR( 40) + CHR( 115) + CHR( 52) + CHR( 49) + ;
   CHR( 52) + CHR( 56) + CHR( 84)

_PHelv = pc_esc + CHR( 40) + CHR( 115) + CHR( 52) + CHR( 84)

&& Spacing
_PFixed = pc_esc + CHR( 40) + CHR( 115) + CHR( 48) + CHR( 80)
_PProp = pc_esc + CHR( 40) + CHR( 115) + CHR( 49) + CHR( 80)

&& Tray
_PLwrTray = pc_esc + CHR( 38) + CHR( 108) + CHR( 52) + CHR( 72)
_PUprTray = pc_esc + CHR( 38) + CHR( 108) + CHR( 49) + CHR( 72)

&& Point Size
_PPt6 = pc_esc + CHR( 40) + CHR( 115) + "#6#" + CHR( 72)
_PPt8 = pc_esc + CHR( 40) + CHR( 115) + "#8#" + CHR( 72)
_PPt9 = pc_esc + CHR( 40) + CHR( 115) + "#9#" + CHR( 72)
_PPt10 = pc_esc + CHR( 40) + CHR( 115) + "#10#" + CHR( 72)
_PPt11 = pc_esc + CHR( 40) + CHR( 115) + "#11#" + CHR( 72)
_PPt12 = pc_esc + CHR( 40) + CHR( 115) + "#12#" + CHR( 72)
_PPt14 = pc_esc + CHR( 40) + CHR( 115) + "#14#" + CHR( 72)
_PPt18 = pc_esc + CHR( 40) + CHR( 115) + "#18#" + CHR( 72)
_PPt24 = pc_esc + CHR( 40) + CHR( 115) + "#24#" + CHR( 72)
_PPt30 = pc_esc + CHR( 40) + CHR( 115) + "#30#" + CHR( 72)
_PPt36 = pc_esc + CHR( 40) + CHR( 115) + "#36#" + CHR( 72)
_PPt42 = pc_esc + CHR( 40) + CHR( 115) + "#42#" + CHR( 72)
_PPt48 = pc_esc + CHR( 40) + CHR( 115) + "#48#" + CHR( 72)
_PPt54 = pc_esc + CHR( 40) + CHR( 115) + "#54#" + CHR( 72)
_PPt60 = pc_esc + CHR( 40) + CHR( 115) + "#60#" + CHR( 72)
_PPt72 = pc_esc + CHR( 40) + CHR( 115) + "#72#" + CHR( 72)

&& Font Selection
_PRmn8 = pc_esc + CHR( 40) + CHR( 56) + CHR( 85)
_PIBMPC = pc_esc + CHR( 40) + CHR( 48) + CHR( 85)

&& Printer Control
_PPrnReset = pc_esc + CHR( 69)
* DMA 06/10/04 End of additional laser-printer codes

*
*   Bar-code character definitions
*   Used in Prntbar2, Barcode, Printbar
*
PUBLIC ARRAY pc_barchar [44]
PUBLIC pc_bchars, pc_xstart, pc_xend, pc_dpl, pc_narrow
pc_bchars = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-. *$/+%"
* pc_xstart and pc_xend adjust printer's cursor position to
* start at top of line and return to bottom of line
pc_xstart = pc_esc + "*p-50Y"
pc_xend = pc_esc + "*p+50Y"
&& Number of dots/line (300 dpi /6 lpi = 50 dpl)
pc_dpl = 50
pc_narrow = ""
*
*   PUBLIC Variables for critical fields
*   These hold the identification and key info on the current case and deponent
*   for general use throughout most of the program.
*
**  TAMASTER File (One record per case)
*    Unique key is pc_clcode
**   Includes items looked up in secondary files via codes in TAMaster
*	
PUBLIC pc_tagdist								&& Tag's District for USDC courts
PUBLIC pn_lrsno                                 && RT Number
PUBLIC pc_lrsno                                 && RT Number in printable format
PUBLIC pc_clcode                                && Client code (UNIQUE KEY)
* 12/08/03 DMA Add identifiers for test and template cases
PUBLIC pl_TestCas                               && .T. if case is for testing
PUBLIC pl_TempCas                               && .T. if this is a mirror template
* 12/08/03 DMA End
PUBLIC pc_offcode                               && Office code for RT office where case was entered
PUBLIC pc_ofcdesc                               && Full name of RT filing office
PUBLIC pc_ofcstat                               && State in which RT filing office is located
PUBLIC pn_group                                 && Group number
PUBLIC pc_litcode                               && Litigation Code
PUBLIC pc_litname                               && Litigation name (from Lit file)
PUBLIC pc_litnotc                               && Name of litigation-specific notice
PUBLIC pc_litfnot                               && Name of litigation-specific from-review notice
*--12/19/02 kdl start:
PUBLIC pc_litsnot                               && Name of litigation-specific notice for subpoena
PUBLIC pc_ltsfnot                               && Name of litigation-specific from-review notice for subpoena
*--12/19/02 kdl end:
PUBLIC pl_litnofx                               && Litigation-based no-fax flag
PUBLIC pl_litath2                               && Litigation-based authorization 2 flag
PUBLIC pn_litiday                               && Litigation-based hold days between issue and mailing
PUBLIC pn_litfday                               && Litigation-based hold days for from-review deponents
PUBLIC pc_litdcap                               && Litigation-based defense caption
* 05/07/03 DMA start:
PUBLIC pc_imagedb                               && Litigation-based image database ID
* 05/07/03 DMA end:
PUBLIC pc_entryN                                && Name of matching EntryX file ("ENTRYn")
PUBLIC pc_entryV                                && Path variable name for EntryX file ("f_entryX")
PUBLIC pc_entryF                                && Full file path to EntryX file
* 03/18/04 DMA start:
PUBLIC pc_plgiven                               && Plaintiff's first name + middle initial
PUBLIC pc_fullnam                               && Plaintiff's 50-char. merged full name
* 03/18/04 DMA end:
PUBLIC pc_pllname                               && Plaintiff's last name
PUBLIC pc_plfname                               && Plaintiff's first name
PUBLIC pc_plminit                               && Plaintiff's middle initial
PUBLIC pc_plnam                                 && Plaintiff's full name (in "first init last" form)
PUBLIC pc_plnamrv                               && Plaintiff's full name (in "last, first init" form)
PUBLIC pc_pladdr1                               && Plaintiff's address line 1
PUBLIC pc_pladdr2                               && Plaintiff's address line 2
PUBLIC pc_plssn                                 && Plaintiff's SSN/EIN
PUBLIC pc_fullssn                                && Plaintiff's full SSN
PUBLIC pc_executr                               && Plaintiff's executor, if any
PUBLIC pd_pldob                                 && Plaintiff's date of birth
PUBLIC pd_pldod                                 && Plaintiff's date of death
PUBLIC pc_platcod                               && Attorney code for plaintiff's attorney
PUBLIC pc_platnam                               && Plaintiff's attorney name (from TAMaster)
PUBLIC pc_platini                               && Plaintiff's att'y initial (from TAMaster)
PUBLIC pc_rqatcod                               && Attorney code for attorney requesting records
PUBLIC pc_amgr_id                               && Login ID of client representative
PUBLIC pc_amgr_nm                               && Full name of client representative
PUBLIC pc_amgr_ml                               && Email address of client representative
PUBLIC pc_amgr_ph                               && Direct-dial number of client representative
* 03/08/04 DMA Variables for tracking client rep's scanned signature
PUBLIC pl_ScanSig                               && True if a scanned signature has been stored
**EF 08/26/15
PUBLIC  pc_txCrtType			   && TX docs need that data  06/12/2017
PUBLIC pc_ScanSg                                && path to the signature's tif file
PUBLIC pl_WebForm                              && .T. if court  has a webform (PCCP)
PUBLIC pc_ScanSg                                && path to the signature's tif file
PUBLIC pl_archive                               && .T. -> Case has been archived
PUBLIC pc_area                                  && Name of filing area
PUBLIC pc_areaID                                && ID number of filing area
PUBLIC pc_areamgr                               && Client representative code for filing area
PUBLIC pl_areanot                               && .T. -> Special notice linked w/this area
PUBLIC pc_arealit                               && Litigation code linked w/this area
PUBLIC pc_court1                                && Primary court for plaintiff's case
PUBLIC pc_Distrct                               && Court district
PUBLIC pc_Divisn                                && Court division
PUBLIC pc_CCLNum                                && County Civil Court at Law (CCL) # of a Texas court
PUBLIC pc_TXCtTyp                               && Texas Court Type ("FED", "DIS", or "CCL")
PUBLIC pc_TXCtLn1                               && Line 1 header for Tx court
PUBLIC pc_TXCtLn2                               && Line 2 header for Tx court
PUBLIC pc_TXCtLn3                               && Line 3 header for Tx Court
PUBLIC pc_TXHold                                && Formatted hold time for Tx Court
PUBLIC pc_TXDiv                                 && Division for Tx Court
PUBLIC pc_TXDist                                && District for Tx Court
PUBLIC pc_TXcsz                                 && City/State/Zip combo for TX Court
PUBLIC pc_c1Name                                && Short name of court 1
PUBLIC pc_c1Desc                                && Description of court 1
PUBLIC pl_c1Form                                && .T. if Court 1 has a form
PUBLIC pl_c1SSubp                               && .T. if Court 1 has a scanned subpoena
PUBLIC pn_c1Due                                 && Additional amount due for Court 1
PUBLIC pl_c1Notic                               && .T. if Court 1 has a notice
PUBLIC pc_c1Cnty                                && County in which Court 1 is located
PUBLIC pn_c1Hold                                && Hold days for Court 1
PUBLIC pn_c1Cmply                               && Compliance days for Court 1
PUBLIC pl_c1Prvdr                               && .T. if court 1 has provider
PUBLIC pl_c1PrtSc                               && .T. if court 1 has printsc flag on
PUBLIC pl_c1Cert                                && .T. if court 1 requires certificate
PUBLIC pc_c1Addr1                               && Court 1 Address Line 1
PUBLIC pc_c1Addr2                               && Court 1 Address Line 2
PUBLIC pc_c1Addr3                               && Court 1 Address Line 3
PUBLIC pc_c1City                                && Court 1 city
PUBLIC pc_c1State                               && Court 1 state
PUBLIC pc_c1Zip                                 && Court 1 zip code
PUBLIC pc_c1Phone                               && Court 1 phone number
PUBLIC pc_court2                                && Secondary court for plaintiff's case
PUBLIC pc_C2Name                                && Short name of court 2
PUBLIC pc_c2Desc                                && Description of court 2
PUBLIC pl_c2form                                && .T. if Court 2 has a form
PUBLIC pl_c2ssubp                               && .T. if Court 2 has a scanned subpoena
PUBLIC pn_c2due                                 && Additional amount due for Court 2
PUBLIC pl_c2notice                              && .T. if Court 2 has a notice
PUBLIC pc_c2cnty                                && County in which Court 2 is located
PUBLIC pn_c2hold                                && Hold days for Court 2
PUBLIC pn_c2cmply                               && Compliance days for Court 2
PUBLIC pl_c2prvdr                               && .T. if court 2 has provider
PUBLIC pl_c2prtsc                               && .T. if court 2 has printsc flag on
PUBLIC pl_c2cert                                && .T. if court 2 requires certificate
PUBLIC pc_c2addr1                               && Court 2 Address Line 1
PUBLIC pc_c2addr2                               && Court 2 Address Line 2
PUBLIC pc_c2addr3                               && Court 2 Address Line 3
PUBLIC pc_c2city                                && Court 2 city
PUBLIC pc_c2state                               && Court 2 state
PUBLIC pc_c2zip                                 && Court 2 zip code
PUBLIC pc_c2Phone                               && Court 2 phone number
PUBLIC pc_RpsForm                               && Court has a RPS form
PUBLIC pl_CrtFlng                               && .t. if a "Court Filing Set" is requested
PUBLIC pc_docket                                && Docket entry for court 1
PUBLIC pc_req_atf                               &&
PUBLIC pl_intrrog                               && .T. if interrogatories used in case
PUBLIC pc_reqatty                               &&
PUBLIC pc_reqpara                               &&
PUBLIC pc_employr                               && Plaintiff's employer
PUBLIC pd_empstrt                               && Starting date of employment
PUBLIC pd_empend                                && Ending date of employment
PUBLIC pd_settled                               && Date on which case was settled
** 01/20/05 DMA Remove use of Worker field in Comment.dbf and FLComm.dbf
*PUBLIC pc_worker                                &&
PUBLIC pl_chosen                                &&
PUBLIC pd_trial                                 && Date of trial
PUBLIC pd_depo                                  && Date on which depositions are due
PUBLIC pd_assign                                && Date on which case was assigned to acct mgr
PUBLIC pd_request                               &&
PUBLIC pc_plcommt                               && Comments on case
PUBLIC pn_depcnt                                && Number of deponents in the case
PUBLIC pc_pldeal                                && Plaintiff's billing deal
PUBLIC pc_projcod                               && Project code
PUBLIC pn_projnum                               && Project number
PUBLIC pc_conditn                               && Condition
PUBLIC pc_simfrst
PUBLIC pc_maiden1                               && Maiden name, line 1
PUBLIC pc_maiden2                               && Maiden name, line 2
PUBLIC pc_mfcture
PUBLIC pc_salesmn                               && Salesperson's user ID
PUBLIC pc_sale_nm                               && Full name of salesperson
PUBLIC pc_sale_ml                               && Email address of salesperson
PUBLIC pc_sale_ph                               && Direct-dial number of salesperson
PUBLIC pd_term
PUBLIC pc_catgory
PUBLIC pc_lotno
PUBLIC pc_occpatn
PUBLIC pc_plcnty
PUBLIC pc_plcaptn
PUBLIC pc_dfcaptn
PUBLIC pc_devno
PUBLIC pd_casentr
PUBLIC pd_casedit
PUBLIC pc_plbbrnd                               && Berry & Berry old-format round number
PUBLIC pc_plbbASB                               && Berry & Berry new-format ASB number
PUBLIC pc_plbbnum                               && Berry & Berry old-format ASB number
PUBLIC pc_BBDock                                && Berry & Berry docket code
PUBLIC pc_billpln
PUBLIC pc_aliencd
PUBLIC pc_proccod
PUBLIC pc_billcod
PUBLIC pn_wittotl
PUBLIC pc_claimno
PUBLIC pd_closing
PUBLIC pc_complnt
PUBLIC pc_reparea
PUBLIC pc_firmcod
PUBLIC pc_casenam
PUBLIC pd_SSCDate                               && Berry & Berry SSC Date
PUBLIC pd_MTADate                               && Berry & Berry MTA Date
PUBLIC pl_MTAXpct                               && .T. if MTA date is expected
PUBLIC pc_CreaCas                               && Original creator of case
PUBLIC pc_EditCas                               && Most recent editor of case

*
*   Computed logical variables based on TAMaster data
*
PUBLIC pl_plisrq                                && .T. if plaintiff and requesting atty are the same
PUBLIC pl_ofcKOP                                && .T. if case opened in KoP office
PUBLIC pl_ofcMD                                 && .T. if case opened in MD office
PUBLIC pl_ofcPgh                                && .T. if case opened in Pittsburgh office
PUBLIC pl_ofcOak                                && .T. if case opened in Oakland office
PUBLIC pl_ofcPas                                && .T. if case opened in Pasadena office
PUBLIC pl_ofcHous                               && .T. if case opened in Houston office
*
*  Computed logical variables that identify specific types of cases
*     that require special processing (esp. during notice generation)
*
PUBLIC pl_Mincey
PUBLIC pl_Chasan
PUBLIC pl_Chartwell
PUBLIC pl_ActAna
PUBLIC pl_RpdAna
PUBLIC  pl_XarAna
PUBLIC pl_TeoAna
PUBLIC pl_ZofAna
PUBLIC pl_FreedLrry
PUBLIC pl_BroadCiv
PUBLIC pl_DtRamsey
PUBLIC pl_LevinCiv
PUBLIC pl_McEldrew
PUBLIC pl_CivCiecka 
PUBLIC pl_ReiSSRI       
PUBLIC pl_ZDHFae
PUBLIC pl_ReiMesh								&&Reilly + area: Transvag Mesh
PUBLIC pl_RisPCCP								&& Risperdal /PCCP 
PUBLIC pl_CambAsb								&& Cambria county/Asbestos
PUBLIC pl_RezNY                                 && .T. for Rezulin+NewYork cases
PUBLIC pl_BBAsb                                 && .T. if this is a Berry & Berry Asbestos case
* 08/02/04 DMA NY City Asbestos flag
PUBLIC pl_NYCAsb                                && .T. for Asbestos litigation, NYC area
PUBLIC pl_NJAsb                                 && .T. for Asbestos litigation, Newjersey area
PUBLIC pl_BBCase                                && .T. if requesting attorney is Berry & Berry
PUBLIC pl_OhioAsb                               && .T. for Asbestos litigation + Ohio area
PUBLIC pl_OhioSil                               && .T. for Silica litigation + Ohio area
PUBLIC pl_TxAbex                                && .T. for Asbestos litigation + "TX_ABEX",
                                                &&   "TX-GERMER", "TX-CIVIL", "TX_PHICO" or "TEXAS" areas
PUBLIC pl_PropFed                               && .T. for Propulsid litigation + "FEDERAL" area
PUBLIC pl_DietDrg                               && .T. for Diet Drug litigation
PUBLIC pl_DDrug2                                && .T. for all four Diet Drug 2 litigations
PUBLIC pl_BayCol                                && .T. for Baycol ligitation + "PHILADELPHIA" area
PUBLIC pl_PSGWC                                 && .T. for GroundWater litigation in Pasadena office
PUBLIC pl_hipaa                                 && .T. if a subp request needs a Hippa notice attached
PUBLIC pl_MDAsb                                 && .T. for Asbestos litigation with requesting
                                                &&  attorneys A1333P, A23580P, and A24483P in
                                                &&  MD office or in KoP office with area of
                                                && "MD/Summarized" or "Maryland"  and "A1691P", "A24604P"
PUBLIC pl_MdSumAsb                              && .T. for office = Phila, lit = Asbestos, area = MD/Summarized
PUBLIC pl_RezMdl                                && .T. for Rezulin litigation + "MDL" or "NYMDL" areas
PUBLIC pl_AsbHipaa
PUBLIC pl_BIHipaa                               && Print Hipaa with Breast Implant subpoenas
PUBLIC pl_ScanSub                               && .T. if scanned subpoena is to be used
PUBLIC pn_HoldSub                               && Computed # of days to hold subpoena before mailing
PUBLIC pl_MdlHold                               && .T. for Rezulin litigation + area "MDL-Hold"
PUBLIC pl_TXRept
PUBLIC pc_IssType                               && Issue type
PUBLIC pl_NJSub                                 && NJ subpoena issues
PUBLIC pl_StDietD                               && State Diet Drug issues
PUBLIC pl_SRZNot                                && Serzone Cases
PUBLIC pn_ObjDay                                && Number of objection days for the ZCM lit
PUBLIC pl_Zicam                                 && Zicam Issues
PUBLIC pl_ZcmFed								&& ZICAM FEDERAL
PUBLIC pd_IssDte                                && Issue Date (txn11)
PUBLIC pd_NotDte                                && Date of notices
PUBLIC pd_MailDte                               && Date for mailing requests
PUBLIC pd_DueDte                                && Due Dte for request to be back
PUBLIC pl_AllDate                               && Logic var
PUBLIC pc_SpecHand
PUBLIC pc_faxcover
PUBLIC pl_EditBlurb
PUBLIC pl_PncFed								&& Panacryl/Federal
PUBLIC pd_RPSPrint
STORE .F. to pl_ofcKOP, pl_ofcMD, pl_ofcPgh, pl_ofcOak, pl_ofcPas, ;
   pl_ofcHous, pl_TXRept, pl_NJSub, pl_AllDate, pl_AIPproc, pl_EditBlurb, pl_NoSimilar
PUBLIC pc_grpname, pc_casname, pc_casenum, pl_nogroup
pl_nogroup = .T.                                && .T.  if no group info available on case
STORE "" TO pc_grpname, pc_casname, pc_casenum, pc_SpecHand, pc_faxcover
*
**  INSTRUCT File (Zero or one record per case)
*    Unique key is pc_clcode
*
PUBLIC pl_rushcas                               && True when case is in rush status
PUBLIC pl_scanned
PUBLIC pn_req_by                                && 1=Autho; 2=Subpoena; 3=either
PUBLIC pl_nohold                                && True if subpoenas can be issued w/o a waiting period.
PUBLIC pl_autscan                               && True when authorization has been scanned for printing
PUBLIC pl_review                                && True if incoming records get reviewed for new deponents
PUBLIC pd_revstop                               && Last date for review of incoming records
PUBLIC pl_bates                                 && Bates-labelling required for records
PUBLIC pl_sgncert                               && Signed certification required with records
*--3/13/03 kdl start: add 1st look variables from INSTRUCT file
PUBLIC pl_CFlook                                && Case level 1st look
PUBLIC pn_Fldays                                && Case level 1st look review days
PUBLIC pc_Fltype                                && Case level 1st look type of review days (Buisiness or Calender)
PUBLIC pc_FlAtty                                && Case level 1st look attorney
PUBLIC pc_Flship                                && Case level 1st look shipment method code
PUBLIC pc_TflAtty                               && Tag level 1st look attorney
PUBLIC pl_Distrib                               && Tag level 1st look distribute
PUBLIC pl_TFlook                                && Tag level 1st look
*--3/13/03 kdl end:

*--4/02/04 kdl start: add more 1st look varaibles
PUBLIC pl_FlNrs											&& 1st look ship NRSs preference

*--4/02/04 kdl end:
*--5/30/19: tag inbound doc type
PUBLIC pc_ScanDocType

**  RECORD File  (One record for each deponent in a case)
**  Unique key is pc_ClCode + "*" + pn_Tag
*
PUBLIC pl_OBrien
PUBLIC pl_DMPitt
PUBLIC pl_CivDT
PUBLIC pl_TPXlit
PUBLIC pn_DepoRec                               && Physical record number in Record.dbf
PUBLIC pn_Tag                                   && Tag number
PUBLIC pc_Tag                                   && Tag number formatted for indexing
PUBLIC pc_TrimTag                               && Tag number formatted for print/display
PUBLIC pc_TagType					&& tag _type ( 2- letter code)
PUBLIC pc_Status                                && Record status
PUBLIC pc_DepoRCA                               && Deponent's RCA # for Berry & Berry requests
PUBLIC pd_OpenDep                               && Date that deponent was opened
PUBLIC pc_MailID                                && Deponent's mail id (unique key into rolodex)
PUBLIC pc_Descrpt                               && Deponent description
PUBLIC pd_ReqDate                               && Date that original request was entered in system
PUBLIC pd_ReqMail                               && Date that original request was mailed/faxed
PUBLIC pc_DepoKey                               && Search key for deponent in files such as EntryX
PUBLIC pc_AdmKey                                && Search key for admissions/categories in Admissn file.
PUBLIC pc_DepType                               && Rolodex type for deponent
PUBLIC pc_DepoFile                              && File name for deponent rolodex
PUBLIC pc_DepoDept                              && Department code for deponent in hospital rolodex
PUBLIC pl_Incompl                               && .T. -> Incomplete Records were received
PUBLIC pc_IncCode                               && Record-incomplete picklist code
PUBLIC pl_Reissue                               && .T. -> Request has been re-issued
PUBLIC pl_HasNRS                                && .T. -> No-record-statement issued for deponent
PUBLIC pc_NRSType                               && Type of most recent NRS issued
PUBLIC pc_RevStat                               && Review-Status code of record
PUBLIC pc_RevLine                               && Expanded review status line
PUBLIC pl_FromRev                               && .T. -> Deponent was found via review
PUBLIC pl_AMResp                                && .T. -> Client representative intervention needed
&&-------EF 09/27/02 Add more variables
PUBLIC pl_HoldPsy                               && hold condition
PUBLIC pl_AutoFax                               && Autofax turn on/off
PUBLIC pc_FaxAttn                               && AutoFax attention person
PUBLIC pn_AFaxNo                                && AutoFax fax number
PUBLIC pn_AFCount                               && Autofax count
PUBLIC pn_AFChkAmt                              && AF Check Amount
PUBLIC pl_Expdte                                && .T. -> Record is "Rush"
PUBLIC pd_Expdate                               && Expedite date
PUBLIC pl_Scann                                 && Scan images  .t./.f.
PUBLIC pl_BBSent                                && B & B related data
PUBLIC pc_BBType                                && B & B related data
PUBLIC pl_FrstLook                              && First look
*--kdl out 7/3/03: PUBLIC pc_FLAtty             && First Look Atty
PUBLIC pl_Redacted                              && Redacted
PUBLIC pl_flimgmod								&& Fl images modified
pl_flimgmod=.f.
PUBLIC pl_MichCrt                               && Indicate Michigan court's issues
PUBLIC pc_BBRound                               && Berry & Berry Round number
PUBLIC pc_BBLocNo                               && Berry & Berry Location number
PUBLIC pl_Pickup                                && Record is awaiting physical pickup
PUBLIC pc_BBWebNo                               && Berry & Berry Web Order number
PUBLIC pc_BBNuRCA                               && Berry & Berry new-format RCA Number
*--7/11/03 kdl start:
PUBLIC pn_Suppto                                && supplemented tag number holder
**EF 02/25/04
PUBLIC pl_WaivRcvd                              && Waiver Received
* DMA 02/26/04 Changes for tracking deponent-level research activity
PUBLIC pl_Resrch                                && .T. if research is in progress
PUBLIC pd_RschDate                              && Date research started
PUBLIC pd_UpldDate                              && Date records uploaded to distribution server
PUBLIC pl_Investig								&& Phone call investigation
PUBLIC pd_created								&& creation date
pd_created=d_today
** Mail Rolodex Variables
PUBLIC pl_Mail                                  && if gfgetmail was activated
pl_Mail = .F.
PUBLIC pn_MailRec                               && Physical record number in a mail file
PUBLIC pc_MailDesc                              && Key - mail description
PUBLIC pc_MAdd1                                 && Address Line 1
PUBLIC pc_MAdd2                                 && Address Line 2
PUBLIC pc_MailCity                              && City
PUBLIC pc_MailSt                                && State
PUBLIC pc_MailZip                               && Zip
PUBLIC pn_MailPhn                               && Phone number
PUBLIC pn_MailFax                               && Fax_no
PUBLIC pl_MailFax                               && If accepts a Fax
PUBLIC pl_FaxOrig                               && If accepts original issues by Fax
PUBLIC pc_FaxSub                                && If accepts subpoenas by Fax
PUBLIC pc_FaxAuth                               && If accepts Auths by fax
PUBLIC pc_GovtLoc                               && Government locations
** new fields in the Doctor rolodex
PUBLIC pc_MailFName                             && Doctor's First Name
PUBLIC pc_MailLName                             && Doctor's Last Name
** new fields in the hospital rolodex
PUBLIC pc_RadDpt                                && Radiology Department
PUBLIC pc_PathDpt                               && Pathology Department
PUBLIC pc_EchoDpt                               && Echo dept.
PUBLIC pn_RadFax                                && Rad dept fax_no
PUBLIC pn_PathFax                               && Path dept fax_no
PUBLIC pn_EchFax                                && Echo dept fax_no
PUBLIC pl_EFax                                  && Echo dept accepts faxes
PUBLIC pl_EFaxOrg                               && Echo dept accepts originals by fax
PUBLIC pl_PFax                                  && Path dept accepts faxes
PUBLIC pl_PFaxOrg                               && Path dept accepts originals by fax
PUBLIC pl_RFax                                  && Rad dept accepts faxes
PUBLIC pl_RFaxOrg                               && Rad dept accepts originals by fax
PUBLIC pc_EFaxSub                               && Echo accepts subpoenas by fax
PUBLIC pc_EFaxAuth                              && Echo accepts auths by fax
PUBLIC pc_PFaxSub                               && Path accepts subpoenas by fax
PUBLIC pc_PFaxAuth                              && Path accepts auths by fax
PUBLIC pc_RFaxSub                               && Rad accepts subpoenas by fax
PUBLIC pc_RFaxAuth                              && Rad accepts auths by fax
PUBLIC pc_BFaxSub                               && Billing Department accepts subpoenas by fax
PUBLIC pc_BFaxAuth                              && Billing Department accepts auth by fax
PUBLIC pn_BillFax                               && Fax number of Bill. dept
PUBLIC pl_BFaxOrg                               && Bill Dept accepts original issues
PUBLIC pl_CallOnly                              && Follow up by calls only
PUBLIC pl_MCall                                 && Hospital-med dept call only
PUBLIC pl_BCall                                 && Hospital-bill dept call only
PUBLIC pl_PCall                                 && Hospital-path dept call only
PUBLIC pl_RCall                                 && Hospital-rad dept call only
PUBLIC pl_ECall                                 && Hospital-echo dept call only
PUBLIC pl_HandDlvr
PUBLIC pl_MailOrig
PUBLIC pl_OutofBus
PUBLIC pl_2ndQue                                && 2nd print queue flag variable - 5/23/02
pl_2ndQue = .F.
PUBLIC pl_UpdHoldReqst, pl_ObjLifted
PUBLIC pl_WcaseChg 
STORE .f. to pl_UpdHoldReqst, pl_ObjLifted  &&05/12/16 - need to track when to add an extra day to the updated follow up - the latest intsruction #40860
*--3/27/03 kdl start:
PUBLIC pl_1st0tag                               && Flag variable for use in subp_pa to identify
&& 1st issue insert tags

PUBLIC pc_specbates

**EF 07/29/03 Print-formatted attorney data filled in by gfAtInfo
PUBLIC pl_GetAt                                 && Logical var to check if gfatinfo called
PUBLIC pc_AtySign                               && Atty Signature
PUBLIC pc_Atyname                               && Atty name
PUBLIC pc_Aty1Ad, pc_Aty2Ad                     && Atty address
PUBLIC pc_AtyFirm                               && Atty Firm
PUBLIC pc_Atycsz                                && Atty City, State, Zip
PUBLIC pc_AtyPhn, pc_AtyFax                     && Atty phone and fax #
PUBLIC pc_AtyAttn								&& Atty attention
PUBLIC pc_AtState								&& Atty State-6/29/2011
**07/29/03

**EF 08/12/03 used by hipaaset
PUBLIC pd_Maild                                 && Hold Issues mail date
PUBLIC pd_DueDate                               && Objections due date
PUBLIC pd_dateCourtset							&&  Hold a date for printing a CourtSet (KOP)
*--kdl 04/21/04 used by DS for order emails
PUBLIC pc_email                            		&& hold email address between DS jobs
pc_email = ""
PUBLIC pl_CADBatch
pl_CADBatch =.f.
*--kdl 07/07/04 used by DS modifcations
PUBLIC pc_Ordlink											&& ordtype table link variable
pc_Ordlink = ""

*--6/01/04 kdl start: client case number condition flag
PUBLIC pl_clCasno
pl_clCasno = .F.

*--01/05/05 kdl start: new soft image system variables
PUBLIC pl_softimg, pc_softdir, pl_softflg,pl_autosc,pn_imagecnt
pl_softimg = .F. 											&& soft image flag
pc_softdir = ""											&& stores the directory that store recordtrak documents for a tag
pl_softok = .F.											&& screen level control for check box access
pl_softflg = .F. 											&& indicates record is flagged  as having scanned soft image file
pl_autosc=.f.
pn_imagecnt=0

PUBLIC pl_PrtOrigSubp
pl_PrtOrigSubp=.f.
PUBLIC pcPublicBlurb
pcPublicBlurb=""

PUBLIC pc_Initials,pn_checkno
pc_Initials=""
pn_checkno=0

PUBLIC pc_PsSqlerr && Help with Finding Errors - Used in MlError - Set in various places
pc_PsSqlerr = ' '

PUBLIC pl_SkipBatchPRT
pl_SkipBatchPRT=.F.

PUBLIC pl_SpecRpsSrv 
pl_SpecRpsSrv=.f. && special perocessing locations marked by a department's category  01/18/10

PUBLIC pl_addcasetag, pl_suppressprint
pl_addcasetag =.f. && flag for automated case/tag adding process
pl_suppressprint= .f.
PUBLIC pl_Mailnew && ( called by QC-AIP)
pl_Mailnew=.F.
PUBLIC pl_UseBase  && ( called by QC-AIP)
pl_UseBase=.f.
PUBLIC 	pl_BlNeedsUpd && ( called by QC-AIP)
pl_BlNeedsUpd=.f.
PUBLIC pc_blurb AS STRING && ( called by QC-AIP)
pc_blurb=""
PUBLIC pc_OrdType AS STRING && ( called by QC-AIP)
pc_OrdType=""
PUBLIC pl_QCProc AS Boolean && ( called by QC-AIP)
pl_QCProc=.f.
PUBLIC pn_QCIssScrn AS Integer && ( called by QC)
pn_QCIssScrn=0
PUBLIC pl_RejectQueue as Boolean
pl_RejectQueue=.f.
PUBLIC pl_QCWCase AS Boolean && ( called by QC-AIP-CASE)
pl_QCWCase=.f.
PUBLIC pl_QCLCase AS Boolean && ( called by QC-AIP-NEW LITIGATION CASE)
pl_QCLCase=.f.
pl_PcxAuth=.f.   &&Qc - show if any pcx authorizations exist
PUBLIC pl_DuplTag AS Boolean && ( called by shwduptag)
pl_DuplTag=.f.

PUBLIC pl_softcopyform
pl_softcopyform=.f.

PUBLIC pc_LocStatus as String
pc_LocStatus=""

PUBLIC pl_ELitNotice as Boolean
pl_ELitNotice=.f.  &&& litigation setting for email notices

PUBLIC pl_addablurb as Boolean
pl_addablurb=.f.   &&& flag setting for adding predefined blurb to new tag

PUBLIC pc_addablurbtxt as String 
pc_addablurbtxt="" &&& text for predefined blurb being added to new tag

PUBLIC pl_QCHold
pl_QCHold=.F.
**6/7/13 added to store the blurb_code with each tag's spec instruction record
PUBLIC pc_BlurbCodes
***12/14/2011-QC Mf2 needs STC category and blurb 
PUBLIC pc_f2STCCat AS STRING && ( called by Mf2/QC Issue)
PUBLIC pc_f2STCBlurb AS STRING
STORE "" TO pc_f2STCCat, pc_f2STCBlurb, pc_BlurbCodes
pn_RpsMerge=0
PUBLIC  PC_QCTagType
PC_QCTagType=""

 *------------------------
 * 07/25/2017 - MD make menu font bigger #65636
* lcfont_name="Courier New"
lcfont_name="Arial"
 lnfont_size=16
 *lcfont_style="B"

 lcxxx = [FONT "] + lcfont_name + [", ] + ALLTRIM(STR(lnfont_size)) &&+[ STYLE "] + lcfont_style+[" ]
public gcMenuF,gcMenuT
gcMenuF = ".f. " + lcxxx
gcMenuT = ".t. " + lcxxx   
*------------------------
**12/03/18, SL, #120367
*Only for use in Issue1
PUBLIC pc_AuthType AS String
pc_AuthType = ""

RETURN
