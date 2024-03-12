PROCEDURE gfClrCas
*     Clears critical public variables (declared in Public.prg) when work on
*     a case is complete. These variables are filled in by the matching
*     gfGetCas routine.
*
*     The time-sheet (EntryX) file, which was opened by gfGetCas,
*     is left open in area F, but all related variables are also cleared.
*
*     REMINDER: Changes to this routine should be made in parallel with
*               changes in gfGetCas and Public
*
*     Original coding: 11/12/2003 DMA
*
*     Called by RTS, CovPage, CaseInfo (after an update),
*        lfPrnBar (in PrintCov), DupCase, CANType
*
*
*    This section covers data that was taken directly from TAMaster
*
** 06/06/06 EF Synch with the latest FoxPro vesrion
** 01/20/05 DMA ELiminate use of TAMaster.Worker field
** 09/23/04 EF Add pl_CivGar
** 09/17/04 EF Added  pl_SRZNot and pl_Motley
** 07/29/04 EF Reset LOR variables
** 11/19/03 IZ added clearing of pl_MdSumAsb
pc_tagdist=""
pn_lrsno   = 0
pc_lrsno   = ""
pc_clcode  = ""
pc_offcode = ""
pl_archive = .F.
* 12/08/03 DMA Add test and template case flags
pl_testcas = .F.
pl_tempcas = .F.
pc_litcode = ""
pc_area    = ""
pc_AreaID  = ""
pn_group   = 0
* 03/18/04 DMA Start:
pc_fullnam = ""
pc_plgiven = ""
pc_plfname = ""
pc_pllname = ""
pc_plminit = ""
pc_pladdr1 = ""
pc_pladdr2 = ""
pc_executr = ""
pc_plssn   = ""
pd_pldob   = {//}
pd_pldod   = {//}
pc_platcod = ""
pc_rqatcod = ""
pc_platnam = ""
pc_platini = ""
pc_amgr_id = ""
pc_plcnty  = ""
pc_docket  = ""
pc_plcaptn = ""
pc_dfcaptn = ""
pc_Court1  = ""
pc_Court2  = ""
pc_req_atf = ""
pc_distrct = ""
pc_divisn  = ""
pc_cclnum  = ""
pl_intrrog = .F.
pc_reqatty = ""
pc_reqpara = ""
pc_employr = ""
pd_empstrt = {//}
pd_empend  = {//}
pd_settled = {//}
* 01/20/05 DMA ELiminate use of TAMaster.Worker field
*pc_worker  = ""
pl_chosen  = .F.
pd_trial   = {//}
pd_depo    = {//}
pd_assign  = {//}
pd_request = {//}
pc_plcommt = ""
pn_depcnt  = 0
pc_pldeal  = ""
pc_projcod = ""
pn_projnum = 0
pc_conditn = ""
pc_simfrst = ""
pc_maiden1 = ""
pc_maiden2 = ""
pc_mfcture = ""
pc_salesmn = ""
pd_term    = {//}
pc_catgory = ""
pc_lotno   = ""
pc_occpatn = ""
pc_devno   = ""
pd_casentr = {//}
pd_casedit = {//}
pc_plbbrnd = ""
pc_plbbnum = ""
pc_plbbASB = ""
pd_SSCDate = {//}
pd_MTADate = {//}
pc_billpln = ""
pc_aliencd = ""
pc_proccod = ""
pc_billcod = ""
pn_wittotl = 0
pc_Claimno = ""
pd_closing = {//}
pc_complnt = ""
pc_reparea = ""
pc_firmcod = ""
pc_casenam = ""
pl_MTAxpct = .F.
pc_CreaCas = ""
pc_EditCas = ""
pc_Suffix=""
*
*    This section contains public variables whose values were
*  computed directly from the contents of the TAMaster file.
*
pl_plisrq  = .F.
pc_plnam = ""
pc_plnamrv = ""
pl_BBCase = .F.
pl_BBAsb = .F.
pc_BBDock = ""

** --- 08/04/2020 MD #170629 added plCourtIN
STORE .F. TO pl_RezWil, pl_Propuls, pl_PropMS, pl_PropPA, pl_PropNJ,    pl_PropFed, pl_PropBlk, pl_NJSpec, pl_TxAbex, pl_FenPhen, pl_PPAPage, ;
   pl_BaySch, pl_DietDrg, pl_DDrug2, pl_MerSch, pl_ThiEve, pl_RezMont,   pl_OhioAsb, pl_MichCrt, pl_NJSub, pl_BayCol, pl_OhioSil, pl_RezMdl, ;
   pl_MdAsb, pl_MdlHold, pl_MoldNY, pl_Remic, pl_MdSumAsb, pl_WeldRod,    pl_ScanSub, pl_MichCrt, pl_NJSub, pl_BIHipaa, pl_AsbHipaa, pl_Hipaa, ;
   pl_RezNY, pl_STDietD, pl_STDSed, pl_PSGWC, pl_HRTLor, pl_Shelltr,    pl_AsbCon, pl_LotronB, pl_Thimil, pl_PropNon, pl_A18839P, ;
   pl_PropNJ1, pl_PropDr, pl_NYCAsb, pl_SRZNot, pl_Motley,    pl_CivGar, pl_HRTMorg, pl_VIXMot, pl_ENBMot, pl_Zicam, pl_ENEPwl, pl_noQcIssue,;
   pl_Clbrx, pl_Zyprx, pl_CivilNY,  pl_IRGFl, pl_BexMot, pl_EvrNJ,    pl_Anglvx, pl_DfrAng, pl_GoldenCiv, pl_DrinkRMD, pl_Pxldech, ;
   pl_PhenAng, pl_RNUAngl, pl_HTSMotl, pl_CRTAngl, pl_DPVAngl, pl_OSCAngl,    pl_DfrAyl, pl_LeadMot, pl_CivFeld, pl_WelFMot, pl_WFSBart, pl_HTSPltf, ;
   pl_EclSpch, pl_MargCiv,pl_BiceAlb, pl_AVAPltf, pl_ENEBrist , pl_AYKAva, pl_NonGBB ,   pl_PAsubp, pl_FLRHi, pl_ZLNAyl, pl_FbtSal, pl_fakePdf, pl_SpecRpsSrv, ;
   pl_LevaNJ, pl_AV1Fed,    pl_AV1PA, pl_AV1IL, pl_AV1CA, pl_Ava1, pl_BalDgtk,pl_RejectQueue,  pl_ZcmFed, pl_CambAsb, pl_ElitNotice,    pl_PncFed, pl_PcxAuth, ;
   pl_NJAsb, pl_Garret, pl_Nebltt, pl_RisPCCP, pl_CambAsb, pl_A044584P, pl_F2newway,    pl_BPBLit, pl_HRobins, pl_AVACourtOrd, pl_PdfReprint, pl_OrdVerSet, ;
   pl_BatchNot, pl_BALsrq, pl_RPDNy, pl_SrqDrk,  pl_McEwen, pl_AvaEwe, pl_BMSLor, pl_CivBeasly, pl_AvaCms,pl_ILCook , pl_CivShMr, pl_CivHelf, pl_Fee37, pl_CMSWag, pl_Stark, ;
   pl_AvaStark, pl_BabLor, pl_ReiMesh, pl_ZDHFae, pl_BIOLor,  pl_CivMess,  pl_CivTang, pl_EisenRoth, pl_GallantPrlw, pl_UpdHoldReqst, pl_ObjLifted,;
   pl_ReiSSRI, pl_CivCiecka , pl_PRLKee, pl_ReedMgn, pl_YazMcEw, pl_MBCoach, pl_CivSFLOP, pl_Thalidmd, pl_Ronan, pl_CivHang , pl_MRCLetter, pl_ZOLMDL, ;
   pl_CivAnapol, pl_ZolLtr, pl_McEldrew, pl_ZOLRuleF13, pl_CivMdOhio,  pl_CivPion,pl_CivLevyB,  pl_Effexor, pl_MulBrazil, pl_TPXlit, pl_CivDT, pl_CivGreat, ;
   pl_CivLocks, pl_ZnkMdl, pl_Golomb, pl_DurantLaw, pl_CivParks, pl_CivGBass, pl_GRBCiv, pl_NJSwny, pl_NJSoriano, pl_XARSch, pl_TTHPh,pl_Archer, pl_KentBc, ;
  pl_CivKBG, pl_Duffy, pl_SchDT, pl_GayCiv, pl_LevinCiv,pl_DtRamsey,  pl_BroadCiv, pl_FreedLrry, pl_RpdAna, pl_XarAna, pl_TeoAna, pl_ZofAna, pl_ActAna, pl_Chartwell , ;
  pl_Chasan, pl_Mincey,pl_MDLead, pl_PharmLocks, pl_SaltzCiv, pl_BuchIn,pl_civMP, pl_CivNLaw, pl_MORAng, pl_XARAgl, pl_BenGol,pl_progHub, pl_WebForm , ;
  pl_Parker , pl_Mccandls, pl_Chubb, pl_AWAC, pl_SwainLaw, pl_Falvello, pl_Green, pl_Zarwin, pl_WebrGall, pl_CivHarris, pl_Mannion , pl_Pisanch, pl_Saltzmo, pl_WagZofrn,  ;
  pl_ATraub,   pl_AnapFos,pl_Himmel,    pl_dpllor, pl_THolland, pl_Bilotti, pl_Cozen,pl_FritzG,pl_CiprCiv, pl_BeglCarl, pl_AwcRay, pl_MarksO, pl_Kovler, pl_Coker, pl_McElree,	;
  pl_Kwass, pl_Sater, pl_ChSdg ,pl_ZofGsk, pl_LangEmi, pl_GoldSeg, pl_CivPillgr, pl_Heavens, pl_WadeCNJ, pl_StarkNJ, pl_ARusso, pl_Laddey, pl_IntPaper, pl_Traflet, pl_Chk4Img, ;
  pl_Savage, pl_MR_RI, pl_JANLor, pl_Winegar, pl_Depasq, pl_TBarry,pl_DSheehan, pl_DMPitt, 	pl_RasLaw, pl_OBrien,  pl_Ostroff, pl_LittleJ, pl_Feller, pl_Datz,pl_RubinG, ;
  pl_Pallante,pl_Zarrow, pl_pdfOnly, pl_ZWFirm, pl_RdckMs, pl_TXCourt, pl_Johans, pl_Strav, pl_Andre, pl_Weisbrg, pl_LambMc, pl_Swartz,  pl_KnightH, pl_Needle, pl_PurchG, ;
  pl_Kutak,pl_ExclMI,pl_Delany,pl_Schubert, pl_GoodRich, pl_Wapner, pl_Lowen, pl_Vidaur, pl_RosenSch, pl_WeberK,  pl_BelloR, pl_GRMN, pl_Naman, pl_VLahr,  pl_TozLaw, ;
  pl_Vigorito, pl_VanderV, pl_Soloff, pl_GRANJ, pl_Strass, pl_YoungCo, pl_Shafer, pl_SchatzS, pl_WilsonGA, pl_Hamilt,   pl_GRCorsi, pl_Daiello, pl_mbart, ;
  pl_AllenGooch, pl_CivAspMM, pl_CsltxLor, pl_Amerilor, pl_GoeLor, pl_CivMcd, pl_CivAspl, pl_BrianMurph, pl_BroadSpire, pl_NardMoore, pl_Chapman, ;
  pl_GoldScar, pl_StarrGallo, pl_GRFullertn, pl_FanelliEvans, pl_FoleyMans, pl_RosenLaw, pl_BroadSp, pl_GRBarnaba, pl_LaffeyPhila, pl_PharmaSim, pl_ShcAsbes, pl_YorkRsk, ;
  pl_Haworth, pl_GRLbmb, pl_FranzDra, pl_GRSwift, pl_Faegre, pl_GoldsegNJ, pl_TexasFran, pl_RyanBrown, pl_AnzaloneLaw, pl_ClarenceBarr, pl_AwacMalaby,pl_Litchfield, ;
  pl_CivSheehy,pl_Litchcavo,pl_Obrien2,pl_civsedg,pl_civcorv,pl_brems,pl_civsacks, pl_Gordon, pl_WeirKest, pl_GrmoSand , pl_BurnWill, pl_JTFox, pl_WilEls, pl_AshGerel, ;
  pl_GAIGrem, pl_UHSHPrn, pl_MagKauf, pl_Simon, pl_WilsonPA, plCourtIN


STORE .F. TO pl_MYngCon, pl_Hawk, pl_WCoxPLC, pl_IAhmuty, pl_HSandberg,pl_GNashCon, pl_GAIGMor, pl_Mintzer,pl_Olearys,pl_MSdMInz, pl_McNab, pl_AtlasB, pl_MPCohen, ;
	pl_Brooks, pl_Sheeley, pl_OConnor, pl_VigoriGAR, pl_VigoriVAL, pl_TraubNJ, pl_TraubNY, pl_CovTrans, pl_use_LOR_Refer


*
*   The following subsections clear values in public variables
*  that were filled by using a TAMaster field as the key to a lookup file.
*
*
*  Filing office data from Office file
*
STORE "" TO pc_ofcdesc, pc_ofcstat, pc_SpecHand, pc_faxcover, pc_BarNo ,  pc_txCrtType
   STORE .F. to pl_ofcKOP, pl_ofcMD, pl_ofcPgh, pl_ofcOak, ;
      pl_ofcPas, pl_ofcHous, pl_MDAsb, pl_MdSumAsb,pc_fullssn, pc_emailAdd,  pc_f2STCCat, pc_f2STCBlurb, pc_BlurbCodes
*
*    Group-related data from CaseInfo file
*
STORE "" TO pc_grpname, pc_casname, pc_casenum,PC_TXQUEST
pl_nogroup = .T.
*
*   Area-related data from area file
*
STORE "" TO pc_areamgr, pc_arealit, Area_ID
pc_areanot = .F.

*
*  Client representative and salesperson info from UserCtrl file
*
* 03/08/04 DMA Add variables for Rep's scanned signature
STORE "" TO pc_amgr_nm, pc_amgr_ml, pc_amgr_ph, ;
   pc_sale_nm, pc_sale_ml, pc_sale_ph, pc_ScanSg
pl_ScanSig = .F.
*
*   Look up litigation-based information from Lit file
*
   STORE 0 to pn_litiday, pn_litfday, pn_objDay, pn_QCIssScrn,  pn_SetNum
   STORE .F. TO pl_litnofx, pl_litath2, pl_CAinKOP, pl_CivBle
   STORE "" TO pc_litname, pc_litnotc, pc_litfnot, pc_litdcap, pc_imagedb
*
*  Case-instruction information from INSTRUCT File
*
STORE .F. TO pl_rushcas, pl_scanned, pl_nohold, pl_autscan, pl_review, ;
   pl_bates, pl_sgncert
STORE d_null TO pd_revstop, pd_startNot
STORE 0 TO pn_req_by
pl_CFlook = .F.
pc_FlAtty = ""
pn_Fldays = 0
pc_Fltype = ""
pc_Flship = ""
*
*  Court-specific data
*
STORE .F. TO pl_c1Form, pl_c1SSubp, pl_c1Notic, pl_c1Prvdr, ;
   pl_c1PrtSc, pl_c1Cert, pl_c2Form, pl_c2SSubp, pl_c2Notic, pl_c2Prvdr, pl_Solis, pl_Reilly,;
   pl_c2PrtSc, pl_c2Cert, pl_AsbHipaa, pl_BIHipaa, pl_StopPrtIss, pl_BiceFl, pl_OutofBus


STORE 0 TO pn_c1Due, pn_c1Hold, pn_c1Cmply, ;
   pn_c2Due, pn_c2Hold, pn_c2Cmply

STORE "" TO pc_c1name, pc_c1Desc, pc_c1Cnty, pc_c1Addr1, pc_c1Addr2, ;
   pc_c1Addr3, pc_c1City, pc_c1State, pc_c1Zip, pc_c1Phone, ;
   pc_c2Name, pc_c2Desc, pc_c2Cnty, pc_c2Addr1, pc_c2Addr2, ;
   pc_c2Addr3, pc_c2City, pc_c2State, pc_c2Zip, pc_c2Phone, ;
   pc_TxCtTyp, pc_TxCtLn1, pc_TxCtLn2, pc_TxCtLn3, ;
   pc_TxDist, pc_TxDiv, pc_TxCSZ, pc_TxHold, pc_RpsForm, pc_EmailAdd	
   STORE .f. to pl_TRBAngl, ;
   pl_THIAngl, pl_AsbAngl, pl_Popcorn, pl_Popcorn2, pl_FLRThomp, pl_SrqFed, ;
   pl_VXNeblett, pl_TBTAstk,pl_CivilAng ,pl_HRTAstk, pl_ZDHAstk, pl_WCABKOP,pl_FooteMey, pl_CivCoach

pn_HoldSub = 0
pc_EntryN = ""
pc_EntryF = ""
pc_EntryV = ""
pl_GotCase = .F.
*--6/01/04 kdl start:
pl_clCasno = .F.
*--07/29/04 EF - reset LOR's var
pn_LORpos = 0
RELEASE patemplist
RETURN
