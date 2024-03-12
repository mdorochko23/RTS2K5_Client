Procedure SUBP_PA
* 03/20/2012  -EF : ADDED NEW USDC FORMS TO THE CA OFFICE
* 02/29/2012  -EF : all KOP litigation use the same USDC form
* 07/29/2011 - EF : Added CourtCode to a KOP Req.Cover Letter
* 01/25/2011 - MD : moved update tblRequest.expedite to make sure that the tblRequest is updated when txn14 is added
* 08/16/2010 - EF : PER JULIE: IGNORE DATA PER USER'S DECISION TO FAX AN ORIGINAL REQUEST
* 05/24/2010 - EF : Print a subp'a scanned pages with the Notice and Court Sets for the KOP Civil lit issues
* 04/30/2010 - kl : Replaced suplemental tag code for (pc_litcode='LQN' AND pc_area="NewJersey")
* 03/23/2010 - EF : Added Av1Letter
* 11/09/2009 - EF : Print SRQletter for "FEDERAL", "DELAWARE", "NEWJERSEY"  areas only
* 10/28/2009 - EF : edited to work with the reprints from pdf files
* 09/14/2009 - EF : Strip a Fax Cover page( pc_faxcover) page from a 1st request
* 09/10/2009 - EF : Strip a Spec Handling( pc_SpecHand) page from a request
* 08/31/2009 - EF : Reprint Original PDF with a Cover page for all reprint/second requests
* 08/25/2009 - EF : Store Request Due date
* 08/10/2009 - EF : getcaSigner/GetCADeliv
* 08/03/2009 - EF : split CA POS into two pages
* 05/14/2009 - EF : Ava Reprint vars.
* 04/13/2009 - EF : MD subs- print dapdate.. text
* 03/23/2009 - EF : new district case/tag level.
* 02/09/2009 - EF : Print an issue date on all subpoens
* 01/12/2009 - EF : UPDATE request dates  FOR KOP SUBPOENAS
* 10/15/2009 - EF : Edited Baltimore subp
* 06/18/2008 - EF:  Print original's date on the second requests subpoena forms
* 05/07/2008 - EF:  removed Flgenpage as cleint does not want to print that page anymore
* 11/29/2007 - EF: 	Added Batch Request processing/ do not allow to fax it
* 10/17/2007 - EF : Separated RUSH/NON-RUSH SRQ First Requests
* 10/16/2007 - MD : DO lp1stLK commented per Kirk's request
* 09/18/2007 - EF : Edited the USDC subs.
* 08/27/2007 - EF : Modified to work with the issue from the Deponent Level.
* 07/11/2007 - MD : Modified to create c_mark as Litigation + userctrl.initials
* 04/27/2007 - EF : Added 'SRU' dept.
* 04/09/2007 - EF : Added a new phone for the Propulsid lit cases
* 02/28/2007 - EF : Tried to fix the problem with faxing requests to a hospitals (orig + sec requests)
*                 : All changes marked with the 2/28/07.
* 07/06/2006 - MD modified to call court serach screen as modal
* 07/05/06 - retrofitted auto tiff document generator
* 04/11/06 - Released CA issues
* 03/8/06  - Texas issues
* 02/28/06 - Added CA Reprints
* 11/07/05 - Switched to Sql
**********************************************************************
* Subp_pa.prg - Program to issue Subpoenas, authos, notices, etc.
*  for all litigation types, courts, etc.
*  Uses RPS for printing.
*
* Note: when adding new litigation types, they must also be added to
*  the nonotice table (type 'A') to get notices for authorizations
*
*  Called directly by DepOpts, TheNotic, CovPage, Plaintif, CourtSet

*  Assumes that gfGetCas, gfGetDep have been called in advance of any call
*  where a tag number is provided as a parameter.
*  Assumes that only gfGetCas has been called if no tag number has been
*  supplied as a parameter (i.e., second request or new issue)

*  Internal routine CivPop called by CasbText.SPR
*  Internal routine MDProof called by TheNotic
*  Internal routine SpecHand called by HIPAASet
*  Internal routine Pick_Aff called by Subp_Lib
*  Internal function FaxValid called by FaxCover.spr
*
*  Uses screens DueDate, ProvInfo, CASubpQu, CACivils, CADecl,
*               CADSPers, CADSper2, CADSOnly, WCABPg2, AsbRound,
*               DepoDate, FaxMgr, FaxCover, SpecHand, RevIssue, NoteRmd
*
*  Calls GetBlurb, ViewInst, WitFee, gfAddTxn, SpinClose, gfReOpen
*        SetOrdTg, GlobUpd, SendMsg, PrtEnqA, PrintGroup, gfChkPln
*        PrintField, SpinOpen, ReAttch, SecondRq, RepAuto,
*        gfHold, gfLkup, gfFrDays, gfIssDay, gfUse, gfUnUse,
*        gfChkDat, gfDtSkip, gfYesNo, gfGetDep, gfDefCnt, gfIssuDt,
*        gfPush, gfPop, gfMailN, gfCall, gfAddTxn, PrintCer, PlNotice,
*        gfState, gfMailPh, NewTag, SpInText, gfPrtGrp, AFaxRmd, PrtPrere,
*        NewDepo, gfSigner, gfServer, gfAddCR, gfOrdNum, gfGetAtt, gfNomdCt,
*        pTXAffid, Subp_Lib, gfTXCour
*
*  Calls the following routines in Subp_CA:
*        CAUSPoS, SUBWCab, CAConNtc, CAConPOS, CAPosNot,
*        CAUSSubp, CAUSOthr, CADepSub, CADecAff
*
* History :
* Date      Name  Comment
* ---------------------------------------------------------------------------
* 10/5/06 kdl -   include orto evra litigation supplemental
* 10/18/05 EF  -  Ask 'If this a rush?' for the CA office cases, too.
* 08/30/05 EF  -  Re-print affidavits for Civil w/Records subp issues (CA ofice)
* 07/22/05 EF  -  Allow to fax the 2nd requests for "G" lit/review tags.
* 07/12/05 EF  -  Fixed a bug : The FAXORIG belongs to the Medical dept ONLY.
* 04/05/05 EF  -  Fixed a bug in calculation of the requests mail date: use gfchkdat
* 03/09/05 EF  -  Do not send request via fax for Zicam first issues
* 02/10/05 EF  -  Add 'Zicam' lit issues
* 01/20/05 DMA -  Remove use of TAMaster.Worker field
* 12/21/04 IZ  -  For the reprints of 2nd request the due date and future date should be
*                 calculated from issue date
* 12/16/04 EF  -  Add "Second Request" to the CA Request Cover Pages
* 11/18/04 EF  -  Bug fix in the MDProof.
* 09/24/04 EF  -  Skip the 'Attachment 3' page printing for depo.personal subp. (CA)
* 08/30/04 EF  -  Fixed a bug : Do not print LORs with notices
* 08/02/04 DMA -  Special deponent names for plaintiff requests in NYC Asb.
*                 Add titles to all SendMsg windows
* 07/29/04 EF  -  Allow to fax a 2nd req if a tag is a reissue
* 07/29/04 EF  -  Control LORs printing by LORCTRL table
* 07/20/04 DMA -  Rename all internal routines to 8-character IDs
*                 Rename SendPage to Send_Pg to avoid overlap w/TA_Lib routine
* 07/09/04 kdl -  Added ta_lib procedure set to PrintSub procedure
* 07/09/04 DMA -  Replace gsCertType with pc_CertTyp
* 07/08/04 DMA -  Replace l_EditMode with pl_EditReq, gsQuest with pc_TXQuest
*                 Move all PRIVATE statements to start of their routines
* 07/07/04 DMA -  Replace msoc_sec with pc_SSNLst4
* 06/28/04 DMA -  Replace bNot with pl_noticng
* 06/22/04 DMA -  Remove "Contact" group from TX documents; built into templates
* 06/21/04 EF  -  Print 'Acknowledgment' St DD page only for "A" issues
* 06/10/04 DMA -  Move PrnTxDoc routine here, from Subp_Lib, for private use.
* 06/09/04 EF  -  Check status of a billing plan for "T" attys only when
*                 issuing a new tag.
* 06/03/04 DMA -  Correct typo, eliminate use of gfentryn via global vbl
*                 Use renamed PrintCer routine ( formerly pPrtCert IN Printcer)
* 05/25/04 DMA -  Switch to use of long plaintiff name in all documents
* 05/10/04 IZ -   Added "Letter of Representation" for HRT-Cohen cases and A25658P attorney
* 05/03/04 DMA    Check first requests against case instructions for use of
*                 proper request type (subp. or autho.)
* 04/21/04 IZ -   If Waiver is Received, do not apply Hold period for Subpoenas
* 04/14/04 EF  -  Add a LOR for "A" issues for "A25465P" def atty in STD/Sedgwick cases
* 03/25/04 DMA -  Use global variable pl_prtnotc for communication w/CaseWork
* 03/24/04 EF  -  Add a parameter to print subps with a 'KOP Court Set'
* 03/22/04 DMA    Reset "Research" flag when second request is created
* 02/27/04 EF  -  Add an "Acknowledgement" page to State DD authorization issues
* 02/26/04 DMA -  Reset "Research" flag in Record when issue/reissue is done
* 02/20/04 EF  -  Start gathering data into the HOLDREQ db table.
* 02/04/04 EF  -  Add a LOR for the Welding Rod lit "A" issues
* 01/30/04 EF  -  Add special wording to the K O P Request Cover pages for DD2
* 01/26/04 EF  -  Use Atty's signature (Name_inv) on K O P documents
* 01/21/04 EF  -  Add AM signature to a Court Cert page
* 01/08/04 DMA -  Check for inactive/missing plans on first requests
* 12/30/03 DMA -  Auto-reopen a closed case for second request or reprint
* 12/10/03 IZ  -  Michigan Subpoena due date hold period changed from 28 to 14
*                 per Megan's request
* 11/19/03 EF  -  print Court Cert for all PA courts
* 11/12/03 EF  -  Add a LOR for the Remicade lit cases.
* 10/17/03 kdl -  Eliminate the first-look confirmation prompt for all but
*                 California and Pasadena offices
* 10/16/03 IZ  -  Added "Letter of Representation" if atty="A18839P"
* 10/14/03 IZ  -  Print notices for the "MD/SUMMARIZED" only for Subpoena
* 09/24/03 EF  -  Print original issue dates on Civil Lit Subp Reissues
* 09/23/03 EF  -  Add the 'Bivona' LOR
* 09/18/03 EF  -  Add 15 dys hold to the MDL-hold rezulin auth issues
* 09/11/03 EF  -  Add HIPAA page to TX Federal sub issues.
* 08/29/03 kdl -  Add setting of first-look to false (else condifiton) to handle mirrored tags
* 08/21/03 kdl -  Changed first-look prompt check for calif to use variable
*                 creqtype instead of pc_Isstype
* 08/20/03 EF  -  Add a new Proof for MD Asb cases.
* 08/12/03 EF  -  Modified the HIPAA notice and add a plaintiff notice for
*                 civil litigation cases
* 08/08/03 EF  -  Add a Consolidation # to the MD Baltimore subps
* 08/01/03 EF  -  Add new title for MD-HCA
* 07/29/03 EF  -  Print CA subp's attachment #3 as a separate page
* 07/22/03 kdl -  Restored AGAIN clause in CACovLtr procedure when subpoena table is opened.
*                 Is needed because table can be openned under different alias.
* 07/21/03 EF  -  Do not print MD proof cert for specific attys
* 07/15/03 IZ  -  Make sure public variable for printing notices is set to FALSE if it's Re-Issue
* 07/11/03 kdl -  Add suppl tag prrocedures for bates stamping data collection
* 07/02/03 kdl -  Add Oakland office subpoena tag-specific document printing
* 07/01/03 EF  -  Removed hold period for Propulsid Subpoena issues
* 06/27/03 EF  -  Add 10 days to Baycol -FromRev- Auth first issues mail date
* 06/26/03 DMA    References to "&dbCounties.." changed to "County."
* 06/24/03 DMA -  Limit display of possible duplicates to KoP version only.
* 06/19/03 EF  -  Remove the check on pl_FromRev to always display list of
*                 possible duplicate issues
* 06/18/03 DMA -  Additional comments on parameter functions.
*                 Move parameter-analysis code to start of program
*                 Switch from lnReqFee to pnReqFee in CAPosSub
* 06/17/03 EF  -  Direct ASU dept jobs to a separate RPS print queue; Fixed lfMisSubp.
* 06/16/03 DMA -  Store Berry & Berry location code, web order # in Record
*                 Fill in date-added field in Subpoena database
* 06/09/03 DMA -  Further tuneup of affidavit-production routines
* 06/06/03 DMA -  Merge in affidavit-production routines from Subp_CA
* 06/02/03 DMA -  Rename "auto" to "l_autosub" for clarity
* 05/29/03 DMA -  Convert noticing variables to standard naming
*              -  Use gfServer, gfSigner instead of routines in Subp_CA
* 05/29/03 DMA -  Use gfOrdNum to format ordinal strings.
*              -  Move CA Cover letter routines here from Subp_CA
* 05/28/03 DMA -  Use gfAddCR to format blurbs and attachment information.
* 05/23/03 DMA -  Move CA Rad/Path Breakdown routine here from Subp_CA
* 05/22/03 EF  -  Add Firmname to MD Asbestos Cert proof
* 05/21/03 DMA -  Use public logical vbl to determine office/version of RTS
* 05/16/03 EF  -  Replace szAttn to pc_FaxAttn to avoid over-assigning a Attn
*                 line for location by AKA for plaintiff
* 05/14/03 EF  -  Add PL Atty address for MD HCA subp
* 05/12/03 DMA -  Tune up logical statements
* 05/12/03 EF  -  Add call for a HIPAA Notice page
* 04/30/03 DMA -  Replace use of AddRecd with NewDepo
* 04/25/03 EF  -  Fax a Reminder Notice vs a Complete Set
* 04/18/03 kdl -  Added first-look functions for first requests (merged 8/4/03)
* 04/14/03 EF  -  Add call for CA Rad/path breakdown forms
* 04/10/03 DMA -  Correct typo in calculation of l_faxallow
* 04/02/03 IZ  -  Remove holding period for Reissues
* 03/27/03 KDL -  Replaced Record table field reference variables with public
*                 variables initialized in the calling progams.
* 03/27/03 KDL -  Add variable to ID new requests that need to have records
*                 inserted into the Record dbf.
* 02/28/03 EF  -  Fix a bug for Propulsid - Auth 2nd request's due dates
* 02/24/03 EF  -  Fixed a due date for MD authorizations (sec. request)
* 02/18/03 kdl -  Block selection of retired deponents for new issues
* 02/14/03 kdl -  Added procedure to allow user to select the dept. for mirrored
*                 hospital tags
* 01/13/02 kdl -  Added code to process califoria scanned autho files
* 12/18/02 kdl -  Blocked coverltr call for bNotcall = .T. and l_autosub (for notices)
* 12/13/02 EF  -  Use 28 regular days for the MI subp due dates calculation
* 12/09/02 kdl -  Added 2nd lor for pl_propuls
* 11/12/02 EF  -  Edit MI subpoenas: print Req.Atty data on subp
* 11/06/02 EF  -  Disable 'Fax First Requests' for CA and TX offices
* 11/06/02 kdl -  Added Propulsid/Empty LOR
* 11/04/02 kdl -  Adjust due date for adjusted serve date if not hand serve notice
* 11/04/02 EF  -  Add 'Fax Original Issues' option
* 10/24/02 EF  -  Add correction to NJ subpoenas/notices
* 10/24/02 DMA -  Exclude current tag from duplicate-issue from-review check
* 10/22/02 kdl -  Print new Thimerasol LOR for Miller,
* 10/21/02 EF  -  Print existing Lotronex LOR for Rezulin/Baycol.
* 10/18/02 EF  -  Print existing Lotronex LOR for VIOXX cases.
* 10/10/02 IZ  -  Removed 3rd (reissue) parameter, changed handling of reissues
* 10/17/02 DMA -  Check for duplicate issues when processing from-review tags
* 10/17/02 kdl -  Activated echocardiogram department code
* 10/17/02 EF  -  Add code for Michigan courts subpoena issues
* 10/10/02 IZ  -  Remove reissue as a 3rd parameter, since it handles through Record.reissue field now
* 10/02/02 kdl -  Check for 12 character file names in Send_Pg. If names are longer,
*                    exit the function
* 09/20/02 EF  -  Stop Propulsid and DD auths from autofax if hold period is not over
* 09/18/02 DMA -  Screen CASubpQu updated to permit higher round numbers
* 09/16/02 kdl -  Added code to process new format tiff file names in
*                 pScnAuth, pScnSubp, pSpecDoc
* 09/16/02 kdl -  In the CovrLetr procedure, switched from field references to public variables
*                 for plaintiff print variables.
* 09/11/02 EF  -  Re-direct RTURUSH print works to a separate printer.
* 09/06/02 EF  -  Edit WorkName() to print "RT Representative' instead of a name of inactive AM
* 09/05/02 kdl -  Initialized variable l_FaxAllow as private variable in printsub
* 09/05/02 DMA -  Use public vbl. for Rezulin/Montgomery
* 09/04/02 EF  -  Allow fax an issue by a subpoena if a hold period is over
* 08/28/02 DMA -  Eliminate unused vbls mGroupName, mCaseName, mCaseNum
* 08/26/02 EF  -  Allow DD/From Revew cases be autofaxed and print duedate +10 days.
* 08/21/02 kdl -  Add Rezulin Litgation - Area = Montgomery Letter of representation
* 08/21/02 EF  -  Sec Request due date for Rezulin-Montgomery changed to be + 10 days
* 08/14/02 kdl -  Changed conditions for TX affidavit printing to match condition
*                 for presenting selection
* 07/30/02 kdl -  Add Lotronex Litgation - Area = beasley Letter of representation
* 07/26/02 DMA -  Update special instructions in PSNotice after blurb is edited
*                 during a second request or reprint.
* 07/23/02 DMA -  Exit w/o asking for questions if no blurb picked in TX issue
* 07/15/02 dma -  Move definitions shared w/Fax2Rq to gfGetCas
* 07/11/02 dma -  Fill in CreatedBy field on 11 transactions
* 06/28/02 kdl -  Add "Asbestos Litgation - Area = connecticut" Letter of representation
* 06/26/02 EF  -  Added code for CA batch autofax of second request
* 06/26/02 kdl -  Aded drqduedate initialization in ist request procedure
* 06/20/02 dma -  Don't ask "Is this a rush?" if case-level rush flag is set
* 06/19/02 dma -  Replace mlogname with pc_UserID; remove ID from gfAddTxn call
* 06/17/02 dma -  Add mailing-date parameter to AddRecd call
* 06/07/02 kdl -  modif condi for checking for TX affidavit in new issues
* 06/06/02 kdl -  Added Thimersal Litgation( area = Evert) letter of representation to
*                 issue doccument packages.
* 06/06/02 kdl -  add new texas lit area to list used to initialize variable l_txAbex
* 05/31/02 kdl -  Added fed ex request sheet for all diet drug discovery, PPH, intermediate
*                 litigations subpoenas and authorizations.
* 05/30/02 kdl -  Add new document for litigation and area - MAR, Schiffrin
* 05/23/02 kdl -  Added pl_2ndQue flag sets for Texas print jobs
* 05/20/02 kdl -  Corrected problem with setting of new litigation variables.
* 04/26/02 IZ  -  Check hold period for New Diet Drug Litigation issues
* 04/25/02 kdl -  Added code to check for spec T files when printing scanned authos
*                 (with creqtype at end of name).
* 04/23/02 kdl -  correct the cover letter and due dates for reprint authos
* 04/22/02 kdl -  modifications to correct problems with requests letters caused
*                 by earlier modifcations
* 04/18/02 MNT -  a letter for Litigation = propulsid and area = Blackmon.
* 03/28/02  HN    Eliminate use of "Worker" file. Use UserCtrl instead.
* 03/27/02  kdl   Set default due date to issue date plus 10 for reprints of
*                 of authorizations.
* 03/26/02  MNT   Added a condition if TIF found don't print PCX. KOP only
* 03/15/02  kdl   Changed propulsid NJ and PA notices due date to today + 14
*                    business days
* 02/20/02  EF    Separate ICU dep. work from others
* 02/18/02  EF    Add print-queue processing for RTU Rush department
* 02/18/02  DMA   Add Echocardiogram Department to all hospital processing
* 02/12/02  EF    Texas new cases will print *.tif images with Autho requests
* 02/08/02  EF    CA office print *.tif files as attached authorizations.
* 01/25/02  EF    Print an internal memo for Texas Federal court issues
* 01/17/02  EF    Add code for Propulsid Subpoenas issues.
* 12/20/01  EF    Add local and LD phone call transactions to
*                 autofax/fax transmittals
*                 Add an autofax cover page for second requests.
* 12/14/01  DMA   Integrate new screens AsbRound, DepoDate, FaxCover, FaxMsg
* 12/13/01  DMA   References to TAMaster items replaced with public variables
*                 Create internal routine FirstReq
* 12/10/01  DMA   Use public office-identification variables (pl_OfcKOP, etc.)
* 12/10/01  EF    Baycol/Shiffrin special handling (Jen D. request)
* 12/05/01  DMA   Add Fed-Specific propulsid handling
* 11/29/01  EF    Texas Court
* 11/02/01  EF    Reprint and Sec. requests need to print txn_date of 11 code
* 10/24/01  EF    Texas subpoena work
* 10/17/01  EF    By Cathy B. request print RTU jobs in 651 building
* 09/12/01  EF    3-char. litigation code
* 08/10/01  EF    Reprint attachment with subp. aff.
* 08/09/01  EF    Move Propulsid pages before matching autho. page.
* 08/01/01  EF    CA asbestos issues print new 800 number.
* 07/18/01  EF    Add propulsid NJ, PA scanned pages. Make pScnSubp function
*                 print multi-pages per tag.
* 6/14/01   EF    TX affidavit edit mode
* 05/19/01  DMA   Add call to gfGetDep when creating new row in Record table
*                 to fill in public variables.
* 04/11/01  DMA   Add accurate area-code analysis for fax cover sheet
*                 Select departmental fax number for fax cover sheet to hosp.
* 03/05/01  EF    Add Autofax Second request code
* 02/27/01  DMA   Use gfChkDat to eliminate depo/due dates on
*                 holidays and weekends
* 12/29/00  DMA   Prevent data overwrite during second requests
* 09/27/00  DMA   Remove unneeded GLY2K references
* 09/26/00  EF    Certifications print with requests (K O P).
* 09/18/00  EF    WCAB Subp.(CA)
* 08/25/00  EF    Court Certificate printed with subpoena for courts
*                 with CourtCert=.t.
* 08/10/00  EF    Civil & deposition subs.(CA)
* 05/11/00  DMA   Add new Philly area codes 445, 835 to identify local calls
* 11/10/99  EF    Modify Autofax & USDC sub.
* 09/24/99  EF    Court Certificate
* 08/20/99  DMA   Change date constants to 4-digit year for Y2K
* 04/22/99  EF    The "Certificate of Service" page printed with
*                 subps (MD courts)
* 03/23/99  Mark  Allow CA office to select department for
*                 non-hospital locations
* 02/03/99  Mark  Include check for "AF_Utility" variable.
*                 If exists, bypasses main printing functions
* 06/21/99  TomC  Modify for Y2K compliance
* 12/09/98  Mark  Cut-in of California office subpoena and Autho
* 08/05/98  Hume  Check existence of Txn 11 and use Insert
*                 instead of Append blank for Entry
* 08/04/98  Hume  Re-direct "HOLD" Authos to HoldSub class.
* 04/09/98  Hume  Added Hot Key to show F2 information
* 12/09/97  Hume  Re-Direct Hold Subpoena cases to different queue.
* 12/09/97  Hume  Do not allow autofax on Hold Subpoena cases.
* 11/10/97  Hume  Add ability to reprint without any user interaction
* 11/10/97  Mark  Adjust dates using COURT.DBF on req. cov. letters
* 07/07/97  Hume  Add Order.dbf records when adding new deponent.
* 07/01/97  Hume  Auto-insert Expedite (txn 14) when
*                 rush case or rush requested
* 06/30/97  Hume  Change to put in Fax Class and address for Fax server
* 06/17/97  Hsu   Print out aka for all the cases (was for breast imp only)
* 01/01/97  Hume  Initial release
*****************************************************************************

Parameters  BNOTCALL, B1STREQ, TAG2REQ, L_AUTOSUB, L_AUTOCOV, L_COURTSET, C_ISSTYPE, L_NEW4SCR, L_SHWDUP, N_ISSUEOPT

** bNotCall = .T. if called from TheNotic; .F. otherwise
** b1streq = 1 (First request), = 2 (Second Request or Reprint)
** reissue = .T. if tag is being reissued. (No billing for reissued tags)
** tag2req = Tag to be issued or reissued
** l_autosub = Automatic operation (No user intervention)
**             .F. unless program is being called from TheNotic or CovPage
** l_autocov = Automated printing of Cover letter only.
**            .F. unless program is being called from CovPage
** l_courtset = .T. if court notice set is required
** c_Issueopt - set the default prompt in frmreqchoice
*-- If tag2req is non-zero, the calling program has already pre-selected
*-- the tag to be issued (incl. mirrored reissues), and gfGetDep will have
*-- already been called to fill in tag-specific global variables.
*-- If tag2req is 0 and b1streq = 1 (first request for brand-new tag or
*-- reissue of a non-mirrored tag), the calling program has not set
*-- tag-specific global variables via gfGetDep.
*-- In this situation, a new deponent must be added to the Record and GRecord
*-- tables, after which globals must be filled via gfGetDep
*-- If tag2req is 0 and b1streq = 2 (second request), user will
*-- choose a tag from a list of previous issues for the case and the program
*-- will then fill in globals via gfGetDep.
* 06/18/03 DMA All parameter-analysis code moved to start of program
Private C_ALIAS As String, C_TSCODE As String, OMED As Object, L_ORIGPDF As BOOLEAN,NCURAREA
L_ORIGPDF=.F.
Store "" To PCPUBLICBLURB, PC_SPECHAND
If Type ('OMED')<>'O'
	OMED = Createobject("generic.medgeneric")
Endif
C_ALIAS=Alias()
***********************************************************************************
If PL_OFCKOP Or PL_OFCMD Or PL_OFCPGH Or  PL_OFCHOUS
	PL_KOPVER=.T.
Endif
If PL_OFCOAK Or PL_OFCPAS
	PL_CAVER=.T.
Endif
PL_1ST_REQ = (B1STREQ = 1)
*--3/27/03 kdl start: New variable to identify "0" 1st request tags
If Parameters() < 3
*--do nothing, we need the error message to find the calling program path!
Endif
PL_1ST0TAG = ( PL_1ST_REQ And TAG2REQ = 0)
*--3/27/03 kdl end:

If PL_1ST_REQ
	C_ACTION =Iif( C_ISSTYPE="S","7","8")
	C_ACTION =ISISSTYPE( C_ACTION, PN_REQ_BY)
	C_ISSTYPE =Iif(C_ACTION="7","S","A")
	PC_ISSTYPE=C_ISSTYPE

**03/01/2012 - Do not allow issuing a subpoena if nonotice file do have a record ( no notices will be added)
	If PC_ISSTYPE='S'
		If Not IFOKSUBP ()
			L_CANCEL=.T.
			Return
		Endif

	Endif
	If Empty(C_ACTION)
		L_CANCEL=.T.
		If PL_1ST_REQ
			L_NOTISS= UPDTOPREISSUE("1")
			If Not L_NOTISS
				GFMESSAGE("Cannot Cancel. Contact IT dept.")
			Endif
		Endif
		Return
	Endif
Endif

If Type( "l_autocov") = "L"
	If L_AUTOCOV
		L_AUTOSUB = .T.
	Endif
Else
	L_AUTOCOV = .F.
Endif

If Type( "l_autosub") = "U"
	L_AUTOSUB = .F.
Endif

If Not Type( "n_Issueopt") = "N"
	N_ISSUEOPT = 1
Endif

*-- 08/20/2018 MD
If Type( "mvScanDocsOnly")="U"
	Public mvScanDocsOnly
ENDIF
mvScanDocsOnly=""
*--

Public LCAASB, SZEDTREQ, SZEDTFAX, SZREQUEST, SZEDTFAX, S, REPREC, SZTXNDATE, ;
	GCOFFLOC, GL_CANC2FAX, PL_STOPORG, MVSP, MVFAXCOV, MVPRT,  CDEPT

Private DBCIVPOP, LSDECLTEXT, DBHOLD, LD_HDAYS, L_RECSPEC, C_SPECHAND
Private L_GOTTAG, C_MAILID, LCSTATE, LCPRTSTATE, LCROUND;
	LCCRTTYPE, USEDINST, CURFILE, L_VIEWREQ, L_REPRINT, ;
	L_FAX2REQ, L_PRT2REQ, N_REQBUTT, N_PICKREQ, LD_BUSDATE, LN_COUNT, ;
	L_FAX1REQ, L_PRTFAX, L_PRT1REQ, L_GOVT, L_REQSTAT, LSTOPFAX, L_RET, ;
	L_NOTERMD, L_BAYCOLFR, L_SUPPLEM, N_SUPPLEM, N_CURAREA
* 05/14/03 DMA -- Local variables for New Berry & Berry fields
*                 (shared only w/routine CANotInf and its screens)
Private C_BBORDER, C_BBLOC, C_OLDRCA, C_NEWRCA, L_RUSHDEPO

Local LCSQLLINE, LCEXACTMAIL
LOCAL LC_PARSE_DOCNAME AS STRING, LC_DOCNAME AS STRING, LC_DOCNAME2 AS STRING, LI_DOC_SEP AS INT	&& 9/23/2020, ZD #190778, JH.


Store "" To C_BBORDER, C_BBLOC, C_OLDRCA, C_NEWRCA, LCROUND
*--5/23/02 kdl start: Set 2nd prnt queue flag to false
** 05/12/03 DMA Set pl_PostFee to .F.
*--7/09/03 kdl start: new supplem private variable initialzed
N_SUPPLEM = 0
Store .F. To LSTOPFAX, L_GOVT, PL_2NDQUE, L_NOTERMD, PL_POSTFEE, L_SUPPLEM
Store "" To MVSP, MVFAXCOV, MVPRT, L_REQSTAT
*--5/23/02 kdl end:
N_REQBUTT = 1
N_PICKREQ = 1
Store .F. To L_PRT2REQ, L_FAX2REQ, L_VIEWREQ, L_REPRINT, GL_CANC2FAX, L_PRTFAX, L_PRT1REQ, L_FAX1REQ, PL_DUPLTAG
LCCRTTYPE = ""                                  && Court Type for Texas

LC_DOCNAME=""		&& 9/23/2020, ZD #190778, JH.
LC_DOCNAME2=""
GNRPS = 0

LCREQCATEGORY=""
If !Empty(Alltrim(Nvl(GOAPP.REQUESTCATEGORY,"")))
	LCREQCATEGORY="("+Alltrim(Upper(GOAPP.REQUESTCATEGORY))+")"
Endif

Set Safety Off

* 05/21/03 DMA -  Use public logical vbl to determine office/version of RTS
If PL_CAVER
	GN_COVER      = 1
	GN_SUBPOENA   = 2
	GN_CNOTICE    = 3
	GN_POSNOTICE  = 4
	GN_AFFINST    = 5
	GN_AFFIDAVIT  = 6
	GN_POSSUBP    = 7
	GN_AUTHCOVER  = 8

	Do Case
	Case PL_OFCOAK Or PL_OFCPAS
		PL_PSGWC = (PL_OFCPAS And PC_LITCODE == "GWC")
		GCOFFLOC = "C"
		PC_SERVNAM = ""
	Otherwise
		GCOFFLOC = " "
		PL_AUTOFAX = .T.
		If .F.
			HAVEFORM = PC_C1FORM
		Endif
	Endcase
Endif

If Type( "gnHold") = "U"
	Public GNHOLD
Endif
If Type( "gnFrDays") = "U"
	Public GNFRDAYS
Endif
If Type( "gnIssDays") = "U"
	Public GNISSDAYS
Endif
GNHOLD = Iif( PL_NOHOLD, 0, PN_C1HOLD)

GNFRDAYS = PN_LITFDAY
GNISSDAYS = PN_LITIDAY
LLFROMREV = Iif (GNFRDAYS<>0, .T.,.F.)

Private L_PROPSUBP
L_PROPSUBP = .F.

Set Intensity On

&& Open TA_Lib procedure file

CURPROC = Set("proc")
Set Procedure To TA_LIB Additive
LCPDIST = ""                                    && Provider District
LCPDIV = ""                                     && Provider Division
CURFILE = Alias()

If Not L_NEW4SCR
	On Key Label "F3" ;
		GFMESSAGE("Only available from 4,I screen.")
Endif

If PL_1ST_REQ
	If C_ACTION = "7"                              && Subpoena
		L_CANCEL =CHKCAPTIONS()&&checkmissingcaps()

		Local l_cancel2 As boolean
		IF NOT PL_REISSUE	&& 3/13/19 YS Allow the tag to be issued for reissue when all the plaintiff attys are being inhibited #129185
			l_cancel2 =	plnonotice(PC_CLCODE)	&& 1/9/2019 YS Checking for plaintiff attys being inhibited #121772
		ENDIF 

		If (L_CANCEL And PL_1ST_REQ) OR l_cancel2 
			L_NOTISS= UPDTOPREISSUE("2")
			If Not L_NOTISS
				GFMESSAGE("Cannot Cancel. Contact IT dept.")
			Endif
			Return
		Endif
	Else
** Authorization
** If a notice will be printed for this,
** then warn about termdate, plcap, defcap

		If Not NONOTICE( PC_AREA, PC_LITCODE, PC_COURT1, C_ACTION, .F.)
&&IF PC_ISSTYPE='A' AND PC_LITCODE ='ZOL'
			If PC_ISSTYPE='A' And pl_ZOLEFF
				L_CANCEL=.F.
			Else

				L_CANCEL=CHKCAPTIONS() && checkmissingcaps()
			Endif

			If L_CANCEL And PL_1ST_REQ
				L_NOTISS= UPDTOPREISSUE("3")
				If Not L_NOTISS
					GFMESSAGE("Cannot Cancel. Contact IT dept.")
				Endif
				Return
			Endif
		Endif
	Endif
Endif

** Autofax utility uses this program to re-print a request,
** but has already created its own "mv" variable
If Type( "AF_Utility")="U" Or Type('mv')<>"C"
	Public MV
Endif
If Type( "mclass")="U"
	Public MCLASS
Endif
If Type( "mgroup")="U"
	Public MGROUP
Endif

** Autofax utility already has a non-empty "mv" container.
If Type( "AF_Utility") = "U" And Not BNOTCALL And Not PL_PRTNOTC And   Not PL_ORDVERSET &&10/22/12
	MV = ""
Endif

SZEDTREQ = ""
SZEDTFAX = ""

Set Memowidth To 68
Store .F. To      L_CANCEL, BPLTREQ
&& User cancelled the issue, && Check if Plaintiff Attorney is Requesting
Store 0 To NDEPREC, NTAG, REPREC, NWITFEE, ADD_DUE
Store "" To    CREQTYPE, CDEPT, MDEP, MATTYPE, SZATTN, PC_FAXATTN, SZDEPNAME
**02/10/05
If Not PL_FAXSUBP && a subpoena should not not be faxed if the notices were not
	SZFAXNUM = ""
Endif
Clear Gets
GDBLANKDT={  /  /    }
DUPDATE = GDBLANKDT
MCOURT = PC_COURT1
**5/26/2010 - use one function in both issue processes: subp_pa and qcissue
If Not L_AUTOSUB
	MCOURT= CHKCOURT(MCOURT)
Endif
****11/20/14- None    and  Not in Suit  cannot be used for Subp Issues -stope here
If Inlist( Alltrim(Upper(MCOURT)), 'NONE', 'NOT IN SUIT')  And C_ACTION = "7"
	GFMESSAGE("Invalid Court. Cannot be used for a subpoena issue.")
	Return
Endif




**5/26/2010 - use one function in both issue processes: subp_pa and qcissue
MCOURT2 = PC_COURT2
Store "" To SZDRLNAME, SZDRFNAME, SZADD1, SZADD2, SZCITY, SZSTATE, SZZIP, SZPHONE
Store "" To SZTAXID, SZATTN, SZAFFTYPE, SZCONT, SZCOMM1, SZCOMM2, SZFAX, MID
Store "" To SZWORKER, SZREQUEST, MCOUNTY, MGNAME, MCNAME, MCNUM, SZMPERS
HAVEFORM  = .T.                                 && Does a form exist for this court

If PL_OFCHOUS
	If Not TXCOURTVAL()
		GFMESSAGE("Invalid court for the texas case")
		Return
	Endif
	LCCRTTYPE = PC_TXCTTYP
Endif
HAVEFORM = PL_C1FORM
MCOUNTY = PC_C1CNTY

If Not L_AUTOSUB
	If Empty( PC_RQATCOD)
		L_CANCEL= CHKCAPTIONS()
		Return
	Endif
Endif

If Type( "c_Action") = "U"
	C_ACTION = Iif(PC_ISSTYPE="A","8","7")
Endif
C_ACTION = Iif(PL_REISSUE, "9" ,C_ACTION)
***10/15/2008
If Not BNOTCALL
	MGROUP = "1"
	Do Case
	Case C_ACTION == "7"&& Subp!!
		CREQTYPE = "S"
		MCLASS = Iif (Alltrim(GOAPP.USERDEPARTMENT)="RTURUSH", "FRTSRTURSH" , "FIRST")
	Case C_ACTION == "8"&& Autho!!
		CREQTYPE = "A"
		MCLASS = Iif (Alltrim(GOAPP.USERDEPARTMENT)="RTURUSH", "FRSTRTURSH" , "FIRST")
	Case C_ACTION == "9"
		CREQTYPE = C_ISSTYPE
		MCLASS = Iif (Alltrim(GOAPP.USERDEPARTMENT)="RTURUSH", "FRSTRTURSH" , "FIRST")
	Otherwise
		If Not BNOTCALL
			CREQTYPE = Iif( PL_TXABEX, "A", "S")
			MCLASS = "Second"
			MGROUP = "0"
		Endif
	Endcase
Endif

If Not BNOTCALL And   Not PL_ORDVERSET &&10/22/12
	MV = ""
Endif

***10/16/2009  -SKIP THAT STEP FOR COURT'S SETS
If Not Used("pc_depofile") And Not L_COURTSET
	_Screen.MousePointer= 11
	Select Request
	Scatter Memo Memvar
	Wait Window " Getting Records.. wait" Nowait Noclear
	PL_GOTDEPO = .F.

**#51529 - make sure we know an issue type
	Do GFGETDEP With m.CL_CODE, m.TAG
	If !Empty( Nvl(CREQTYPE ,'')) And Empty(Alltrim(PC_ISSTYPE))
		PC_ISSTYPE=Nvl(CREQTYPE ,'A')
	Endif

&&11/21/2017- RE-CHECK NONPROG AS TYPE IN THE RECORD MAYBE BE EMPTY
	If pl_noSform=.F.
		Do  ChkNonProg
	Endif

	_Screen.MousePointer= 0
Endif

If PL_1ST_REQ
	If PL_ZICAM
		PL_ALLDATE = .F.
		_Screen.MousePointer= 11
		Do GFALLDAT With 1
		_Screen.MousePointer= 0
	Endif
&& Process a First Request for a specific tag
***********************************************************************************
	Do FIRSTREQ
***********************************************************************************
Else

	If PL_ZICAM
		PL_ALLDATE = .F.
		PN_TAG =TAG2REQ

		_Screen.MousePointer= 11
		Do GFALLDAT With 2
		_Screen.MousePointer= 0
	Endif
&& Process a second request or reprint for a specific tag
***********************************************************************************
	Do SECREQ With TAG2REQ
***********************************************************************************
Endif

Do RETPROC
Return
***************************************************************************
***************************************************************************
Procedure FIRSTREQ
***************************************************************************
*--5/23/02 kdl start: Set 2nd prnt queue flag to false
PL_2NDQUE = .F.
*--5/23/02 kdl end:
* 08/02/04 DMA Set plaintiff-request flag false until proven otherwise
C_PLTREQ = .F.
**03/20/2009 Add DISTRICT selection to the USDC subpoena issues ****************
** 04/25/12 - START: wcab subp need a scanned imageas "S"  or "B" tag level file found
If (PL_WCABKOP And PC_ISSTYPE="S") And Not WCABIMG(PC_LRSNO,PN_TAG)
	GFMESSAGE( "Please, scan a WCAB SUBPOENA file for a tag or pick another court for a case." )
	L_CANCEL=.T.
	PL_STOPPRTISS=.F.
	L_NOTISS= UPDTOPREISSUE("1")
	If Not L_NOTISS
		GFMESSAGE("Cannot Cancel. Contact IT dept.")
	Endif
	Return

Endif
* 04/25/12 -END: wcab subp need a scanned imageas "S"  or "B" tag level file found


Private LC_DIST As String
LC_DIST=""
**09/17/09 all USDC courts follow the same rule
If Left( Alltrim(PC_COURT1), 4) = "USDC" And C_ISSTYPE="S"
*!*		GFMESSAGE("Please pick a District for an issue." )
*!*		LC_DIST=DISTRICTLIST()
*!*		LC_DIST=IIF(UPPER(ALLTRIM(LC_DIST))="NONE","",LC_DIST)

*!*	ENDIF
*!*	IF NOT EMPTY(ALLTRIM(LC_DIST)) AND TYPE("pc_tagdist")="C"
*!*		PC_TAGDIST= LC_DIST
*!*		IF  USED('record')
*!*			REPLACE DISTRICT WITH LC_DIST IN RECORD
*!*		ENDIF
*!*		IF  USED('Request')
*!*			REPLACE DISTRICT WITH LC_DIST IN REQUEST
*!*		ENDIF
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

**3/20/09 end-usdc**********************************************************

Wait Window "Gathering data. Please wait."  Nowait Noclear
_Screen.MousePointer=11
C_TIMESHEETID=""
Local OTS3 As MEDTIMESHEET Of TIMESHEET
OTS3 = Createobject("medtimesheet")
OTS3.GETITEM(Null)
C_CODE =FIXQUOTE(PC_CLCODE)

OTS3.SQLEXECUTE("Exec [dbo].[GetSpecInsByClCodeTag] '" + C_CODE + "',' " + Str(PN_TAG) + "'", "Spec_ins")
MID = Alltrim(PC_MAILID)
** Main processing loop for initial requests

L_RUSHDEPO = PL_RUSHCAS

*--6/26/02 kdl start: need to initialize this variable for all cases
DRQDUEDATE = D_TODAY + 60

If Not Empty( MID)
** Deponent has been selected!!  Get Special Instructions!!

	PC_DEPTYPE = Upper( Left( MID, 1))
	If Not Inlist( PC_DEPTYPE, "H", "E", "A", "D")
		PC_DEPTYPE = "D"
	Endif

&&Get Texas affidavit type
&&6/21/07 - added Tx_Affidavit area
	If CREQTYPE <> "S" And (PL_OFCHOUS Or ;
			(PL_OFCKOP And PC_LITCODE == "A  " And ;
			INLIST(Upper(Allt(PC_AREA)),"TX_ABEX","TX_AFFIDAVIT") ) )
		CDEPT = PICK_AFF()
	Endif
	If Not L_CANCEL
***SUPPLEMENT-MOVE 2/10/06
*!*			IF PL_OFCHOUS AND CREQTYPE= "A"
*!*	* For a Texas subpoena, get the list of deposition questions that
*!*	* will be used as a part of the request.

*!*				DO SUBP_LIB
*!*				IF EMPTY( PC_TXQUEST)
*!*					RETURN
*!*				ENDIF
*!*			ENDIF

*--4/18/03 kdl start: add first-look confirmation check
*--10/17/03 kdl start: eliminate the first-look confirmation prompt
*-- for all but California and Pasadena offices
		Do Case
		Case Inlist(PC_OFFCODE, "C", "S") And ;
				(PL_CFLOOK Or (PC_OFFCODE = "C" And ;
				PC_RQATCOD = "BEBE  3C" And PC_LITCODE = "A  " And ;
				CREQTYPE = "A"))
		Case PL_CFLOOK
			PL_TFLOOK = .T.
			PC_TFLATTY = PC_FLATTY
		Otherwise
			PL_TFLOOK = .F.
			PC_TFLATTY = ""
		Endcase

** Time to print subpoenas or authos!!
**First issue: .f. parameter below means no stored pdf yet should be anyway
		Do PRINTSUB With .F.
	Endif
Endif
*   add conformation call txn
If Type("l_cancel") ="C"
	L_CANCEL=.F.
Endif
If Not L_CANCEL
	Do ADDCONFRMCALL

**03/28/2016-  Added a record to the tblJobcall for a newly issued tag#36492
	LCSQLLINE=" exec [dbo].[AddJobCallviaTagIssue] '"+ PC_LRSNO + "','" + Str(Record.Tag)  + "','"+  Nvl(Record.mailid_no,'')  + "','" +  Record.id_tblrequests  + "','" +  CREQTYPE + "'"
	OTS3.SQLEXECUTE(LCSQLLINE,"")
**03/28/2016- Added a record to the tblJoball for a newly issued tag


**EF : 8/21/07- Skip a question when issue from a depoent's screen
** 06/28/2010 -UPADTE THE QC/AIP QUEUE FOR THE ISSUED TAGS
	Local N_JOB As Integer
	N_JOB=0
	N_JOB=GETJOBID(PN_LRSNO, PN_TAG)
	If N_JOB<>0
		C_SQL=" exec [dbo].[QC_StatusUpdate] '" + Alltrim(PC_USERID) + "','" + Str(N_JOB) + "', 'NQ'" && "NQ"- OUTSIDE THE QC ISSUE
		OTS3.SQLEXECUTE(C_SQL,"")
	Endif
Endif && not cancel
** 06/28/2010 -Update THE QC/AIP QUEUE FOR THE ISSUED TAGS
If P_DEPLEVELISSUE
	Return
Endif
**EF :  8/21/07- Skip a question when issue from a depoent's screen



If  Not L_NEW4SCR &&  EXECUTE BELOW FOR THE CASE LAVEL ISSUE ONLY
**05/11/2011- ADD CHECK FOR DUPS
	If  PL_DUPLTAG  Or L_CANCEL && called by shwduptag
		LCSQLLINE="update tblRequest set STATUS='T' where CL_CODE ='" + FIXQUOTE(PC_CLCODE) +"' AND TAG ='" + Str(PN_TAG)  +"' AND ACTIVE =1"
		OTS3.SQLEXECUTE(LCSQLLINE)
		=GFMESSAGE("A request has been canceled.")
	Else
		=GFMESSAGE("A request has been issued" + Iif( PL_STOPPRTISS, ", but won't be printed.","." ))
	Endif


	Local O_MESSAGE2  As Object
	C_TYPE= Iif( C_ISSTYPE = "S", "Subpoena", "Authorization")
	LC_MESSAGE = "Do you want to issue another " + C_TYPE+ " request?"
	O_MESSAGE2 = Createobject('rts_message_yes_no',LC_MESSAGE)
	O_MESSAGE2.Show
	L_CONFIRM=Iif(O_MESSAGE2.EXIT_MODE="YES",.T.,.F.)
	O_MESSAGE2.Release
	If  L_CONFIRM
		Do ISSUEREQ With C_ISSTYPE, Alltrim(Master.ID_TBLMASTER), .T.

	Else
		Store "" To CDEPT, MDEP, MATTYPE, SZATTN, SZDEPNAME	 && Hospital Deponent Department!!/Deponent Name/Type of requesting attorney/ && Attention to on CoverLtr!!

** Display Deponent and Special Instructions!!
		NWITFEE = 0
		Store "" To SZDRLNAME, SZDRFNAME, SZADD1, SZADD2, SZCITY
		Store "" To SZSTATE, SZZIP, SZPHONE, SZFAX, MID, SZREQUEST
		Store "" To SZTAXID, SZATTN, SZCONT, SZCOMM1, SZCOMM2, SZWORKER
		DUPDATE = GDBLANKDT
	Endif

Endif
Release OTS3
Return
***************************************************************************
***************************************************************************
Procedure SECREQ
***************************************************************************
Parameters TAG2REQ
PL_1ST0TAG = .F.
PL_2NDQUE = .T.


Store "" To CDEPT, SZATTN, MID, C_TIMESHEETID
&& Allow user to pick the deponent that will receive the request
BSELECT = Iif(BNOTCALL,.T.,.F.)

If Not L_AUTOSUB
	C_TIMESHEETID=SECONDRQ (TAG2REQ)
Else
	L_GOT11=OMED.SQLEXECUTE(" exec dbo.GetTxn11Line '" +FIXQUOTE(PC_CLCODE)+ "' ,'" +Str(TAG2REQ ) + "'","Timesheet")

	If Not L_GOT11 Or Eof()
		Return
	Endif
	C_TIMESHEETID=TIMESHEET.ID_TBLTIMESHEET
Endif

If Not Empty(C_TIMESHEETID)
	Local OTS2 As MEDTIMESHEET Of TIMESHEET
	OTS2 = Createobject("medtimesheet")
	OTS2.GETITEM(C_TIMESHEETID)
	Select TIMESHEET
	C_TSCODE=FIXQUOTE(TIMESHEET.CL_CODE)
	Release OTS2
Endif


** 04/25/12 - START: wcab subp need a scanned imageas "S"  or "B" tag level file found
If (PL_WCABKOP And PC_ISSTYPE="S") And Not WCABIMG(PC_LRSNO,TAG2REQ)
	GFMESSAGE( "Please note that there is no scanned WCAB SUBPOENA file for RT# " + Alltrim(PC_LRSNO) +  " tag#" + Alltrim(Str(TAG2REQ)) + "." )

Endif
* 04/25/12 -END: wcab subp need a scanned imageas "S"  or "B" tag level file found


If BSELECT
	If Empty( mailid_no)
		GFMESSAGE("Deponent's Mail ID is empty!!" + Chr(13) + ;
			"Please check with IT Dept.")
		Return
	Endif


	N_REQBUTT = 1
	N_PICKREQ = 1
	Store .F. To L_PRT2REQ, L_FAX2REQ,  L_REPRINT, L_VIEWREQ
	If Not L_AUTOSUB

		LN_PICK = GOAPP.OPENFORM("Request.frmReq2type", "M")
		If LN_PICK=0 Then
			N_REQBUTT=2
		Endif
		Do Case
		Case LN_PICK=1
			L_PRT2REQ=.T.
		Case LN_PICK=2
			L_FAX2REQ=.T.
		Otherwise
			L_REPRINT=.T.
		Endcase

&& EF 04/25/03 Reminder letter vs a complete request
		If L_FAX2REQ
&&ln_Set=1 - reminder, ln_set=2 -complete set
			LN_SET = GOAPP.OPENFORM("Request.frmNotermd", "M")
			If LN_SET=0 Then
				N_REQBUTT = 2
			Endif
			L_NOTERMD=Iif(LN_SET=1,.T.,.F.)
		Endif

	Else
		L_REPRINT = .T.
	Endif
***EF 02/10/05 "Zicam" lit -start

	If PL_ZICAM
		Do Case
		Case PL_1ST_REQ
			LN_REQ = 1
		Case L_REPRINT
			LN_REQ = 3
		Otherwise
			LN_REQ =2
		Endcase
		PL_ALLDATE = .F.
		Do GFALLDAT With LN_REQ
	Endif
**EF 02/10/05 "Zicam" -end
	If N_REQBUTT = 1
* Need to generate second request or a reprint of 1st request!!
*IF pl_autofax
		MID = Alltrim(TIMESHEET.mailid_no)
		NTAG = TIMESHEET.Tag
		MDEP = Upper(Allt(TIMESHEET.Descript))
* Determine Deponent Type!!
		If Not Isdigit( Left( Allt( MID), 1))
			PC_DEPTYPE = Left( Allt( MID), 1)
		Else
			PC_DEPTYPE = "D"
		Endif
* Determine if pc_deptype was left unassigned -MM 9/7/95
		If Empty( Allt( PC_DEPTYPE))
			PC_DEPTYPE = "D"
		Endif
* Check if hospital!!
		If PC_DEPTYPE = "H"
* Determine the Department!!

			CDEPT=DEPTBYDESC(TIMESHEET.Descript)


		Endif
* Get deponent information!!
		Wait Window "Getting Deponent's information" Nowait Noclear
		_Screen.MousePointer=11

		L_MAIL=OMED.SQLEXECUTE("exec dbo.GetDepInfoByMailIdDept  '" + TIMESHEET.mailid_no +"','" + CDEPT + "' ", "pc_DepoFile")

		=CursorSetProp("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
		_Screen.MousePointer=0
* Get the requested instructions!!
		SZREQUEST = ""
		If Not PL_AUTOFAX

			Select SPEC_INS
			If Reccount()>0
				LLREPREC=.F.
				Locate For ID_TBLTIMESHEET =C_TIMESHEETID

				CREQTYPE = Upper(Allt(SPEC_INS.Type))
				SZREQUEST = SPEC_INS.SPEC_INST
				SZTXNDATE = Ctod(Right(Dtoc(SPEC_INS.TXN_DATE),10))
				PC_CERTTYP = SPEC_INS.CERT_TYPE

				If Not Empty( SPEC_INS.DEPT) And (Alltrim(CDEPT)<>'Z')
					If  (Alltrim(SPEC_INS.DEPT) <> CDEPT)
						LLREPREC= Iif (PC_DEPTYPE='H' And SPEC_INS.Type="S",.T.,LLREPREC)

					Endif
				Endif

			Else
				CREQTYPE = "S"
				SZREQUEST = ""
				PC_CERTTYP=""
			Endif
**12/21/2006- To print sub with notices
			If PL_OFCKOP
				If (L_REPRINT And LLREPREC=.T. )And Not PL_REPNOTC &&reprec = 0
					L_CANCEL = .T.
					Wait Window "Subpoena printing cancelled as a department from a tag's description and in the Spec_ins.dept do not agree. Please fix." Nowait
				Endif
			Endif
			If Not BNOTCALL

				Do Case
				Case L_FAX2REQ                   && Fax a 2nd Request
&&--EF 6/3/02 include CA office into autofax process
* 05/21/03 DMA -  Use public logical vbl to determine office/version of RTS
					MCLASS = Iif (PL_CAVER, "CAFax2Rq", "2ReqFax") &&--EF end
**06/20/2011 - add additional fax2 class- so we don't store the request that were done with pdfs
&&2/5/15 : stop using  followup with pdfs
*!*						MCLASS= IIF(PL_PDFREPRINT AND NOT PL_EDITREQ,MCLASS  + 'fromPdf',MCLASS )

					MGROUP = "0"

				Case L_PRT2REQ                   && Print a 2nd Request
					MCLASS = "Second"
					MGROUP = "1"
					CREQTYPE = GOAPP.OPENFORM("Issued.frmpickisstype", "M",CREQTYPE,CREQTYPE)
					If Not Inlist( CREQTYPE, "S", "A")
						L_CANCEL = .T.
					Endif

					If Inlist( Allt(Upper(GOAPP.USERDEPARTMENT)), "RTU", "ICU", "ASU", "SRU")
						MCLASS =  Iif( Alltrim(GOAPP.USERDEPARTMENT) = "RTURUSH", ;
							"SecRTURUSH", MCLASS + Allt(Upper(GOAPP.USERDEPARTMENT)))
					Endif

				Case L_REPRINT

					If Empty(GOAPP.USERDEPARTMENT) Or Allt(Upper(GOAPP.USERDEPARTMENT))="NONE"
						MCLASS = "Reprint"
					Else
						MCLASS = "Rep" + Allt(Upper(GOAPP.USERDEPARTMENT))
					Endif
					MGROUP = "1"
				Endcase
			Endif
		Endif
&& Autofax sec. requests need the very last Spec_Inst record
		If PL_AUTOFAX
			Select SPEC_INS
			If Reccount()>0

				Locate For ID_TBLTIMESHEET =C_TIMESHEETID
				SZREQUEST = ""
				SZEDTREQ = ""
				SZTXNDATE = Ctod(Right(Dtoc(SPEC_INS.TXN_DATE),10))

				SZREQUEST = SPEC_INS.SPEC_INST
				Set Memowidth To 68
				SZEDTREQ = GFADDCR( SPEC_INS.SPEC_INST)
				PC_CERTTYP = ""
				PC_CERTTYP = SPEC_INS.CERT_TYPE
				CREQTYPE = Upper(Allt(SPEC_INS.Type))
				If Empty(CREQTYPE)
					CREQTYPE = TIMESHEET.Type
				Endif

			Else
&&Spec_Inst record doesn't exist: skip for autofax
				L_CANCEL = .T.
				PL_AUTOFAX = .F.
			Endif
		Endif
*--12/18/06 kdl to print courset docs

		Store 1 To GNX
		Do While Len(Sys(16,GNX)) != 0
			If "COURTSET" $ Upper(Sys(16,GNX))
				L_CANCEL=.F.
				Exit
			Endif
			GNX=GNX+1
		Enddo

		If Not L_CANCEL
&& Print cover letter and subpoena!!
**8/31/2009 reprint an Original PDF  with a new Cover page on top RESOTORE IT LATER
			PL_PDFREPRINT=.F.
			Private L_PDFPARAM As BOOLEAN
			L_PDFPARAM=.F.
&&2/5/15 : stop using  followup with pdfs
*!*				L_PDFPARAM=PL_PDFREPRINT
***********************************************************************************
			Do PRINTSUB With L_PDFPARAM
***********************************************************************************
		Endif
	Endif
Endif


PC_CERTTYP = ""
Return
**************************************************************************************************************************************************************
Procedure RETPROC
CURFILE=Alias()
Clear Program

Release SZDRLNAME, SZDRFNAME, SZADD1, SZADD2, SZCITY
Release SZSTATE, SZZIP, SZPHONE, SZFAX, NWITFEE
Release SZTAXID, SZATTN, SZCONT, SZCOMM1, SZCOMM2, SZAFFTYPE
Release DUPDATE, SZWORKER&&, pl_PrtNotc
Release SZREQUEST, SZEDTREQ, SZEDTFAX, SZTXNDATE, PD_DUEDATE, PD_MAILDTE
Store .F. To PL_TESTRPS, PL_PDFREPRINT, PL_FAKEPDF, PL_2NDQUE, PL_NosForm
Store "" To PC_TXQUEST
If Not Empty( CURFILE)
	Select (CURFILE)
Endif

Set Safety Off
On Key Label "F3"

Return

*****************************************************************************************************************************************************
*****************************************************************************************************************************************************
Procedure PRINTSUB
*****************************************************************************************************************************************************
Parameters L_PDFFILE

**8/31/2009 -l_pdffile=.t. when original pdf exists
Private ISSDATE, LCCURAREA, LNTXNID, LCTYPE, LCSTATUS, LNNOTCNT, LDWORK, ;
	LLHS_SUBP, LNADD, LCSUBTYPE, L_FAXALLOW, D_CHKDATE, D_COMPARE
Public LLNOTICE, PNREQCHECK, PNREQFEE, L_ADDNOT
Private LDHANDSERVE, LLRPRSUBP, LLRPRAFF, LLREQAFF, ;
	LLRPATTCH, LCREQTYPE, DB_NOTICE, LDTXNDATE
Private I, NREC, PRINTED, ONHOLD, LNOTSCAN
Private LDPROPDTE, C_CURPROC, NBDAY
L_ADDNOT=.T.
*//--4/3/08 kirktest
Private L_LSTOPISSUE As BOOLEAN,  N_CHOICE As Integer
*l_lstopissue=IIF( (pl_1st_Req AND ifsupressreq(pc_clcode)),.T.,.F.)
*//--4/3/08 kirktest

** YS 06/06/2018 Creating an object(OMED) if it doesn't exist
If Type ('OMED')<>'O'
	OMED = Createobject("generic.medgeneric")
ENDIF

If Not Type( "n_Issueopt") = "N"
	N_ISSUEOPT = 1
Endif

L_LSTOPISSUE=.F.

**06/11/2012 - Client Memorandum (txn19) project -start
If PL_1ST_REQ And Not PL_QCPROC
	LTXN19=.F.
	PNREQFEE = 0
	N_CHOICE=1
	Local ccl, ntg
	ccl=PC_CLCODE
	ntg=PN_TAG
	LTXN19=ChkTxn19(ccl, ntg)


	N_CHOICE=GOAPP.OPENFORM("qcaipjobs.frmreqchoice","M", LTXN19, LTXN19, N_ISSUEOPT)
	Do Case
	Case N_CHOICE=0 && CANCEL FROM ABOVE SCREEN
		L_CANCEL =.T.
		Return .T.
	Case N_CHOICE=1
		PL_STOPPRTISS=.F.
**normal issue
	Case N_CHOICE=2
**supress
		PL_STOPPRTISS=.T.
		** YS 05/29/18 RPS No Print Job Logging [#88327]
		** YS 06/06/18 Change from OTS3 to OMED #89705
		lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(pc_clcode),1) + "','" + convertToChar(pn_tag,1) + "','";
			+ convertToChar(pc_IssType,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','subp_pa.prg(1)','"+ ALLTRIM(MCLASS) +"'"
		
		OMED.SQLEXECUTE(lcSQLLine,'')
	Otherwise
		L_LSTOPISSUE=Iif(N_CHOICE=3, .T.,.F.)
		PL_STOPPRTISS=L_LSTOPISSUE
		** YS 05/29/18 RPS No Print Job Logging [#88327]
		** YS 06/06/18 Change from OTS3 to OMED #89705
		IF PL_STOPPRTISS
			lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(pc_clcode),1) + "','" + convertToChar(pn_tag,1) + "','";
			+ convertToChar(pc_IssType,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','subp_pa.prg(2)','"+ ALLTRIM(MCLASS) +"'"
			
			OMED.SQLEXECUTE(lcSQLLine,'')
		ENDIF
	Endcase

Endif
**06/11/2012 - Client Memorandum (txn19) project -start


NBDAY=0
LDPROPDTE = D_TODAY

*--9/5/02 kdl start: set default value for l_FaxAllow, added variable to
*--the above private statement
*--11/04/02 fax originals
**2/28/07 -REMOVED l_FaxAllow
L_FAXALLOW=.F.


LDDUEDATE = GDBLANKDT
LNNOTCNT = 0                                    && Count of number of Notices to be sent out.
C_ISSTYPE=CREQTYPE

If Not L_AUTOSUB
	If Not Empty(C_TIMESHEETID)
		C_RETVALUE=GOAPP.OPENFORM("casedeponent.frmRequestDetails", "M", Request.id_tblrequests, ;
			REQUEST.id_tblrequests, C_TIMESHEETID, CREQTYPE, .T., "M", ;
			IIF(L_REPRINT,"Reprint", Iif(PL_1ST_REQ, "First","SecReq")),PL_RUSHCAS)

		If Isnull(C_RETVALUE)
			L_CANCEL=.T.
			Return
		Endif
	Else
**first request
		C_RETVALUE=GOAPP.OPENFORM("casedeponent.frmRequestDetails", "M", Request.id_tblrequests, ;
			REQUEST.id_tblrequests, Null,  C_ISSTYPE, .T., "M", "First", PL_RUSHCAS)

		If Isnull(C_RETVALUE)
			L_CANCEL=.T.
			If PL_1ST_REQ
				L_NOTISS= UPDTOPREISSUE("4")
				If Not L_NOTISS
					GFMESSAGE("Cannot Cancel. Contact IT dept.")
				Endif
			Endif
			Return
		Endif


	Endif
***************2/2/28/07 moved here from the firstrequest module as dept is picked just a seconds ago
	Wait Window "Checking deponent's data. Please wait."  Nowait Noclear


	PL_MAIL = .F.
	Do GFDEPINF With CDEPT
	_Screen.MousePointer=0
*----------------- MD --------------------------------
	Local LNXXX, LCFIELD, LCVALUE
	Store "" To LCFIELD,LCVALUE
	Select Request
	=Afields(LAREQFLDS)
	For LNXXX=1 To Alen(LAREQFLDS,1)
		Do Case
		Case Alltrim(Upper(LAREQFLDS[lnXXX,1]))=="NAME"
			LCFIELD="REQUEST.NAME"
			Exit
		Case Alltrim(Upper(LAREQFLDS[lnXXX,1]))=="DESCRIPT"
			LCFIELD="REQUEST.DESCRIPT"
			Exit
		Endcase

	Next
	If !Empty(Alltrim(LCFIELD))
		LCVALUE=&LCFIELD
	Endif
*----------------------- md ------------------------
	If PC_DEPTYPE == "D"
		C_DRNAME=GFDRFORMAT(LCVALUE)
		MDEP = Iif(Not "DR."$C_DRNAME,"DR. "+Alltrim(C_DRNAME),C_DRNAME)
	Else
		MDEP = Alltrim(LCVALUE)
	Endif

	If PL_1ST_REQ
		If Used("pc_depofile")
**05/23/12 -Check for valid sate for the USDC subpoenas
			If Left( Alltrim(PC_COURT1), 4) = "USDC" And PC_ISSTYPE="S"

				OMED.CLOSEALIAS( "DeponentSt")
				LC_STATE=""
				L_ST=OMED.SQLEXECUTE("SELECT dbo.gfState('" + Alltrim(Nvl(PC_DEPOFILE.STATE,''))+ "')", "DeponentSt")
				LC_STATE=Nvl(DEPONENTST.Exp,'')

				If Empty(Alltrim( LC_STATE)) Or Inlist(Upper(LC_STATE),"NONE")
					GFMESSAGE("Cannot issue the USDC subpoena to a Deponent with an invalid State. Fix data or pick another location and continue.")
					L_CANCEL=.T.
					Return
				Endif
			Endif
		Endif
*!*	**05/23/12 -Check for valid sate for the USDC subpoenas


		L_GOVT = Iif( Inlist( PC_GOVTLOC, "S", "F"), .T., .F.)

**03/12/2013- use the same proc as qc issue  to determine if allowed to fax : "HoldPrint" Project.



****************************************************************
** 05/09/2017 #61228 : ask for a check for KOP issues to CA locations
		Do CaChk15

****************************************************************

		LSTOPFAX =  !NOFAXREQ(Nvl(CDEPT,'Z'), PC_ISSTYPE, Str(PN_TAG) )


		If PL_1ST_REQ
** added on 3/15 to match with the StopFax
			If Not PL_STOPPRTISS  And Not LSTOPFAX  And   Empty(PC_BATCHRQ)
				If Not PL_FAXORIG    ;
						OR ( CDEPT=="R" And Not PL_RFAXORG) ;
						OR (CDEPT=="P" And Not PL_PFAXORG) ;
						OR (CDEPT=="E" And Not PL_EFAXORG) ;
						OR (CDEPT=="B" And Not PL_BFAXORG) And Not LSTOPFAX

					LC_MESSAGE = "This deponent does not accept original issues by fax. Continue to send a fax? "

					If Not GFMESSAGE(LC_MESSAGE,.T.)
						LSTOPFAX=.T.
					Endif

				Endif
			Endif
		Endif


**03/12/2013- use the same proc as qc issue  to determine if allowed to fax

		PL_MAILFAX  =Iif(LSTOPFAX, .F., PL_MAILFAX) && 04/11/2011- lit/area rules overwite the location's rule per Alec

		If Not L_GOVT And Not LSTOPFAX Or PL_MAILFAX

			N_OKBUTT = 1
			N_PICK = 1
** find preferred methods for sending requests
			If CREQTYPE = "S"
				If PC_FAXSUB = "Y" Or PC_EFAXSUB = "Y" Or PC_PFAXSUB = "Y" ;
						OR PC_RFAXSUB = "Y" Or PC_BFAXSUB = "Y"
					L_FAX1REQ = .T.
					Store .F. To L_PRT1REQ, L_PRTFAX
				Endif
				If PC_FAXSUB = "M" Or PC_EFAXSUB = "M" Or PC_PFAXSUB = "M" ;
						OR PC_RFAXSUB = "M" Or PC_BFAXSUB = "M"
					L_PRTFAX = .T.
					Store .F. To L_PRT1REQ, L_FAX1REQ

				Endif
				If  PC_FAXSUB="E" And PC_EFAXSUB="E" And PC_PFAXSUB="E" ;
						AND  PC_RFAXSUB="E" And PC_BFAXSUB="E"
					L_PRT1REQ = .T.
					Store .F. To L_PRTFAX, L_FAX1REQ

				Endif
			Else
				If PC_FAXAUTH = "M" ;
						OR PC_EFAXAUTH = "M" Or PC_PFAXAUTH = "M" ;
						OR PC_RFAXAUTH = "M" Or PC_BFAXAUTH = "M"
					L_PRTFAX = .T.
					Store .F. To L_PRT1REQ, L_FAX1REQ
				Endif
				If PC_FAXAUTH = "Y" ;
						OR PC_EFAXAUTH = "Y" Or PC_PFAXAUTH = "Y" ;
						OR PC_RFAXAUTH = "Y" Or PC_BFAXAUTH = "Y"
					L_FAX1REQ = .T.
					Store .F. To L_PRT1REQ, L_PRTFAX
				Endif
				If PC_FAXAUTH ="E" ;
						AND  PC_EFAXAUTH= "E" And PC_PFAXAUTH="E" ;
						AND  PC_RFAXAUTH="E" And PC_BFAXAUTH="E"

					L_PRT1REQ = .T.
					Store .F. To L_PRTFAX, L_FAX1REQ
				Endif
			Endif
**08/16/2010- PER JULIE: IGNORE DATA PER USER'S DECISION TO FAX AN ORIGINAL REQUEST
			If  Not LSTOPFAX
				L_PRT1REQ =.F.
				L_PRTFAX=.F.
				L_FAX1REQ=.T.

			Endif
**08/16/2010- END
			Do Case
			Case L_PRT1REQ
				N_PICK=1
			Case L_FAX1REQ
				N_PICK=2
			Case L_PRTFAX
				N_PICK=3
			Endcase

			Local l_SubBalt As BOOLEAN
* 04/11/2007 MD modifed to default to print CA first issue
			If PL_1ST_REQ And PL_CAVER
				PL_PRTNOTC = .F.
				N_PICK=1
			Endif

			If ( pc_c1Name = "MD-BaltimoCity" And CREQTYPE="S") &&PL_1ST_REQ
				l_SubBalt=.T.
			Else
				l_SubBalt=.F.
			Endif
&&4/23/15- DO NOT SHOW BELOW SELECTION SCREEN FOR MD/BALT SUBPS
			If PL_1ST_REQ And l_SubBalt
				Store  .F. To PL_PRTNOTC , L_FAXALLOW, L_FAX1REQ,  L_PRTFAX
				N_PICK=1
			Endif


*1/23/08 supress printing
*//--03/11/2011 - Risperdal pccp -do not fax original request
*//--4/3/08 kirktest
			If (Not PL_STOPPRTISS) And (Not L_LSTOPISSUE) And Not PL_RISPCCP And Not l_SubBalt
*IF NOT pl_StopPrtIss
*//--4/3/08 kirktest

				LN_PICK = GOAPP.OPENFORM("Request.frmOrigreq", "M",N_PICK)
				If LN_PICK=0
					N_OKBUTT = 2

				Endif
				Do Case
				Case N_PICK = 1
					L_PRT1REQ = .T.
					L_FAX1REQ=.F.
					L_PRTFAX  =.F.
				Case N_PICK = 2
					L_FAX1REQ = .T.
					L_PRT1REQ=.F.
					L_PRTFAX=.F.
				Case N_PICK = 3
					L_PRTFAX = .T.
					L_PRT1REQ=.F.
					L_FAX1REQ=.F.
				Endcase
				If N_OKBUTT=2
					Return
				Endif

			Endif

			L_FAXALLOW = (PL_1ST_REQ And (L_FAX1REQ Or L_PRTFAX))

		Endif &&& FIRST REQ ONLY
	Endif  &&1/23/08
*****************2/28/07-end
	L_RUSHDEPO = PL_RUSHCAS
	SZREQUEST = SPEC_INS.SPEC_INST

*----------------- MD --------------------------------
	Local LNXXX, LCFIELD, LCVALUE, L_USENETAPP
	Store "" To LCFIELD,LCVALUE
	Select Request
	=Afields(LAREQFLDS)
	For LNXXX=1 To Alen(LAREQFLDS,1)
		Do Case
		Case Alltrim(Upper(LAREQFLDS[lnXXX,1]))=="NAME"
			LCFIELD="REQUEST.NAME"
			Exit
		Case Alltrim(Upper(LAREQFLDS[lnXXX,1]))=="DESCRIPT"
			LCFIELD="REQUEST.DESCRIPT"
			Exit
		Endcase

	Next
	If !Empty(Alltrim(LCFIELD))
		LCVALUE=&LCFIELD
	Endif
*----------------------- md ------------------------
	If PC_DEPTYPE == "D"
		C_DRNAME=GFDRFORMAT( LCVALUE)
		C_DEP = Iif(Not "DR."$C_DRNAME,"DR. "+Alltrim(C_DRNAME),C_DRNAME)
	Else
		C_DEP = Alltrim( LCVALUE)

	Endif


Else
*********************NEED WORK later as a part of the autofax app?
	If L_AUTOCOV
		Do VIEWINST With .T., "I"
	Endif
Endif

SZADD1=Alltrim(PC_DEPOFILE.ADD1)
SZADD2=Alltrim(PC_DEPOFILE.ADD2)
SZCITY=Alltrim(PC_DEPOFILE.CITY)
SZSTATE=Alltrim(PC_DEPOFILE.STATE)
SZZIP=Alltrim(PC_DEPOFILE.ZIP)
SZATTN = Alltrim(PC_DEPOFILE.ATTN)
SZCONT = Alltrim(PC_DEPOFILE.CONTACT)
SZCOMM1 = Alltrim(PC_DEPOFILE.COMMENTS)

LCSUBTYPE = ""                                  && Type of subpoena, as stored in Decl file.
SQUEST = ""
* Initialization of new Berry & Berry fields
C_BBORDER = ""
C_BBLOC = ""
C_OLDRCA = ""
C_NEWRCA = ""

If PL_CAVER
	F_SUBPOENA=Iif(PL_OFCPAS,GOAPP.PSDATAPATH,GOAPP.CADATAPATH)	+ "\Subpoena"
	F_DECL=Iif(PL_OFCPAS,GOAPP.PSDATAPATH,GOAPP.CADATAPATH)	+ "\Decl"
	If Not Used('Subpoena')
**2/28/06 - OPEN FREE FOXPRO TABLES HERE
		Use (F_SUBPOENA) In 0
	Endif
	If Not Used('Decl')
		Use (F_DECL) In 0
	Endif
Endif




If PL_1ST_REQ And Not L_CANCEL And Not L_AUTOSUB
* 06/24/03 DMA Add a KoP-version check to the IF statement
* 06/19/03 EF  Remove the Review check from below If statement
* 10/17/02 DMA If this deponent was added to the case by the Review Team,
*              it may have been entered inaccurately (e.g., a doctor's
*              name rather than the hospital where the doctor works).
*              In this situation, after the user has selected and edited
*              the deponent name, the program requires that this be
*              compared against previous deponents to avoid duplicate
*              requests.
**EF l_new4scr- called for a single tag

**05/11/2011- call the duplicate deponets screen : added ShwDuptag
	If (L_NEW4SCR And PL_KOPVER ) Or L_SHWDUP
		Local LCCLCODE As String, LCDEPN As String
		LCCLCODE=PC_CLCODE
		LCDEPN=Alltrim(MDEP)
		L_CANCEL= SHWDUPTAG (LCCLCODE, LCDEPN, Master.ID_TBLMASTER, Record.id_tblrequests)
	Endif

	If PL_CAVER And Not L_CANCEL

* Initialize screen variables to defaults

* Always false for authorizations; optional for subpoenas
		PL_HANDSRV = .F.

*     Hand-service flag is always false at this point.
*     Always add in the non-hand-serve extra days to start with.

**01/16/2009 RE-CALCULATE SERVICE AND DUE DATE
** Non Hs: [Service date]= [txn11 date] + 10, due date= [Service date] +15
** HandServe: [Service date]= [txn11 date] + 5, due date= [Service date] +15
**01/16/2009
		*-- 03/10/2021 MD #224406 added WCAB 
		*-- LDHANDSERVE =Iif(Left( Alltrim(PC_COURT1), 4) = "USDC", D_TODAY,GETSERVD(D_TODAY, PL_HANDSRV )     )
		LDHANDSERVE =IIF(INLIST(Left( Alltrim(UPPER(PC_COURT1)), 4), "USDC","WCAB"), D_TODAY,GETSERVD(D_TODAY, PL_HANDSRV )     )
		PD_CASRVDT=LDHANDSERVE
		* ------04/04/2018 MD #77675
		*PD_DEPSITN =GFCHKDAT(LDHANDSERVE +15, .F.,.F.)
		*-- 03/10/2021 MD #224406 replace IF statement with Case
		DO CASE 
		CASE Left( Alltrim(PC_COURT1), 4) == "USDC"
			PD_DEPSITN =GFCHKDAT(LDHANDSERVE +20, .F.,.F.)
		CASE Left( Alltrim(PC_COURT1), 4) == "WCAB"
			*-- 03/10/2021 MD #224406 added WCAB 
			oMed.closeAlias("viewCourtDepoDate")			
			oMed.sqlexecute("exec dbo.getCourtDepoDate '"+fixquote(ALLTRIM(pc_clcode))+"'","viewCourtDepoDate")
			SELECT viewCourtDepoDate
			IF RECCOUNT()>0
				GO top
				PD_DEPSITN =GFCHKDAT(LDHANDSERVE +viewCourtDepoDate.addDays, .F.,.F.)
			ELSE
				PD_DEPSITN =GFCHKDAT(LDHANDSERVE +16, .F.,.F.)
			ENDIF 
		    oMed.closeAlias("viewCourtDepoDate")
		OTHERWISE 
*** chg to +30, 2/20/2024, JH	
*			*-- 03/13/2019 MD #126908
*		    *PD_DEPSITN =GFCHKDAT(LDHANDSERVE +15, .F.,.F.)
*		    *-- 04/08/2019 MD ##126908 added check for handserv
*		    IF PL_HANDSRV
*			    PD_DEPSITN =GFCHKDAT(LDHANDSERVE +15, .F.,.F.)
*		    ELSE
*			    PD_DEPSITN =GFCHKDAT(LDHANDSERVE +16, .F.,.F.)
*		    ENDIF 		    
			pd_Depsitn = gfChkDat(D_TODAY+30,.F.,.F.)
*** 2/20

		ENDCASE 
		 
		*----------------------------
*!*	**01/16/2009
*!*			pd_Depsitn = d_today + IIF( pc_Litcode == "A  ", 24, 25)
*!*			pd_Depsitn = gfChkDat( pd_Depsitn, .F., .F.)
		D_COMPARE = PD_DEPSITN
		PL_PRNTNOT = .T.                          && Print notice?
		PL_POSTFEE = .F.                          && Post a witness fee?
		PC_SUBPTYP = "D - Default Subpoena"       && Subpoena format to be used
*                                                  D = Default (Document Rqst.)
*                                                  C = Civil Subpoena
*                                                  P = Personal appearance
*                                                  W = WCAB (Worker's Comp.)
		C_BBORDER = ""                            && Berry & Berry Web order Number
		C_BBLOC = ""                              && Berry & Berry location code
		LCQ_ROUND = "RCD"
		N_QUESTION = 0                            && 1 = OK, 2 = Cancel
		C_CIVADD1 = ""                            && Civil subpoena address line 1
		C_CIVADD2 = ""                            && Civil subpoena address line 2


		L_OK=GOAPP.OPENFORM("case.frmCASubpQu", "M", Master.ID_TBLMASTER, Master.ID_TBLMASTER, CREQTYPE)
		If Not L_OK

			L_CANCEL = .T.

			Do UPDTOPREISSUE With "5"
			GFMESSAGE("A request has been canceled.")

		Else
			LLHS_NOTICE = PL_HANDSRV
			LDDEPDATE = PD_DEPSITN
			LDHANDSERVE=PD_CASRVDT
			LLNOTICEITEM = PL_PRNTNOT
			LCROUND = Iif( (PC_RQATCOD="BEBE  3C") And ;
				(PC_LITCODE == "A  "), LCQ_ROUND, "   ")
		Endif

		PC_SUBPTYP = Left( PC_SUBPTYP, 1)

		If Inlist( PC_SUBPTYP, "P", "C") And Not L_CANCEL
			Select 0

			Select COURT
			Set Order To COURT
			Seek Allt( PC_COURT1)

			C_CIVADD1 = COURT.ADD1

			If Allt( COURT.ADD2) = ""
				C_CIVADD2 = Iif( Not Empty( COURT.ADD3), ;
					ALLT( COURT.ADD3), "") ;
					+ (Upper( Allt( COURT.CITY))) + ", " + ;
					COURT.STATE + "  " + Allt( COURT.ZIP)
			Else
				C_CIVADD2 = Allt( COURT.ADD2) + ;
					IIF( Not Empty( COURT.ADD3), ;
					CHR(13) + Allt( COURT.ADD3), "") ;
					+ (Upper( Allt( COURT.CITY))) + ", " + ;
					COURT.STATE + "  " + Allt( COURT.ZIP)
			Endif

* Get details for civil and personal-appearance subpoenas
			Do Case
			Case PC_SUBPTYP = "C"

				L_OK=GOAPP.OPENFORM("case.frmCACivils", "M", Master.ID_TBLMASTER, Master.ID_TBLMASTER,  C_CIVADD1, C_CIVADD2, PD_DEPSITN)
				If Not L_OK
					L_CANCEL=.T.

					Select Decl
					Delete For CL_CODE =PC_CLCODE And Tag =PN_TAG

					Do UPDTOPREISSUE With "6"
				Endif



			Case PC_SUBPTYP = "P"

				N_PICK=GOAPP.OPENFORM("case.frmdspertyp", "M")
				If N_PICK<>0

					If N_PICK =1

						L_OK=GOAPP.OPENFORM("case.frmcadspers","M", Master.ID_TBLMASTER, Master.ID_TBLMASTER,PD_DEPSITN)

						Select SUBPOENA
						Set Order To CLTAG
						Seek PC_CLCODE +Str(PN_TAG)
						If Found()
							SZATCH = GFADDCR(SUBPOENA.TEXT2)
						Endif
					Else

						L_OK=GOAPP.OPENFORM("case.frmcadsonly","M", Master.ID_TBLMASTER, Master.ID_TBLMASTER)
					Endif
				Endif
				If Not L_OK
					L_CANCEL=.T.
					Do UPDTOPREISSUE With "7"
				Endif
			Endcase

		Endif

		If Not L_CANCEL And Not (L_FAX2REQ Or L_FAX1REQ) And Not PL_STOPPRTISS && 6/12/12 txn19 -client memo is picked


			LC_MESSAGE = "Print this " + Iif( CREQTYPE = "S", "Subpoena", "Authorization") + "?"
			O_MESSAGE = Createobject('rts_message_yes_no',LC_MESSAGE)
			O_MESSAGE.Show
			L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
			O_MESSAGE.Release
			If Not L_CONFIRM

				L_CANCEL = .T.
			Endif
		Endif

	Endif
Endif

Select Master
NSPIN = 0
LLPROVIDER = Iif( CREQTYPE = "S", PL_C1PRVDR, .F.)
If Not L_CANCEL

	If PL_1ST_REQ

		NTAG = PN_TAG && First request

* Special processing for CA-office Civil and WCAB subpoenas
* 05/21/03 DMA -  Use public logical vbl to determine office/version of RTS
		If PL_CAVER
			LCSUBTYPE=PC_SUBPTYP
			If Inlist( PC_SUBPTYP, "C", "W")
				Do Case
				Case PC_SUBPTYP = "C"
				Case PC_SUBPTYP = "W"
				Endcase
			Endif
		Endif


		Wait Window "Adding transactions. Please wait." Nowait Noclear

* 05/21/03 DMA -  Use public logical vbl to determine office/version of RTS
		If PL_CAVER

**8/10/09 added getcaSigner/GetCADeliv
			If Empty( PC_MAILNAM)
				PC_MAILNAM=GETCASIGNER(D_TODAY,PC_OFFCODE)
			Endif


			LNNOTCNT = GFDEFCNT( .T.)


		Else
** 04/02/03 IZ do not print notices for reissues

			If Not PL_REISSUE And Not NONOTICE( PC_AREA, PC_LITCODE, PC_COURT1, C_ACTION, .F.)
				LNNOTCNT = GFDEFCNT( .T.)

			Endif
		Endif

**EF 02/10/05   -start

		If Not PL_REISSUE And PL_1ST_REQ
			LN_HOLDRULZ = HoldRulzA()
			If Not Used('HoldRulz')
*!*					*LN_HOLDRULZ =OMED.SQLEXECUTE("exec DBO.GetHoldRulz", "Holdrulz")
*!*					**#51529 - removed litigation rules for "S" when calculating a hold and comply
*!*
				If !LN_HOLDRULZ
*!*						=CURSORSETPROP("KeyFieldList", "Office, Litigation", "HoldRulz")
*!*						INDEX ON OFFICE+ALLTRIM(LITIGATION) FOR ACTIVE TAG OFFLIT ADDITIVE
*!*						INDEX ON OFFICE+ALLTRIM(LITIGATION) FOR ISSTYPE="A" TAG TYPEA ADDITIVE
*!*						INDEX ON OFFICE+ALLTRIM(LITIGATION) FOR ISSTYPE="S" TAG TYPES ADDITIVE

*!*					ELSE
					GFMESSAGE("No HoldRulz data. See IT.")
					Return

				Endif
			Endif



&&& CHECK IF A SERVDATE  IS  SENDDATE?
*!*					IF pl_Caver AND ldHandServe<>d_today
*!*					**01/16/09 -save a request release date for the CA issues
*!*						ld_HDays =ldHandServe
*!*					ELSE
**03/03/2011 ADD RISPERDAL/PCCP
			If GNHOLD=0 And Not PL_RISPCCP
				LD_HDAYS =D_TODAY
			Else
				LD_HDAYS = GF_HRULE( D_TODAY, CREQTYPE)
			Endif
		Else
			LD_HDAYS =D_TODAY &&reissue
		Endif
**EF 02/10/05   -end

** Check existence of Txn 11 and use Insert instead of Append blank

		OTS = Createobject("medtimesheet")
		If !Used("timesheet")
			OTS.GETITEM(Null)
		Endif
		If !Used("timesheet")
			GFMESSAGE("Can't create txn 11.  The request would not be issued.  Please notify IT Department!")
			Return
		Endif
		Select TIMESHEET
		If Reccount()=0
			Append Blank
		Endif
		Go Top

** 10/10/02 IZ check if it's not Reissue, if it is, then take type from Record

		If C_ACTION = "9"
*--kdl out 3/27/03: use public variable
			LCTYPE = C_ISSTYPE
*--kdl out 3/27/03: lcType = Record.Type
		Else
			LCTYPE = Iif( C_ACTION = "7", "S", "A")
		Endif
** 10/10/02 IZ check Record table instead of parameter
		LCSTATUS = Iif( C_ACTION="9", "R", "")

		Local  L_PTFADD As BOOLEAN
		L_PTFADD =.F.
**12/10/12 -
		If PL_1ST_REQ And (PL_NYCASB=.T. Or PL_NJASB=.T.)
			If '[PTF]' $ MDEP
			Else
				LC_MESSAGE = "NYC/NJ Asbestos Requestor Check. Is this a plaintiff counsel request?"
				O_MESSAGE = Createobject('rts_message_yes_no',LC_MESSAGE)
				O_MESSAGE.Show
				L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
				O_MESSAGE.Release
				If L_CONFIRM
*	mdep = mdep + " [PTF]"
					L_PTFADD =.T.
				Endif
			Endif

		Endif
**12/10/12 -
		Select Request
		Locate For Tag =PN_TAG
**EF- 3/20/07- To fix missing dept in hospitals
		If Found()
			If PC_DEPTYPE='H' Or PL_CAVER
*--  06/18/2007 - MD
				If PC_DEPTYPE == "D"
					MDEP=GFDRFORMAT(Alltrim(Request.Descript))
					MDEP = Iif(Not "DR."$MDEP,"DR. "+Alltrim(MDEP),MDEP)
				Else
					MDEP = Request.Descript
				Endif
				MDEP=Left(FIXQUOTE(Alltrim(MDEP)), 50)  + Iif(L_PTFADD , '[PTF]','')


				Do Case
				Case CDEPT = "C"
					If  Rat('(CATH)',MDEP)=0
						MDEP = MDEP + " (CATH)"
					Endif
				Case CDEPT = "E"
					If  Rat('(ECHO)',MDEP)=0
						MDEP = MDEP + " (ECHO)"
					Endif
				Case CDEPT = "R"
					If  Rat('(RAD)',MDEP)=0
						MDEP = MDEP + " (RAD)"
					Endif
				Case CDEPT = "P"
					If Rat('(PATH)',MDEP)=0
						MDEP = MDEP + " (PATH)"
					Endif
				Case CDEPT = "B"
					If  Rat('(BILL)',MDEP)=0
						MDEP = MDEP + " (BILL)"
					Endif
				Case CDEPT = "M"
					If  Rat('(MED)',MDEP)=0
						MDEP = MDEP + " (MED)"
					Endif
				Endcase
				Replace Descript With MDEP In Request
			Endif &&no dept's in the name
		Endif
**EF-3/20/07- end

		Select TIMESHEET
		LCCURAREA = Alias()

		If PC_CLCODE <>Request.CL_CODE
			PC_CLCODE=Request.CL_CODE
		Endif


&&#60359 TX docs : store questions codes in RQ_QUEST : PC_TXQUEST
&&08/15/2017 : TX Reissue needs original dwq

**10/03/2017: CHECK THE STORED DWQ FIRST
		Local  lc_QUEST As String
		lc_QUEST=""
		If  PL_TXCOURT  And CREQTYPE="S"
*IF PL_REISSUE
			c_quest= GetTxDWQ(PC_CLCODE, Iif(PL_REISSUE And  PN_SUPPTO<>0 , PN_SUPPTO, PN_TAG))
			lc_QUEST=c_quest
			If Empty(lc_QUEST)
				lc_QUEST=Nvl(PC_TXQUEST,'')
			Endif

*!*				ELSE
*!*					lc_QUEST=PC_TXQUEST
*ENDIF
		Endif



		Replace TXN_DATE With Dtoc(D_TODAY), ;
			DESCRIPT With MDEP, ;
			CL_CODE With PC_CLCODE, TXN_CODE With Iif(Not L_LSTOPISSUE,11,19), Tag With PN_TAG, mailid_no With Request.mailid_no, ;
			SOC With PC_USERID, TXN_ID With 0, RQ_AT_CODE With Allt(PC_RQATCOD), REC_OUT With .T., ;
			REC_RUSH With L_RUSHDEPO, DUE_DATE With Dtoc(DRQDUEDATE), Type With LCTYPE, ;
			STATUS With LCSTATUS, Count With LNNOTCNT, ;
			RQ_QUEST With lc_QUEST, ;
			ACTIVE With .T., CREATED With Dtoc(D_TODAY) ;
			CREATEDBY With PC_USERID ,  ;
			id_tblrequests With Request.id_tblrequests ;
			IN TIMESHEET

		OTS.UPDATEDATA()
		C_TIMESHEETID=TIMESHEET.ID_TBLTIMESHEET
		Replace ID_TBLTIMESHEET With C_TIMESHEETID In SPEC_INS

		C_SQL = "Update tblTimesheet set descript ='" + Left(FIXQUOTE(Alltrim(MDEP))+LCREQCATEGORY, 50) + "'" + ;
			" WHERE ID_tbltimesheet='" + C_TIMESHEETID+ "' and txn_code=11 and deleted is null"
		L_RECUPD= OMED.SQLEXECUTE (C_SQL,"")

		Do  DOIFCANCEL With "IfCancel","tblTimesheet",C_TIMESHEETID, "D"


**06/11/2012- ADD TXN 4 FOR EACH TXN19-start
**06/22/2012- Force to store a memo -new "A" type added
		If L_LSTOPISSUE
			L_RET=.T.
			L_RET=MEMOTXN("A",.F.)
			If  Not L_RET
				L_CANCEL=.T.
			Else
				Replace QUAL With "1" In Request

				Do  DOIFCANCEL With "IfCancel","tblTimesheet", TIMESHEET.ID_TBLTIMESHEET, "D"
				Do  DOIFCANCEL With "IfCancel","tblCOMMENT", TIMESHEET.ID_TBLTIMESHEET, "D"
			Endif
		Endif

**06/11/2012- ADD TXN 4 FOR EACH TXN19 		-end


		L_SUPPLEM = .F. &&*check for rezulin, ortho evra supplemental tags


		If L_RUSHDEPO And Not L_LSTOPISSUE

			Do ADD14TXN
* 01/25/2011 - MD moved from the bellow to make sure that the tblRequest is updated when txn14 is added
			Replace EXPEDITE With .T. In Request
			Replace EXPDATE With D_TODAY In Request
		Endif

**07/09/2021 WY 240165 (QUESTION NO LONGER NEEDED USER ALWAYS SELECT NO)
*!*	** add txn 37: 6.29.15 for wcab subpoenas ask a question
*!*			If (PL_WCABKOP And CREQTYPE = "S" ) And PL_1ST_REQ  And  Not PL_REISSUE

*!*				L_CONFIRM=.F.
*!*				LC_MSSG = "Do you want to add Original Subpoena Preparation Fee (txn 37)?"
*!*				O_MSSG = Createobject('rts_message_yes_no',LC_MSSG)
*!*				O_MSSG.Show
*!*				L_CONFIRM=Iif(O_MSSG.EXIT_MODE="YES",.T.,.F.)
*!*				O_MSSG.Release
*!*				PL_FEE37 =L_CONFIRM


*!*			Endif
** add txn 37: 6.29.15
**removed next day 12/7/16- as not needed yet
*!*	**#51529 - added  on 12/6/16 txn 37 to the Non_programmed subps
*!*			IF Pl_Nosform
*!*				PL_FEE37 =.T.
*!*		      ENDIF


**03/13/2013 add txn37 for orig sub requests -part of the 'HOLDPRINT' project
**02/16/2015 do not add txn37 for  PL_REISSUE
		If  PL_1ST_REQ  And Not L_LSTOPISSUE And  (PL_FEE37 And CREQTYPE="S")  And Not PL_REISSUE
			C_STR=""
			LN_FEE=10&& txn37 fee
			C_STR= "Exec dbo.gfAddTxn4 '" + Dtoc(Date())+  " ', '" ;
				+ FIXQUOTE(Alltrim(MDEP)) + "' ,'" + FIXQUOTE(PC_CLCODE )+ "',' " ;
				+ Alltrim(Str(37)) + "','"  + Alltrim(Str(NTAG) )+ "','" ;
				+ Alltrim(PC_MAILID) + "','" +Alltrim(Str(0)) + "','" ;
				+ Alltrim(Str(0)) + "','" +  "" + "','" ;
				+ Alltrim(Str(0)) + "', '"  + "" + "','" ;
				+ CREQTYPE+ "','" ;
				+ Alltrim(PC_USERID) + "','" ;
				+ Request.id_tblrequests + "','',10"
			L_TXN37=OTS.SQLEXECUTE(C_STR,"TXN37")
		Endif
**03/13/2013 add txn37 for orig sub requests

**05/04/2016 add txn 5 per the litigation rules setting #7896-start
		If  PL_1ST_REQ  And Not PL_REISSUE

			OTS.CLOSEALIAS("Littxn5")
			C_STR= " EXEC [dbo].[getLitRulestxn5value] '" + PC_LITCODE+"','" + Alltrim(PC_AREA) + "','" + PC_OFFCODE+ "'"
			OTS.SQLEXECUTE(C_STR,"Littxn5")
			If Used("Littxn5") And !Eof()
				If Nvl(Littxn5.Valuetxn5,0)<>0
					LN_FEE=Nvl(Littxn5.Valuetxn5,0)&& txn5 fee


					Do addtxn5exclorder In qcissue  With 5, NTAG, Left(MDEP,50),PC_MAILID,  LN_FEE, Request.id_tblrequests



				Endif

			Endif


		Endif

**05/04/2016 add txn 5 per the litigation rules setting #7896-end


		_Screen.MousePointer=11
* Create orders for all associated attorneys in the case
		Do SETORDTG With NTAG
		_Screen.MousePointer=0

*** 2/1/17:  Check for a bankrupt/credit hold and stop from issuing if rq atty is set as one #57300
		If !Empty(Nvl(PC_RQATCOD,''))
			If crdhold( PC_RQATCOD, .T.)
				L_CANCEL=.T.
				Return
			Endif
		Endif

*** 2/1/17:  Check for a bankrupt/credit hold and stop from issuing if rq atty is set as one #57300



**2/20/07 - set review status
		If PL_REVIEW
			Replace REVW_STAT With 'U' In Request
		Else
			Replace REVW_STAT With '' In Request
		Endif
**2/20/07********************
		If L_FAX1REQ Or L_PRTFAX
			Select Request
			L_REQSTAT = Request.Status
		Endif
** 10/10/02 IZ added if it's reissue

		If Not PL_1ST0TAG Or  PL_REISSUE
*
** Only need to update Record (already should be on it)
			Select Request

**06/12/12 - TXN19 STAYS 'T' STATUS
			Replace REQ_DATE With Iif(Not L_LSTOPISSUE,D_TODAY,{}), ;
				STATUS With Iif(Not L_LSTOPISSUE,"W","T") ;
				TAG With NTAG,   ;
				mailid_no With MID, ;
				LOGIN_ID With PC_USERID ;
				RESEARCH With .F. ,;
				TYPE With Iif( C_ACTION = "7", "S", ;
				IIF( C_ACTION = "9", C_ISSTYPE, "A")) In Request




			If L_LSTOPISSUE
				Replace INPROGRESS With .T. In Request
			Else
				Replace INPROGRESS With .F. In Request
			Endif
*//--4/3/08 kirktest




*--7/11/03 kdl start: add supplemental tag replacement
			If L_SUPPLEM
				Replace SUPPLEM_TO With N_SUPPLEM In Request
			Endif
*--7/11/03 kdl end:
*--4/18/03 kdl: first-look field replacements
*--8/29/03 add setting of first-look to false (else condifiton) to
*--handle mirrored tags.
			If PL_TFLOOK
				Replace FIRST_LOOK With .T., ;
					FL_ATTY With PC_FLATTY In Request
			Else
				Replace FIRST_LOOK With .F., ;
					FL_ATTY With "" In Request
			Endif

**3/3/2011 added Rispeedal/pccp
			If PL_ZICAM
				Replace FLD_NAME With "OBJDAYS", FLD_TYPE  With "N",  ;
					DATE_FLD With D_TODAY, CHAR_FLD With PC_RQATCOD, ;
					NUM_FLD With PN_OBJDAY In Request
			Endif
**07/11/2013- new release date
&&ef  01/12/09 - UPDATE SENDDATE FOR KOP SUBPOENAS :Hold_Print new spec
			If Not PL_REISSUE And PL_1ST_REQ  And PC_OFFCODE	 	="P"
				If LD_HDAYS <> D_TODAY
					If !PL_RISPCCP  && #45883 - FIX RPS/PCCP SO THEY HAVE 5 BUSNESS DAYS - DO NOT ADD EXTRA
						D_MAILDATE=GFCHKDAT( LD_HDAYS+1, .F., .F.)
					Else
						D_MAILDATE=GFCHKDAT( LD_HDAYS, .F., .F.)
					Endif
				Else
					D_MAILDATE=D_TODAY
				Endif
			Else
				D_MAILDATE=D_TODAY


			Endif
**3/5/14- DO NOT STORE SEND DATE FOR "T' TAGS( TXN19)

			If P_DEPLEVELISSUE And PL_QCPROC &&5/12/14- issued from a deponnet's rolodex
				N_CHOICE=1
			Endif
			If   N_CHOICE<>3 && ALLTRIM(REQUEST.QUAL)<>'1'
				Replace SEND_DATE With D_MAILDATE In Request
			Endif

			Wait Window "Updating Request's data. Please wait" Nowait Noclear
			_Screen.MousePointer=11

			ORECMED=Createobject('medrequest')

**		&& 04/28/2020, ZD #168026, JH
			C_SQL="select web_order from RecordTrak..tblRequest(nolock) where CL_CODE ='" + FIXQUOTE(PC_CLCODE) +"' AND TAG ='" + Str(PN_TAG) +"' AND ACTIVE=1"
			ORECMED.SQLEXECUTE (C_SQL,"ReqUpdated")
			If Used("ReqUpdated") And !Eof()
			   REPLACE WEB_ORDER with ReqUpdated.web_order in Request
			ENDIF
			ORECMED.CloseAlias('ReqUpdate')
**		&& 04/28

			ORECMED.UPDATEDATA()


*****07/05/2016 : #38672 - USE NEW BURNBASE FOR ALL USERS: STOP USING THE tiffauto.exe
**09/15/16- STORE  "SC" FOR A REISSUE TAGS
			If (Type ("pc_tagtype")="C" And !Empty(Alltrim(pc_tagtype))) And PL_REISSUE
				C_SQL=" "
				C_SQL=" Exec dbo.UpdateTagType '" + FIXQUOTE(Request.CL_CODE) + "','" +  Str(Request.Tag) + "','" + 	 Nvl(pc_tagtype,'') + "','" + Alltrim(PC_USERID) + "'"
				ORECMED.SQLEXECUTE (C_SQL,"")
			Endif

			Release ORECMED
			O_MESSAGE = Createobject('rts_message_yes_no',"Create tag documents from case's base documents?")
			O_MESSAGE.Show
			L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
			O_MESSAGE.Release

			If L_CONFIRM

				C_CURDBF=Select()
				Wait Window "Display a selection of the available base documents" Nowait

				O_BASE=Createobject('request.frmselectbasedocs')
				O_BASE.Show
				If Not Empty(C_CURDBF)
					Select (C_CURDBF)
				Endif
				O_BASE.Release
			Endif



**02/03/14- Added extra validation for the Zoloft 	lit issues
*!*			a.       Scanned “A” type document exists for RT-Tag in PCX/PCXARCH – Print requests documents as we do now.
*!*			b.      No Scanned “A” type document exists at issue but base document is selected – allow request to print as normal
*!*			c.       No scanned “A” type document exists and no base selected – Auto suppress the printing of the request and present STC processing screen.  The user should already being doing this but this would be added to prevent a request from being generated without authorization.  ***this is one of the items that got the MRC in trouble so we need to be especially careful.

			If Type ('OMED')<>'O'
				OMED = Createobject("generic.medgeneric")
			Endif
			If pl_Chk4Img And CREQTYPE="A"  &&added zofran to that rule #56641
&&'ZOL' START 2/4/14	: do not allow to issue when there is no image but allow that is user add Client Memo (txn19)
				Local n_Tagn As Integer
&&05/08/14 - for reissue use supplemental tag's docs
				n_Tagn= Iif(PL_REISSUE,PN_SUPPTO,PN_TAG)
* 02/27/2017 - md #58807
				If n_Tagn=0
					n_Tagn=PN_TAG
				Endif
*-----------------------
				**09/12/2018, SL, Zendesk #104106
				*L_CANCEL =Iif (PL_STOPPRTISS , .F.,ValidAuth( PC_LRSNO,n_Tagn,L_CONFIRM))
				L_CANCEL =Iif (PL_STOPPRTISS , .F.,ValidAuth(L_CONFIRM))
			Endif  && END 2/4/14

*--1/28/16: start: check for "A" and "B" images for "A" issues  KOP office Zen#27852

			Local l_stc As BOOLEAN
			Do Case
			Case  PL_STOPPRTISS
				If 	  (pc_c1Name = "MD-BaltimoCity" And CREQTYPE="S") 	&&03/25/2015- do not stc Md-Baltimo city subps issues
					l_stc=.F.
				Else
					l_stc=.T.
				Endif
			Case  LCTYPE ="A" And PL_KOPVER
				lpcx=.T. && assume we have a tag level image to attach
				Local nTag4  As Integer
*nTag4= IIF(PL_REISSUE,PN_SUPPTO,PN_TAG) && for reissue use supplemental tag's docs?
				nTag4= PN_TAG
				lpcx=findimg(nTag4, "A")
				If Not lpcx
					lpcx=findimg(nTag4, "B")
					If Not lpcx
&& offer to add an STC
						l_stc=.T.

					Endif
				Endif
*--1/28/16: end: check for "A" and "B" images for "A" issues  KOP office Zen#27852


			Otherwise
				l_stc=.F.
			Endcase
**03/25/2015- do not stc Md-Baltino city sups issues



			If l_stc  &&CALL STC

				Local c_namefull As String, l_stc As TextBox
				c_namefull=""
				PN_TAG=Request.Tag

				If  Type("master.name_full") <>"C"
					c_namefull=Rtrim(Master.name_first) + ' ' + Rtrim(Master.name_init) + ' ' + Rtrim(Master.name_last)
				Else
					c_namefull= Alltrim(Master.name_full)
				Endif
				l_stc=.F.

				PL_STOPPRTISS =.T. &&02/17/16- STOP PRINTING REQUEST IF NO AUTHO TO ATTACH
				** YS 05/29/18 RPS No Print Job Logging [#88327]
				** YS 06/06/18 Change from OTS3 to OMED #89705
				lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + convertToChar(pc_lrsno,1) + "','" + convertToChar(fixquote(pc_clcode),1) + "','" + convertToChar(pn_tag,1) + "','";
					+ convertToChar(pc_IssType,1) + "','" + convertToChar(fixquote(PC_USERID),1) + "','subp_pa.prg(3)','"+ ALLTRIM(MCLASS) +"'"
				*lcSQLLine=" exec [dbo].[AddTrackStopPrint]   '" + ALLTRIM(pc_lrsno) + "','" + ALLTRIM(pc_clcode) + "','" + ALLTRIM(STR(pn_tag)) + "','";
					+ pc_IssType + "','" + ALLTRIM(PC_USERID) + "','subp_pa.prg(3)','" + MCLASS + "'"
				OMED.SQLEXECUTE(lcSQLLine,'')
				
				l_stc = GOAPP.OPENFORM("STC.frmAddSTC","M","", ;
					MASTER.ID_TBLMASTER,Request.Tag, Request.Descript, 	Request.mailid_no,Request.CL_CODE, c_namefull,.F. ,"frmdeponentoptions")


				If !Nvl(l_stc,.F.)
					L_CANCEL =.T.
					PL_STOPPRTISS=.F.
					GFMESSAGE("Adding of Tag cancelled. A tag requires scanned documents or a status to counsel to be created.")
				Endif

			Endif &&CALL STC

			If Not L_CANCEL

				C_SQL = "Update tblRequest set descript ='" + Left(FIXQUOTE(Alltrim(MDEP))+LCREQCATEGORY, 50) + "' " + ;
					", requestcategory='"+Alltrim(Upper(Nvl(GOAPP.REQUESTCATEGORY,"")))+"'"+;
					" WHERE ID_tblrequests='" + TIMESHEET.id_tblrequests + "'"
				L_RECUPD= OMED.SQLEXECUTE (C_SQL,"")
			Else
**05/18/16- IF CANCELED OUT OF AN ISSUE MAKE SURE TO DELETE THE TXN 30 (IF WAS ADDED) #41462
				If Nvl(l_stc,.F.)
*!*						C_SQL = "Update tblTimesheet set  active=0, deleted='"+DTOC(DATE())+"', " + ;
*!*							"deletedby='IssCanceled_"+ALLTRIM(PC_USERID)+"'"+ ;
*!*							" where  cl_code='"+FIXQUOTE(PC_CLCODE)+"' and tag ='"+STR(PN_TAG)+"' and txn_code =30 and active =1"
&&05/08/17: #62202
					C_SQL = ""
					C_SQL = "Exec dbo.CancelAtIssuewithSTC  '" + FIXQUOTE(PC_CLCODE)+"','" + Str(PN_TAG) + "','" + Alltrim(PC_USERID) + "'"

					L_RECUPD= OMED.SQLEXECUTE (C_SQL,"")
				Endif
**05/18/16- IF CANCELED OUT OF AN ISSUE MAKE SURE TO DELETE THE TXN 30 (IF WAS ADDED) #41462

				If Used ('IFCANCEL')


					Select ifcancel
					Scan For action="D"

						If Alltrim(ifcancel.tblname)='tblTimesheet' Or  Alltrim(ifcancel.tblname)='tblComment'
							C_STR="Update " +  ifcancel.tblname + " set active=0, deleted='"+Dtoc(Date())+"', " + ;
								"deletedby='IssCanceled_"+Alltrim(PC_USERID)+"'"+ ;
								" where ID_TBLtIMESHEET ='" + ifcancel.tblKEY + "' and DELETED IS NULL"

						Endif
						OMED.SQLEXECUTE(C_STR,"")

						Select ifcancel
					Endscan
				Endif

				Do UPDTOPREISSUE With "11"

				Return
			Endif

			_Screen.MousePointer=0
			If Not L_RECUPD
				L_CANCEL=.T.
				Do DELRECORDS With "IfCancel"
				*-- 11/02/2023 MD #336442 move code to SQL with additional validations
*!*					LCSQLLINE="update tblOrder set active=0, deleted='"+CT_TODAY+"', "+;
*!*						"deletedby='CANCELED BY "+Alltrim(GOAPP.CURRENTUSER.NTLOGIN)+"'"+;
*!*						" where cl_code='"+FIXQUOTE(PC_CLCODE)+"' and tag ='"+Str(PN_TAG)+"'"
*!*					OMED.SQLEXECUTE(LCSQLLINE)

*!*					LCSQLLINE="update tblDistbill  set active=0, deleted='"+CT_TODAY+"', "+;
*!*						"deletedby='CANCELED BY "+Alltrim(GOAPP.CURRENTUSER.NTLOGIN)+"'"+;
*!*						" where cl_code='"+FIXQUOTE(PC_CLCODE)+"' and tag ='"+Str(PN_TAG)+"'"
*!*					OMED.SQLEXECUTE(LCSQLLINE)

*!*					LCSQLLINE="update tblordtype set active=0, deleted='"+CT_TODAY+"', "+;
*!*						"deletedby='CANCELED BY "+Alltrim(GOAPP.CURRENTUSER.NTLOGIN)+"'"+;
*!*						" where order_link like '"+FIXQUOTE(PC_CLCODE)+ "*" + Alltrim(Str(PN_TAG)) + "%'"
*!*					OMED.SQLEXECUTE(LCSQLLINE)
			LCSQLLINE="exec dbo.DeleteOrders '"+FIXQUOTE(PC_CLCODE)+"', "+Alltrim(Str(PN_TAG))+", '"+Alltrim(GOAPP.CURRENTUSER.NTLOGIN)+"'"
			OMED.SQLEXECUTE(LCSQLLINE)
			*-- 
			
				If PL_1ST_REQ
					Do UPDTOPREISSUE With "8"
				Endif
				Return
				GFMESSAGE('The Record File has not been updated.')
			Endif

		Endif
&& l_new4scr

		If PL_OFCHOUS And CREQTYPE <> "A"
** The following added by HN to be tested/released later for Texas
			Do Case
			Case Inlist( LCCRTTYPE, "CCL", "DIS")
				Do ADDWFEE With "X", 1.00, .F., "T"
			Case Inlist( LCCRTTYPE, "FED")
				Do ADDWFEE With "Y", 40.00, .T., "T"
			Endcase
		Endif

		If LLPROVIDER
			GOAPP.OPENFORM("issued.frmProvinfo", "M")
			LCPDIST=Request.district
			LCPDIV =Request.DIVISION
		Endif

		LLFROMREV = Request.FROMREV

		If Not PL_OFCHOUS &&3/13/06  added as the texas issues do not need to go to teh kop court file

			DBHOLD = Select()
			Select COURT
			Index On COURT Tag COURT
			LNCOMPLY = Iif( Seek( PC_COURT1), GNHOLD + COMPLY, 10)
			Select (DBHOLD)
		Endif &&3/13/06  added as the texas issues do not need to go to teh kop court file


		If PL_OFCHOUS
&& TEXAS ISSUES

			LDBUSONLY = GFDTSKIP( D_TODAY, Iif( CREQTYPE = "S", 20, 9))
			LDDUEBUS = GFDTSKIP( D_TODAY, 33)
			DDUEDATE =  Iif( CREQTYPE = "S", LDDUEBUS, LDBUSONLY )
		Else
			LNCOMPLY = Iif( PL_PROPPA Or PL_PROPNJ, 0, LNCOMPLY)
			LDBUSONLY = D_TODAY
			If PL_MICHCRT
				LDBUSONLY = MIDUEDAT( D_TODAY + 1)
			Endif

			If CREQTYPE = "A"

				For I = 0 To 13
					LDBUSONLY = LDBUSONLY + 1
					LDBUSONLY = GFCHKDAT( LDBUSONLY, .F., .F.)
				Next
			Endif
			Local L_USEBUSS As BOOLEAN
**#49176 use 18 calendar days for Il-Cook
			*-- 08/17/2021 MD #245094 rmove business days check. !!use calendar days only!!
			*--L_USEBUSS =Iif( PL_PROPPA Or PL_PROPNJ Or PL_MICHCRT Or PL_CAMBASB  , .T.,.F.)
			L_USEBUSS =.F.
			*-- 08/17/2021 
			
			DDUEDATE = Iif(L_USEBUSS , LDBUSONLY, D_TODAY) + ;
				IIF( GNHOLD=0, Iif( PL_MICHCRT, 0, LNCOMPLY), GNHOLD)

			If CREQTYPE = "A" And ( PL_DIETDRG Or PL_MDLHOLD)
				DDUEDATE = D_TODAY + 15
			Endif

			If LLFROMREV And PL_DDRUG2 And CREQTYPE = "A"
				DDUEDATE = D_TODAY + 10
			Endif

**3/3/11 Risperdal/pccp
			If PL_RISPCCP And  CREQTYPE = "A"
				DDUEDATE = LD_HDAYS + 10
				PD_DUEDTE=DDUEDATE
			Endif

			DDUEDATE = GFCHKDAT( DDUEDATE, .F., .F.)
		Endif                                     &&tx

** 04/02/03 IZ remove holding period for Reissues
		If PL_REISSUE
			MDATE = D_TODAY
			DUEDATE = D_TODAY + 10
			DDUEDATE = D_TODAY + 10
		Endif
** end IZ

		If PL_CAVER

			LLHS_SUBP = PL_HANDSRV
			If PC_RQATCOD == "BEBE  3C"
				C_OLDRCA = LCROUND + "." + Allt( PC_PLBBNUM)
				C_NEWRCA = PC_PLBBASB + "." + LCROUND
			Else
				Store "" To C_OLDRCA, C_NEWRCA, C_BBORDER, C_BBLOC
			Endif
			Replace WEB_ORDER With C_BBORDER, ;
				ASB_ROUND With LCROUND, ;
				BB_LOCATOR With C_BBLOC In Request
			If Type ('l_stc')="U"
				l_stc=.F.
			Endif
			If Nvl(l_stc,.F.) =.T. && 07/06/2016 - MARK HOLD FOR CA ISSUES WITH STC  #44025
				Replace HOLD With .T. In Request
			Endif
			PC_BBROUND = LCROUND
			PC_BBWEBNO = C_BBORDER
			PC_BBLOCNO = C_BBLOC

			Select TIMESHEET

			Replace ASB_ROUND With PC_BBROUND
			Replace RCA_NO With C_NEWRCA


			LCROUND = C_NEWRCA
			ORECMED=Createobject('medrequest')

			ORECMED.UPDATEDATA()
			Release ORECMED
**9/08/2009 - EDIT Request Due date
			C_SQL = "Update tblRequest set reqduedate ='" +Dtoc(PD_DEPSITN) +"', descript ='" + Left(FIXQUOTE(Alltrim(MDEP))+LCREQCATEGORY, 50) + "'" + ;
				", requestcategory='"+Alltrim(Upper(Nvl(GOAPP.REQUESTCATEGORY,"")))+"'"+;
				" WHERE ID_tblrequests='" + TIMESHEET.id_tblrequests + "'"
			L_RECUPD= OMED.SQLEXECUTE (C_SQL,"")



			OTS = Createobject("medtimesheet")
			OTS.UPDATEDATA()

			C_SQL = "Update tblTimesheet set descript ='" + Left(FIXQUOTE(Alltrim(MDEP))+LCREQCATEGORY, 50) + "'" + ;
				" WHERE ID_tbltimesheet='" + TIMESHEET.ID_TBLTIMESHEET + "' and txn_code=11 and deleted is null"
			L_RECUPD= OMED.SQLEXECUTE (C_SQL,"")

			If .F.
				If Allt(Upper(GOAPP.USERDEPARTMENT))="AM"
					PL_PRNTNOT = GFYESNO("Print Notice?")
				Endif
			Endif
** 10/10/02 IZ print notices only if it's not reissue; Pasadena - all (was for all CA before)
			If PL_OFCPAS Or Not PL_REISSUE

**8/10/09 added getcaSigner/GetCADeliv
				If Empty( PC_MAILNAM)
					PC_MAILNAM=GETCASIGNER(D_TODAY,PC_OFFCODE)
				Endif
				If Empty( PC_SERVNAM)
					PC_SERVNAM=GETCADELIV(PC_OFFCODE,D_TODAY,PC_CLCODE)
				Endif
**8/10/09
				N_PRINTED = Iif(PL_PRNTNOT,0,1)

				LC_STR=""
				LC_STR="Exec dbo.sp_AddNotice '" ;
					+ PC_CLCODE + "','" ;
					+ Str(NTAG) + "','" ;
					+ Dtoc(D_TODAY) + "','" ;
					+ Dtoc(PD_DEPSITN)+ "','" ;
					+ FIXQUOTE(MDEP) + "','" ;
					+ '' + "','" ;
					+ Iif( PL_PRNTNOT, Allt(PC_RQATCOD), "no print") + "','" ;
					+ PC_LITCODE + "','" ;
					+  Right(Alltrim(GOAPP.CURRENTUSER.OREC.SSN), 4) + "','" ;
					+ Alltrim(MID) + "','" ;
					+ CREQTYPE + "'," ;
					+ Str(N_PRINTED) + " ," ;
					+ Iif(LLHS_SUBP,Str(1),Str(0)) + "," ;
					+ Iif(PL_HANDSRV,Str(1),Str(0)) + ", null, '','', '', '" ;
					+ Alltrim(PC_USERID) + "'," + Str(0) ;
					+ ",'" + Iif( PL_HANDSRV, PC_SERVNAM, PC_MAILNAM) + "'"

				L_NOTICE=OMED.SQLEXECUTE(LC_STR,"")

				If Not L_NOTICE
					GFMESSAGE("No notices have been added. Contact IT. ")
				Else

					Do  DOIFCANCEL With "IfCancel","tblPsNotice","", "D"
				Endif


			Endif
		Else
** Removing the feature for using FROMREView to check for printing or not printing of notices
**  May be re-instituted at a later time.
** IZ 07/15/03 make sure public variable for printing notices is set to FALSE if it's Re-Issue
***01/12/09-HOLDDATE

			If PL_REISSUE
				PL_PRTNOTC = .F.
			Endif

** IZ 07/15/03 go to Notices "thing" if it's Not Reissue
			If Not PL_REISSUE And Not NONOTICE( PC_AREA, PC_LITCODE, PC_COURT1, C_ACTION, .F.)

&&EF 6/7/01 do not print Texas notice with issue , but create a record for further reprint
				If PL_1ST_REQ
					PL_PRTNOTC = Iif( PL_TXABEX Or PL_OFCHOUS Or PL_NJSPEC, .F., .T.)
				Else
					PL_PRTNOTC=.F.
				Endif


				LDWORK = Iif( PL_OFCMD Or (CREQTYPE="A" And PL_OFCKOP And Not PL_CAMBASB) , ;
					GFCHKDAT( D_TODAY + 10, .F., .F.), DDUEDATE)

&&11/8/01 Texas notices

*!*					If PL_OFCHOUS And C_ISSTYPE = "S"

*!*						LC_STR="Exec dbo.sp_AddCrtNotic '" ;
*!*							+ PC_CLCODE + "','" ;
*!*							+ Str(NTAG) + "','" ;
*!*							+ Dtoc(D_TODAY) + "','" ;
*!*							+ Dtoc(LDWORK) + "','" ;
*!*							+ FIXQUOTE(MDEP) + "','" ;
*!*							+ Allt(PC_RQATCOD) + "','" ;
*!*							+ Alltrim(MID) + "','" ;
*!*							+ CREQTYPE + "','" ;
*!*							+ PC_PLCNTY + "','"  ;
*!*							+ Alltrim(PC_USERID) + "'"

*!*						L_CRTNOT=OTS.SQLEXECUTE(LC_STR,"")

*!*						If Not L_CRTNOT
*!*							GFMESSAGE("No Court notices have been added. Contact IT. ")
*!*						Else
*!*							Do  DOIFCANCEL With "IfCancel","tblCrtNotic","", "D"
*!*						Endif



*!*					Endif   && tx OFFICE


**EF 02/10/05 "Zicam"  issues -start



&&EF 10/17/2002  calculated notice due date for MI issues
*--3/15/02 BY KDL start: set due date to today + 14 for  NJ and PA propulsid litigations
**#49176 use 18 calendar days for Il-Cook
				*-- 08/17/2021 MD #245094 rmove business days check. !!use calendar days only!!
				*--L_USEBUSS = Iif(PL_PROPPA Or PL_PROPNJ Or PL_MICHCRT  Or PL_CAMBASB  , .T.,.F.)
				L_USEBUSS =.F.
				*-- 08/17/2021

				If  L_USEBUSS
					Do Case
*!*						CASE PL_ILCOOK
*!*							LN_COUNT=17
&&06/29/2011 added bus days to NJ
*!*						CASE PL_NJSUB
*!*							LN_COUNT=13
					Case PL_CAMBASB
						LN_COUNT=8
					Otherwise
						LN_COUNT=13
					Endcase


					For I = 0 To LN_COUNT
						LDPROPDTE = LDPROPDTE + 1
						LDPROPDTE = GFCHKDAT( LDPROPDTE, .F., .F.)
					Next


					LDWORK =LDPROPDTE
					DDUEDATE=LDPROPDTE
					PD_DUEDATE=LDPROPDTE
				Endif
				If PL_ZICAM
					LDPROPDTE =  GFCHKDAT(D_TODAY+PN_OBJDAY, .F., .F.)
					LDWORK = LDPROPDTE
				Endif

				If PL_RISPCCP
					LDPROPDTE =  GFCHKDAT(D_MAILDATE+10, .F., .F.)
					LDWORK = LDPROPDTE
					PD_DUEDATE=LDPROPDTE

				Endif

				If  PL_NJSUB &&3/11/14- use calendar days insteda of busness per Liz
					LDPROPDTE =  GFCHKDAT(D_MAILDATE+14, .F., .F.)
					LDWORK = LDPROPDTE
					PD_DUEDATE=LDPROPDTE
				Endif

**EF 02/10/05    -end
				LC_STR=""

*3/22/06 - edit for the CA issues
*--3/8/07 kdl: make sure there is something in the spec_ins.
				If Type("pcPublicBlurb")!="C"
					PCPUBLICBLURB=""
				Endif
				C_REQUEST= FIXQUOTE(Iif(Empty(Alltrim(SZREQUEST)),PCPUBLICBLURB,SZREQUEST))

*//--4/3/08 kirktest

**01/11/2011-  ADD CAMBRIA NOTICES FOR ONE TAG ONLY
				If PL_CAMBASB
&&EF -09/24/2010 -Cambria County-Asbstos only need one notice per a case -

					OTS.SQLEXECUTE("exec dbo.GetNoticeCount '" + PC_CLCODE + "'","CambriaNot")

					Select CAMBRIANOT
					If CAMBRIANOT.CNT3>=1  Or MID="AN57535"&& ONLY ONE ISSUE GETS NOTICED AND WE SKIP missing info tags JULIE'S request
						L_ADDNOT=.F.

					Endif
				Else
* add notices for il-wcc 1/11/17 #56121
&&11/16/2012- no notices for il-wcc issues
*L_ADDNOT=IIF( PL_KOPVER AND ALLTRIM(PC_COURT1)='IL-WCC',.F.,.T.)

				Endif





				If Not L_LSTOPISSUE And L_ADDNOT
*//--4/3/08 kirktest



					LC_STR="Exec dbo.sp_AddNotice '" ;
						+ PC_CLCODE + "','" ;
						+ Str(NTAG) + "','" ;
						+ Dtoc(D_TODAY) + "','" ;
						+ Iif((PL_PROPPA Or PL_PROPNJ Or PL_MICHCRT Or PL_NJSUB  Or PL_CAMBASB  ;
						OR PL_ZICAM ), Dtoc(LDPROPDTE), Dtoc(LDWORK)) + "','" ;
						+ FIXQUOTE(MDEP) + "','" ;
						+ C_REQUEST + "','" ;
						+ Allt(PC_RQATCOD) + "','" ;
						+ PC_LITCODE + "','" ;
						+ Iif(Alltrim(GOAPP.CURRENTUSER.OREC.SSN)='','0',Right(Alltrim(GOAPP.CURRENTUSER.OREC.SSN), 4))+ "','" ;
						+ Alltrim(MID) + "','" ;
						+ CREQTYPE + "'," ;
						+ Str(0) + " ," ;
						+ Str(0) + "," ;
						+ Str(0) + ", null, '','', '', '" ;
						+ Alltrim(PC_USERID) + "'," + Iif (PL_OFCHOUS,Str(1),Str(0)) ;
						+ ",'" + Iif( PL_HANDSRV, PC_SERVNAM, PC_MAILNAM) + "'"

					L_NOTICE=OTS.SQLEXECUTE(LC_STR,"")
*//--4/3/08 kirktest
				Else
					L_NOTICE=.T.
				Endif
*//--4/3/08 kirktest

				If Not L_NOTICE
					GFMESSAGE("No notices have been added. Contact IT. ")
				Else
					Do Case
					Case PC_OFFCODE="P"
						C_TABLE="tblPsNotice"
					Case PC_OFFCODE="T"
						C_TABLE="tblTXNotice"
					Endcase
					Do  DOIFCANCEL With "IfCancel",C_TABLE,"", "D"
				Endif

*ENDIF                               && Texas office
			Endif                                  && Not Nonotice AND Not Reissue
		Endif
&& CA version

**EF 2/10/05 start:Insert a record into HoldReq here (move from below)

		If PL_KOPVER And Not L_LSTOPISSUE && 06/12/12 txn19 -skip adding a record for a 'fake' issue
			If Type('ldWork')<>"D"
				LDWORK =LDPROPDTE
			Endif
			If Not PL_REISSUE And PL_1ST_REQ
				If LD_HDAYS <> D_TODAY

					LC_STR=""
					n_prt=0 && DEFAULT IS NOT PRINTED SET
**#51529 - mark nonprog as printed sets as we have the filings (yet) - use stored proc as QC issue


					LC_STR=""
					LC_STR =" exec dbo.InsertHoldReq '"  + FIXQUOTE(Nvl(C_CODE,'') )+ "', '" ;
						+ Str(NTAG)+  "','" +CREQTYPE + "','"  ;
						+ Dtoc(LD_HDAYS)+ "','" + Iif( (PL_PROPPA Or PL_PROPNJ Or PL_MICHCRT Or PL_NJSUB Or PL_ZICAM  Or PL_CAMBASB Or PL_RISPCCP ),  Dtoc(LDPROPDTE ), Dtoc(LDWORK) ) + "','" ;
						+ Alltrim( PC_COURT1 )+ "','" + Nvl(MID,'')+ "','" + Alltrim(PC_USERID)  + "','"  + Dtoc(D_TODAY) + "'"

					L_HOLREC=OTS.SQLEXECUTE(LC_STR,"")




**#51529 - mark

					Do  DOIFCANCEL With "IfCancel","tblHoldReq","", "D"

				Endif && NOT hold REQUEST
			Endif
		Endif


&& Add Special Instructions!!
		L_SPECID=ADDSPEC_INS( C_TIMESHEETID, PC_CLCODE, NTAG, MDEP, CREQTYPE, MID, CDEPT,SZREQUEST)

		If Not L_SPECID
			GFMESSAGE("No record has been added to the tblSpec_ins")

			L_CANCEL=.T.
		Else
			Replace ID_TBLSPEC_INS With EDITSP.ID_TBLSPEC_INS In SPEC_INS
			Do  DOIFCANCEL With "IfCancel","tbltblSpec_ins",EDITSP.ID_TBLSPEC_INS, "D"
		Endif

	Else                                         && pl_1st_Req

&& This is a second request or a reprint of 1st request
&& Update proper Entry database


		Select Request

		If LLPROVIDER
			LCPDIST = district
			LCPDIV  = DIVISION
			If Not "DIVISION" $ Upper( LCPDIV)
				LCPDIV = Allt( LCPDIV) + " Division"
			Endif
		Endif
* 03/22/04 DMA Update Research flag when second request
*              goes out, as research is now complete.
		If Request.RESEARCH

			Wait Window "Updating Request's data. Please wait" Nowait Noclear
			_Screen.MousePointer=11
			Replace RESEARCH With .F. In Request

			ORECMED=Createobject('medrequest')

			ORECMED.UPDATEDATA()
			Release ORECMED
**8/31/07- start: the index needed when kop civil notices print
			=CursorSetProp("KeyFieldList", "ID_tblRequests,Cl_code, Tag", "Request")
			Index On CL_CODE + '*'+Str(Tag) Tag CLTAG Additive
			Set Order To CLTAG
*8/31/07-end

			C_SQL = "Update tblRequest set descript ='" + Left(FIXQUOTE(Alltrim(MDEP))+LCREQCATEGORY,50) +"'"+ ;
				", requestcategory='"+Alltrim(Upper(Nvl(GOAPP.REQUESTCATEGORY,"")))+"'"+;
				" WHERE ID_tblrequests='" + TIMESHEET.id_tblrequests + "'"
			L_RECUPD= OMED.SQLEXECUTE (C_SQL,"")
			_Screen.MousePointer=0
			If Not L_RECUPD

				L_CANCEL=.T.
				GFMESSAGE('The Record File has not been updated.')
			Endif
		Endif
		If (Type('c_tscode')="U")
			C_TSCODE=FIXQUOTE(PC_CLCODE)
		Endif

		L_GOTTAG=OMED.SQLEXECUTE("SELECT dbo.gfIssuDt('" + C_TSCODE + "',' " +  Str(TIMESHEET.Tag ) + "')", "Is11Exist")

		Do Case
		Case L_REPRINT

		Case L_PRT2REQ Or L_FAX2REQ
			Select TIMESHEET

			Scatter To ENTSCAT

***EF : GET TXN 11 FOR A REPRINT

			If !L_GOTTAG Or Empty(Nvl(IS11EXIST.Exp,""))
				GFMESSAGE("Missing 11 transaction for this deponent!" + ;
					CHR(13) + "Please notify IT Dept. of RT # and tag." + ;
					CHR(13) + "Do not try to re-issue request until " + ;
					"repairs are complete.")
			Else

				D_TXN11=Ctod(Left(Dtoc(IS11EXIST.Exp),10))

				Select TIMESHEET
				Set Order To
				Append Blank
				Gather From ENTSCAT
				Replace TXN_CODE With 44, ;
					TXN_DATE With Dtoc(D_TODAY), ;
					ID_TBLTIMESHEET With Null, ;
					CREATEDBY With PC_USERID, ;
					CREATED With Dtoc(D_TODAY)

				Local OTS As MEDTIMESHEET Of TIMESHEET
				OTS = Createobject("medtimesheet")
				OTS.UPDATEDATA()
				Release OTS

				C_TIMESHEETID=TIMESHEET.ID_TBLTIMESHEET

				C_SQL = "Update tblTimesheet set descript ='" + Left(FIXQUOTE(Alltrim(MDEP))+LCREQCATEGORY, 50) + "'" + ;
					" WHERE ID_tbltimesheet='" + C_TIMESHEETID + "' and txn_code=11 and deleted is null"
				L_RECUPD= OMED.SQLEXECUTE (C_SQL,"")

				Do  DOIFCANCEL With "IfCancel","tblTimesheet",C_TIMESHEETID, "D"
			Endif
		Case N_REQBUTT = 2                     && New-style cancel
			Return
		Case L_VIEWREQ                         && New-style view request
			Return
		Endcase



		If Not L_AUTOSUB                         && Allow blurb change on reprint  (HN 12/04/97)

			If Not L_REPRINT
				Select SPEC_INS
				Replace ID_TBLTIMESHEET With C_TIMESHEETID In SPEC_INS
			Endif
			If Not L_REPRINT
				L_SPECID=ADDSPEC_INS( C_TIMESHEETID, PC_CLCODE, NTAG, MDEP, CREQTYPE, MID, CDEPT,SPEC_INS.SPEC_INST)

				If Not L_SPECID
					GFMESSAGE("No record has been added to the tblSpec_ins")
					L_CANCEL=.T.

				Else
					Replace ID_TBLSPEC_INS With EDITSP.ID_TBLSPEC_INS In SPEC_INS
**UPDATE IFCANCEL HERE  for all 1st reqs
					Do  DOIFCANCEL With "IfCancel","tblSpec_Ins",EDITSP.ID_TBLSPEC_INS, "D"

				Endif
			Endif  &&&ONLY ADD a Record to the spec_ins for a new record

			If Type("pcPublicBlurb")!="C"
				PCPUBLICBLURB=""
			Endif
			C_REQUEST= FIXQUOTE(Iif(Empty(Alltrim(SZREQUEST)),PCPUBLICBLURB,SZREQUEST))
			C_STR="Update tblPSnotice SET Spec_Inst ='" + C_REQUEST + ;
				"' Where cl_code = '" +C_TSCODE + "' AND" + ;
				"  Tag = '" + Str(TIMESHEET.Tag) +"'"
			L_PSNOTUPD = OMED.SQLEXECUTE(C_STR,"")
			If Not L_PSNOTUPD
				GFMESSAGE("Special Instruction did not get to the Notices File")
			Endif
			If L_REPRINT

****8/30/06- update spec_inst for reprints -ef start
****5/29/07 - added cert_type to teh below sql update statement
				C_STR= "Update tblSpec_Ins SET EDITEDby='" + Alltrim(PC_USERID) ;
					+ "', EDITED='" +	C_TODAY + "', Spec_inst='" + C_REQUEST  ;
					+ "', CERT_TYPE='" + PC_CERTTYP + "'  Where id_tblSpec_Ins ='" + SPEC_INS.ID_TBLSPEC_INS + "'"


				L_UPDSP = OMED.SQLEXECUTE(C_STR,"")
				If Not L_UPDSP
					GFMESSAGE("Special Instruction File was not updated")
				Endif
			Endif
****8/30/06 ef -end

			Select SPEC_INS
		Endif
	Endif                                        && b1strec

	Wait Clear

*//--4/3/08 kirktest l_lstopissue
	If  L_LSTOPISSUE
		Return
	Endif


	If L_CANCEL

		Do DELRECORDS With "IfCancel"
*!*			If PL_OFCHOUS And CREQTYPE <> "A"
*!*	**DELETE Check's data for TX issues

*!*				LCSQLLINE="update tblcheck  set active=0, deleted='"+CT_TODAY+"', "+;
*!*					"deletedby='CANCELED BY "+Alltrim(GOAPP.CURRENTUSER.NTLOGIN)+"'"+;
*!*					" where cl_code='"+FIXQUOTE(PC_CLCODE)+"' and tag ='"+Str(NTAG)+"'"
*!*				OMED.SQLEXECUTE(LCSQLLINE)
*!*			Endif
		If PL_OFCOAK Or PL_OFCPAS
			Select SUBPOENA
			Delete For CL_CODE =PC_CLCODE And Tag =PN_TAG
			FLUSH											&& 3/28/2023, ZD #308916, JH
			Select Decl
			Delete For CL_CODE =PC_CLCODE And Tag =PN_TAG
			FLUSH											&& 3/28
		Endif

	Endif
&&EF 01/25/2002 print an internal memo for TX office original-issue
&&              subpoenas going to Federal courts


	If  Type('l_SubBalt')="U"
		If ( pc_c1Name = "MD-BaltimoCity" And CREQTYPE="S") &&PL_1ST_REQ
			l_SubBalt=.T.
		Else
			l_SubBalt=.F.
		Endif
	Endif


*!*		If PL_1ST_REQ And LCCRTTYPE = "FED" And PL_OFCHOUS And CREQTYPE = "S"

*!*			Do TXMEMOPG With PC_CLCODE, NTAG
*!*		Endif

	If Not L_AUTOSUB Or Not PL_AUTOFAX
		L_SPECHAND = .F.
		If (Not L_FAX2REQ) And (Not L_FAX1REQ) And Not PL_AUTOFAX And Not PL_NOTICNG  And Not PL_STOPPRTISS &&EF 6/26/02

*******************03/13/2012 ask about a check for all isues-start
&&04/28/17 : ask for check for KOP issues to the CA locations #61228


			If !Nvl(PL_POSTFEE,.F.)

				Local L_WITFEE As BOOLEAN
				Do Case
**05/09/2017 : MOVED TO THE OTHER SECTTION PER 5/4 EMAIL ON #61228
*!*				CASE  PL_KOPVER AND  ALLTRIM(NVL(pc_mailst,''))='CA' AND !PL_POSTFEE
*!*					L_WITFEE=GFMESSAGE("Do you need to send a $15.00 check with this request?",.T.)
*!*					IF L_WITFEE
*!*						PL_POSTFEE=.T.
*!*					ELSE
*!*						PL_POSTFEE=.F.
*!*					ENDIF

				Case  PL_KOPVER And Alltrim(PC_COURT1)='IL-WCC'  And CREQTYPE = "S"&&11/16/12- needs a check for $20.00
					PL_POSTFEE=.T.
				Case PL_OFCOAK
					PL_POSTFEE=.T.
				Otherwise
					L_WITFEE=GFMESSAGE("Do you need to send a check with this request?",.T.)
					If L_WITFEE
						PL_POSTFEE=.T.
					Else
						PL_POSTFEE=.F.
					Endif

				Endcase
			Endif

*******************11/16/2012+ 5/5/15 added more rules per zendesk #4683
			Local L_FORCE As BOOLEAN
**added more rules #57632
			L_FORCE=forcesh(CREQTYPE)

			If   L_FORCE
				L_CONFIRM=.T. && FORCE A CHECK AND SPECHAND FOR ABOVE ISSUES
			Else
*******************03/13/2012 ask about a check for all isues -end
				L_CONFIRM=GFMESSAGE("Do you want to add Special Handling Instructions?",.T.)
			Endif

			PNREQCHECK = 0		&& 6/22/2027, ZD #277478, JH

			If L_CONFIRM
				L_SPECHAND = .T.
**03/13/2012 -add checks
				If  PL_POSTFEE
					L_CANCEL = GOAPP.OPENFORM("timesheet.frmWitFee2", "M",.Null.,.Null.,Request.id_tblrequests)

					If   PL_KOPVER  And  Alltrim(PC_COURT1)='IL-WCC'  And CREQTYPE = "S" And PL_POSTFEE=.T. And  Type("pnReqCheck")="L"
						PL_POSTFEE=.F. && allow cancel  WF per Alec/Liz


					Endif

				Endif


			Else

**05/24/12- force spec handling  for pl_HandDlvr OR pl_MailOrig + l_SubBalt (4/9/15)
				If PL_1ST_REQ And Not PL_CAVER And (PL_HANDDLVR Or pl_MailOrig Or l_SubBalt)


					=HANDORIG (.T.)
					PL_FAXMAIL=.F.
					L_SPECHAND = .T.

				Else
					If "SPC" $ MCLASS
						MCLASS = Strtran( MCLASS, "SPC")
					Endif


				Endif

			Endif
		Endif



*******************************************************************************************************
*--02/08/2019 
		If L_SPECHAND OR (PL_1ST_REQ=.T. and PL_REISSUE=.F. AND ALLTRIM(UPPER(PC_LITCODE)) == "C" AND ALLTRIM(UPPER(PC_AREA)) == ALLTRIM(UPPER("HamiltonMiller")))
			Do SPECHAND
		Endif
*******************************************************************************************************

* 05/21/03 DMA -  Use public logical vbl to determine office/version of RTS
		If PL_CAVER
			L_FAXALLOW = (L_FAX2REQ Or L_FAX1REQ Or L_PRTFAX) And Not PL_AUTOFAX
		Else
			If Not PL_AUTOFAX                      &&EF 06/26/02
				N_FAXCOVER = 1
				If L_FAX2REQ
					ISSDATE=Ctod(Left(Dtoc(D_TXN11),10))
					If CREQTYPE = "S"                && and gnHold<>0  'Subpoenas-hold cases
*---- EF 09/04/02 allow fax all subpoenas if a hold period is over
						LN_HOLDFAX = 0
						LN_HOLDFAX = Iif(PL_WAIVRCVD Or PL_REISSUE, 0, GNHOLD)
						L_FAXALLOW = (D_TODAY >= ISSDATE + LN_HOLDFAX)
					Else

						L_FAXALLOW = .T.
*---EF 09/20/2002 no autofax for Propulsid PA & NJ ;
*till hold period is complete
						If PL_PROPPA Or PL_PROPNJ
							For LN_COUNT = 1 To 14
								LD_BUSDATE = ISSDATE + LN_COUNT
								LD_BUSDATE = GFCHKDAT( LD_BUSDATE, .F., .F.)
							Next
							L_FAXALLOW = Iif( D_TODAY > LD_BUSDATE, .T., .F.)
						Endif
					Endif

*----- no autofax till review period is over
**EF 07/22/05 - remove "G" from the list below
					If Inlist (PC_LITCODE, "E  ", "Q  ") And PL_FROMREV
						L_FAXALLOW = ( D_TODAY >= ISSDATE + 10)

					Endif
&&09/24/02 add "D" conditions
					If PC_LITCODE == "D  "
						L_FAXALLOW = ( D_TODAY >= ISSDATE + 15)
					Endif

				Endif



&&do not fax 1st requst for the IL-cookcounty subpoenas
				If 	PL_ILCOOK And PL_1ST_REQ And CREQTYPE = "S"
					L_FAXALLOW =.F.
				Endif

&&do not fax 1st requst for the IL-cookcounty subpoenas
				If L_FAXALLOW And Not PL_STOPPRTISS
					L_FAXALLOW = .F.

					LC_MESSAGE = "Do you want to print a Fax Cover Sheet?"
					O_MESSAGE = Createobject('rts_message_yes_no',LC_MESSAGE)
					O_MESSAGE.Show
					L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
					O_MESSAGE.Release
					If L_CONFIRM
						L_FAXALLOW=.T.
					Else
						If L_FAX2REQ And !L_FAXALLOW
							Select TIMESHEET
							If TXN_CODE=44

								Delete    && delete txn 44
							Endif
							L_FAXALLOW=.F.
							L_FAX2REQ=.F.
							GL_CANC2FAX=.T.

						Endif
					Endif &&11/18/05
				Endif
			Else                                   &&EF 06/27/02
				L_FAXALLOW = .F.
			Endif                                  && AUTOFAX
		Endif


		If L_FAXALLOW And Not PL_STOPPRTISS
			Do PFAXCOVR
			If GL_CANC2FAX
				L_CANCEL=.T.
				Return
			Endif
		Endif

* Print Cover Letter
		Set Memowidth To 68
* 05/28/03 DMA Use new utility routine
		SZEDTREQ = GFADDCR( SZREQUEST)
* 05/21/03 DMA -  Use public logical vbl to determine office/version of RTS

		If PL_CAVER
			LLREQAFF = .T.                         && Assume that affidavit is required
			LLRPRSUBP = .T.                        && Assume that subpoena must be reprinted
			LLRPRAFF = .T.                         && Assume that affidavit must be reprinted
			LLRPATTCH = .F.                        && Assume no need to reattach affidavit
			LCREQTYPE = ""
*****EF 04/25/03 Print a Reminder Notice instead of a request
			If L_FAX2REQ And L_FAXALLOW And L_NOTERMD
				Do AFAXRMD With PN_LRSNO, PN_TAG, SZREQUEST, MV, ;
					MCLASS, SZFAXNUM, SZATTN
				Return
			Endif
******
			Do Case
			Case Not PL_1ST_REQ
* Since this is NOT a first request, fill in details on the
* documents to be reprinted using the Decl and PSNotice files
* and relevant global variables
				If Not L_FAX2REQ &&AND NOT pl_autofax
&& 7/17/09 remove the question as we want to print always the sub/auth !
					LCREQTYPE="No Type?"
					If Not PL_AUTOFAX
						If C_ISSTYPE = "A"
							LCREQTYPE = "Authorization"
						Else
							LCREQTYPE = "Subpoena"
						Endif

*!*							lc_message = "Reprint &lcReqType?"
*!*							o_message = CREATEOBJECT('rts_message_yes_no',lc_message)
*!*							o_message.SHOW
*!*							l_Confirm=IIF(o_message.exit_mode="YES",.T.,.F.)
*!*							o_message.RELEASE
*!*							llRPRSubp = l_Confirm
						LLRPRSUBP=.T.

					Endif

					Select Decl
					Set Order To CLTAG
					If Seek( PC_CLCODE + Str(NTAG))
						If Decl.C1
							LLREQAFF = .F.
						Endif
					Endif


				Endif &&not pl_Autofax
* 03/11/03 DMA Use new-format B&B RCA Number

**07/25/2011- re-order per Alec
				LCROUND =   PC_BBROUND +"." +PC_PLBBASB
* 03/11/03 DMA End
				DBHOLD = Select()
				Select 0

				L_PSNOTFILE=GETPSNOTIC (PC_CLCODE)
				If Not L_PSNOTFILE
					GFMESSAGE('Cannot open the PsNotice File for the CA cases.')
					Return
				Endif
				DB_NOTICE = Alias()
				Seek PC_CLCODE
				Scan While ( PSNOTICE.CL_CODE = PC_CLCODE)
					If PSNOTICE.Tag = NTAG
						Exit
					Endif
				Endscan
				If Not (PSNOTICE.CL_CODE = PC_CLCODE)
					Seek PC_CLCODE
				Endif
				LLCAASB = PL_BBCASE
				LLHS_SUBP = .T.
				PL_HANDSRV = PSNOTICE.HS_NOTICE

**01/22/09  USE 	getservd
				LDHANDSERVE =Iif(Left( Alltrim(PC_COURT1), 4) = "USDC", Ctod(TXN_DATE),GETSERVD(Ctod(TXN_DATE) , PL_HANDSRV )      )
				PD_CASRVDT=LDHANDSERVE

				PD_DEPSITN = Ctod(Nvl(PSNOTICE.DUE_DATE,''))
				Select (DBHOLD)

			Otherwise
				Select 0

				L_PSNOTFILE=GETPSNOTIC (PC_CLCODE)
				If Not L_PSNOTFILE
					GFMESSAGE('Cannot open the PsNotice File for the CA cases.')
					Return
				Endif
				Scan While ( PSNOTICE.CL_CODE = PC_CLCODE)
					If PSNOTICE.Tag = NTAG
						Exit
					Endif
				Endscan
* Since this is a first request, most information
* has just been specified by the user. However,
* the hand-service date must still be calculated.
*ldHandServe = CTOD(PsNotice.Txn_date) + IIF( pl_HandSrv, ;
IIF( pc_Litcode == "A  ", 4, 5), 10)
*ldHandServe = gfChkDat( ldHandServe, .F., .F.)
				LDHANDSERVE =Iif(Left( Alltrim(PC_COURT1), 4) = "USDC",Ctod(PSNOTICE.TXN_DATE),GETSERVD(Ctod(PSNOTICE.TXN_DATE) , PL_HANDSRV )      )
				PD_CASRVDT=LDHANDSERVE

			Endcase

			If PL_AUTOFAX
				LDTXNDATE = Ctod(TIMESHEET.TXN_DATE)
			Else
				LDTXNDATE = Iif( PL_1ST_REQ, D_TODAY, Ctod(TIMESHEET.TXN_DATE))
			Endif

			PNREQCHECK = 0		&& 6/22/2027, ZD #277478, JH

			If Not L_PDFFILE
**12/06/12- ASK FOR WITFEE ABOVE

				If PL_1ST_REQ And PL_POSTFEE And PNREQFEE=0
					PNREQCHECK = 0
					PNREQFEE = 0.00

&&03/13/12 - issue check for all types of issues
					L_CANCEL = GOAPP.OPENFORM("timesheet.frmWitFee2", "M",.Null.,.Null.,Request.id_tblrequests)
				Endif
				If CREQTYPE = "S"

**12/20/12 - get the corrcet check# for each ca issue
					If Used('Checks')
						Select CHECKS
						Use
					Endif
					OMED.SQLEXECUTE("Exec [dbo].[GetChecksforPDF] 'C','" + FIXQUOTE(TIMESHEET.CL_CODE) + "','" + Str(NTAG) + "'", "Checks")

					If Not Eof()
						PNREQCHECK = CHECK_NO
					Endif



*******************************************************************************************************
					*-- 02/10/2021 MD #224406 added check for WCAB
					IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 
						Do CAAUTCOV With LCROUND, SZEDTREQ, LDTXNDATE, .F.
					else
						Do CACOVLTR With LCROUND, PL_HANDSRV, PNREQCHECK, LDTXNDATE, .F.
					ENDIF 
*******************************************************************************************************
				Else
*******************************************************************************************************
					Do CAAUTCOV With LCROUND, SZEDTREQ, LDTXNDATE, .F.
*******************************************************************************************************
				Endif
			Endif &&&09/02/09
		Else
** Cover letters for KoP, MD, TX

*-- 12/18/02 KDL START: Added conditional statement to block cover
*-- letter for notices

**8/31/09 FOLLOW-UP LETTER +PDF (l_pdffile)
			If Not BNOTCALL And  Not L_PDFFILE
*****EF 04/25/03 Print a Reminder Notice instead of a request
				If L_FAX2REQ And L_FAXALLOW And L_NOTERMD
					Do AFAXRMD With PN_LRSNO, PN_TAG, SZREQUEST, MV, MCLASS, SZFAXNUM, SZATTN
					Return
				Endif

&&&&05/02/2014- PRINT MRC COVER FOR RE-ISSUE TAGS ON THE ORIGINAL ZLOFT'S TAG=START
				pl_MRCLetter=.F.


				If PC_LITCODE ='ZOL' And PL_REISSUE

					Local MV_ZOL  As String, n_mrc As Number
					n_mrc =0
					MV_ZOL =""
&&get supplemental tag's data as the reisue uses it
					nworktag= PN_SUPPTO
					n_mrc= origmrctag(PC_LRSNO,nworktag)
					If n_mrc>0   &&NOT pl_ZOLMDL && only call for MRC tags  + 4/15/14: that are not MDL
						pl_MRCLetter=.T.
						n_rtnum=PN_LRSNO
						MV_ZOL =mrccover (n_rtnum, TIMESHEET.Tag, TIMESHEET.Descript)
						MV=MV+ MV_ZOL
					Endif
				Endif

&&&&05/02/2014- PRINT MRC COVER FOR RE-ISSUE TAGS ON THE ORIGINAL ZLOFT'S TAG=END

				If Type ('ldTxnDate')="U"
					LDTXNDATE = Iif( PL_1ST_REQ, D_TODAY, Ctod(TIMESHEET.TXN_DATE))
				Endif
**********************************************************************************************************************************************************************
				MV=KOPREQCOV2(Iif(Empty(Alltrim(PC_ISSTYPE)),CREQTYPE,PC_ISSTYPE) , L_REPRINT,LDTXNDATE,L_AUTOCOV, CDEPT, NTAG, MDEP,.F.,.F.)
**********************************************************************************************************************************************************************
				If PL_TXCOURT And Alltrim(PC_ISSTYPE)="S"
*08/09/2017 : MOVE IN FRONT OF A SUBP PAGE : -Notice and Deposition by Written Questions **************************************************************
					Do Txnot1 With Iif(PL_REISSUE And  PN_SUPPTO<>0 , PN_SUPPTO, NTAG) , Alltrim(MDEP), Alltrim(MID)

				Endif
			Endif
		Endif
&&covpage
	Else
** Not l_autosub OR Not pl_autofax
* Print Cover Letter for KoP-based offices
		If L_AUTOCOV And PL_KOPVER
*// 3/31/10 by kdl to expand blurb size
			If PC_LITCODE='AV1'
				Set Memowidth To 126
			Else
				Set Memowidth To 68
			Endif
			SZEDTREQ = GFADDCR( SZREQUEST)
			CREQTYPE = Type

*****EF 04/25/03 Print a Reminder Notice instead of a request
			If L_FAX2REQ And L_FAXALLOW And L_NOTERMD
				Do AFAXRMD With PN_LRSNO, PN_TAG, SZREQUEST, MV , MCLASS, SZFAXNUM
				Return
			Endif

**DO CovrLetr
**8/25/09 NEW kopreqcov2.PRG STORES A REQUEST'S DUE DATE.
			If Type ('ldTxnDate')="U"
				LDTXNDATE = Iif( PL_1ST_REQ, D_TODAY, Ctod(TIMESHEET.TXN_DATE))
			Endif



			MV=KOPREQCOV2( Iif(Alltrim(PC_ISSTYPE)="",CREQTYPE,PC_ISSTYPE), L_REPRINT,LDTXNDATE,L_AUTOCOV, CDEPT, NTAG, MDEP, .F.)
			*-- 03/29/2018 md #81998 modified issue process called from deponent options screen
            IF ALLTRIM( NVL(record.scandocs,""))=="1"  
   				LOCAL SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
  				sdClCode=pc_clcode
    			sdTag=pn_TAG
  				SDIssueType=CREQTYPE
    			sdPrintAll=1
    			sdReqDept=ALLTRIM(NVL(cDept,""))
    			sdReqDescript=ALLTRIM(fixquote(NVL(mDep,"")))
    			sdHiTech=ALLTRIM(NVL(record.hitech,"0"))
    			*-- 12/11/2019 #146658 MD added sdReqDept, sdReqDescript, sdHiTech
				DO printScannedDocs WITH SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
			ENDIF 
			If PL_OFCHOUS And CREQTYPE = "S" And Not L_AUTOSUB
				Do PRTENQA With MV, "TXTest", Iif( Empty(MGROUP), "1", MGROUP) , ""
			Endif
		Endif
	Endif                                        && ! l_Autosub
	PRINTED = .F.
	ONHOLD = .F.

	If Type( "timesheet.Txn_date") ="C"
		ISSDATE =Ctod(TIMESHEET.TXN_DATE)
	Else
		ISSDATE=Ctod(Left(Dtoc(TIMESHEET.TXN_DATE),10))
	Endif

	If Not L_PDFFILE
** Print a LOR page
**05/16/2013 -added BabbitLOR-pl_BabLor
**04/24/2013 EF -added lor for A049299P (start&stark  firm)
**06/14/2011 EF added pl_HRobins lor
**01/05/2010 EF-added LOR for A044203P
**12/21/2010 EF-added LOR for all issues where 'A044119P' is a rq atty.
		PL_GARRET= Iif(Nvl(PC_RQATCOD,'')='A044119P' And CREQTYPE="A", .T.,.F.)
		PL_NEBLTT=Iif(Nvl(PC_RQATCOD,'')='A044203P' And CREQTYPE="A", .T.,.F.)
		PL_HROBINS= Iif(Nvl(PC_RQATCOD,'')="A045042P" And CREQTYPE="A", .T.,.F.)
		PL_MCEWEN =Iif(Nvl(PC_RQATCOD,'')="A048214P" And CREQTYPE="A", .T.,.F.)
* *8/4/15- removed per zendesk#13294 PL_STARK=IIF(NVL(PC_RQATCOD,'')="A049299P" AND CREQTYPE="A", .T.,.F.)
		PL_BABLOR =Iif(Nvl(PC_RQATCOD,'')="A049631P" And CREQTYPE="A", .T.,.F.)


*		LC_DOCNAME = PRINTLOR(CREQTYPE)				&& 9/23/2020, ZD #190778, JH.

		LC_PARSE_DOCNAME = PRINTLOR(CREQTYPE)			&& 9/23/2020, ZD #190778, JH.
		LI_DOC_SEP = AT('|',LC_PARSE_DOCNAME)
		IF LI_DOC_SEP > 0
			LC_DOCNAME = SUBSTR(LC_PARSE_DOCNAME,1,LI_DOC_SEP-1)
			LC_DOCNAME2 = SUBSTR(LC_PARSE_DOCNAME,LI_DOC_SEP+1,LEN(LC_PARSE_DOCNAME)-LI_DOC_SEP)
		ELSE
			LC_DOCNAME=LC_PARSE_DOCNAME
			LC_DOCNAME2 = ""
		ENDIF							&& 9/23

**02/12/2014 - added MRC Court Order
**05/12/14- MDL area tags do nto get the court corder doc

		If pl_MRCLetter And PC_LITCODE= 'ZOL'
			If Not  PL_REISSUE
				n_mrc=0  && 7/10/14- check if original mrc tag
				n_mrc= origmrctag(PC_LRSNO,NTAG)
			Endif
			If   pl_ZOLMDL And n_mrc>0
				Do MRCLETTER
			Endif
		Endif


***2/21/08- added SRQ Preservation Letter-start
**11/09/2009 added "FEDERAL", "DELAWARE", "NEWJERSEY" areas to below IF ..statement per Sarah P.
		If PC_LITCODE='SRQ' And Inlist(Alltrim(Upper(PC_AREA)) , "FEDERAL", "DELAWARE", "NEWJERSEY"  )
			Do SRQLETTER  With MDEP, CDEPT, .F.
		Endif
***2/21/08- added SRQ Preservation Letter -end
		If PL_ECLSPCH &&1/4/07 - PRINT NOTICES FOR ECOLI CASES-START
			Do ECLNOTICE With PC_PLATCOD, PN_TAG, (Iif(L_FAX2REQ Or L_FAX1REQ Or L_PRTFAX,.T.,.F.))
		Endif
&&1/4/07 - PRINT NOTICES FOR ECOLI CASES-END

*****06/14/2011 added Court Order for litigations avandia (ava) areas: Kirkendall and Heard Robbins
		If PL_AVACOURTORD
			Do AVACOURTORD
		Endif
&&08/22/11 print bailey /srq rush letter
		If PL_BALSRQ
			Do BALSRQRUSH
		Endif
&&11/09/2012 - court order
		If PL_AVAEWE
			Do AVAMCEWEN
		Endif
**04/24/2013 EF -added lor for A049299P (start&stark  firm)
*8/4/15- removed per zendesk#13294
*!*			IF PL_STARK
*!*				DO STARKLORPAGE
*!*			ENDIF
**09/08/2017: added LOR #68978
		If pl_VLahr And CREQTYPE="A"
			Do VLLor
		Endif
**09/08/2017: added LOR #68978
**11/13/2017 #73000 :  LOR to the Firm Code F000020550 (Hamilton, Miller & Birthisel)
		If pl_Hamilt  And CREQTYPE="A"
			Do HMBLor
		Endif



		If CREQTYPE == "S"
&& NJ-courts cases need scanned subpoenas ;
&& to be printed along WITH requests.
			If PL_SCANSUB
				LNOTSCAN = .F.
				If  Not  L_COURTSET  &&02/12/16
					Do PSCNSUBP
**10/04/2017 #70542 - added a rider  per Christine's H

					Do SUBPATTCH With MV, SZEDTREQ,  Iif(PL_REISSUE And  PN_SUPPTO<>0 , PN_SUPPTO, ntag) , MDEP

					If Not LNOTSCAN
						Do OTHERSUB With Upper(Allt(TIMESHEET.Descript))
					Endif
				Endif    &&02/12/16
			ENDIF
*--------------------------------------------------------------	
* --- 03/30/2020 MD	#165570 remove CERTINST			
*!*				If PL_MICHCRT And PL_KOPVER And  !pl_ExclMI
*!*	&&EF 07/28/2017 - mi-wcab does not need a instruct page #66656
*!*					Do CERTINST
*!*				Endif
*--------------------------------------------------------------	

			If PL_KOPVER And Not PL_TXABEX And Not PL_OFCHOUS
				If Not Empty( PC_CERTTYP)
					If PL_AUTOFAX And Not PL_OFCHOUS
						If Ctod(SPEC_INS.TXN_DATE) >= {10/19/2000} And Not PL_NOTICNG
							Do PRINTCER With TAG2REQ, B1STREQ, ;
								SPEC_INS.ID_TBLSPEC_INS
						Endif
					Else

						If ISSDATE>= {10/19/2000} And Not PL_NOTICNG
							*Do PRINTCER With NTAG, B1STREQ, SPEC_INS.ID_TBLSPEC_INS
							*10/06/2021 WY 245050 (USDC-TX, run normal cert only if we don't have a TX DWQ entered)
							*<245050>
							LOCAL llRunCertification
							llRunCertification = .t.
							IF UPPER(LEFT(pc_Court1,7)) == "USDC-TX" AND LEN(ALLTRIM(GetTxDWQ(pc_clcode, nTag))) > 0
								llRunCertification = .f.
							ENDIF  
							IF llRunCertification
								Do PRINTCER With NTAG, B1STREQ, ;
									SPEC_INS.ID_TBLSPEC_INS
							ENDIF 
							*</245050>
						Endif
					Endif
				Endif
			Endif
			If  l_SubBalt		  &&04/07/15 :  MD new Balt page:
				MV=MV+ PrtMdNot (Date(),TIMESHEET.CL_CODE, TIMESHEET.mailid_no, TIMESHEET.Tag, TIMESHEET.Descript)

			Endif &&  l_SubBalt	4/7/15: do not need kop certs
* This is a subpoena!!

			If Not PL_AUTOFAX Or Not L_COURTSET

				Set Procedure To TA_LIB Additive
				Do SPINOPEN With "Printing Subpoena!"

			Endif
**EF 09/11/03 TX Federal sub needs a HIPAA page
*!*				If PL_OFCHOUS And PC_TXCTTYP = "FED"
*!*					Do PRINTGROUP With MV, "TXHIPAA"
*!*				Endif

**removed page from IL WCC package #56121
**11/16/2012 - Il-WCC paperwork
*!*				IF PL_KOPVER AND ALLTRIM(PC_COURT1)='IL-WCC'   AND NOT BNOTCALL
*!*					DO ILWCPAGE1 WITH  MDEP, CDEPT, ISSDATE
*!*				ENDIF


* 03/08/2018 MD #75726/78152 do not print subpoena for the scanDocs Only
			If Not PL_SCANSUB AND ALLTRIM( NVL(record.scandocs,""))<>"1"                          &&not NJ courts
***********************************************************************************
				Do THESUBP
***********************************************************************************
			ENDIF
*--------------------------------------------------------------	
* --- 03/30/2020 MD	#165570 remove MIProff			
*!*	&&EF 07/28/2017 - mi-wcab does not need a proof page #66656
*!*	&&EF 10/17/02 MI proof of service page : print after a subpoena
*!*				If PL_MICHCRT And !pl_ExclMI
*!*					Do PRINTGROUP With MV, "MIProof"
*!*					Do PRINTFIELD With MV, "DepDate", Dtoc( D_TODAY)

*!*					Do PDEPINFO With MID, Proper( MDEP), .F.
*!*					Do PRINTGROUP With MV, "Case"
*!*					Do PRINTFIELD With MV, "Plaintiff", Allt(PC_PLCAPTN)
*!*					Do PRINTFIELD With MV, "Defendant", Allt(PC_DFCAPTN)
*!*					Do PRINTFIELD With MV, "Docket", PC_DOCKET
*!*				Endif
*--------------------------------------------------------------	
&& 11/12/01 Texas Subpoenas
*!*				IF PL_OFCHOUS AND CREQTYPE = "S"
*!*	* 06/10/04 Routine moved internal; this is its only use
*!*					_SCREEN.MOUSEPOINTER=11
*!*					DO PRNTXDOC

*!*					IF NOT PL_1ST_REQ
*!*						PL_TXAFFID = ( LEFT( TIMESHEET.RQ_QUEST, 1) = "N")
*!*					ENDIF
*!*					IF PL_TXAFFID
*!*	* 06/10/04 DMA Call stand-alone version of affidavit printer
*!*						DO PTXAFFID WITH CDEPT

*!*					ENDIF
*!*					_SCREEN.MOUSEPOINTER=0
*!*				ENDIF
			If ISSDATE + GNHOLD > D_TODAY
				ONHOLD = .T.
			Endif


*--7/02/03 kdl start: add Oakland subpoena tag specific documents
			If PL_OFCOAK And Not PL_SCANSUB
				Do PSPECDOC With 'C' && 4/3/14- Print 'case' level docs with the ca subp issues
				Do PSCNSUBP

			Endif
*--7/02/03 kdl end:
		Else
* Process an authorization request
*******************************************************************************************************
**EF 06/09/08 Tabacco  Trust Lit cases
			If PL_TBTASTK And CREQTYPE = "A"
				Do  TOBACCOPAGES
			Endif
*******************************************************************************************************
*******************************************************************************************************
&&8/7/06- print spec.page for Motley/Lead-RI
			If PL_LEADMOT And PL_KOPVER And Inlist(Upper(Alltrim(PC_AREA)),'LEAD-RI','LEAD-WI')
				Do NOTARYINS
			Endif
*******************************************************************************************************



* If needed, print a record certification document for the request
			If PL_AUTOFAX And Not PL_OFCOAK

				_Screen.MousePointer=11
				Do PRINTCER With TAG2REQ, B1STREQ,	SPEC_INS.ID_TBLSPEC_INS
				_Screen.MousePointer=0

			Else
				If PL_KOPVER And Not PL_TXABEX And Not PL_OFCHOUS
					If Not Empty( PC_CERTTYP)
						If Type( "timesheet.Txn_date") ="C"
							ISSDATE =Ctod(TIMESHEET.TXN_DATE)
						Else
							ISSDATE=Ctod(Left(Dtoc(TIMESHEET.TXN_DATE),10))
						Endif

						If ISSDATE>= {10/19/2000} And Not PL_NOTICNG
							_Screen.MousePointer=11
							Do PRINTCER With NTAG, B1STREQ,	SPEC_INS.ID_TBLSPEC_INS
							_Screen.MousePointer=0
						Endif
					Endif
				Endif
			Endif

** 10/12/09 moved AVA/Plaintiff CourtOrder after cert page per Megan/Sarah
*******************************************************************************************************
			If	PL_AVAPLTF Or PL_AV1FED
				Do GETAVAPLORDER
			Endif
*******************************************************************************************************
**3/23/2010- Ava1 letter'
*******************************************************************************************************
			If PL_AVA1
				Do AV1LETTER  With MDEP, CDEPT
			Endif
*******************************************************************************************************

			If Not PL_AUTOFAX

				Set Procedure To TA_LIB Additive
				Do SPINOPEN With "Printing Authorization"

			Endif
			If CREQTYPE = "A"
				If PL_LITATH2

					Do Case
					Case Upper( Allt( PC_PLDEAL)) == "A"
						Do LFAUTHO2 With "A"
					Case Upper( Allt( PC_PLDEAL)) == "B"
						Do LFAUTHO2 With "B"
					Endcase
				Endif

* For Texas-office and Texas Asbestos cases, generate affidavit pages

*--08/14/02 kdl start: Changed conditions for TX affidavit printing
* to match condition for presenting selection list to the user
**3/20/06 - removed  to frmrequestdetails
**6/21/07 -added Tx_affidavit
				If CREQTYPE <> "S" And (PL_OFCHOUS Or ;
						(PL_OFCKOP And PC_LITCODE == "A  " And ;
						INLIST(Upper( Allt( PC_AREA)) , "TX_ABEX","TX_AFFIDAVIT") ) )

					Select SPEC_INS

					Scatter Memo Memvar
					CDEPT2 = Allt( m.DEPT)
					NREC = Len( CDEPT2)
					I_AFF = 1
					Do While  .T.
						If I_AFF > NREC
							Exit
						Endif
						CDEPT = Substr( CDEPT2, I_AFF, 1)
						Do Case
						Case CDEPT = "E"
							SZAFFTYPE = "ECHOCARDIOGRAM VIDEOS"
							THEINFO = "ECHO"
							SZITEM = "VIDEOS"

						Case CDEPT = "R"
							SZAFFTYPE = "RADIOLOGY RECORDS"
							THEINFO = "RAD"
							SZITEM = "FILMS"

						Case CDEPT = "P"
							SZAFFTYPE = "PATHOLOGY MATERIALS"
							THEINFO = "PATH"
							SZITEM = "SLIDES/BLOCKS"

						Case CDEPT = "B"
							SZAFFTYPE =  "BILLING RECORDS"
							THEINFO = "BILLS"
							SZITEM = "PAGES"

						Case CDEPT = "M"
							SZAFFTYPE = "MEDICAL RECORDS"
							THEINFO = "MED"
							SZITEM = "PAGES"

						Case CDEPT = "S"
							SZAFFTYPE = "BUSINESS RECORDS"
							THEINFO = "S"
							SZITEM = "PAGES"

						Case CDEPT = "G"
							SZAFFTYPE = ""
							THEINFO = "G"
							SZITEM = ""

						Otherwise
							SZAFFTYPE = "RECORDS"
							THEINFO = "NR"
							SZITEM = "PAGES"
						Endcase
						I_AFF = I_AFF + 1

						Do PRINTGROUP With MV, ;
							IIF( CDEPT=="G", "TX_GenAff", "TX_Affid")
						If PL_AUTOFAX

							Select TIMESHEET

						Endif
						Do PRINTFIELD With MV, "Attn", Allt( SZAFFTYPE)
						Do PRINTFIELD With MV, "Items", Allt( SZITEM)
						Do PRINTFIELD With MV, "Tag", Str( TIMESHEET.Tag)


						L_ST=OMED.SQLEXECUTE("SELECT dbo.gfState('" + Iif(Empty(Alltrim(PC_DEPOFILE.STATE)),"TX",Alltrim(PC_DEPOFILE.STATE)) + "')", "DepSt")
						LC_STATE=Iif(L_ST,DEPST.Exp, "")
						LCPRTSTATE = ""

						LCPRTSTATE = Alltrim(Upper( LC_STATE))
						Do PRINTFIELD With MV, "DepState", LCPRTSTATE

&&  court description to an aff. page

						If Not PL_OFCHOUS

							Select COURT
							If Seek(PC_COURT1)
								LCCRTDES = Allt( COURT.Desc)
								LNCNT = At( ",", (Allt(LCCRTDES)), 1)
								If LNCNT <> 0
									IREST = Len( LCCRTDES)
									LCCRTPART1 = Left( ( Allt(LCCRTDES)), LNCNT)
									LCCRTPART2 = Upper( Right( Allt( LCCRTDES), IREST-(LNCNT)))
								Endif

								Do PRINTFIELD With MV, "CourtOf", "" &&ALLT(UPPER(court.County))
								Do PRINTFIELD With MV, "County", ;
									IIF( LNCNT <> 0, Allt( Upper( LCCRTPART1)), LCCRTDES)
								Do PRINTFIELD With MV, "CrtDesc", ;
									IIF( LNCNT <> 0, LCCRTPART2, "")
							Endif
						Else
							Do GFTXCOUR                   && IN gftxcour WITH ALLTRIM( TAMaster.court)
						Endif

&&11/26/01 TX federal courts
						If Not PL_OFCHOUS
							MCOUNTY = Allt( PC_PLCNTY)
							MDESC = Allt( pc_distrct)  + " DISTRICT"
						Endif

						Select TIMESHEET


						Do PRINTGROUP With MV, "Case"
						Do PRINTFIELD With MV, "Plaintiff", Allt(PC_PLCAPTN)
						Do PRINTFIELD With MV, "Defendant", Allt(PC_DFCAPTN)
						Do PRINTFIELD With MV, "Docket", PC_DOCKET

						Do PRINTGROUP With MV, "PlCaption"
* 05/25/04 DMA Use long plaintiff name
						Do PRINTFIELD With MV, "FirstName", PC_PLNAM
						Do PRINTFIELD With MV, "MidInitial", ""
						Do PRINTFIELD With MV, "LastName", ""

						Do PRINTGROUP With MV, "Deponent"
						SDNAME = Allt( Proper( MDEP))
						NCNT2 = At( "(", (Allt(SDNAME)), 1)
						If NCNT2 <> 0
							IREST = Len( SDNAME)
							SDPART1 = Left( Proper( Allt(SDNAME)), NCNT2)
							SDPART2 = Upper( Right( Allt(SDNAME), IREST-(NCNT2)))
							MDEP = Proper( SDPART1) + Proper( SDPART2)
						Endif
						Do PRINTFIELD With MV, "Name", MDEP
						Do PRINTFIELD With MV, "Addr", ;
							PROPER(Alltrim( PC_DEPOFILE.ADD1)) + ' ' + Proper(Alltrim( PC_DEPOFILE.ADD2 ))
						Do PRINTFIELD With MV, "City", Proper(Alltrim(PC_DEPOFILE.CITY))
						Do PRINTFIELD With MV, "State", Alltrim(PC_DEPOFILE.STATE)
						Do PRINTFIELD With MV, "Zip", Alltrim(PC_DEPOFILE.ZIP)
					Enddo                               && affnumb
				Endif



				If PN_LORPOS = 1 And Not Empty( LC_DOCNAME) && print a LOR before auth
					Do PRINTGROUP With MV, LC_DOCNAME
					IF NOT EMPTY(LC_DOCNAME2)			&& 9/23/2020, ZD #190778, JH.
						Do PRINTGROUP With MV, LC_DOCNAME2
					ENDIF
				Endif


				Do PSCNAUTH                            && print Authos


				If ISSDATE + Iif( LLFROMREV, GNFRDAYS, GNISSDAYS) > D_TODAY
					ONHOLD = .T.
				Endif


			Endif
		Endif


**08/31/2009
	Endif
**08/31/2009
	If PL_CAVER

		LFORMEXT = .F.
		If Used( "SUBPOENA")
			Select SUBPOENA
			Use
		Endif
		Select 0
		Use (F_SUBPOENA) Again Order CLTAG
		DBSUBP = Alias()
		LLDEFAULT = .T.
		If Seek( PC_CLCODE + Str(NTAG))
			LLDEFAULT = .F.
			LLNOTICE = SUBPOENA.NOTICES
			LFORMEXT = SUBPOENA.EXTRA
			Scatter Memo Memvar
		Endif


		D_TXN11 = GFCHKDAT( FORIGISS(NTAG), .F., .F.)
**08/31/2009
		If Not L_PDFFILE
**08/31/2009
			Do Case

			Case Left( Alltrim(PC_COURT1), 4) = "USDC"

**03/27/2012 - since the usdc  set has now a copy of a pliantiff's notice we do not need to sent a proof and servive list (per Liz)
**10/24/2017 - added pos back #70800
				Do CAUSPoS In Subp_CA With d_txn11

				If Inlist( SPEC_INS.DEPT, "P", "R") And PL_OFCOAK
					Do CABRKDWN With SPEC_INS.DEPT, NTAG, MDEP, MID
				Endif				
				*---- 04/10/2018 MD #78152, #83678 print scanned affidavits instead of programmed ones
				*--- Do CA_AFFID With .F.
				IF findcerts(.F.,NTAG)=.F.	   			
					Do CA_AFFID With .F.
				ENDIF 
			
				If CREQTYPE = "S"
					Do CAUSDCP2 With D_TXN11
				Endif

			Otherwise
*EF   Print Notice to Consumer if autho too.
				If CREQTYPE = "S"
					If LLRPRSUBP
						If LFORMEXT Or LLDEFAULT      && pc_SubpTyp="D"   for default & civil Duces Tecum= .T.
							*--- 12/18/2020 MD #213290
							*--- If Not PL_PLISRQ           && Request from plaintiff's att						
							Do CACONNTC In SUBP_CA With D_TXN11, ;
								PL_HANDSRV, PD_DEPSITN, MDEP, MID
							Do CACONPOS In SUBP_CA ;
								WITH D_TXN11, PL_HANDSRV, PD_DEPSITN							 
							*--  Endif *--- 12/18/2020 MD #213290
						Endif

						If Not LLNOTICE And Not LFORMEXT && True for Notices and false for not notices

**8/3/09 split POS into two pages
**8/31/09 - only BB Gets new pages
							If Not PL_BBASB
								Do CAPOSNOT In SUBP_CA  With NTAG, PL_HANDSRV, .F., .F., D_TXN11
							Else

								Do CAPOSPAGE With NTAG, PL_HANDSRV, .F., .F., D_TXN11, "P"
								Do CAPOSPAGE With NTAG, PL_HANDSRV, .F., .F., D_TXN11, "D"

							Endif
						Else
							If LLNOTICE And Not LFORMEXT Or Not LLDEFAULT &&pc_SubpTyp$"DP"
**8/3/09
**8/31/2009 only BB get two new pages
								If Not PL_BBASB
									Do CAPOSNOT In SUBP_CA 	With NTAG, PL_HANDSRV, .F., .F., D_TXN11
								Else

									Do CAPOSPAGE With NTAG, PL_HANDSRV, .F., .F., D_TXN11, "P"
									Do CAPOSPAGE With NTAG, PL_HANDSRV, .F., .F., D_TXN11, "D"

								Endif
							Else
								If Not LLNOTICE And Not LFORMEXT
**8/3/09
&&8/31/09 only BB  gets new pages
									If Not PL_BBASB

										Do CAPOSNOT In SUBP_CA 	With NTAG, PL_HANDSRV, .F., .F., D_TXN11
									Else
										Do CAPOSPAGE With NTAG, PL_HANDSRV, .F., .F., D_TXN11, "P"
										Do CAPOSPAGE With NTAG, PL_HANDSRV, .F., .F., D_TXN11, "D"

									Endif &&8/31/09
								Endif
							Endif
						Endif
					Endif
				Endif                               &&dep.pers

* Personal appearance subpoenas do not need affidavit at all
				If PL_1ST_REQ
					If Inlist( PC_SUBPTYP, "D", "W") And LLRPRAFF
						If Inlist( SPEC_INS.DEPT, "P", "R") And PL_OFCOAK &&04/14/03 EF
							Do CABRKDWN With SPEC_INS.DEPT, NTAG, MDEP, MID
						Endif						
						*---- 04/10/2018 MD #78152, #83678 print scanned affidavits instead of programmed ones
						*--- Do CA_AFFID With .T.
						IF findcerts(.F.,NTAG)=.F.	   			
							Do CA_AFFID With .T.
						ENDIF 
					Endif
				Else
					Select 0
					Use ( F_SUBPOENA) Again Order CLTAG
					DBSUBP = Alias()
					If Inlist( SPEC_INS.DEPT, "P", "R") And PL_OFCOAK &&EF 04/14/03
						Do CABRKDWN With SPEC_INS.DEPT, NTAG, MDEP, MID
					Endif

					Seek( PC_CLCODE + Str( NTAG))
					If Not Found() And LLRPRAFF						
						*---- 04/10/2018 MD #78152, #83678 print scanned affidavits instead of programmed ones
						*--- Do CA_AFFID With .F.
						IF findcerts(.F.,NTAG)=.F.	   			
							Do CA_AFFID With .F.
						ENDIF 
						
&& reprint attachment- removed on 8/17/09 per Alec/Liz
*!*						IF llRPAttch
*!*							DO ReAttch WITH ntag, mdep, mid
*!*						ENDIF
					Endif
				Endif
**EF 08/30/05 - re-print affidavit

				If LLRPRAFF  Or PL_1ST_REQ
					If PC_SUBPTYP = "C" And LFORMEXT						
						*---- 04/10/2018 MD #78152, #83678 print scanned affidavits instead of programmed ones
						*--- Do CA_AFFID With .F.
						IF findcerts(.F.,NTAG)=.F.	   			
							Do CA_AFFID With .F.
						ENDIF 
					Endif
				Endif

				If CREQTYPE = "S" And LCSUBTYPE <> "W"
&&EF 06/12/02 DO NOT AUTOFAX LAST PAGE OF non-WCAB SUBPOENA
					If Not L_FAX2REQ
						If Not PL_AUTOFAX             &&EF 06/26/02
							If LLRPRSUBP
								Do CAPOSSUB
							Endif
						Endif
					Endif                            && AUTOFAX SKIPS THIS PAGE
				Else
					If CREQTYPE = "S" And LCSUBTYPE = "W"
						IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 
						*-- 02/10/2021 MD #224406 added CA WCAB 
							*	GFMESSAGE("No WCAB supoenas" )
							DO SubWCAB IN Subp_CA WITH "1", szEdtReq, pd_Depsitn, ntag, convertToDate(timesheet.Txn_date)	&& 03/29/2021 #232338 MD changed CTOD to convertToDate 						
						ENDIF 
					Endif
				Endif
			ENDCASE
			IF LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK AND creqType = "S"
				*-- 03/18/2021 MD #224406 second page
				DO SubWCAB IN Subp_CA WITH "2", szEdtReq, pd_Depsitn, ntag, convertToDate(timesheet.Txn_date)&& 03/29/2021 #232338 MD changed CTOD to convertToDate 	
			ENDIF 
		Endif

**08/31/2009 CA
	Endif

**08/31/2009 CA


	If PL_PROPNJ Or PL_PROPPA Or PL_ZICAM  Or PL_RISPCCP
		ONHOLD = Iif( PL_1ST_REQ, .T., .F.)
	Endif

	If PL_SCANSUB And Not PL_AUTOFAX
		C_FAX = Strtran( SZFAXNUM, " ", "")
		C_TEMP = Strtran( C_FAX, "-", "")
		C_TEMP2 = Strtran( C_TEMP, "(", "")
		SZFAXNUM = Strtran( C_TEMP2, ")", "")
&&04/09/13- skip printing of scanned subp with civ order as they be pribted togetehr fron civverifivcation.prg

		If Not PL_ORDVERSET
			*-- 03/29/2018 md #81998 modified issue process called from deponent options screen
            IF ALLTRIM( NVL(record.scandocs,""))=="1"  
   				LOCAL SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
  				sdClCode=pc_clcode
    			sdTag=pn_TAG
  				SDIssueType=CREQTYPE
    			sdPrintAll=1
    			sdReqDept=ALLTRIM(NVL(cDept,""))
    			sdReqDescript=ALLTRIM(fixquote(NVL(mDep,"")))
    			sdHiTech=ALLTRIM(NVL(record.hitech,"0"))
    			*-- 12/11/2019 #146658 MD added sdReqDept, sdReqDescript, sdHiTech
				DO printScannedDocs WITH SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
			ENDIF 
			Do PRTENQA With ;
				MV, Iif( ONHOLD  And Not PL_NOTICNG , "HoldSub", MCLASS), MGROUP, ;
				IIF( L_FAXALLOW, Alltrim( SZFAXNUM), "")
		Endif

	ENDIF	
       If PL_KOPVER  And  PC_LITCODE='C  ' And CREQTYPE="S" &&AND  pc_RpsForm<>"KOPGeneric"
**05/24/2010 - Print a subp'a scanned pages with the Notice and Court Sets for the KOP Civil lit issues
**07/15/013- KOP Generic now have their own sub form that prints (G) with an attchment as a real subpoena not just a scanned page.
		If PL_NOTICNG Or  L_COURTSET			
			*-- 11/23/2021 MD  dont print second time if its already printed
			* Do PSPECDOC With CREQTYPE
			*--01/26/2022 #262779 MD define variable 
			IF TYPE("scannedSubPrinted")="U"
					scannedSubPrinted=.F.
			ENDIF 
			IF NVL(scannedSubPrinted,.F.)=.F.
				Do PSPECDOC With CREQTYPE
			ENDIF 
			*-- 11/23/2021 MD 
			
			If PL_NosForm  AND  ALLTRIM( NVL(record.scandocs,""))<>"1" && 03/10/17- add rider after a subp
				Do SUBPATTCH With MV,  GFADDCR( SPEC_INS.SPEC_INST),  PN_TAG, MDEP
			Endif
			IF  ALLTRIM( NVL(record.scandocs,""))="1" && /////  03/08/2018 MD #75726/78152  added check for scanDocs
				C_RIDERPCX=""
				ntag= PN_TAG
				C_RIDERPCX=SUBRIDERPCX	(ntag,"R",1 )
				IF !EMPTY(ALLTRIM(C_RIDERPCX))					
					DO pspecdoc WITH 'R'
				Endif
			Endif
		Endif
	Endif   
*\\ 9/22/2009 kdl buisiness rule change - do not block documents when court has scanned subpoena
	If PL_KOPVER And Not PL_SCANSUB
&& print special scanned page(s)
**10/26/16 - #51529 :DO NOT PRINT SCANNED SUBP FOR A SECOND TIME for non-programmed subps

		If Not L_PDFFILE And !PL_NosForm
			If Not PL_NOTICNG And Not Empty( CREQTYPE)			  
				If CREQTYPE="S" And PL_TXCOURT
**skip && 09/25/2017- PRINT "s" TYPE AT OTHER SPOT AS THESE DOCS NEEDED AT THE BEGINING OF A SET
				Else
					Do PSPECDOC With CREQTYPE
				Endif

				Do PSPECDOC With "B"
			Endif
			
			*10/06/2021 WY 245050 (USDC-TX, needs affidavit and DWQ when DWQ is entered into DB)
			*ask about after scans
			*<245050>
			IF UPPER(LEFT(pc_Court1,7)) == "USDC-TX"
				c_quest = GetTxDWQ(pc_clcode, nTag)
				IF LEN(ALLTRIM(c_quest)) > 0
					IF NOT BNotCall &&10/12/2021 when printing USDC-TX notice, skip USDC-TX affidavid
						Do txaffid With Iif( PL_REISSUE And PN_SUPPTO<>0 , PN_SUPPTO, NTAG), Alltrim(MDEP), Alltrim(MID), Nvl(PC_CERTTYP,'N')
						*12/19/2021 #258295 (move 2 lines up)
						DO Txquest WITH NTAG, MDEP, MID, c_quest, .T.
					ENDIF 
					*DO Txquest WITH NTAG, MDEP, MID, c_quest, .T.

				ENDIF 
			ENDIF 
			*</245050>

*******************************************************************************************************
**** START&&05/29/12  MOVED FROM ABOVE TO BE THE VERY LAST PAGES IN THE KOP SUBS SETprint Hipaa notice
			If PL_HIPAA And Not PL_NOTICNG And Not PL_OFCMD  And CREQTYPE="S"
				Do ATTHIPAA
			Endif
*******************************************************************************************************
*******************************************************************************************************
**EF 02/27/04 add an "Acknowledgement" page to State DD issues for "A" issues
			If PL_STDIETD And CREQTYPE = "A"
				Do PRINTGROUP With MV, "Ackgment"
			Endif
*******************************************************************************************************
** 09/25/2017 this LOR to all request issued with firm code F000020274.  Both autho and subpoena. #69833
			If pl_Vigorito
				Do VigorLor In Subp_pa
			Endif
**12/12/2017"	 LOR to Firm Code F000004192 for all subpoena and autho tags. . #75224
			If pl_GRCorsi
				Do CorsiLor In subp_pa
			Endif

**07/29/04 EF - prints a LOR page after auth/subps
			If Not PL_NOTICNG
				If PN_LORPOS=2 And Not Empty(LC_DOCNAME)
					Do PRINTGROUP With MV, LC_DOCNAME
					IF NOT EMPTY(LC_DOCNAME2)			&& 9/23/2020, ZD #190778, JH.
						Do PRINTGROUP With MV, LC_DOCNAME2
					ENDIF

					Do Case
					Case PL_WELDROD Or PL_HRTLOR
						Do PRINTFIELD With MV, "CasePlaintiff", Alltrim( PC_PLNAM)
					Case PL_STDSED

						Do PRINTFIELD With MV, "CasePlaintiff", Alltrim( PC_PLNAM)
						Do PDEPINFO With MID, Proper( MDEP), .F.
					Endcase
				Endif
			Endif
**07/29/04  EF -end

		Endif

*******************************************************************************************************
		If (PL_WCABKOP And CREQTYPE = "S" ) And Not PL_NOTICNG &&04/23/12 -wcab page
			Do WCABPAGE
		Endif
*******************************************************************************************************

		If Not Empty( MV) And Not PL_AUTOFAX
			If ( PL_TXABEX And Not L_FAX2REQ) And ;
					( Not L_FAX1REQ) And ( Not L_PRTFAX)
				MCLASS = "TXAuth"
				If Inlist( Allt( Upper( GOAPP.USERDEPARTMENT)), "RTU", "ICU","SRU")
					MCLASS = MCLASS + Allt( Upper( GOAPP.USERDEPARTMENT))
				Endif
                    *-- 03/29/2018 md #81998 modified issue process called from deponent options screen
                    IF ALLTRIM( NVL(record.scandocs,""))=="1"  
   						LOCAL SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
  						sdClCode=pc_clcode
    					sdTag=pn_TAG
  						SDIssueType=CREQTYPE
    					sdPrintAll=1
    					sdReqDept=ALLTRIM(NVL(cDept,""))
    					sdReqDescript=ALLTRIM(fixquote(NVL(mDep,"")))
    					sdHiTech=ALLTRIM(NVL(record.hitech,"0"))
    					*-- 12/11/2019 #146658 MD added sdReqDept, sdReqDescript, sdHiTech
						DO printScannedDocs WITH SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
				ENDIF 
				Do PRTENQA With MV, MCLASS, Iif( Empty(MGROUP), "1", MGROUP), ""
			Else
**AutoFax first/SecReq issues

				If L_FAXALLOW And ( L_FAX2REQ Or L_FAX1REQ Or L_PRTFAX)
					C_FAX = Strtran( SZFAXNUM, " ", "")
					C_TEMP = Strtran( C_FAX, "-", "")
					C_TEMP2 = Strtran( C_TEMP, "(", "")
					SZFAXNUM = Strtran( C_TEMP2, ")", "")
					If ( L_FAX1REQ And L_FAXALLOW)
						MCLASS = "FrstFax"
					Endif
					*-- 03/29/2018 md #81998 modified issue process called from deponent options screen
                   	IF ALLTRIM( NVL(record.scandocs,""))=="1"  
   						LOCAL SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
  						sdClCode=pc_clcode
    					sdTag=pn_TAG
  						SDIssueType=CREQTYPE
    					sdPrintAll=1
    					sdReqDept=ALLTRIM(NVL(cDept,""))
    					sdReqDescript=ALLTRIM(fixquote(NVL(mDep,"")))
    					sdHiTech=ALLTRIM(NVL(record.hitech,"0"))
    					*-- 12/11/2019 #146658 MD added , sdReqDept, sdReqDescript, sdHiTech
						DO printScannedDocs WITH SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
					ENDIF 
					If ( L_PRTFAX And L_FAXALLOW)
						MVPRT = MV
						Do PRTENQA With ( MVFAXCOV+MV), "FrstFax", "1", ;
							+ Alltrim(SZFAXNUM)
						Do PRTENQA With ( MVSP+MVPRT), "FrstPrtFax", "1", ;
							+ ""
					Else
						Do PRTENQA With MV, MCLASS, "1", ;
							+ Alltrim(SZFAXNUM)
					Endif
				Else
** re-print notices WITH subpoenas in one queue.

****************10/17/07- Separate RUSH/NONRUSH SQR jobs
					If  Allt(Upper(GOAPP.USERDEPARTMENT))= "SRU" And L_RUSHDEPO
						MCLASS = Allt(Upper(GOAPP.USERDEPARTMENT))+"RUSH"
					Endif
****************10/17/07- Separate RUSH/NONRUSH SQR jobs

					If Not PRINTED And PL_REPNOTC  And Not PL_FAXSUBP And   Not PL_ORDVERSET && 10/22/12- SKIP IT HERE AS ORDER VERIF HAS ITS OWN ASSIGMENT TO A CLASS
&&03/23/2016 removed  OMRPage #36180
*!*							IF (CREQTYPE=="A")  OR (PL_ILCOOK AND CREQTYPE=="S")
*!*								DO OMRPAGE
*!*							ENDIF
&&03/23/2016 removed  OMRPage #36180

					Else
&&fax a subpoena with notice

&&03/23/2016 removed  OMRPage #36180
**03/08/2012 added OMRPAGE/
*!*							IF PL_KOPVER  AND (CREQTYPE=="A") AND (NOT PL_NOTICNG  OR (PL_ILCOOK AND CREQTYPE=="S" AND NOT PL_ORDVERSET AND NOT PL_CRTSETCOOK))
*!*								DO OMRPAGE
*!*							ENDIF
&&03/23/2016 removed  OMRPage #36180

&&04/07/2015 last page of the new MD request is a service page
						If ( pc_c1Name = "MD-BaltimoCity" And CREQTYPE="S" And Not PL_NOTICNG)
							MV =MV + mdservice(	Iif( Type('D_TXN11')="U", Date(), D_TXN11),1)
						Endif


						If Not PL_FAXSUBP And Not L_COURTSET And   Not PL_ORDVERSET &&10/22/12
&&ORIG NOT
**11/5/14 print jobs as one sql
							If Not PL_NOTICNG
**2.19.15- MD subp-1st request send to Hold Printer-Liz -start

								If PL_KOPVER  And (CREQTYPE=="S") And PL_1ST_REQ  And PL_OFCMD
									MCLASS ='MDSubReq'
								Endif
**2.19.15-end

								*-- 03/29/2018 md #81998 modified issue process called from deponent options screen
                   				IF ALLTRIM( NVL(record.scandocs,""))=="1"  
   									LOCAL SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
  									sdClCode=pc_clcode
    								sdTag=pn_TAG
  									SDIssueType=CREQTYPE
    								sdPrintAll=1
    								sdReqDept=ALLTRIM(NVL(cDept,""))
    								sdReqDescript=ALLTRIM(fixquote(NVL(mDep,"")))
    								sdHiTech=ALLTRIM(NVL(record.hitech,"0"))
    								*-- 12/11/2019 #146658 MD added sdReqDept, sdReqDescript, sdHiTech
									DO printScannedDocs WITH SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
								ENDIF 
								Do PRTENQA With MV, Iif( ONHOLD  , "HoldSub", MCLASS), MGROUP, ""
							Endif
						Else
**EF 02/10/05 notice-fax
**EF 06/19/09 notice-fax WITH A SUBPOENA
**06/20/2011
							If PL_NOTICNG And Not L_COURTSET And Not PL_FAXSUBP And Not PL_ORDVERSET &&10/22/12
								*-- 03/29/2018 md #81998 modified issue process called from deponent options screen
                   				IF ALLTRIM( NVL(record.scandocs,""))=="1"  
   									LOCAL SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
  									sdClCode=pc_clcode
    								sdTag=pn_TAG
  									SDIssueType=CREQTYPE
    								sdPrintAll=1
    								sdReqDept=ALLTRIM(NVL(cDept,""))
    								sdReqDescript=ALLTRIM(fixquote(NVL(mDep,"")))
    								sdHiTech=ALLTRIM(NVL(record.hitech,"0"))
    								*-- 12/11/2019 #146658 MD added sdReqDept, sdReqDescript, sdHiTech
									DO printScannedDocs WITH SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
								ENDIF 
								Do PRTENQA In TA_LIB With MV, "FaxNotice", ;
									"2", SZFAXNUM
							Endif
						Endif
					Endif

				Endif
			Endif &&texas cases
			Release PRINTED, ONHOLD
		Endif
	Endif
*******************************************************************************************************
&&TX FILINGS #60359
	If PL_1ST_REQ And  PL_TXCOURT  And CREQTYPE="S" And   !PL_REISSUE
		dep_date=TIMESHEET.DUE_DATE
		bBalt=.F.
		mCrtDesc=""
		Do txfiling With NTAG,  MDEP, MID, D_TODAY
	Endif
*******************************************************************************************************
	

	If PL_CAVER
		If Type( "AF_Utility") = "U"
			If L_FAXALLOW And ( L_FAX2REQ Or L_FAX1REQ Or L_PRTFAX)
				C_FAX = Strtran( SZFAXNUM, " ", "")
				C_TEMP = Strtran( C_FAX, "-", "")
				C_TEMP2 = Strtran( C_TEMP, "(", "")
				SZFAXNUM = Strtran( C_TEMP2, ")", "")

				If ( L_FAX1REQ And L_FAXALLOW)
					MCLASS = "FrstFax"
					GNRPS=12
				ENDIF
				*-- 03/29/2018 md #81998 modified issue process called from deponent options screen
				 IF ALLTRIM( NVL(record.scandocs,""))=="1"  
   					LOCAL SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
  					sdClCode=pc_clcode
    				sdTag=pn_TAG
  					sdIssueType=CREQTYPE
    				sdPrintAll=1
    				sdReqDept=ALLTRIM(NVL(cDept,""))
    				sdReqDescript=ALLTRIM(fixquote(NVL(mDep,"")))
    				sdHiTech=ALLTRIM(NVL(record.hitech,"0"))
    				*-- 12/11/2019 #146658 MD added sdReqDept, sdReqDescript, sdHiTech
					DO printScannedDocs WITH SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
				ENDIF 
				If ( L_PRTFAX And L_FAXALLOW)
					MVPRT = MV
					Do PRTENQA With (MVFAXCOV + MV), "FrstFax", "1", ;
						+ Alltrim(SZFAXNUM)
					Do PRTENQA With (MVSP + MVPRT), "FrstPrtFax", "1", ;
						+ Alltrim(SZFAXNUM)
				Else
					Do PRTENQA With MV, Iif(L_FAX1REQ, "FrstFax", MCLASS), "1", ;
						+ Alltrim(SZFAXNUM)
				Endif
			Endif
		Endif
		If Not PL_AUTOFAX And Not L_PRTFAX
			If (Not Empty(MV) ) And (GCOFFLOC=="C") &&AND (creqtype=="A")
			*-- 03/29/2018 md #81998 modified issue process called from deponent options screen
			 	IF ALLTRIM( NVL(record.scandocs,""))=="1"  
   					LOCAL SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
  					sdClCode=pc_clcode
    				sdTag=pn_TAG
  					SDIssueType=CREQTYPE
    			    sdPrintAll=1
    			    sdReqDept=ALLTRIM(NVL(cDept,""))
    				sdReqDescript=ALLTRIM(fixquote(NVL(mDep,"")))
    				sdHiTech=ALLTRIM(NVL(record.hitech,"0"))
    			    *-- 12/11/2019 #146658 MD added , sdReqDept, sdReqDescript, sdHiTech
					DO printScannedDocs WITH SDclCode, SDtag, SDissueType,sdPrintAll, sdReqDept, sdReqDescript, sdHiTech
			    ENDIF 
				Do PRTENQA With MV, MCLASS, MGROUP, ""
			Endif
		Endif                                     && autofax
	Endif
	If Not PL_AUTOFAX And Not L_COURTSET
		Do SPINCLOSE
	Endif
Endif                                           && EF 6/28/02

Return

*******************************************************************************************************
*******************************************************************************************************
Procedure ADD14TXN
*** Add transAction 14 to entry file (expedite)
*******************************************************************************************************
Private LCDESCRIPT
LCDESCRIPT = Trim( MDEP) + " - " + Allt( PC_PLATNAM)

Do ADDSTCTXN With  LCDESCRIPT, PC_CLCODE, 14, NTAG, MID, C_ISSTYPE, PC_USERID,	Request.id_tblrequests, "", .F.
Do  DOIFCANCEL With "IfCancel","tblTimesheet",ENTRYID.Exp, "D"
Return

*******************************************************************************************************
*******************************************************************************************************
Procedure PFAXCOVR
*******************************************************************************************************
Private SZDATE, SZCASE, BPROC, SZPROC, SZPGCNT, C_FAXDEPT, ;
	LC_ORDER, LC_ORDER2, LC_KEY, LC_KEY2, C_FAXTRANS
DBINIT=Alias()

C_FAXTRANS = "(999) 999-9999"
C_FAXTRAN="@R (999)999-9999"
If Type( "creqtype") <> "C"
	CREQTYPE = "S"
Endif
MDATE = D_TODAY + Iif( CREQTYPE = "A", 0, GNHOLD)
Store "" To SZPGCNT, LC_ORDER, LC_ORDER2, LC_KEY, LC_KEY2, LC_REQTEXT
SZDATE = Cmonth(MDATE) + " " + Allt(Str(Day(MDATE))) + ;
	", " + Allt(Str(Year(MDATE)))


If Not(Type( "szKey")="U") And (Not Empty(SZKEY))
	SZDESC = Upper(Allt(TIMESHEET.Descript))
Endif

&& Check if Fax number exists!!
If (Type( "szFaxNum") == "U") Or (Empty(SZFAXNUM))

	SZFAXNUM = ""
	Select PC_DEPOFILE

	If Left(TIMESHEET.mailid_no, 1) = "H"
		If Not Empty( CDEPT)
			C_FAXDEPT = CDEPT
		Else

			Public LC_DEPT As String
*!*				Local O_MESSAGE4 As Object
*!*				LC_MESSAGE = "Please pick a Department for your request."
*!*				O_MESSAGE4 = Createobject('rts_message',LC_MESSAGE)
*!*				O_MESSAGE4.Show
*!*	&&08/19/2011- REMOVE MASTER DEPARTMENT FROM A LIST
*!*				Do HOSPDEPT.MPR
*!*				C_FAXDEPT=LC_DEPT
&&11/27/2017:  allow to pick the dept that exist in our Rolodex #67478
			LC_DEPT	= validdept( Nvl(TIMESHEET.mailid_no,''))
			C_FAXDEPT=LC_DEPT
			Release LC_DEPT
			Release O_MESSAGE4
		Endif

*----------------- MD --------------------------------
		Local LNXXX, LCFIELD
		LCFIELD=""
		Select PC_DEPOFILE
		=Afields(LADEPTFLDS)
		For LNXXX=1 To Alen(LADEPTFLDS,1)
			If Alltrim(Upper(LADEPTFLDS[lnXXX,1]))=="DEPT_CODE"
				LCFIELD="DEPT_CODE"
			Endif
			If Alltrim(Upper(LADEPTFLDS[lnXXX,1]))=="DEPTCODE"
				LCFIELD="DEPTCODE"
			Endif
			If Alltrim(Upper(LADEPTFLDS[lnXXX,1]))=="CODE"
				LCFIELD="CODE"
			Endif
		Next
		If !Empty(Alltrim(LCFIELD))
			LCFIELD=Alltrim(Upper(LCFIELD))+"='"+Alltrim(Upper(C_FAXDEPT))+"'"
			Select FAX_NO From PC_DEPOFILE Where &LCFIELD Into Cursor HOLDFAXNO
			Select HOLDFAXNO
			If Reccount()>0

				SZFAXNUM = Transform( Alltrim(HOLDFAXNO.FAX_NO) , C_FAXTRAN)
			Endif
			Use In  HOLDFAXNO
		Endif
*----------------------- md ------------------------
	Else
		SZFAXNUM = 	Transform( Alltrim(PC_DEPOFILE.FAX_NO), C_FAXTRAN)
	Endif
Else
	If Type( "szFaxNum") = "C"
		SZFAXNUM = Transform( Val( SZFAXNUM), C_FAXTRAN)
	Else
		SZFAXNUM = Transform( SZFAXNUM, C_FAXTRAN)
	Endif
Endif

SZCASE = PC_PLNAM

PC_FAXATTN = " "
BTNCHOICE = 0

**11/01/2011 - added a new form

MV=GOAPP.OPENFORM("issued.frmfax2cov", "M", Request.id_tblrequests ,Request.id_tblrequests, ;
	MASTER.ID_TBLMASTER, SZFAXNUM, Alltrim(Request.Descript) )
If L_FAX1REQ
	Replace FAX_NO With SZFAXNUM In PC_DEPOFILE && 2/22/13 -MAKE SURE THE EDITED FAX# USED TO FAX A 2ND REQUEST
Endif
If !Empty(MV)
	L_PHONETXN = .T.
	If L_REPRINT


		LC_MESSAGE = "Do you want to add a phone call transaction ?"
		O_MESSAGE = Createobject('rts_message_yes_no',LC_MESSAGE)
		O_MESSAGE.Show
		L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
		O_MESSAGE.Release
		If Not L_CONFIRM

			L_PHONETXN = .F.
		Endif
	Endif
	If L_PHONETXN
		If L_FAX1REQ Or L_PRTFAX
*DO ADDPHNTX WITH IIF(L_FAX1REQ, 1, 3), NTAG
			Do FaxMemo With Iif(L_FAX1REQ, 1, 3), NTAG  &&5/8/17 #61920/21
		Else
*DO ADDPHNTX WITH 2, PN_TAG
			Do FaxMemo With  2, PN_TAG
		Endif
	Endif
Else
	Local O_MESSAGE5 As Object
	LC_MESSAGE = "Do you want to print a " + Iif( L_FAX1REQ Or L_PRTFAX, "first", "second")+ ;
		" request?"
	O_MESSAGE5 = Createobject('rts_message_yes_no',LC_MESSAGE)
	O_MESSAGE5.Show
	L_CONFIRM=Iif(O_MESSAGE5.EXIT_MODE="YES",.T.,.F.)
	O_MESSAGE5.Release
	If  L_CONFIRM

		GL_CANC2FAX = .F.
		If L_FAX1REQ Or L_PRTFAX
			L_PRT1REQ = .T.
		Else
			L_PRT2REQ = .T.
		Endif
		Store .F. To L_FAXALLOW, L_FAX2REQ, L_FAX1REQ, L_PRTFAX
	Else
		GL_CANC2FAX = .T.
**c_Txncode=IIF( l_Fax1Req OR l_PrtFax, STR(11), STR(44))
**07/29/2011 -replaced the sql with stored proc

		LCSQLLINE="exec [dbo].[CancelIssue_UpdateTag] '" + Alltrim(GOAPP.CURRENTUSER.NTLOGIN) + "','" +;
			C_TIMESHEETID + "'," + Iif(L_RUSHDEPO, Str(1),Str(0) ) + "," + Iif(L_FAX1REQ, Str(1),Str(0)) + ",'" + ;
			FIXQUOTE(PC_CLCODE) + "','" +Alltrim(Str(PN_TAG) )+ "','" + C_TODAY +"'"
		OMED.SQLEXECUTE(LCSQLLINE)



		If L_FAX1REQ Or L_PRTFAX
			L_UPDREC= OMED.SQLEXECUTE("Exec dbo.sp_UpdRequestStatus '" ;
				+ PC_CLCODE + "','" + Str(PN_TAG) + "','" ;
				+ L_REQSTAT + "','" + Alltrim(PC_USERID) + "'", "UpdRec")
			If Not L_UPDREC
				GFMESSAGE("Error in the program.")
			Endif
		Endif
	Endif
	Store .F. To L_FAXALLOW, L_FAX2REQ, L_FAX1REQ, L_PRTFAX

Endif

Select (DBINIT)
Return GL_CANC2FAX
*******************************************************************************************************
*******************************************************************************************************
Function SPECHAND
* Called both internally and by external routine HIPAASet
*******************************************************************************************************
Private  C_CASE, L_PROC, C_PROC, C_PGCNT, C_MESSAGE
*ON ERROR DO GET_ErrorSkip IN QCISSUE WITH ERROR(), 'SUBP_PA'
PC_SPECHAND=""
If Not Empty(TIMESHEET.Descript)
	C_DESC = Alltrim(TIMESHEET.Descript)
Else
	If TIMESHEET.TXN_CODE = 17
		C_ALIAS = Alias()
		Select TIMESHEET
		Skip -1
		If Not Empty(C_ALIAS)
			Select (C_ALIAS)
		Endif
	Endif
	C_DESC = Upper(Allt(TIMESHEET.Descript))
Endif
C_CASE = PC_PLNAM
C_WORKER = "RecordTrak Representative"
SZMESSAGE = " "

If Not Used('RECORD') &&02/07/2011 - LOOKS LIKE SOMETIMES A RECORD IS NOT OPEN- BUG FIX
	N_TAG4=PN_TAG
	N_LRS=PN_LRSNO
	If Type ('OMED')<>'O'
		OMED = Createobject("generic.medgeneric")
	Endif

	C_SQL="dbo.getrequestbylrsno " +Alltrim(Str(N_LRS))+","+Alltrim(Str(N_TAG4))
	OMED.SQLEXECUTE(C_SQL,'RECORD')
Endif

* ------------------------01/15/2018 MD #76582 ------------------------
*MV= GOAPP.OPENFORM("casedeponent.frmspechand", "M", Record.id_tblrequests ,Record.id_tblrequests, Master.ID_TBLMASTE
LOCAL lnCurArea
lnCurArea=SELECT()
SELECT record
LOCATE FOR tag=PN_TAG
IF FOUND()
	MV= GOAPP.OPENFORM("casedeponent.frmspechand", "M", Record.id_tblrequests ,Record.id_tblrequests, Master.ID_TBLMASTER)
ELSE
	MV= GOAPP.OPENFORM("casedeponent.frmspechand", "M", timesheet.id_tblrequests , timesheet.id_tblrequests, Master.ID_TBLMASTER)
ENDIF 
*------------------------------------------------------------------------------	

If Not Empty(MV) And Not "SPC" $ MCLASS
	PC_SPECHAND="SPC"
	MCLASS = Iif(Empty(Allt(MCLASS)),"", Allt(MCLASS))+ PC_SPECHAND +Iif(Allt(Upper(GOAPP.USERDEPARTMENT))= "AM" ,"AM","")
Endif

&& #70765 11/27/17:  update the print location of first requests for Court beginning "USDC" and office Philadelphia regardless of litigation to print at RPS 2.
&&11/18/14-1) USDC SUBPS GET A SEPARATE RPS PRINT CLASS-START

If   PL_KOPVER And  (  Left( Alltrim(PC_COURT1), 4) = "USDC" And PC_ISSTYPE='S'  )
	If PL_1ST_REQ
	    * --- 08/16/2018 MD #98879 added USDC subpoena for Abilify
    	IF ALLTRIM(UPPER(pc_litcode))=="ABL" AND ALLTRIM(UPPER(pc_area))=="MDL" AND pc_IssType="S"  AND pl_reissue=.F.
	    	mclass="ABLFstSubp"    	
    	ELSE 
			mclass="FIRSTUSDC"
		ENDIF 
	Else
		MCLASS=MCLASS+ "Civ"
	Endif
Endif


&&11/18/14- USDC SUBPS GET A SEPARATE RPS PRINT CLASS-END

**05/23/12- added hand delivery page here/ && 08/05/13 use future date for hold-print queue jobs
If Not PL_CAVER
	If PL_1ST_REQ  And PL_HANDDLVR
		Local c_mv As String
		c_mv=Alltrim(MV)
		d_print=Date()

		If CHECKTEST("HOLD_PRINT2")=.F. And  GNHOLD<>0
			d_print=LD_HDAYS
		Endif
		Do HANDDLVR With  c_mv, Record.Tag, Record.Descript, Dtoc(d_print), Transform( PC_DEPOFILE.PHONE, PC_FMTPHON)
	Endif

Endif
**05/23/12-end

If L_PRTFAX
	MVSP = MV
	MV = ""
Endif
Return .T.

*******************************************************************************************************
*******************************************************************************************************
Procedure THESUBP
*******************************************************************************************************
Private MNAMEINV, MRATADD1, MRATADD2, MRATCSZ, SZPLATTY, LLCOURT, MDATE1, ;
	SZATTYTYPE, MRATADD1P, MRATADD2P, MRATCSZP, MPHONE, mCrtDesc, LDTXN11, ;
	bBalt, BMDBALT, MPHONEP, LC_RECPERTAIN, LC_BARNUM, L_ST, LC_STATE
Store .F. To bBalt, BMDBALT, L_ST
Store "" To LC_RECPERTAIN, LC_BARNUM, LC_STATE
DBHOLD = Select()

Select COURT
Index On COURT Tag COURT
Set Order To COURT
LNCOMPLY = Iif( Seek( PC_COURT1), GNHOLD + COMPLY, 10)
PL_PRTORIGSUBP=.F.
**10/26/09 EF- when printing with pdf the sztxndate var is not defined
If Type ('sztxndate')="U"
	Private SZTXNDATE As Date
**1/5/10- FOR CIVIL PDF
	LD_11=TIMESHEET.TXN_DATE
	If Type('ld_11')="C"
		SZTXNDATE = Iif(PL_1ST_REQ, D_TODAY,Ctod(TIMESHEET.TXN_DATE))
	Else
		SZTXNDATE = Iif(PL_1ST_REQ, D_TODAY,Ttod(TIMESHEET.TXN_DATE))
	Endif
**1/5/10- FOR CIVIL PDF
Endif

LDTXN11 = GFCHKDAT( FORIGISS(Iif(PL_REISSUE And PN_SUPPTO<>0 , PN_SUPPTO,PN_TAG)), .F., .F.)

TXNOTFED = .T.
**Federal subpoenas need originals
If PL_OFCHOUS
	Select TXCOURT
	Set Order To CRT_ID
	If Not Empty(PC_COURT2)
		TXNOTFED = Iif(Seek(Allt(PC_COURT2)), .F., .T.)
	Endif
Endif


Select (DBHOLD)
dep_date = D_TODAY + LNCOMPLY
**EF 04/05/05 -start
MDATE = GFCHKDAT(D_TODAY + GNHOLD, .F.,.F.)
**EF 04/05/05 -end

If Not PL_1ST_REQ                            && second request or reprint
	If L_REPRINT
		If SZTXNDATE > {11/09/1997}

			dep_date = SZTXNDATE + LNCOMPLY
			If PL_NJSUB And Type('ldBusOnly')="U"
				LDBUSONLY = Iif(L_REPRINT, SZTXNDATE, D_TODAY)
				LDBUSONLY = GFCHKDAT( LDBUSONLY+14, .F., .F.) &&3/11/14 -USE CALENDAR DAYS INSTEAD OF BUSNESS PER LIZ
*!*					FOR I = 0 TO 13
*!*						LDBUSONLY = LDBUSONLY + 1
*!*						LDBUSONLY = GFCHKDAT( LDBUSONLY, .F., .F.)
*!*					NEXT
			Endif



**EF 04/05/05 -start
			MDATE = GFCHKDAT(SZTXNDATE + GNHOLD,.F.,.F.)
**EF 04/05/05 -end
		Else
			dep_date = SZTXNDATE + 10
			MDATE = SZTXNDATE
		Endif
	Else
		dep_date = D_TODAY + (LNCOMPLY - GNHOLD)
		MDATE = D_TODAY
	Endif
Endif
dep_date = GFCHKDAT( dep_date, .F., .F.)

MDEFENDANT = Allt(PC_DFCAPTN)
SZPLTNAME = Iif( PL_OFCHOUS, PC_PLNAM, PC_PLCAPTN )
MTERM =  PD_TERM
MRDOCKET = PC_DOCKET


Store "" To SZATNAME, MNAMEINV, MRATADD1, MRATADD2, MRATCSZ, MPHONE, mCrtDesc, C_RQATTY
If Not Empty( PC_RQATCOD)
	C_RQATTY=FIXQUOTE(PC_RQATCOD)
	PL_GETAT = .F.

&&08/01/207- more edits on the TX docs per Alec/Liz
	Do AtyMixed With FIXQUOTE(C_RQATTY), "M", Nvl(PL_TXCOURT,.F.)


*DO GFATINFO WITH C_RQATTY, "M"


**12/07/2011 - USE SIGNNATURE INSEAD OF NAME FOR NJ SUBP PER DAN/LIZ/ALEC
**03/08/12 -USDC PRINTS FIRM'S NAME
	SZATNAME = Iif (PL_NJSUB, Iif(Empty(PC_ATYSIGN),PC_ATYNAME,PC_ATYSIGN),PC_ATYNAME)
	MNAMEINV = Iif (PL_NJSUB Or  Left( Alltrim(PC_COURT1), 4) = "USDC", PC_ATYFIRM,PC_ATYSIGN)
	MRATADD1 = PC_ATY1AD
	MRATADD2 = PC_ATY2AD
	MRATCSZ = PC_ATYCSZ
	MPHONE = PC_ATYPHN

Endif


**07/13/2011 nj needs an atty with NJ state (if a rq atty does not have it already look for any other address within that firm)
If PL_NJSUB And PC_ATSTATE<>'NJ'
	Local C_CLCODE As String, L_GOTONE As BOOLEAN
	L_GOTONE=.F.
	C_CLCODE=PC_CLCODE
	L_GOTONE= GETNJATTY ( C_RQATTY)
	If L_GOTONE
		MRATADD1 = PC_ATY1AD
		MRATADD2 = PC_ATY2AD
		MRATCSZ = PC_ATYCSZ
	Endif

Endif
**07/07/2011 nj needs an atty with NJ state (if a rq atty does not have it already)
Store "" To SZPLATTY, MNAMEINVP, MRATADD1P, MRATADD2P, MRATCSZP, MPHONEP, mCrtDesc
If Not Empty( PC_PLATCOD)


	C_PLATTY =FIXQUOTE(PC_PLATCOD)
	PL_GETAT = .F.

	Do GFATINFO With C_PLATTY, "M"

	SZPLATTY =PC_ATYNAME
	MNAMEINVP = PC_ATYSIGN
	MRATADD1P = PC_ATY1AD
	MRATADD2P = PC_ATY2AD
	MRATCSZP = PC_ATYCSZ
	MPHONEP = PC_ATYPHN

Endif

Select Master

HAVEFORM = PL_C1FORM
MCOUNTY = PC_C1CNTY
 
If PL_CAVER

** The California subpoena routines are called as separate procedures
** to avoid conflict with the ordinary subpoena printing process.
** Implementing a separate procedure also allows the CANOTICE
** program to easily reprint the deposition subpoena page.

**EF 2/21/07 start -change all SecReq to print dates from the txn11
	D_TXN11 = GFCHKDAT( FORIGISS(NTAG), .F., .F.)
**2/21/07 end

	Local L_COURT As String, L_COURT2 As String, L_ATNAME As String, L_NAMEINV As String, L_REQTYPE As String, L_COUNTY As String, ;
		L_DEP As String, L_MID As String
	Do Case
*EF usdc subs for all states
*!*		CASE ALLT( pc_Court1) == "USDC"
*!*			DO CAUSSubp IN Subp_CA ;
*!*				WITH szEdtReq, mdep, mid, d_txn11, pd_Depsitn, ntag

	Case Left( Alltrim(PC_COURT1), 4) = "USDC" And CREQTYPE="S" &&ALLT( pc_Court1) ="USDC"
*!*			DO CAUSOthr IN Subp_CA ;
*!*				WITH  llProvider, szEdtReq, d_txn11, pd_Depsitn, ntag

		Store "" To L_COURT , L_COURT2, L_ATNAME, L_NAMEINV , L_REQTYPE , L_COUNTY,L_DEP ,L_MID

		Select COURT
		L_COURT=MCOURT
		L_COURT2=MCOURT2
		L_ATNAME=SZATNAME
		L_NAMEINV=MNAMEINV
		L_REQTYPE= CREQTYPE
		L_COUNTY=MCOUNTY
		L_DEP=MDEP
		L_MID=MID
		Do SUBPRINT With NTAG, L_COURT, L_COURT2,  L_ATNAME, L_NAMEINV,  L_REQTYPE,L_COUNTY, L_DEP, L_MID


	Case Allt( PC_COURT1) = "WCAB" And CREQTYPE="S"
		*-- 02/10/2021 MD #224406
		*-- GFMESSAGE("No WCAB supoenas in the system." )
		DO SubWCAB IN Subp_CA WITH "1", szEdtReq,pd_Depsitn, ntag, convertToDate(timesheet.Txn_date)	&& 03/29/2021 #232338 MD changed CTOD to convertToDate 		
		Do REATTCH With NTAG, MDEP, MID
	Otherwise
		If LLRPRSUBP

			Do CADEPSUB In SUBP_CA ;
				WITH SZEDTREQ, MDEP, MID, D_TXN11, PD_DEPSITN, NTAG



			If Not LFORMEXT                     &&EF 09/24/04-start: skip the attachment page printing
				Do REATTCH With NTAG, MDEP, MID
			Endif                               &&EF 09/24/04 -end



* For subpoenas, generate a CA Affidavit under the following
* circumstance:
* 1) First request for a civil subpoena with extra items
* 2) Reprint for a civil subpoena
			If CREQTYPE <> "A"
				If PL_1ST_REQ
					If PC_SUBPTYP = "C" And LFORMEXT
						Do CADECAFF In SUBP_CA With NTAG, D_TXN11
					Endif
				Else

					Select SUBPOENA

					If Seek( PC_CLCODE + Str(NTAG))
						If SUBPOENA.Type = "C"
							Do CADECAFF In SUBP_CA With NTAG, D_TXN11
						Endif
					Endif
* 05/20/03 DMA Close Subpoena file when work is done

				Endif
			Endif
		Endif

	Endcase

Else
&& KOP SUBPS
	Store "" To L_COURT , L_COURT2, L_ATNAME, L_NAMEINV , L_REQTYPE , L_COUNTY,L_DEP ,L_MID
	Select COURT
	L_COURT=MCOURT
	L_COURT2=MCOURT2
	L_ATNAME=SZATNAME
	L_NAMEINV=MNAMEINV
	L_REQTYPE= CREQTYPE
	L_COUNTY=MCOUNTY
	L_DEP=MDEP
	L_MID=MID

	If Not PL_WCABKOP && 04/23/12-wcab sups print scanned subps
		Do SUBPRINT With NTAG, L_COURT, L_COURT2,  L_ATNAME, L_NAMEINV,  L_REQTYPE,L_COUNTY, L_DEP, L_MID
	Endif


Endif


**Court Certificate added to be printed with subpoena- for courts with CourtCert = .T.
**11/16/2012-ADDED EXHIBIT A TO THE IL-WCC COURTS
**01/16/2013 added ILcooks



If PL_KOPVER
*3.11.15 print RIDER for all subps
*IF PL_PASUBP  OR  INLIST(ALLTRIM(PC_COURT1) ,'IL-WCC'  , "IL-COOKCOUNTY")
	If PL_1ST_REQ
		If Type('OMED') <>"O"
			OMED= Createobject("generic.medgeneric")
		Endif
		OMED.SQLEXECUTE("select [dbo].[DoWeStoreOrigSub]('" + Alltrim(PC_COURT1) + "')","Dowestore")
		If DOWESTORE.Exp=.T.
			Do ORIGSUBP With PC_COURT1,   PN_TAG, MDEP, LDTXN11
		Endif
	Endif



	If L_PRT2REQ Or L_FAX2REQ Or PL_QCPROC
		L_COURTSET=.F.
	Endif

	If L_COURTSET Or BNOTCALL
		If Used("Spec_ins")
			Select SPEC_INS
			Use
		Endif
		OMED.SQLEXECUTE("Exec [dbo].[GetTheLatestBlurb] '" + FIXQUOTE(PC_CLCODE) + "',' " + Str(PN_TAG) + "'", "Spec_ins")
		If Not pl_HSubpCourt  And Not PL_NosForm&&10/15/13 - DO BOT PRINT AN ATTACMENT WITH A COURT SETS TO SIGN SUBS + 3/10/17 NONPROGRAMMED COURTS ( HAVE ITS OWN ORDER) #57795
			Do SUBPATTCH With MV,  GFADDCR( SPEC_INS.SPEC_INST),  PN_TAG, MDEP
		Endif
	ELSE
*******************************************************************************************************
**10/26/16  Non-programmed subps  prints first #51529
** --- 08/05/2020 MD #170629 add pl_ILCook=.F. and plCourtIN=.F. ----------------------------------- 
		If PL_NosForm AND pl_ILCook=.F. and plCourtIN=.F.
** STOP1 : S
			Do PSPECDOC In SUBP_PA With "S"
		Endif
** STOP1a : rider - in-house or scanend
**09/07/17- upper  deponame  as 9.7.17
**08/16/2017:  TX Reissue needs an original tag's data
		If  (pl_txCourt And PL_REISSUE And  PN_SUPPTO<>0)
			SZEDTREQ= GETSPECINSFORTAG(PN_SUPPTO)
			Do SUBPATTCH With MV, SZEDTREQ,  PN_SUPPTO, Upper(MDEP)
		Else
			Do SUBPATTCH With MV, SZEDTREQ,  PN_TAG, Upper(MDEP)
		Endif

&&10/26/26- Non-programmed subps has its own order for scanned docs: s, r are done now we do  c,b and certs last (x for now)
		If PL_NosForm
			Local l_scancert As BOOLEAN
** STOP2 :   C AND B
			Do PSPECDOC In SUBP_PA With "C"
			Do PSPECDOC In SUBP_PA With "B"
			l_scancert=.F.
**a) check CERT type in the ScanDocLog and print them all here
			*l_scancert=findcerts(.T.)
**b) for all 'x' types on a case print the pages
*l_scancert=findimg(NTAG, "x")

		ENDIF		
*-----------------------------------------------------------------
* 01/25/2018 MD #77400 move this line here to print for all types      
* 02/26/2018 MD #80782 don't print certs for TX.  Tx  has its own set of docs
IF pl_TxCourt  AND NVL(PC_ISSTYPE,'A')="S"
	*
ELSE
	l_scancert=findcerts(.F.,nTag)	
ENDIF 
	
*-----------------------------------------------------------------------		
&&10/26/26- Non-programmed subps has its own order for scanned docs: s, r are done now we do  c,b and certs last
*******************************************************************************************************
	Endif

*******************************************************************************************************
**08/09/2017:  move Notice Page in front of the subpoena page
**05/30/2017 : TX 	Docs : print a rest of the docs in a request
	*If PL_TXCOURT  And CREQTYPE="S" && AND !PL_REISSUE
	*11/15/2021 WY #256321 include UPPER(LEFT(pc_Court1,7)) == "USDC-TX"
	*If (CREQTYPE="S") and (PL_TXCOURT or UPPER(LEFT(pc_Court1,7)) == "USDC-TX") AND !PL_REISSUE		&& 4/1/2022, ZD #267892, JH.
	If (CREQTYPE="S") and (PL_TXCOURT or UPPER(LEFT(pc_Court1,7)) == "USDC-TX") 						&& 4/1/2022
		Local c_quest  As String
&& 08/15/2017 TX REISSUE  NEEDS DWQ AND AFFIDAVITS FROM ORIG TAG
		c_quest=""

**Cover and Notice and Subp pages are done  so we print the rest here:
**page 4 -Direct Written Questions**************************************************************
		c_quest= GetTxDWQ(TIMESHEET.CL_CODE, Iif(PL_REISSUE And  PN_SUPPTO<>0 , PN_SUPPTO, NTAG))

** 10/20/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only
		If  SkipTxDocs (PN_LRSNO, Iif(PL_REISSUE And  PN_SUPPTO<>0 , PN_SUPPTO, NTAG))
			c_quest="!"
		Endif

		If Empty(c_quest)
			Wait Window "TX Docs: Missing  Direct Written Questions."
			Return
		Endif

		Do Txquest With  Iif(PL_REISSUE And  PN_SUPPTO<>0 , PN_SUPPTO, NTAG), Alltrim(L_DEP), Alltrim(L_MID),  c_quest, .F.
**page 5-Cert of service****************************************************************************************
		*11/15/2021 WY  #25  #256321
		LOCAL llRunCertification
		llRunCertification = .t.
		IF UPPER(LEFT(pc_Court1,7)) == "USDC-TX" AND LEN(ALLTRIM(GetTxDWQ(pc_clcode, nTag))) > 0
			llRunCertification = .f.
		ENDIF  
		IF llRunCertification
			Do TxCert With Iif(PL_REISSUE And  PN_SUPPTO<>0 , PN_SUPPTO, NTAG), Alltrim(L_DEP), Alltrim(L_MID)
		ENDIF 
**page 6-Affidavit**************************************************************************************
		Do txaffid With Iif( PL_REISSUE And PN_SUPPTO<>0 , PN_SUPPTO, NTAG), Alltrim(L_DEP), Alltrim(L_MID), Nvl(PC_CERTTYP,'N')
	Endif

	If Not BNOTCALL
		If Inlist( C_ACTION, "7", "4", "9")
			If HAVEFORM Or PL_HIPAA                   &&EF 11/19/03 print Court Cert for all PA courts
				If PL_C1CERT
					Do REPPACRT
				Endif
				Do REPCCERT
			Endif
		Endif
	Endif
Endif
******courtcert
PD_MAILD = MDATE

C_ACTION=""
Return

************************************************************************************************************************
Procedure COVRLETR
************************************************************************************************************************

Private LDWORK, LDTXN11, LCOFC, LLUSERCTRL, LC_HVIEW, LC_WEBADD, LC_HIPAANOTE, C_COURT

Set Procedure To TA_LIB Additive

DBHOLD = Select()
If Not PL_OFCHOUS
	Select COURT
Else
	Select TXCOURT
Endif
Index On COURT Tag COURT
SZATTN=""

If PL_AUTOFAX && if it's autofax job, it's not reprint then
	L_REPRINT = .F.
Endif

If Not Empty(PC_COURT1)
	LNCOMPLY = Iif( Seek( PC_COURT1), GNHOLD + COMPLY, 10)
Endif

If Not PL_OFCHOUS
** no holding period for reissues
	If PL_REISSUE Or (C_ISSTYPE = "A" And PC_LITCODE == "3  ")
		GNHOLD = 0
	Endif
Else

	If Not PL_1ST_REQ&&-autofax
		LDTXN11=Ctod(TIMESHEET.TXN_DATE)
	Endif
	LDBUSONLY = GFDTSKIP( Iif( PL_1ST_REQ, D_TODAY, LDTXN11), ;
		IIF( PC_TXCTTYP = "FED", 16, 20))
Endif

Select (DBHOLD)

Select Master

If Type( "creqtype")<>"C"
	CREQTYPE = "S"
Endif


&&4/21/10 AVANDIA WORK
If Type("gnFRDays")="U" Or PL_AIPPROC
	GNFRDAYS = PN_LITFDAY
	GNISSDAYS = PN_LITIDAY
	LLFROMREV = Iif (GNFRDAYS<>0, .T.,.F.)
Else
	LLFROMREV = Iif (GNFRDAYS<>0, .T.,.F.)
Endif

&&4/21/09 AVANDIA WORK

If Not PL_OFCHOUS
	Do Case
	Case CREQTYPE = "A"
		L_BAYCOLFR = PL_BAYCOL And PL_FROMREV
		L_PROPSUBP = .F.
		MDATE = D_TODAY + Iif( LLFROMREV, GNFRDAYS, GNISSDAYS)

		LDBUSONLY = D_TODAY
		For I = 0 To 13
			LDBUSONLY = LDBUSONLY + 1
			LDBUSONLY = GFCHKDAT( LDBUSONLY, .F., .F.)
		Next
		Do Case

		Case PL_PROPPA Or PL_PROPNJ
			MDATE = LDBUSONLY

		Case PL_DIETDRG Or PL_MDLHOLD
			MDATE = MDATE + 15


		Case L_BAYCOLFR
			MDATE = MDATE + 10

		Endcase
&& Due date for Rezulin-Montgomery should be + 10 days
		DUEDATE = Iif( PL_REZMONT , MDATE + 10, MDATE)
&&  Diet Drug Sec.Req print + 10 days for a duedate
		DUEDATE = Iif( Not PL_1ST_REQ And Inlist( PC_LITCODE,  ;
			"D  ", "E  ", "G  ", "Q  "), MDATE + 10, MDATE)

		If PC_LITCODE == "3  " And CREQTYPE = "A"
			DUEDATE = MDATE + 10
		Endif

&&(ava reprint)
		If Type('pl_avaSpec')='U'
			PL_AVASPEC=.F.
		Endif
		If Not PL_1ST_REQ And  Not PL_AVASPEC


			If L_REPRINT
				Do Case

				Case L_BAYCOLFR
					MDATE = SZTXNDATE + Iif( LLFROMREV, GNFRDAYS, GNISSDAYS) + 10
					DUEDATE = MDATE + 10

				Case PL_MDLHOLD
					MDATE = SZTXNDATE +Iif( LLFROMREV, GNFRDAYS, GNISSDAYS)+15
					DUEDATE = MDATE + 10
				Case PL_ZICAM
					If TIMESHEET.TXN_CODE=11
						DUEDATE = PD_DUEDTE
						MDATE = PD_ISSDTE
					Else
&& Reprint of the sec. request
						MDATE = SZTXNDATE + Iif( LLFROMREV, GNFRDAYS, GNISSDAYS)
						DUEDATE = MDATE + Iif( LLFROMREV,;
							IIF( GNFRDAYS>0, GNFRDAYS, 10 ), ;
							IIF( GNISSDAYS>0, GNISSDAYS, 10))
						PD_DUEDTE = GFCHKDAT( DUEDATE, .F., .F.)

					Endif

				Otherwise
					MDATE = SZTXNDATE + Iif( LLFROMREV, GNFRDAYS, GNISSDAYS)
					DUEDATE = MDATE + Iif( LLFROMREV,;
						IIF( GNFRDAYS>0, GNFRDAYS, 10 ), ;
						IIF( GNISSDAYS>0, GNISSDAYS, 10))

				Endcase
			Else
				MDATE = D_TODAY

				If  L_PRT2REQ Or L_FAX2REQ
					DUEDATE=MDATE + 10
				Endif
			Endif
		Endif
	Otherwise

&&  MI courts: calculate due date
		If PL_MICHCRT
			LDBUSONLY = MIDUEDAT( Iif( L_REPRINT, SZTXNDATE + 1, D_TODAY + 1))
		Endif
**#49176 use 18 calendar days for Il-Cook
		If  PL_CAMBASB &&OR PL_ILCOOK
			LDBUSONLY = Iif(L_REPRINT, SZTXNDATE, D_TODAY)
			Do Case
*!*				CASE PL_NJSUB
*!*					LN_COUNT=13
*!*				CASE  PL_ILCOOK
*!*					LN_COUNT=17
			Otherwise
				LN_COUNT=8
			Endcase


			For I = 0 To LN_COUNT
				LDBUSONLY = LDBUSONLY + 1
				LDBUSONLY = GFCHKDAT( LDBUSONLY, .F., .F.)
			Next
		Endif

		If PL_NJSUB And Type('DUEDATE ')="U"
			LDBUSONLY = Iif(L_REPRINT, SZTXNDATE, D_TODAY)
			DUEDATE  = GFCHKDAT( LDBUSONLY+14, .F., .F.) &&3/11/14 -USE CALENDAR DAYS INSTEAD OF BUSNESS PER LIZ

		Endif

**#49176 use 18 calendar days for Il-Cook
		DUEDATE = Iif( PL_MICHCRT Or PL_NJSUB Or PL_CAMBASB , ;
			LDBUSONLY, D_TODAY + LNCOMPLY)
		MDATE = GFCHKDAT(D_TODAY + GNHOLD,.F.,.F.)


		If Not PL_1ST_REQ                      && Not 1st request

			If L_REPRINT

				If SZTXNDATE > {11/09/1997}
					If TIMESHEET.TXN_CODE=44
** -reprint of a second request
						MDATE=Ctod(TIMESHEET.TXN_DATE)
						DUEDATE = MDATE + GNHOLD
					Else

&& reprints of txn 44: due date should be calculated from issue date
**#49176 use 18 calendar days for Il-Cook
						LDTXN11=Ctod(TIMESHEET.TXN_DATE)
						DUEDATE = Iif( PL_MICHCRT Or PL_NJSUB Or PL_CAMBASB  ,  ;
							LDBUSONLY, LDTXN11 + LNCOMPLY)
						MDATE = LDTXN11 + GNHOLD
					Endif  &&REPRINT OF SEC REQ
				Else

					DUEDATE = GFCHKDAT(SZTXNDATE+10,.F.,.F.)
					MDATE = GFCHKDAT(SZTXNDATE, .F.,.F.)


				Endif

			Else

				DUEDATE = Iif( PL_MICHCRT Or PL_NJSUB Or PL_CAMBASB, ;
					LDBUSONLY, D_TODAY + (LNCOMPLY - GNHOLD))
				MDATE = D_TODAY

			Endif
		Endif
	Endcase
&& for reprints
Endif
If Not PL_OFCHOUS

	If (PL_PROPPA Or PL_PROPNJ)
		If L_REPRINT And CREQTYPE <> "S"
			MDATE = TIMESHEET.TXN_DATE + Iif( LLFROMREV, GNFRDAYS, GNISSDAYS)
			LDBUSONLY = MDATE
			For I = 0 To 13
				LDBUSONLY = LDBUSONLY + 1
				LDBUSONLY = GFCHKDAT( LDBUSONLY, .F., .F.)
			Next
			DDUEDATE = LDBUSONLY
			DUEDATE = DDUEDATE + 10
		Endif
	Endif
	DUEDATE = GFCHKDAT( DUEDATE, .F., .F.)
	MDATE = GFCHKDAT( MDATE, .F., .F.)

Else
	If CREQTYPE = "S"
		MDATE = LDBUSONLY
		DUEDATE = GFCHKDAT( LDBUSONLY + 20, .F., .F.)
	Else
		MDATE = Ctod(TIMESHEET.TXN_DATE)
		DUEDATE = LDBUSONLY
	Endif
Endif
&& Authorization issues

If Not PL_OFCHOUS
&& Propulsid subpoenas issues vs.auth.
	DUEDATE = Iif( CREQTYPE = "A" And PL_1ST_REQ , ;
		GFCHKDAT( DUEDATE + 10, .F., .F.), GFCHKDAT( DUEDATE, .F., .F.))
	If PL_ZICAM
		DUEDATE = PD_DUEDTE
	Endif
Else
	DUEDATE = Iif( CREQTYPE="A", LDBUSONLY, DUEDATE)
Endif
** no holding period for Reissues
If PL_REISSUE
	MDATE = D_TODAY
	DUEDATE = GFCHKDAT( D_TODAY +10, .F., .F.)
	DDUEDATE = DUEDATE
Endif

&& (ava reprint)
If Type('pl_avaSpec')='U'
	PL_AVASPEC=.F.
Endif
If PL_AVASPEC
	DUEDATE = GFCHKDAT( Date() +10, .F., .F.)
	SZTXNDATE=Date()
Endif

LDWORK = DUEDATE
* Hipaa notices need to know due date
PD_DUEDATE = LDWORK

If Not L_AUTOCOV And Not  PL_STOPPRTISS
	DUEDATE  =GOAPP.OPENFORM("request.frmDueDate", "M", PD_DUEDATE, PD_DUEDATE, "Due Date")

Endif

If LDWORK <> DUEDATE                            && Has been changed.
	LDDUEDATE = DUEDATE
	PD_DUEDATE=DUEDATE
Endif

If PC_DEPTYPE = "H"
	If Not Empty(CDEPT)
** This is filled in only if hospital!!
		Do Case
		Case CDEPT == "E"
			SZATTN = "ATTN: ECHOCARDIOGRAM DEPARTMENT"
			THEINFO = "ECHO"
			THEINFO2 = "ECHO"

		Case CDEPT == "R"
			SZATTN = "ATTN: RADIOLOGY DEPARTMENT"
			THEINFO = "RAD"
			THEINFO2 = "RAD"

		Case CDEPT == "P"
			SZATTN = "ATTN: PATHOLOGY DEPARTMENT"
			THEINFO = "PATH"
			THEINFO2 = "PATH"

		Case CDEPT == "B"
			SZATTN =  "ATTN: BILLING DEPARTMENT"
			THEINFO = "BILLS"
			THEINFO2 = "BILLS"

		Case CDEPT == "C"
			SZATTN =  "ATTN: CARDIAC CATHS DEPARTMENT"
			THEINFO = "CATH"
			THEINFO2 = "CATH"

		Otherwise
			SZATTN = "ATTN: MEDICAL RECORDS DEPARTMENT"
			THEINFO = "MED"
			THEINFO2 = "MED"
		Endcase
	Else
		SZATTN = ""
		THEINFO = "MED"
		THEINFO2 = "MED"
	Endif                                        && not empty cdept
Else
	THEINFO = "OTHER"
	THEINFO2 = "MED"
Endif                                           && pc_deptype = H

If Not Empty(PC_MAIDEN1)                        && AND UPPER(a.Litigation) == "I  "
	SZAKA = "A.K.A.: " + Trim( PC_MAIDEN1)
Else
	SZAKA = ""
Endif

&&Add new words for dd2 hipaa
Store "" To LC_HIPAANOTE, LC_HVIEW, LC_WEBADD
If PL_DDRUG2
	LC_HVIEW = "** This order can be viewed at:"
	LC_WEBADD = " http:/" + "/www.fenphen.verilaw.com/pto/PTO2390.pdf."
	LC_HIPAANOTE = " approved by the US District Court for the Eastern District "     +  ;
		"of PA, MDL Docket No. 1203, Civil Action #99-20593, Pretrial Order #2930** "   +  ;
		"(Para.2)"
Endif
&& new words for dd2 hipaa

&& Phila-Texas authorizations vs. Texas-Texas authorizations.

If PL_TXABEX And CREQTYPE <> "S" And Not PL_OFCHOUS
	Do PRINTGROUP With MV, "TX_AuthoCov"         &&Phila-TX Autho cases
Else
	If PL_OFCHOUS And CREQTYPE = "S"
		Do PRINTGROUP With MV, "TX_SubpCov"       &&TX Subp
	Endif
	If PL_OFCHOUS And CREQTYPE = "A"
		Do PRINTGROUP With MV, "TX_AuthCovT"      && TX Autho
	Endif

	If Not PL_OFCHOUS And Not PL_TXABEX
		If Type('pd_IssDte')<>'D'
			PD_ISSDTE=Date()
		Endif
		If PL_AIPPROC
**6/23/09 added for all Automated Requests lit/area combos
			DISSUE=PD_ISSDTE
		Else

			DISSUE=Iif( PL_ZICAM Or PL_AVAPLTF 	, PD_ISSDTE, Ctod(TIMESHEET.TXN_DATE))
		Endif

		SADDITION = Iif( (MDATE>D_TODAY Or DISSUE>D_TODAY), "H", "")

		Do PRINTGROUP With MV, ;
			IIF( DISSUE >= {10/19/2000}, ;
			SADDITION + "RequestCover", "RequestCovold")

	Endif
Endif


Store "" To C_COURT, C_MARK

*!*	DO CASE
*!*	CASE PL_OFCMD OR PL_OFCPGH OR PL_OFCKOP
*!*		L_GETRPS= ACDAMNUMBER (PC_AMGR_ID)
*!*		IF L_GETRPS
*!*			C_OFFLOCATION=IIF(ISNULL(LITRPS.RPSOFFCODE) OR EMPTY(LITRPS.RPSOFFCODE), 'P', LITRPS.RPSOFFCODE)
*!*		ENDIF
*!*		C_MARK=ALLTRIM(UPPER(NVL(PC_LITCODE,"")))+"."+ALLTRIM(UPPER(NVL(PC_INITIALS,"")))
*!*	OTHERWISE
*!*		C_OFFLOCATION=PC_OFFCODE
*!*	ENDCASE

C_MARK=Alltrim(Upper(Nvl(PC_LITCODE,"")))+"."+Alltrim(Upper(Nvl(PC_INITIALS,"")))

c_offlocation=RpsLoc()
**08/22/2017: New ACD Lines #67249
If Empty(Alltrim(c_offlocation))
	c_offlocation=pc_Offcode
Endif


Do PRINTFIELD With MV, "SpecMark", C_MARK
*****07/29/2011- added  Court Code
C_COURT= Iif(Not Empty(pc_c1Name) And PC_ISSTYPE="S", pc_c1Name, "")
Do PRINTFIELD With MV, "CourtCode", C_COURT

Do PRINTFIELD With MV, "Loc", C_OFFLOCATION

If PL_OFCHOUS
	Do PRINTFIELD With MV, "DueDate", Dtoc( DUEDATE)
Else

&& Propulsid subpoenas issues vs.auth.
	If PL_1ST_REQ
		If CREQTYPE = "A" And (PL_PROPNJ Or PL_PROPPA)
			DUEDATE = GFCHKDAT( DUEDATE, .F., .F.)
		Endif
	Endif

	If PL_ZICAM
		DUEDATE=PD_DUEDTE
	Endif
*

	Do PRINTFIELD With MV, "DueDate", ;
		DTOC( DUEDATE)
Endif
&&5/14/09 -ava reprint ( only used as a utility)
If PL_AVASPEC
	SZEDTREQ=""
Endif

***EF 1/12/07- NOT SURE IT IS NEEDED HERE..TRYING TO CATCH A PROBLEM WITH MISSING BLURBS ON ATTACHMENT3
If Empty(SZEDTREQ)
	SZEDTREQ= GETSPECINSFORTAG(Iif( PL_AUTOFAX, TAG2REQ, NTAG))
Endif
***EF 1/12/07-END
**4/16/2010 re-space the blurb

Do PRINTFIELD With MV, "InfoText",  Strtran( Strtran( SZEDTREQ, Chr(13), " "), Chr(10), "")
Do PRINTFIELD With MV, "Info", THEINFO
* 01/30/04 additions for K O P dietdrug2's req cover pages
If Not PL_OFCHOUS
	Do PRINTFIELD With MV, "HipaaNote", LC_HIPAANOTE
	Do PRINTFIELD With MV, "HView", LC_HVIEW
	Do PRINTFIELD With MV, "WebAdd", LC_WEBADD
Endif

Do PRINTFIELD With MV, "RequestCode", Iif(CREQTYPE="S", "SUBP", "AUTH")

If Not PL_1ST_REQ
	If PL_AUTOFAX Or L_PRT2REQ Or L_FAX2REQ
		Do PRINTFIELD With MV, "SecondRequest", "1"
		Do PRINTFIELD With MV, "SecRequest", "1"
		If PL_KOPVER
			Do GFPRTGRP
		Endif
	Else
		Do PRINTFIELD With MV, "SecondRequest", "0"
		Do PRINTFIELD With MV, "SecRequest", "0"
		If PL_KOPVER
			Do GFPRTGRP
		Endif
	Endif
Else
	Do PRINTFIELD With MV, "SecondRequest", "0"
	Do PRINTFIELD With MV, "SecRequest", "0"
	If PL_KOPVER
		Do GFPRTGRP
	Endif
Endif

Do PRINTGROUP With MV, "Control"

If PL_ZICAM
	If  (L_PRT2REQ Or L_FAX2REQ )
		MDATE = D_TODAY
	Else
		MDATE = PD_ISSDTE
	Endif
ENDIF
* --- 08/16/2018 MD #98879 added USDC subpoena for Abilify
IF ALLTRIM(UPPER(pc_litcode))=="ABL" AND ALLTRIM(UPPER(pc_area))=="MDL" AND creqType = "S"
   * do not print controlDate for the ABL
   Do PRINTFIELD With MV, "Date",""   
ELSE 
    Do PRINTFIELD With MV, "Date", Dtoc( MDATE)
ENDIF 
Do PRINTFIELD With MV, "LrsNo", PC_LRSNO
Do PRINTFIELD With MV, "Tag", Str( Iif( PL_AUTOFAX, TAG2REQ, NTAG))


Do PRINTGROUP With MV, "Deponent"
Do PRINTFIELD With MV, "Name", MDEP
Do PRINTFIELD With MV, "Addr", ;
	IIF(Empty(PC_DEPOFILE.ADD2), PC_DEPOFILE.ADD1, PC_DEPOFILE.ADD1 + Chr(13) + PC_DEPOFILE.ADD2)
Do PRINTFIELD With MV, "City", Alltrim(PC_DEPOFILE.CITY)
Do PRINTFIELD With MV, "State", Alltrim(PC_DEPOFILE.STATE)
Do PRINTFIELD With MV, "Zip", Alltrim(PC_DEPOFILE.ZIP)
Do PRINTFIELD With MV, "Extra", Iif(Isnull(SZATTN),"",SZATTN)
Do PRINTGROUP With MV, "Plaintiff"
Do PRINTFIELD With MV, "FirstName", PC_PLNAM
Do PRINTFIELD With MV, "MidInitial", ""
Do PRINTFIELD With MV, "LastName", ""
Do PRINTFIELD With MV, "Addr1", PC_PLADDR1
Do PRINTFIELD With MV, "Addr2", PC_PLADDR2
If Type('pd_pldob')<>"C"
	PD_PLDOB=Dtoc(PD_PLDOB)
Endif
If Type('pd_pldod')<>"C"
	PD_PLDOD=Dtoc(PD_PLDOD)
Endif

Do PRINTFIELD With MV, "BirthDate", Left(PD_PLDOB,10)
Do PRINTFIELD With MV, "SSN", Allt( PC_PLSSN)
Do PRINTFIELD With MV, "DeathDate",  Left(PD_PLDOD,10)
Do PRINTFIELD With MV, "Extra", SZAKA

Return

*******************************************************************************************************
Procedure PSCNAUTH
**EF 11/30/05 - added goapp...
*******************************************************************************************************
Set Safety Off
Private FILEHAND, I, LCLRS, LCSOURCE, LCDEST, LCSPATH, LCDPATH, LFILEEXT
&&  CA  & Texas print *.tif files
LFILEEXT = ".TIF"
F_PCX=Iif(PL_OFCOAK, GOAPP.CAPCX ,GOAPP.PCXPATH)
F_PCXARCH=Iif(PL_OFCOAK,GOAPP.CAPCXARCH,GOAPP.PCXARCHPATH)

&&lFileExt = IIF( pl_CAVer or pl_OfcHous, ".TIF", ".PCX")
LCLRS = Allt( PC_LRSNO)
*lcLrs = ALLT( STR( A.lrs_no))
LCSPATH = F_PCX + LCLRS
LCDPATH = F_PCXARCH + Right(LCLRS,1) + "\" + LCLRS

****** Send single autho page if it exists (lllll.TIF) ******
LCSOURCE = LCSPATH + LFILEEXT
LCDEST   = LCDPATH + LFILEEXT

If Not SEND_PG( LCSOURCE, LCDEST)

** 02/21/02 EF-K O P Office print tif and pcx  images
** 02/26/02 MNT - IF TIF EXISTS DO NOT PRINT PCX FOR KOP ***
	If (PL_OFCKOP Or PL_OFCMD Or PL_OFCPGH)
		LCSOURCE = LCSPATH + ".PCX"
		LCDEST   = LCDPATH + ".PCX"
		= SEND_PG( LCSOURCE, LCDEST)
	Endif
Endif
****** Send autho pages for the case (llllCn.TIF)
For I = 1 To 9
	LCSOURCE = LCSPATH + "C" + Trans(I, "9") + LFILEEXT
	LCDEST   = LCDPATH + "C" + Trans(I, "9") + LFILEEXT

	If Not SEND_PG(LCSOURCE, LCDEST)
		If PL_OFCKOP Or PL_OFCMD Or PL_OFCPGH
			LCSOURCE = LCSPATH + "C" + Trans(I, "9") + ".PCX"
			LCDEST   = LCDPATH + "C" + Trans(I, "9") + ".PCX"
			= SEND_PG( LCSOURCE, LCDEST)
		Endif
*EXIT
	Endif
Endfor

****** Send autho pages for this specific tag (llllTn.ttt)
For I = 1 To 9
	LCSOURCE = LCSPATH + "T" + Trans(I, "9") + "." + Trans(NTAG, "@L 999")
	LCDEST   = LCDPATH + "T" + Trans(I, "9") + "." + Trans(NTAG, "@L 999")

	If Not SEND_PG( LCSOURCE, LCDEST)
		Exit
	Endif
Endfor

*--4/25/02 kdl start: need to check for spec T files  (with creqtype at end of name)
*--if there is one, print it
If PL_SCANSUB And Not Empty(CREQTYPE)
****** Send pages for this specific tag (llllTnc.ttt)
	For I = 1 To 9
		LCSOURCE = LCSPATH + "T" + Trans(I, "9") + ;
			CREQTYPE + "." + Trans(NTAG, "@L 999")
		LCDEST   = LCDPATH + "T" + Trans(I, "9") + ;
			CREQTYPE + "." + Trans(NTAG, "@L 999")
		If Not SEND_PG(LCSOURCE, LCDEST)
			Exit
		Endif
	Endfor

*--9/16/02 kdl start: new file format:
*--Send pages for this specific tag 999999#n.999 where # is req type
*--   DO fndtiff WITH "pScnAuth", creqtype
	For I = 1 To 9
		LCSOURCE = LCSPATH + CREQTYPE + Trans(I, "9") + ;
			"." + Trans(NTAG, "@L 999")
		LCDEST   = LCDPATH + CREQTYPE + Trans(I, "9") + ;
			"." + Trans(NTAG, "@L 999")
		If Not SEND_PG(LCSOURCE, LCDEST)
			Exit
		Endif
	Endfor
*--9/16/02 kdl end:

*\\kdl add "both" page types
	For I = 1 To 9
		LCSOURCE = LCSPATH + "B" + Trans(I, "9") + "." + Trans(NTAG, "@L 999")
		LCDEST   = LCDPATH + "B" + Trans(I, "9") + "." + Trans(NTAG, "@L 999")
		SEND_PG( LCSOURCE, LCDEST)
	Endfor

Endif
*--4/25/02 kdl end

*--1/13/02 kdl start: need to accomodate california documants
If PL_CAVER And Not PL_SCANSUB And Not Empty(CREQTYPE)
	For I = 1 To 9
		LCSOURCE = LCSPATH + CREQTYPE + Trans(I, "9") + ;
			"." + Trans(NTAG, "@L 999")
		LCDEST   = LCDPATH + CREQTYPE + Trans(I, "9") + ;
			"." + Trans(NTAG, "@L 999")
		If Not SEND_PG(LCSOURCE, LCDEST)
			Exit
		Endif
	Endfor
Endif
*--1/13/02 kdl start:

* -- Set Safety On && 03/10/2021 MD #230210 
Return

*******************************************************************************************************
Procedure PSCNSUBP
*******************************************************************************************************
Private FILEHAND, I, LCLRS, LCSOURCE, LCDEST, LCSPATH, LCDPATH
CREQTYPE = "S"

F_PCX=Iif(PL_OFCOAK, GOAPP.CAPCX ,GOAPP.PCXPATH)
F_PCXARCH=Iif(PL_OFCOAK,GOAPP.CAPCXARCH,GOAPP.PCXARCHPATH)
Set Safety Off
LCLRS = Allt( PC_LRSNO)
LCSPATH = F_PCX + LCLRS
LCDPATH = F_PCXARCH + Right(LCLRS,1) + "\" + LCLRS

****** Send pages for this specific tag (llllTn.ttt)

For I = 1 To 9
	LCSOURCE = LCSPATH + "T" + Trans(I, "9") ;
		+ Iif(Empty(CREQTYPE), "", CREQTYPE) + "." + Trans(NTAG, "@L 999")
	LCDEST   = LCDPATH + "T" + Trans(I, "9") +;
		IIF(Empty(CREQTYPE), "", CREQTYPE) + "." + Trans(NTAG, "@L 999")
	If Not SEND_PG( LCSOURCE, LCDEST)

		Exit
	Else
		LNOTSCAN= .T.
	Endif
Endfor

*--9/16/02 kdl start: check for scanned docs saved with names in the new
*--naming format
If Not Empty(CREQTYPE)
*--   DO  fndtiff WITH "pScnAuth", creqtype, lNotScan
	For I = 1 To 9
		LCSOURCE = LCSPATH + CREQTYPE + Trans(I, "9") + ;
			"." + Trans(NTAG, "@L 999")
		LCDEST   = LCDPATH + CREQTYPE + Trans(I, "9") + ;
			"." + Trans(NTAG, "@L 999")
		If Not SEND_PG( LCSOURCE, LCDEST)
			LNOTSCAN = .F.
			Exit
		Else
			LNOTSCAN = .T.
		Endif
	Endfor

*\\kdl add "both" page types
	If !pl_Noticng
		For I = 1 To 9
			LCSOURCE = LCSPATH + "B" + Trans(I, "9") + "." + Trans(NTAG, "@L 999")
			LCDEST   = LCDPATH + "B" + Trans(I, "9") + "." + Trans(NTAG, "@L 999")
			SEND_PG( LCSOURCE, LCDEST)
		Endfor
	Endif
Else
	LNOTSCAN = .F.
Endif
*--9/16/02 kdl end:

* -- Set Safety On  && 03/10/2021 MD #230210 
Return LNOTSCAN
*******************************************************************************************************
Procedure PSPECDOC
* Print scanned special documents
*******************************************************************************************************

Parameters CREQTYPE
*SET STEP ON 
Private FILEHAND, I, LCLRS, LCSOURCE, LCDEST, LCSPATH, LCDPATH, LFILEEXT

LFILEEXT = ".TIF"
Set Safety Off
**4/3/14- ADDED CA OFFICE
F_PCX=Iif(PL_OFCOAK, GOAPP.CAPCX ,GOAPP.PCXPATH)
F_PCXARCH=Iif(PL_OFCOAK,GOAPP.CAPCXARCH,GOAPP.PCXARCHPATH)

LCLRS = Allt( PC_LRSNO)
LCSPATH = F_PCX + LCLRS
LCDPATH = F_PCXARCH + Right(LCLRS,1) + "\" + LCLRS

****** Send single autho page if it exists (lllll.TIF) ******

LCSOURCE = LCSPATH + Iif(Empty(CREQTYPE), "", CREQTYPE) + LFILEEXT
LCDEST   = LCDPATH + Iif(Empty(CREQTYPE), "", CREQTYPE) + LFILEEXT
=SEND_PG(LCSOURCE, LCDEST)
**
If PL_OFCKOP Or PL_OFCMD Or PL_OFCPGH
	LCSOURCE = LCSPATH + Iif(Empty(CREQTYPE), "", CREQTYPE) + ".PCX"
	LCDEST   = LCDPATH + Iif(Empty(CREQTYPE), "", CREQTYPE) + ".PCX"
	=SEND_PG(LCSOURCE, LCDEST)
Endif
**

****** Send pages for the case (llllCn.PCX)
For I = 1 To 9
	LCSOURCE = LCSPATH + "C" + Trans(I, "9") + ;
		IIF(Empty(CREQTYPE), "", CREQTYPE) + LFILEEXT
	LCDEST   = LCDPATH + "C" + Trans(I, "9") + ;
		IIF(Empty(CREQTYPE), "", CREQTYPE) + LFILEEXT
	If Not SEND_PG(LCSOURCE, LCDEST)
		Exit
	Endif
Endfor

**
If PL_OFCKOP Or PL_OFCMD Or PL_OFCPGH
	For I = 1 To 9
		LCSOURCE = LCSPATH + "C" + Trans(I, "9") + ;
			IIF(Empty(CREQTYPE), "", CREQTYPE) + ".PCX"
		LCDEST   = LCDPATH + "C" + Trans(I, "9") + ;
			IIF(Empty(CREQTYPE), "", CREQTYPE) + ".PCX"
		If Not SEND_PG(LCSOURCE, LCDEST)
			Exit
		Endif
	Endfor
Endif
**

****** Send pages for this specific tag (llllTn.ttt)
For  I = 1 To 9
	LCSOURCE = LCSPATH + "T" + Trans(I, "9") + ;
		IIF(Empty(CREQTYPE), "", CREQTYPE) + "." + Trans(NTAG, "@L 999")
	LCDEST   = LCDPATH + "T" + Trans(I, "9") + ;
		IIF(Empty(CREQTYPE), "", CREQTYPE) + "." + Trans(NTAG, "@L 999")
	If Not SEND_PG(LCSOURCE, LCDEST)
		Exit
	Endif
Endfor

*--9/16/02 kdl start: new file format:
If Not Empty(CREQTYPE)
*--Send pages for this case 999999#n.TIF where # is req type
	For I = 1 To 9
		LCSOURCE = LCSPATH + CREQTYPE + Trans(I, "9") + ;
			LFILEEXT
		LCDEST   = LCDPATH + CREQTYPE + Trans(I, "9") + ;
			LFILEEXT
		If Not SEND_PG(LCSOURCE, LCDEST)
			Exit
		Endif
	Endfor
*--Send pages for this case 999999#n.PCX where # is req type
	If PL_OFCKOP Or PL_OFCMD Or PL_OFCPGH
		For I = 1 To 9
			LCSOURCE = LCSPATH + CREQTYPE + Trans(I, "9") + ;
				".PCX"
			LCDEST   = LCDPATH + CREQTYPE + Trans(I, "9") + ;
				".PCX"
			If Not SEND_PG(LCSOURCE, LCDEST)
				Exit
			Endif
		Endfor
	Endif
*--Send pages for this specific tag 999999#n.999 where # is req type
	For I = 1 To 9
		LCSOURCE = LCSPATH + CREQTYPE + Trans(I, "9") + ;
			"." + Trans(NTAG, "@L 999")
		LCDEST   = LCDPATH + CREQTYPE + Trans(I, "9") + ;
			"." + Trans(NTAG, "@L 999")
		If Not SEND_PG(LCSOURCE, LCDEST)
			Exit
		Endif
	Endfor

	*08/16/2021 WY #222165, apply case level documents/scans to subpoenas	
	*99999Cn.TIF
	*very confusing, look for subpoena (CREQTYPE = "S") but the file name must have the letter C for case level
	*currently PSPECDOC gets called with a letter C (CREQTYPE = "C") in 2 places (handled above) 
	*<#222165>
	IF CREQTYPE = "S" && avoid rendering the document/scan twice when CREQTYPE = "B"
		*-- 11/23/2021 MD do not print case level docs with notice for IL/IN courts
		IF PL_NOTICNG=.T. and (pl_ILCook=.T. or plCourtIN=.T.)
			*-- do nothing
		ELSE 
			For I = 1 To 9
				LCSOURCE = LCSPATH + "C" + Trans(I, "9") + ".TIF"
				LCDEST   = LCDPATH + "C" + Trans(I, "9") + ".TIF"
				If Not SEND_PG(LCSOURCE, LCDEST)
					Exit
				Endif
			Endfor
		ENDIF 
	ENDIF 
	*</#222165>

Endif
**--9/16/02 kdl end:





* -- Set Safety On && 03/10/2021 MD #230210 
Return

*******************************************************************************************************
Function SEND_PG

*******************************************************************************************************
Parameters LCFROM, LCTO
Local lc_fname As String
lc_fname=Alltrim(LCFROM)

N_POS = At("\", lc_fname, 2)
N_FILELEN = Len(Alltrim(lc_fname)) - (N_POS  )
If N_FILELEN > 12
	Return .T.
Endif

FILEHAND = Fopen(LCFROM)
If FILEHAND <> -1
	=Fclose(FILEHAND)
	Copy File (LCFROM) To (LCTO)
	If Type("L_COURTSET")="L"
		If Not L_COURTSET && KOP GENERIC -HOLDPRINT PROJECT
			Delete File (LCFROM)
		Endif
	Else
		Delete File (LCFROM)
	Endif
	Do SENDAUTH With LCTO
Else
	FILEHAND = Fopen(LCTO)
	If FILEHAND <> -1
		=Fclose(FILEHAND)
		Do SENDAUTH With LCTO
	Else
		Return .T.
	Endif
Endif
Return .T.


*******************************************************************************************************

Procedure SENDAUTH

*******************************************************************************************************
Parameters THEPCX

&&5/14/09 (ava reprint)
If Type('pl_avaSpec')='U'
	PL_AVASPEC=.F.
Endif
If PL_AVASPEC
	SZTXNDATE=D_TODAY
ENDIF
IF TYPE("SZADD1")<>"C"
	SZADD1=""
ENDIF 
IF TYPE("SZADD2")<>"C"
	SZADD2=""
ENDIF 
IF TYPE("SZCITY")<>"C"
	SZCITY=""
ENDIF 
IF TYPE("SZSTATE")<>"C"
	SZSTATE=""
ENDIF 
IF TYPE("SZPHONE")<>"C"
	SZPHONE=""
ENDIF 
IF TYPE(" SZZIP")<>"C"
	 SZZIP=""
ENDIF 
IF TYPE("L_REPRINT")<>"L"
	L_REPRINT=.F.
ENDIF 	

**10/26/09 EF- when printing with pdf the sztxndate var is not defined
If Type ('sztxndate')="U"
**1/5/10- FOR CIVIL PDF
	LD_11=TIMESHEET.TXN_DATE

	If Type('ld_11')="C"
		SZTXNDATE = Iif(PL_1ST_REQ, D_TODAY,Ctod(TIMESHEET.TXN_DATE))
	Else
		SZTXNDATE = Iif(PL_1ST_REQ, D_TODAY,Ttod(TIMESHEET.TXN_DATE))
	Endif
**1/5/10- FOR CIVIL PDF


Endif

If Type ('MDEP')<>"C"

	If PC_DEPTYPE == "D"
		MDEP=GFDRFORMAT(Alltrim(TIMESHEET.Descript))
		MDEP = Iif(Not "DR."$MDEP,"DR. "+Alltrim(MDEP),MDEP)
	Else
		MDEP =TIMESHEET.Descript
	Endif
Endif


dep_date = Iif( Not PL_1ST_REQ And L_REPRINT, SZTXNDATE, D_TODAY)
dep_date = GFCHKDAT( dep_date, .F., .F.)
&& #51529 - PRINT CERT X
Do PRINTGROUP With MV, Iif( PL_SCANSUB Or pc_RpsForm="KOPGeneric" Or pl_webform Or  PL_NosForm Or  pl_txcourt, "ScannedSub", "Authorization")
Do PRINTFIELD With MV, "Id", THEPCX
**HOLD_PRINT : "R' TYPE PRINTS HERE
If Not PL_SCANSUB  And pc_RpsForm<>"KOPGeneric" And !pl_webform And !PL_NosForm   And ! pl_txcourt&& #51529 -


	Do PRINTFIELD With MV, "Loc", ;
		IIF(PL_OFCMD Or PL_OFCPGH, "P", PC_OFFCODE)
	Do PRINTGROUP With MV, "Deponent"
	Do PRINTFIELD With MV, "Name", MDEP
	Do PRINTFIELD With MV, "Addr", Iif(Empty(SZADD2), SZADD1, ;
		SZADD1 + Chr(13) + SZADD2)
	Do PRINTFIELD With MV, "City", SZCITY
	Do PRINTFIELD With MV, "State", SZSTATE
	Do PRINTFIELD With MV, "Zip", SZZIP
	Do PRINTGROUP With MV, "Control"
	Do PRINTFIELD With MV, "Date", Dtoc( dep_date)
Else
	Do PRINTFIELD With MV, "RT", "RT: " + PC_LRSNO ;
		+ "." + Allt(Str(NTAG))
Endif
Return

**********************************************************************
**********************************************************************
*EF 8/4/00 Function returns affidavit types for Texas_Abex cases
Function PICK_AFF

**********************************************************************
** Called both internally and from routine SelQType in Subp_Lib
Private LCALIAS

OMED2 = Create("generic.medgeneric")

LCALIAS = Alias()
If Not Used("AffType")

	LN_AFF =OMED2.SQLEXECUTE("Exec dbo.GetAffType ", "AffType")
	If LN_AFF
		Select AFFTYPE
		=CursorSetProp("KeyFieldList", "Code", "Afftype")
		Index On [Code] Tag AFFCODE Additive

	Else
		GFMESSAGE("No Affidavit Type data. See IT.")
		Return

	Endif
Endif
L_CANCEL=GOAPP.OPENFORM("issued.frmAffidtype", "M", Master.ID_TBLMASTER, Master.ID_TBLMASTER)

If L_CANCEL
	Return
Endif

Select AFFTMP
Go Top

LCAFF = ""
Scan For Select
	LCAFF = Allt( LCAFF) + Allt( AFFTMP.Code)
Endscan

If Not Empty( LCALIAS)
	Select ( LCALIAS)
Endif
Release OMED2
Return LCAFF

*******************************************************************************************************
Function GETTXAFF                               && For edit mode

*******************************************************************************************************
Private LCALIAS, I, NREC
LCALIAS = Alias()
LLAFF = GFUSE( "AffType")
Create Table C:\TEMP\TMPAFF ( Desc C(20), Select L, Code C(5))
Select AFFTYPE
Scan
	Insert Into TMPAFF;
		( Desc, Select, Code) ;
		VALUES ;
		( AFFTYPE.Desc, .F., AFFTYPE.Code)
Endscan
Select SPEC_INS
Set Order To CLTAG
If L_PRT2REQ Or L_FAX2REQ
	If Seek( PC_CLCODE + "*" + Allt( Str( NTAG)))
		CDEPT2 = Allt(DEPT)
	Endif
Else
	CDEPT2 = Allt(DEPT)
Endif
If Not Empty( CDEPT2)
	NREC = Len( CDEPT2)
	ICNT = 1
	CDEPT = ""
	For ICNT = 1 To NREC
		If ICNT > NREC
			Exit
		Endif
		CDEPT = Substr( CDEPT2, ICNT, 1)
		Select TMPAFF
		Replace TMPAFF.Select With .T. For Code = CDEPT
	Next
Endif
Select TMPAFF
Go Top
Define Window W_AFFPICK From 4,0 To 20,57;
	COLOR Scheme 10 ;
	CLOSE Float Grow Zoom
*ACTIVATE WINDOW w_AffPick
On Key
Browse Fields ;
	SELECT  :H= "Select" :P=.F., ;
	DESC :R :H= "Affidavit", ;
	CODE :R :H= "Code" ;
	FREEZE Select ;
	TITLE " T/F to Select/Deselect; <Ctrl+W> to save" ;
	WINDOW W_AFFPICK
Deactivate Window W_AFFPICK
Release Window W_AFFPICK
Goto Top
LCAFF = ""
Scan For Select
	Select TMPAFF
	LCAFF = Allt( LCAFF) + Allt( TMPAFF.Code)
Endscan
Select TMPAFF
Use
Delete File C:\TEMP\TMPAFF.Dbf
= GFUNUSE( "AFftype", LLAFF)
If Not Empty( LCALIAS)
	Select (LCALIAS)
Endif
Return LCAFF

*******************************************************************************************************
Procedure LFAUTHO2
*******************************************************************************************************
Parameters LCDOC
* 05/25/04 DMA Use long plaintiff name
Do PRINTGROUP With MV, Iif( LCDOC = "A", "AuthoCover1", "AuthoCover2")
Do PRINTFIELD With MV, "Loc", ;
	IIF( PL_OFCPGH Or PL_OFCMD, "P", PC_OFFCODE)

Do PRINTGROUP With MV, "Deponent"
Do PRINTFIELD With MV, "Name", MDEP
Do PRINTFIELD With MV, "Addr", ;
	IIF(Empty(SZADD2), Allt(SZADD1), Allt(SZADD1)  + "  " + Allt(SZADD2))
Do PRINTFIELD With MV, "City", SZCITY
Do PRINTFIELD With MV, "State", SZSTATE
Do PRINTFIELD With MV, "Zip", SZZIP

Do PRINTGROUP With MV, "Plaintiff"
* 05/25/04 DMA Use long plaintiff name
Do PRINTFIELD With MV, "FirstName", PC_PLNAM
Do PRINTFIELD With MV, "MidInitial", ""
Do PRINTFIELD With MV, "LastName", ""
Do PRINTFIELD With MV, "SSN", PC_PLSSN
If Type('pd_pldob')<>"C"
	PD_PLDOB=Dtoc(PD_PLDOB)
Endif
Do PRINTFIELD With MV, "InfoText",  Left(PD_PLDOB,10)
Return

*******************************************************************************************************
****EF  Reprint PA court certificate
Procedure REPPACRT

*******************************************************************************************************
&&EF 06/29/16 Aded a  new page : kopcert2.prg #43585
&&EF 03/24/04 Replaced by external program
&&EF 05/12/03 Print a 'future' mail date on a cert page
Private c_mv
c_mv = ""
PL_GETAT = .F.
Do GFATINFO With PC_RQATCOD, "M"

*c_mv = PRTPRERE ( 1, IIF( PL_HIPAA AND NOT PL_REISSUE, PD_MAILD, MDATE))
&&06/27/16- added  a new court prer page #43585
c_mv =KopCert2 ( 1, Iif( PL_HIPAA And Not PL_REISSUE, PD_MAILD, MDATE), .F.)
MV = MV + c_mv
Return
*********************************************************************
Procedure REPCCERT
* Reprint non-PA Court Certificate

*******************************************************************************************************
* EF  01/26/04  Use Atty Signature not the szAtName
* DMA 02/27/01  Changed to use SQL Insert
Private OMEDC As Object

OMEDC = Createobject("generic.medgeneric")
C_CLCODE=FIXQUOTE(PC_CLCODE)
C_NAME=FIXQUOTE( MNAMEINV)
C_STR= "INSERT INTO tblCourtCer ;
	(RT, TAG, cl_code, Txn_date, reqatty, id_tblTimesheet, Active, created, createdby) ;
	VALUES 	( '" + Str(PN_LRSNO) + "','" + Str( NTAG) + "','" ;
	+  C_CLCODE + "','" + Dtoc( D_TODAY) + "','" + C_NAME  ;
	+ "','" + TIMESHEET.ID_TBLTIMESHEET+ "'," + Str(1) + ",'" + Dtoc( D_TODAY)+ "','" + PC_USERID   + "')"

L_OK=OMEDC.SQLEXECUTE (C_STR,"")
If Not L_OK
	GFMESSAGE( "No record has been added to the tblCourtCertification" )
Endif
Release OMEDC
Return

*******************************************************************************************************
*---------------------------------------------------------------------------------
*EF  procedure for the casbtext screen (CA subpoenas pick screen)
*----------------------------------------------------------------------------------
Procedure CIVPOP

*******************************************************************************************************
Private DBCIVPOP


DBCIVPOP = GFUSE( "CivPop")
m.DESC = ""
X = GETPOP( F_CIVPOP, "desc", m.DESC, "desc", "Select data", ;
	5, 1, "ZZZ", .T.)
=GFUNUSE( "CivPop", DBCIVPOP)
If Not Empty( X)
	Select TYPEDATA
	GETTEXT2= .T.
	X = Allt(X)
	Replace TYPETEXT With ""
	Replace TYPETEXT With X
Endif
Return
*--------------------------------------------------------------------------------
Procedure MDPROOF
Parameters NTAG, LPLATTY
* Called directly from TheNotice
* Called from Subp_Pa
*EF replace mProof.doc with a new one
*--------------------------------------------------------------------------------
Private LLTAB, MNAMEINV, MNAMEINVP, MRATADD1, MRATADD1P, ;
	MRATADD2, MRATADD2P, MRATCSZP, MRATCSZ, LD_DEPDATE, ;
	LC_DOCNAME, LCINIT, D_DEPDATE

C_ALIAS =Alias()
Dimension LAENV[1,3]

Store "" To MNAMEINV, MNAMEINVP, MRATADD1P, MRATADD2P, MRATCSZP, LCINIT
Store "" To SZATTYINFO, MRATADD1, MRATADD2, MRATCSZ, SZATNAME, LC_DOCNAME

If Not Used('record')
	L_GOTREC=OMED.SQLEXECUTE("exec [dbo].[GetRequestbyClcode]'" + FIXQUOTE(PC_CLCODE) + "'", 'Record')
	If Not L_GOTREC
		Return
	Endif
Endif
Select Record

If (Type( "ISSDATE")="U")
	If (Type('c_tscode')="U")
		C_TSCODE=FIXQUOTE(PC_CLCODE)
	Endif

	L_GOTTAG=OMED.SQLEXECUTE("SELECT dbo.gfIssuDt('" + C_TSCODE + "',' " +  Str(NTAG ) + "')", "Is11Exist")

	ISSDATE =Ctod(Left(Dtoc(IS11EXIST.Exp),10))
Endif

LD_DEPDATE =  Iif( PL_MDASB, ( ISSDATE + 2),  ISSDATE)

If PL_C1PRTSC
	Do Case
	Case Alltrim( PC_COURT1) == "MD-OWCP/DC"
		Do PRINTGROUP With MV, "OWCPProof"
	Otherwise
		Do Case
		Case PL_MDASB
			LC_DOCNAME = "DeposNot"
		Case PC_LITCODE == "A  "
			LC_DOCNAME = "ProofOfA"
		Otherwise
			LC_DOCNAME = "ProofOfService"
		Endcase
		Do PRINTGROUP With MV, LC_DOCNAME

	Endcase
&&EF  changes for MD-District proof of service page
&&08/01/03 Add new title for MD-HCA
	Do Case
	Case Allt( PC_COURT1) == "MD-District"
		LC_TITLE = "DISTRICT COURT OF MARYLAND"
	Case Allt( PC_COURT1) == "MD-HCA"
		LC_TITLE = "IN THE HEALTH CLAIMS ARBITRATION OFFICE"
	Otherwise
		LC_TITLE = "IN THE CIRCUIT COURT FOR"
	Endcase
&&08/01/03
	Do PRINTFIELD With MV, "TITLE", LC_TITLE
&&08/29/03 Add 2 days for atty to scan request to the courtlink.com
*--9/10/03 kdl start: fix variable type in statment
*EF 09/17/04 out-mdate1 = DTOC( IIF( pl_MdAsb, CTOD( MDATE1) + 2, CTOD( mdate1)))
*--kdl out 9/10/03:   mdate1=dtoc( IIF(pl_MdAsb, CTOD(MDATE1)+2,mdate1))
	D_DEPDATE = GFCHKDAT(LD_DEPDATE, .F., .F.)

	Do PRINTFIELD With MV, "DepDate", Dtoc( D_DEPDATE)
	Do PRINTGROUP With MV, "Case"
	Do PRINTFIELD With MV, "Plaintiff", PC_PLCAPTN
	Do PRINTFIELD With MV, "Defendant", PC_DFCAPTN
	Do PRINTFIELD With MV, "Docket", PC_DOCKET
	Do PRINTFIELD With MV, "Court", PC_COURT1
	Do PRINTFIELD With MV, "County", Iif( PC_COURT1 = "MD-HCA", "", PC_C1CNTY)
	Do PRINTFIELD With MV, "AttyType", Iif( PL_PLISRQ, "P", "D")

	If Not Empty( PC_RQATCOD)
		C_RQATTY=FIXQUOTE(PC_RQATCOD)
		PL_GETAT = .F.
		Do GFATINFO With C_RQATTY, "M"
		SZATNAME = PC_ATYNAME
		MNAMEINV = PC_ATYSIGN
		MRATADD1 = PC_ATY1AD
		MRATADD2 = PC_ATY2AD
		MRATCSZ = PC_ATYCSZ
		MPHONE = PC_ATYPHN

	Endif
	Do PRINTFIELD With MV, "AttyName", SZATNAME
	Do PRINTGROUP With MV, "Atty"
	Do PRINTFIELD With MV, "Name_inv", MNAMEINV
	Do PRINTFIELD With MV, "Ata1", MRATADD1
	Do PRINTFIELD With MV, "Ata2", MRATADD2
	Do PRINTFIELD With MV, "Atacsz", MRATCSZ

	If Not Used('Tabills')
		L_TABILL=GETTABILL(PC_CLCODE)
		If Not L_TABILL
			GFMESSAGE("Cannot get TAbills file")
			Return
		Endif
	Endif
	Select TABILLS

	Scan While Allt( TABILLS.CL_CODE) == Allt( PC_CLCODE)
		If Allt( TABILLS.AT_CODE) = Allt( PC_RQATCOD)
			Loop
		Endif
		C_TABATTY=FIXQUOTE(TABILLS.AT_CODE)
		PL_GETAT = .F.
		Do GFATINFO With C_TABATTY, "M"
		SZPLATTY = PC_ATYNAME
		MNAMEINVP = PC_ATYSIGN
		MRATADD1P = PC_ATY1AD
		MRATADD2P = PC_ATY2AD
		MRATCSZP = PC_ATYCSZ
		MPHONEP = PC_ATYPHN

		SZATTYINFO = Proper( SZPLATTY) + ", " + ;
			PROPER( MRATADD1P) + " " + Proper( MRATADD2P) ;
			+ " " + Proper( MRATCSZP)
		If Not PL_MDASB
			Do PRINTGROUP With MV, "Item"
			Do PRINTFIELD With MV, "Tbl1Col", SZATTYINFO
		Endif

		Select TABILLS
		Loop
	Endscan

Endif

If Not Empty(C_ALIAS)
	Select (C_ALIAS)
Endif
Wait Clear
Return

**********************************************************************
**********************************************************************
Function FSECISS
**********************************************************************
Parameters LNTAG
Dbalias = Select()
LCENT = PC_ENTRYN
Select ( LCENT)
Set Order To CL_TXN
DISSUE = Iif( Seek( PC_CLCODE + "*" + Str(11)  + "*" + Str(LNTAG)), ;
	TXN_DATE, {  /  /    })
Select (Dbalias)
Return DISSUE
*********************************************************************
**********************************************************************
Procedure PDEPINFO
**********************************************************************
* Print Deponent Information
* 06/16/03 DMA Eliminate use of gflkup to cut file open/close time
*              Add optional parameter to print phone number
Parameters MID, MDEP, L_PHONE
Private C_ROLONAME, L_ROLOUSED, C_OLDFILE, OMEDGEN, L_GOT11LINE
If Parameters() = 2
	L_PHONE = .F.
Endif


C_OLDFILE = Select()
Wait Window "Print Deponent Information" Nowait
If Empty(Alltrim(MID)) And !Empty(Alltrim(PC_MAILID))
	MID=Alltrim(PC_MAILID)
Endif
OMEDGEN = Createobject("generic.medgeneric")
L_GOT11LINE=.F.
OMEDGEN.SQLEXECUTE(" select [dbo].[GetTxn11Description] ('" + FIXQUOTE(PC_CLCODE)+ "','" +Str(PN_TAG ) +"')","Desc11")
If Not Empty(Nvl(DESC11.Exp,''))
	L_GOT11LINE=.T.
Endif

**07/29/2010- for some reason the pc_deptype sometimes is undefined (need to look more into it when have some time)
* re-determine Deponent Type!!
If Type('pc_deptype')<>"C"
	If Not Isdigit( Left( Allt( MID), 1))
		PC_DEPTYPE = Left( Allt( MID), 1)
	Else
		PC_DEPTYPE = "D"
	Endif
Endif
**07/29/2010-end
If (L_GOT11LINE And PC_DEPTYPE = "H" ) Or PL_CAVER
	C_DEPTYPE=DEPTBYDESC(DESC11.Exp)
Else
	C_DEPTYPE="Z"
Endif

Wait Window "Getting Deponent's information" Nowait Noclear
_Screen.MousePointer=11
**08/25/2017: Mixed Cases on the TX docs
*L_MAIL=OMEDGEN.SQLEXECUTE("exec dbo.GetDepInfoByMailIdDept '" + MID+"','" + C_DEPTYPE + "' ", "pc_DepoFile")
L_MAIL=DepoData (MID, C_DEPTYPE,  PL_TXCOURT)

=CursorSetProp("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
_Screen.MousePointer=0


Select PC_DEPOFILE
If Eof()

	Wait Window " No deponent data is available. Note the case and tag number (" + Alltrim(PC_LRSNO) + "." + Alltrim(Str(PN_TAG) ) + ") and contact IT dept. Thank you."

Endif
Release OMEDGEN
Do PRINTGROUP With MV, "Deponent"


C_ADDITION= GETDESCRIPT(C_DEPTYPE)

C_DEP=DEPTOPRINT (Alltrim(Nvl(PC_DEPOFILE.Name,MDEP)))


Do PRINTFIELD With MV, "Name",  Iif(PL_TXCOURT, Upper(C_DEP ), c_dep)+ Iif(PC_DEPTYPE = "H"  ,"",C_ADDITION) &&lc_dname
**05/21/2012- print deponent's name  insted of txn 11 line ( per Alec)


If PL_CIVBLE   Or PL_TXCOURT&&#66153: mixed cases for address
	Do PRINTFIELD With MV, "Addr", Alltrim(PC_DEPOFILE.ADD1)+  Iif(Empty(Alltrim(PC_DEPOFILE.ADD2)),"", ", " ) + Alltrim(PC_DEPOFILE.ADD2)
	Do PRINTFIELD With MV, "City",	Alltrim(PC_DEPOFILE.CITY)
Else

	Do PRINTFIELD With MV, "Addr", Alltrim(Proper(PC_DEPOFILE.ADD1))+Iif(Empty(Alltrim(PC_DEPOFILE.ADD2)),"", ", " ) + Alltrim(Proper(PC_DEPOFILE.ADD2))
	Do PRINTFIELD With MV, "City",	Alltrim(Proper(PC_DEPOFILE.CITY))
Endif

Do PRINTFIELD With MV, "State", Alltrim(PC_DEPOFILE.STATE)
Do PRINTFIELD With MV, "Zip", Iif(Alltrim(PC_DEPOFILE.ZIP)='00000','', Alltrim(PC_DEPOFILE.ZIP))

If L_PHONE
	Do PRINTFIELD With MV, "Extra", Transform( PHONE, PC_FMTPHON)
Endif

Select ( C_OLDFILE)
Return
********************************************************************************
Procedure OTHERSUB
* Print Other Subpoena

*********************************************************************************
Parameters MDEP
**10/25/16: do not print SubpoenaOther page here and in subpprint.prg


*!*	IF PL_WCABKOP
*!*		RETURN && 04/23/12 - do not print OtherSuibp page as a scanned subp should print instead -per Alec.
*!*	ENDIF


*!*	DBINIT = SELECT()
*!*	SELECT COURT

*!*	LNCOMPLY = IIF( SEEK( ALLT( PC_COURT1)), GNHOLD + PN_C1CMPLY, 10)
*!*	MDATE = (D_TODAY + GNHOLD)

*!*	SELECT (DBINIT)

*!*	DEP_DATE = D_TODAY + LNCOMPLY
*!*	DO PRINTGROUP WITH MV, "SubpoenaOther"
*!*	DO PRINTFIELD WITH MV, "RT", PC_LRSNO + "." + ALLT( STR( NTAG))
*!*	DO PRINTFIELD WITH MV, "RequestDate", DTOC( MDATE)
*!*	DO PRINTFIELD WITH MV, "Loc", ;
*!*		IIF( PL_OFCMD OR PL_OFCPGH, "P", PC_OFFCODE)

*!*	IF PL_NJSUB OR PL_CAMBPASB
*!*		LDBUSONLY = IIF(L_REPRINT, SZTXNDATE, D_TODAY)
*!*	**07/01/2011
*!*		LN_COUNT =IIF(PL_NJSUB, 13,8)

*!*		IF PL_NJSUB
*!*			LDBUSONLY  = GFCHKDAT( LDBUSONLY+LN_COUNT, .F., .F.) &&3/11/14 -USE CALENDAR DAYS INSTEAD OF BUSNESS PER LIZ

*!*		ELSE

*!*			FOR I = 0 TO LN_COUNT
*!*				LDBUSONLY = LDBUSONLY + 1
*!*				LDBUSONLY = GFCHKDAT( LDBUSONLY, .F., .F.)
*!*			NEXT
*!*		ENDIF
*!*	ENDIF

*!*	DO PRINTFIELD WITH MV, "DepDate", ;
*!*		IIF( PL_NJSUB OR PL_CAMBASB, DTOC( LDBUSONLY), DTOC( DEP_DATE))
*!*	IF EMPTY( SZEDTREQ)
*!*		SZEDTREQ = GFADDCR( SZREQUEST)
*!*	ENDIF
*!*	**04/16/2010 respace the blurb
*!*	DO PRINTFIELD WITH MV, "InfoText",  STRTRAN( STRTRAN( SZEDTREQ, CHR(13), " "), CHR(10), "")
*!*	DO PRINTGROUP WITH MV, "Case"
*!*	DO PRINTFIELD WITH MV, "Plaintiff", ALLT( PC_PLCAPTN)
*!*	DO PRINTFIELD WITH MV, "Defendant", ALLT( PC_DFCAPTN)
*!*	DO PRINTFIELD WITH MV, "AttyType", ;
*!*		IIF( PL_PLISRQ, "P", "D")
*!*	PL_GETAT = .F.
*!*	DO GFATINFO WITH FIXQUOTE(PC_RQATCOD), "M"

*!*	DO PRINTFIELD WITH MV, "AttyName", PC_ATYNAME

*!*	DO PRINTFIELD WITH MV, "Docket", PC_DOCKET
*!*	DO PRINTFIELD WITH MV, "Court", PC_COURT1

*!*	DO PRINTFIELD WITH MV, "Term",  PD_TERM
*!*	DO PDEPINFO WITH MID, PROPER( MDEP), .F.
*!*	SELECT (DBINIT)
Return

********************************************************************
**1/25/2002 EF Print an internal memo page for Texas-Federal issues
********************************************************************
Procedure TXMEMOPG

**********************************************************************
Parameters LCCL_CODE, NTAG
DBINIT=Alias()

Select 0


C_SQL="SELECT * FROM tblCheck WITH(NOLOCK) WHERE cl_code='" + ;
	FIXQUOTE(LCCL_CODE) + "' AND tag='" +  ;
	ALLTRIM(Str(NTAG) )+ "'  and active =1"

OMED.SQLEXECUTE(C_SQL,'Checktx')

Do PRINTGROUP With MV, "TXMemo"
Do PRINTFIELD With MV, "RTTag", PC_LRSNO + "." + Alltrim(Str(NTAG))
Do PRINTFIELD With MV, "Deponent", Alltrim( CHECKTX.Descript)
Do PRINTFIELD With MV, "CheckNo",  CHECKTX.CHECK_NO
Do PRINTFIELD With MV, "Plaintiff", Alltrim( PC_PLNAM)

Use
Select (DBINIT)
Return
******************************************************************************************
******************************************************************************************
**EF 11/04/02
*!*	FUNCTION STOPFAX
*!*	******************************************************************************************
*!*	PARAMETERS LC_DEPT
*!*	PRIVATE L_STOPFAX
*!*	L_STOPFAX = .F.
*!*	**11/06/02 exclude CA and TX offices

*!*	IF PL_CAVER OR PL_OFCHOUS OR PL_RISPCCP
*!*		L_STOPFAX = .T.
*!*		PL_FAXORIG= .F.
*!*		RETURN
*!*	ENDIF
*!*	**01/07/03 Litigation Rules
*!*	IF CREQTYPE = "S"
*!*		IF GNHOLD <> 0
*!*			L_STOPFAX = .T.
*!*			PL_FAXORIG= .F.
*!*		ENDIF

*!*		IF ALLTRIM(PC_COURT1)='USDC'  AND CREQTYPE = "S"   &&11/12/14- do not fax USDC
*!*			L_STOPFAX = .T.
*!*			PL_FAXORIG= .F.
*!*		ENDIF


*!*		IF PL_KOPVER AND ALLTRIM(PC_COURT1)='IL-WCC'  AND CREQTYPE = "S"
*!*	&& 11/16/2012 needs a check $20.00 so no faxing soe subps in the il-wcc courts
*!*			L_STOPFAX = .T.
*!*			PL_FAXORIG= .F.
*!*		ENDIF
*!*	&&do not fax 1st requst for the IL-cookcounty subpoenas
*!*		IF 	PL_ILCOOK AND PL_1ST_REQ
*!*			L_STOPFAX = .T.
*!*			PL_FAXORIG= .F.
*!*		ENDIF
*!*	&&do not fax 1st requst for the IL-cookcounty subpoenas

*!*	ELSE
*!*		IF PL_PROPPA OR PL_PROPNJ
*!*			L_STOPFAX = .T.
*!*		ENDIF
*!*		IF INLIST (PC_LITCODE, "E  ", "D  ", "G  ", "Q  ") AND PL_FROMREV
*!*			L_STOPFAX = .T.
*!*		ENDIF
*!*		IF PL_ZICAM AND PN_OBJDAY<>0
*!*			L_STOPFAX = .T.
*!*		ENDIF
*!*	ENDIF

*!*	**11/29/07 DO NOT FAX BATCH REQUESTS
*!*	IF !EMPTY(PC_BATCHRQ)
*!*		L_STOPFAX = .T.
*!*		PL_SKIPBATCHPRT=.F.
*!*	ENDIF
*!*	**11/29/07
*!*	**04/03/2008 -DO NOR FAX # like 111111111
*!*	IF TYPE('PN_MAILFAX')='C'
*!*		LCEXACTMAIL=SET("Exact")
*!*		SET EXACT OFF
*!*		DO CASE
*!*		CASE  PN_MAILFAX  =  '111' OR PN_MAILFAX='55555'
*!*			L_STOPFAX = .T.
*!*		ENDCASE
*!*		SET EXACT &LCEXACTMAIL
*!*	ENDIF
*!*	**04/03/2008 -DO NOR FAX # like 111111111


*!*	IF NOT PL_STOPPRTISS  AND NOT L_STOPFAX
*!*		IF NOT PL_FAXORIG    ;
*!*				OR ( LC_DEPT=="R" AND NOT PL_RFAXORG) ;
*!*				OR ( LC_DEPT=="P" AND NOT PL_PFAXORG) ;
*!*				OR ( LC_DEPT=="E" AND NOT PL_EFAXORG) ;
*!*				OR ( LC_DEPT=="B" AND NOT PL_BFAXORG) AND NOT L_STOPFAX

*!*			LC_MESSAGE = "This deponent does not accept original issues by fax. Continue to send a fax? "

*!*			IF NOT GFMESSAGE(LC_MESSAGE,.T.)
*!*				L_STOPFAX=.T.
*!*			ENDIF

*!*	*l_StopFax = NOT gfYesNo( "This deponent does not accept original" ;
*!*	+ " issues by fax. Continue to send a fax?")

*!*		ENDIF
*!*	ENDIF && AND NOT pl_StopPrtIss 1/23/08

*!*	**11/29/07 DO NOT FAX BATCH REQUESTS
*!*	IF !EMPTY(PC_BATCHRQ)
*!*		L_STOPFAX = .T.
*!*		PL_SKIPBATCHPRT=.F.
*!*	ENDIF
*!*	**11/29/07


*!*	IF L_STOPFAX
*!*		STORE .F. TO L_FAX1REQ, L_PRTFAX
*!*	ENDIF

*!*	RETURN L_STOPFAX
*******************************************************************************
Procedure CERTINST                              && Certification's Instruction page for MI issues

********************************************************************************
Private C_SAVE
C_SAVE = Select()
Wait Window "Printing Instructions for Certification Page" Nowait Noclear
Do PRINTGROUP With MV, "InstCertif"
Do PRINTFIELD With MV, "Loc", "P"
Select (C_SAVE)
Wait Clear
Return


********************************************************************************
* PROCEDURE: LPMIRDPT
* nor used : the pick of a dept is done in the frmRequestDetails
* Abstract: Let user select dept. for mirrored hospital tags.  Modify description
*  if mirrored tag's dept. is different from original tag's dept.
********************************************************************************
Procedure LPMIRDPT

*******************************************************************************
*!*	Parameter CDEPT

*!*	Private N_CURAREA, C_CURTAG, LC_DEPT
*!*	N_CURAREA = Select()
*!*	Select TIMESHEET



*!*	If "MIRROR OF" $ Descript

*!*		Public LC_DEPT As String
*!*		LC_MESSAGE = "Please pick a Department for your request."
*!*		O_MESSAGE = Createobject('rts_message',LC_MESSAGE)
*!*		O_MESSAGE.Show
*!*	&&08/19/2011- REMOVE MASTER DEPARTMENT FROM A LIST
*!*		Do HOSPDEPT.MPR
*!*		CDEPT=LC_DEPT
*!*		Release LC_DEPT


*!*	Endif


*!*	*--check if dept is different than in record description
*!*	Do Case
*!*	Case CDEPT = "B"
*!*		LC_DEPT = "(BILL)"
*!*	Case CDEPT = "E"
*!*		LC_DEPT = "(ECHO)"
*!*	Case CDEPT = "P"
*!*		LC_DEPT = "(PATH)"
*!*	Case CDEPT = "R"
*!*		LC_DEPT = "(RAD)"
*!*	**8/27/07-added a new department's type
*!*	Case CDEPT = "C"
*!*		LC_DEPT = "(CATH)"
*!*	Otherwise
*!*		LC_DEPT = "(MED)"
*!*	Endcase

*!*	If Not LC_DEPT $ PC_DESCRPT
*!*		Do Case
*!*		Case "(CATH)" $ PC_DESCRPT
*!*			PC_DESCRPT = Strtran( PC_DESCRPT, "(CATH)", LC_DEPT)
*!*		Case "(BILL)" $ PC_DESCRPT
*!*			PC_DESCRPT = Strtran( PC_DESCRPT, "(BILL)", LC_DEPT)
*!*		Case "(ECHO)" $ PC_DESCRPT
*!*			PC_DESCRPT = Strtran( PC_DESCRPT, "(ECHO)", LC_DEPT)
*!*		Case "(MED)" $ PC_DESCRPT
*!*			PC_DESCRPT = Strtran( PC_DESCRPT, "(MED)", LC_DEPT)
*!*		Case "(RAD)" $ PC_DESCRPT
*!*			PC_DESCRPT = Strtran( PC_DESCRPT, "(RAD)", LC_DEPT)
*!*		Case "(PATH)" $ PC_DESCRPT
*!*			PC_DESCRPT = Strtran( PC_DESCRPT, "(PATH)", LC_DEPT)
*!*		Endcase
*!*		Select Request

*!*		Replace Descript With PC_DESCRPT In Request

*!*		ORECMED=Createobject('medrequest')
*!*		ORECMED.UPDATEDATA()

*!*		C_SQL = "Update tblRequest set descript ='" + Left(FIXQUOTE(Alltrim(MDEP))+LCREQCATEGORY, 50) + "'" + ;
*!*			", requestcategory='"+Alltrim(Upper(Nvl(GOAPP.REQUESTCATEGORY,"")))+"'"+;
*!*			" WHERE ID_tblrequests='" + TIMESHEET.id_tblrequests + "' and active =1"
*!*		L_RECUPD= OMED.SQLEXECUTE (C_SQL,"")
*!*		Release ORECMED
*!*	Endif
*!*	Select (N_CURAREA)
Return
**************************************************************************************
Procedure ATTHIPAA                              && Print Attached HIPAA notice page

**************************************************************************************
**DMA 07/22/04 - Update parameters in HIPAASet call
**EF  08/12/03 - print plaintiff notices for civil lit cases


Local  LC_SAVE As String, LC_PLATCOD As String, LN_NOT As Integer, LC_SCAN As String, L_NREC As Integer
Store "" To LC_PLATCOD, LC_SCAN, LC_SAVE
Store 0 To L_NREC, LN_NOT

LC_SAVE = Select()
L_TABILL=GETTABILL(PC_CLCODE)
If Not L_TABILL
	GFMESSAGE("Cannot get TAbills file")
	Return
Endif
**08/16/2011 - when a rq atty =pl atty in the case then prinr a defense atty notices

LN_NOT=1
If Alltrim(PC_RQATCOD)=Alltrim(PC_PLATCOD)
	LC_SCAN="  TABILLS.CODE='D' AND TABILLS.NONOTICE=.F.  AND  ln_not =1 "
Else
	LC_SCAN="  TABILLS.CODE='P' and INLIST( Response, 'T', 'F', 'S') AND  ln_not =1 "
Endif


Select TABILLS
Go Top
Scan  For  &LC_SCAN
	L_NREC=Recno()
	LN_NOT=2
	LC_PLATCOD=AT_CODE
* Generate a HIPAA notice for each plaintiff's attorney	/  or as 08/16/2011 when a rq atty =pl atty in the case then prinr a defense atty notices

	If PL_OFCOAK And Left( Alltrim(PC_COURT1), 4) = "USDC"
&&03/16/12 - new plaintiff's notice for the USDC court

		If Type ('pn_tag')="C"
			N_TAG =Val(PN_TAG)
		Else
			N_TAG=PN_TAG
		Endif
		C_CLCODE=PC_CLCODE
		Do USDCPLNOT With LC_PLATCOD, C_CLCODE, N_TAG

	Else
		*-- If !PL_TXCOURT  06/08/2021 MD #240194 exclude this page for IN subpoenas
		If !PL_TXCOURT AND !plCourtIn
			Do PLNOTICE With LC_PLATCOD
		Endif
	Endif

	Select TABILLS
	Goto L_NREC
Endscan

* Generate a HIPAA document set for the deponent
* 07/22/04 DMA Eliminate unused parameters in call to HIPAASet
**06/29/2011- NJ sub- do not print hippa set
**01/16/2013 - Aded IL-Cook sub
**11/18/16 - print hipaa for NJ subps #53154
*IF NOT PL_NJSUB
**If Not PL_ILCOOK &&  --- 08/05/2020 MD #173172 removed ILCook check

	Do HIPAASET With .T.
**Endif
*ENDIF

If Not Empty(LC_SAVE)
	Select (LC_SAVE)
Endif
Wait Clear



Return


*******************************************************************************************************
Procedure CABRKDWN

*******************************************************************************************************
** DMA 05/28/03 Moved here from Subp_CA, since it's only called from subp_pa
** EF 04/14/03  Generate CA Rad-Path breakdown document
Parameters LCDEPT, LNTAG, LCDEPONENT, LCMAIL_ID
** lcDept: Hospital Department Code ("R" = Radiology, "P" = Pathology)
** lnTag: Tag # for which form is being created
** lcDeponent: Deponent name
** lcMail_ID: Mail ID of deponent

Private LCALIAS, LCDEPATTN, LCDPHONE, L_ISRAD, C_ROLONAME
L_ISRAD = ( LCDEPT = "R")
LCALIAS = Select()
Do PRINTGROUP With MV, "RadPath"
Do PRINTFIELD With MV, "IssueType", ;
	IIF( C_ISSTYPE="S", "Subpoena", "Authorization")
Do PRINTFIELD With MV, "Materials", ;
	IIF( L_ISRAD, "X-Rays", "Pathology")
Do PRINTFIELD With MV, "Slides", ;
	IIF( L_ISRAD, ""," slides/blocks")
Do PRINTFIELD With MV, "Action", ;
	IIF( L_ISRAD, "duplication.", "remitting.")
Do PRINTFIELD With MV, "OtherInst", ;
	IIF( L_ISRAD, "Our office can pick-up the original " + ;
	"x-rays for duplication if desired. The originals will be returned to you.",;
	"")
Do PRINTFIELD With MV, "Col1", ;
	IIF( L_ISRAD, "Number of Films", "Accession #")
Do PRINTFIELD With MV, "Col2", ;
	IIF( L_ISRAD, "Type of Films", "Specimen")
Do PRINTFIELD With MV, "Col3", ;
	IIF( L_ISRAD, "Dates Taken", "Slide/Block #")
Do PRINTFIELD With MV, "Col4", ;
	IIF( L_ISRAD, "Price Per Film", "Price Per Slide/Block")

Do PRINTFIELD With MV, "Loc", PC_OFFCODE
Do PRINTFIELD With MV, "RTTag", ;
	"RT #: " + PC_LRSNO + " Tag#: " + Alltrim( Str( LNTAG))
If Type('pd_pldob')<>"C"
	PD_PLDOB=Dtoc(PD_PLDOB)
Endif
Do PRINTFIELD With MV, "PertainTo", ;
	PC_PLNAMRV +  " DOB: " +  Left(PD_PLDOB,10) ;
	+ " SSN: " + Alltrim( PC_PLSSN)
Do PRINTGROUP With MV, "Deponent"
Do PRINTFIELD With MV, "Name", Alltrim( LCDEPONENT)

Select PC_DEPOFILE
Do PRINTFIELD With MV, "Addr", Alltrim(PC_DEPOFILE.ADD1+ ' ' + PC_DEPOFILE.ADD2)
Do PRINTFIELD With MV, "City",	Alltrim(PC_DEPOFILE.CITY)
Do PRINTFIELD With MV, "State", Alltrim(PC_DEPOFILE.STATE)
Do PRINTFIELD With MV, "Zip", Alltrim(PC_DEPOFILE.ZIP)

* 05/14/03 DMA Use external routine for easier maintenance
LCDEPATTN = GFGETATT( PC_DEPTYPE)
Do PRINTFIELD With MV, "Extra", Upper( Alltrim( LCDEPATTN))

LCDPHONE = PC_DEPOFILE.PHONE
Do PRINTFIELD With MV, "NotcName", Transform( LCDPHONE, PC_FMTPHON)
If Not Empty(LCALIAS)
	Select (LCALIAS)
Endif

Return
**************************************************************************************************************
Procedure CACOVLTR
**************************************************************************************************************
** Cover letter for CA Subpoena-based request
* 05/24/03 DMA  Moved here from Subp_CA since it's only called from Subp_PA
*               Modified to use global TAMaster variables and eliminate
*               unneeded parameters.
Parameters LCRCANO, LLHS, LNCHECK, LDCONTROL,  L_FAKEPRINT
Private _LCPROC, DBINIT, C_ROLONAME, C_ADDITION As String, C_SQL As String
Store "" To C_ADDITION , C_SQL

DBINIT = Select()
*LNCHECK =0
Set Procedure To TA_LIB Additive

Wait Window "Printing Cover Letter for Subpoena" Nowait Noclear
_Screen.MousePointer=11

Select SUBPOENA
Set Order To CLTAG
LLDEFAULT = .T.

local lbFileAvail							&& 9/22/2022, ZD #288190, JH
lbFileAvail = chkFileAvail(f_subpoena)
if !lbFileAvail
	wait window "Subpoena table could not be located."
endif										&& 9/22

If Seek( PC_CLCODE + Str( NTAG))
	LLDEFAULT = .F.
	Scatter Memo Memvar
	Do Case
	Case SUBPOENA.Type = "C"
		PC_SUBPTYP="C"
		Do PRINTGROUP With MV, "CARequestCivil"

	Case SUBPOENA.Type = "P"
		PC_SUBPTYP="P"
		Do PRINTGROUP With MV, "CARequestDepPers"
	Endcase
ELSE
		Do PRINTGROUP With MV, "CARequestCover"
Endif
**USE  && CLOSED SUBPOENA FILE: KEEP IT OPEN

Do PRINTFIELD With MV, "Loc", PC_OFFCODE + Iif( PL_BBASB, "A", "")

If Left( Alltrim(PC_COURT1), 4) <> "USDC" And LLDEFAULT
*-- 03/17/2022 MD #266354
	*--Do PRINTFIELD With MV, "HandServeDate", ;
		*--IIF( LLHS, "HS", "S") + "-" + Dtoc( LDHANDSERVE)
	*-- 03/17/2022 MD #266354
	SELECT 0	
	If Type('OMED') <>"O"
		OMED= Createobject("generic.medgeneric")
	Endif
	OMED.CLOSEALIAS("tagNoNotice")
	C_SQL="select dbo.checktagNoNotice('" +FIXQUOTE(PC_CLCODE) +"',"+Alltrim(Str(NTAG))+")  as cntr"
	OMED.SQLEXECUTE(C_SQL, "tagNoNotice")
	LOCAL noNoticeCntr
	noNoticeCntr=0
	SELECT tagNoNotice
	IF RECCOUNT()>0
		noNoticeCntr=NVL(tagNoNotice.cntr,0)
	ENDIF 
	OMED.CLOSEALIAS("tagNoNotice")
	Select SUBPOENA
	IF noNoticeCntr>0
		Do PRINTFIELD With MV, "HandServeDate", ;
		IIF( LLHS, "HS", "S") + "-" + Dtoc( LDHANDSERVE)
	ELSE 
		Do PRINTFIELD With MV, "HandServeDate",""
	ENDIF 	
Else
	Do PRINTFIELD With MV, "HandServeDate", ""
Endif
If Not L_FAKEPRINT
&& 11/16/09 REMOVED PER ALIEC
	Do PRINTFIELD With MV, "SecondRequest", Iif( L_PRT2REQ Or L_FAX2REQ, "0", "0")
Else
	Do PRINTFIELD With MV, "SecondRequest",  "0"
Endif

Do PRINTFIELD With MV, "RcaNo", Iif( Empty( LCRCANO), " ", ;
	"ASB#:"  +Space(12)+ PC_BBROUND + "." + PC_PLBBASB )
*!*	IF  PL_POSTFEE AND PNREQCHECK<>0
*!*		LNCHECK=PNREQCHECK
*!*	ENDIF
IF TYPE(" LNCHECK")<>"N"
	 LNCHECK=0
ENDIF 	 
Do PRINTFIELD With MV, "CheckNo", ;
	IIF( LNCHECK = 0, " ", Alltrim( Str( LNCHECK)))

Do PRINTGROUP With MV, "Control"
Do PRINTFIELD With MV, "Date", Dtoc( LDCONTROL)
Do PRINTFIELD With MV, "LrsNo", PC_LRSNO
Do PRINTFIELD With MV, "Tag", Alltrim(Str( NTAG))

Select PC_DEPOFILE
C_ADD=PC_DEPOFILE.ADD1 + Iif(Empty(PC_DEPOFILE.ADD2),'',Chr(13) +PC_DEPOFILE.ADD2)
Do PRINTGROUP With MV, "Deponent"
**05/21/2012- print deponent's name on a CA cover page insted of txn 11 line ( per Alec)
C_DEP=""

If Type('OMED') <>"O"
	OMED= Createobject("generic.medgeneric")
Endif
OMED.CLOSEALIAS("Dept")
C_SQL="select dbo.GetDeptCode2('" +FIXQUOTE(PC_CLCODE) +"',"+Alltrim(Str(NTAG))+") as deptcode"
OMED.SQLEXECUTE(C_SQL, "Dept")
C_ADDITION= GETDESCRIPT(Nvl(DEPT.DEPTCODE,'Z'))

C_DEP=DEPTOPRINT (Alltrim(Nvl(PC_DEPOFILE.Name,MDEP)))

Do PRINTFIELD With MV, "Name", C_DEP  + C_ADDITION &&lc_dname
**07/17/12 - SHOW ATTN LINE FROM ROLODEX OR DEPT (HOSPITALS ONLY)
Do DEPINFOLETTER With Nvl(DEPT.DEPTCODE,'Z') In REPPDF

Do PRINTFIELD With MV, "Addr", C_ADD
Do PRINTFIELD With MV, "City", Alltrim(PC_DEPOFILE.CITY)
Do PRINTFIELD With MV, "State",Alltrim(PC_DEPOFILE.STATE)
Do PRINTFIELD With MV, "Zip", Alltrim(PC_DEPOFILE.ZIP)
Do PRINTFIELD With MV, "Extra", Iif(Isnull(SZATTN),"",SZATTN)

Do PRINTGROUP With MV, "Plaintiff"
Do PRINTFIELD With MV, "FirstName", PC_PLNAM
Do PRINTFIELD With MV, "MidInitial", ""
Do PRINTFIELD With MV, "LastName", ""
Do PRINTFIELD With MV, "Addr1", PC_PLADDR1
Do PRINTFIELD With MV, "Addr2", PC_PLADDR2
If Type('pd_pldob')<>"C"
	PD_PLDOB=Dtoc(PD_PLDOB)
Endif
If Type('pd_pldoD')<>"C"
	PD_PLDOD=Dtoc(PD_PLDOD)
Endif


Do PRINTFIELD With MV, "BirthDate",  Iif(Isnull(PD_PLDOB),'',Left(PD_PLDOB,10))
Do PRINTFIELD With MV, "SSN", PC_PLSSN
Do PRINTFIELD With MV, "DeathDate", Iif(Isnull(PD_PLDOD),'',Left(PD_PLDOD,10))
Do PRINTFIELD With MV, "Extra", ;
	IIF( Not Empty( PC_MAIDEN1), "A.K.A.: " + Allt( PC_MAIDEN1), "")

_Screen.MousePointer=0
Select (DBINIT)
Wait Clear
Return
*--------------------------------------------------------------------------------------------------------
Procedure CAAUTCOV
*--------------------------------------------------------------------------------------------------------
* 05/24/03 DMA  Moved here from Subp_CA since it's only called from Subp_PA
*               Modified to use global TAMaster variables and eliminate
*               unneeded parameters.
Parameters LCRCANO, SZEDTREQ, LDCONTROL, L_FAKEPRINT
Private _LCPROC, DBINIT, LNCHECK, C_ADDITION As String, C_SQL As String
Store "" To C_SQL, C_ADDITION

DBINIT = Select()

Set Procedure To TA_LIB Additive

Wait Window "Printing Cover Letter for Authorization" Nowait Noclear
_Screen.MousePointer=11
LNCHECK = 0
***EF 1/12/07- NOT SURE IT IS NEEDED HERE..TRYING TO CATCH A PROBLEM WITH MISSING BLURBS ON ATTACHMENT3
If Empty(SZEDTREQ)
	SZEDTREQ= GETSPECINSFORTAG(NTAG)
Endif
***EF 1/12/07-END

Do PRINTGROUP With MV, "CAAuthCover"
Do PRINTFIELD With MV, "Loc", PC_OFFCODE + Iif( PL_BBASB, "A", "")
If Not L_FAKEPRINT
	Do PRINTFIELD With MV, "SecondRequest", Iif( L_PRT2REQ Or L_FAX2REQ, "0", "0")
Else
	Do PRINTFIELD With MV, "SecondRequest",  "0"
Endif

If Type('PNREQCHECK')<>"N"
	PNREQCHECK=0
Endif

Do PRINTFIELD With MV, "RcaNo", Iif( Empty(LCRCANO), " ", ;
	"ASB#:" + Space(12) + PC_BBROUND + "." + PC_PLBBASB  )
If  PL_POSTFEE And PNREQCHECK<>0
	LNCHECK=PNREQCHECK
Endif
Do PRINTFIELD With MV, "CheckNo", Iif( LNCHECK = 0, " ", Alltrim( Str( LNCHECK)))
Do PRINTFIELD With MV, "InfoText", ;
	STRTRAN( Strtran( SZEDTREQ, Chr(13), " "), Chr(10), "")

Do PRINTGROUP With MV, "Control"
Do PRINTFIELD With MV, "Date", Dtoc( LDCONTROL)
Do PRINTFIELD With MV, "LrsNo", PC_LRSNO
Do PRINTFIELD With MV, "Tag", Alltrim(Str( NTAG))

Do PRINTGROUP With MV, "Deponent"

**05/07/2012- print deponent's name on a CA cover page insted of txn 11 line ( per Alec)
C_DEP=""
C_SQL="select dbo.GetDeptCode2('" +FIXQUOTE(PC_CLCODE) +"',"+Alltrim(Str(NTAG))+") as deptcode"
If Type('OMED') <>"O"
	OMED= Createobject("generic.medgeneric")
Endif
OMED.SQLEXECUTE(C_SQL, "Dept")
C_ADDITION= GETDESCRIPT(Nvl(DEPT.DEPTCODE,'Z'))
C_DEP=DEPTOPRINT (Alltrim(Nvl(PC_DEPOFILE.Name,MDEP)))

Do PRINTFIELD With MV, "Name", C_DEP  + C_ADDITION &&lc_dname
**05/07/2012- print deponent's name on a CA cover page insted of txn 11 line ( per Alec)
**07/17/12 - SHOW ATTN LINE FROM ROLODEX OR DEPT (HOSPITALS ONLY)
Do DEPINFOLETTER With  Nvl(DEPT.DEPTCODE,'Z') In REPPDF

Do PRINTFIELD With MV, "Addr", SZADD1 + ;
	IIF( Empty( SZADD2), "", Chr(13) + SZADD2)
Do PRINTFIELD With MV, "City", SZCITY
Do PRINTFIELD With MV, "State", SZSTATE
Do PRINTFIELD With MV, "Zip", SZZIP
Do PRINTFIELD With MV, "Extra", Iif(Isnull(SZATTN),"",SZATTN)

Do PRINTGROUP With MV, "Plaintiff"
Do PRINTFIELD With MV, "FirstName", PC_PLNAM
Do PRINTFIELD With MV, "MidInitial", ""
Do PRINTFIELD With MV, "LastName", ""
Do PRINTFIELD With MV, "Addr1", PC_PLADDR1
Do PRINTFIELD With MV, "Addr2", PC_PLADDR2
If Type('pd_pldob')<>"C"
	PD_PLDOB=Dtoc(PD_PLDOB)
Endif
If Type('pd_pldoD')<>"C"
	PD_PLDOD=Dtoc(PD_PLDOD)
Endif
Do PRINTFIELD With MV, "BirthDate", Left(PD_PLDOB,10)
Do PRINTFIELD With MV, "SSN", Alltrim( PC_PLSSN)
Do PRINTFIELD With MV, "DeathDate", Left(PD_PLDOD,10)
SZAKA = Iif( Not Empty( PC_MAIDEN1), "A.K.A.: " + Allt( PC_MAIDEN1), "")
Do PRINTFIELD With MV, "Extra", SZAKA
_Screen.MousePointer=0

Select (DBINIT)
Wait Clear
Return
*--------------------------------------------------------------------------------------------------------
Procedure CA_AFFID
*--------------------------------------------------------------------------------------------------------
** Print a California Affidavit (Record Certification) Form,
** preceeded by optional instruction page.
* 06/09/03 DMA Reorganized for efficiency
*              Use global or inherited variable info for all form data.
* 06/06/03 DMA Moved here from Subp_CA because it's only called
*              from within Subp_PA.
*              Added parameter to indicate if instructions are needed, to
*              allow elimination of CAAffInst as separate subroutine
Parameters L_NEEDINST
Private DBINIT, DBSPEC_INS, L_USETYPEA, C_TEMPLATE
DBINIT = Select()

Select SUBPOENA

LLDEFAULT = .T.
If Seek( PC_CLCODE + Str( NTAG))
	LLDEFAULT = .F.
	LFORMEXT = SUBPOENA.EXTRA
	Scatter Memo Memvar
Endif

If Not ( LLDEFAULT Or LFORMEXT)
* No affidavit is required for this document.
	Select (DBINIT)
	Wait Clear
	Return
Endif


Select SPEC_INS
DBSPEC_INS = Alias()
**--------------------------------------------------------------------
** 11/23/2009 - MD the latest changes  bring only last record 11 or 44

Go Top
**--------------------------------------------------------------------
&&4/28/2010- add asb# to affidavits
LCDEPT = Alltrim(Nvl(SPEC_INS.DEPT,''))
LCAFFTYPE =Alltrim(Nvl(CERT_TYPE,''))
* 08/01/01 EF  Print old-style affidavit for "A" requests
L_USETYPEA = (SPEC_INS.Type = "A" Or Left( Alltrim(PC_COURT1), 4) = "USDC")
SZREQUEST = SPEC_INS.SPEC_INST
SZEDTREQ = GFADDCR( SZREQUEST)
**12/07/2010- get an affidavit type ( old by dept, new by cert type data)
C_TEMPLATE=GETCAAFFTYPE (  LCDEPT, LCAFFTYPE, LFORMEXT, LLDEFAULT, L_USETYPEA)

If Empty( C_TEMPLATE)
* No affidavit is assigned to this type of request.
	Select ( DBINIT)
	Wait Clear
	Return
Endif
* If affidavit instruction sheet is needed, print it before the affidavit
*----- 11/12/2019 MD #149736
*!*	If L_NEEDINST
*!*		Wait Window "Printing Affidavit Instructions" Nowait Noclear
*!*	* 07/20/04 DMA arGroup[ gn_AffInst] is always set to CAAffInst
*!*		Do PRINTGROUP With MV, "CAAffInst"
*!*		Wait Clear
*!*	Endif
*------
Wait Window " Printing Affidavit." Nowait Noclear
* Open the pre-selected affidavit template and generate the document
Do PRINTGROUP With MV, C_TEMPLATE
* Add in department-specific fields

**01/04/2010 - get an affidavits to print either by a dept or afftype
Do FILLCAAFF With LCDEPT,  LCAFFTYPE
* Add in fields found on all affidavits
Do PRINTFIELD With MV, "InfoText", ;
	STRTRAN( Strtran( SZEDTREQ, Chr(13), " "), Chr(10), "")
Do PRINTFIELD With MV, "DepoDate", Nvl(Dtoc( PD_DEPSITN),'')

Do PRINTGROUP With MV, "Case"
Do PRINTFIELD With MV, "Plcap", Alltrim( PC_PLCAPTN)
Do PRINTFIELD With MV, "Defcap", ;
	IIF( PC_LITCODE = "GWC", "", Alltrim( PC_DFCAPTN))
Do PRINTFIELD With MV, "Docket", Alltrim( PC_DOCKET)

Do PRINTGROUP With MV, "Control"
&&4/28/2010 : get asb.
Local C_ASBNUM As String
C_ASBNUM=""
C_ASBNUM =Iif( (PL_BBCASE And !Empty(Nvl(PC_PLBBASB,""))) , " ASB#: " + Alltrim(PC_PLBBASB),"")

Do PRINTFIELD With MV, "LrsNo", PC_LRSNO +  C_ASBNUM
Do PRINTFIELD With MV, "Tag", Alltrim( Str( NTAG))

Do PRINTGROUP With MV, "Deponent"
If PC_DEPTYPE == "D"
	C_DRNAME=GFDRFORMAT(MDEP)
	C_DEP = Iif(Not "DR."$C_DRNAME,"DR. "+Alltrim(C_DRNAME),C_DRNAME)
Else
	C_DEP = Alltrim(MDEP)

Endif

Do PRINTFIELD With MV, "Name", C_DEP

Do PRINTGROUP With MV, "Plaintiff"
* 05/25/04 DMA Use long plaintiff name

Do PRINTFIELD With MV, "FirstName", PC_PLNAM
Do PRINTFIELD With MV, "MidInitial", ""
Do PRINTFIELD With MV, "LastName", ""
If Type('pd_pldob')<>"C"
	PD_PLDOB=Dtoc(PD_PLDOB)
Endif

Do PRINTFIELD With MV, "BirthDate", Left(PD_PLDOB,10)
Do PRINTFIELD With MV, "SSN", PC_PLSSN

* Add court info for all civil documents and all non-USDC regular requests
If LFORMEXT Or (LLDEFAULT And Left( Alltrim(PC_COURT1), 4)  <> "USDC")
	Do PRINTGROUP With MV, "Court"
	Do PRINTFIELD With MV, "Name", Alltrim( PC_C1DESC)
Endif
Select (DBINIT)
Wait Clear
Return


*******************************************************************************************************
Procedure CAUSDCP2
*******************************************************************************************************
* added lrs/tag 04/09/12
* edited 3/1/12- use a new proof page
Parameters DISSUE
If Type('dissue')="D"
	DISSUE=Dtoc(DISSUE)
Endif


Wait Window "Printing Proof of Service for USDC Subpoena" Nowait Noclear
Do PRINTGROUP With MV, "CAUSDCProof"
Do PRINTFIELD With MV, "Court", Alltrim( PC_COURT1)
Do PRINTFIELD With MV, "Spec", 	Alltrim( DISSUE)
Do PRINTFIELD With MV, "LRS",  PC_LRSNO
Do PRINTFIELD With MV, "Tag", Alltrim(Str(PN_TAG))
Do PRINTGROUP With MV, "Case"
Do PRINTFIELD With MV, "District", pc_distrct
Do PRINTFIELD With MV, "Docket", PC_DOCKET
Do PRINTFIELD With MV, "Plcap", Alltrim( PC_PLCAPTN)
Do PRINTFIELD With MV, "Defcap", Alltrim( PC_DFCAPTN)
Do PDEPINFO With MID, MDEP, .F.
Wait Clear
Return



*******************************************************************************************************
Procedure CAPOSSUB                              && Proof of service of subpoena

*******************************************************************************************************
* 09/13/10 EF  Added call to getrogsdir.prg
* 06/18/03 DMA Switch from lnReqFee to pnReqFee, to eliminate parameter
* 06/16/03 DMA Moved here from Subp_pa
*              Eliminate extra open of TAMaster and SCATTER MEMVAR from Subpoena
* 11/05/02 kdl Modif CAPosSub to look for first 11 transAction to get issue date
*-- 02/10/2021 MD #224406 added CA WCAB check
If LEFT(ALLTRIM(UPPER(pc_court1)), 4) = "WCAB" and pl_ofcoaK 
	RETURN
ENDIF 		
*-- 02/10/2021 MD #224406

Private OMEDSUB As Object
OMEDSUB= Createobject("generic.medgeneric")
Private DBINIT, N_FEEAMT, D_ISSUE
DBINIT = Select()
Wait Window "Printing Proof of Service for Subpoena" Nowait Noclear
*--//  8/11/2009 add logic to use existing POS tiff document if it exists
Local C_POSFOLDER,N_IMAGES,N_FILENUM,C_DPATH,LCDEST,LCSOURCE, LCROGS
LCROGS=""
LCROGS= Alltrim(GETROGSDIR(PN_LRSNO))
If Not Empty(LCROGS)
	C_POSFOLDER=LCROGS+"007\"+Addbs(Padl(Alltrim(Str(NTAG)),3,'0'))

	C_DPATH = Addbs(Alltrim(Addbs(MLPRIPRO("R", "RTS.INI", "Data", "pcxarch", "\")))) + ;
		ADDBS(Right(Allt( PC_LRSNO),1))
	LCDEST   = Addbs(C_DPATH) + Allt( PC_LRSNO) + "ps." + Trans(NTAG, "@L 999")
	N_IMAGES=Adir(A_IMAGES,C_POSFOLDER+"*.tif")
	If N_IMAGES>0 Or File(LCDEST)
*// replace RPS generated POS with the tif image version of the POS
*// the first time it is found. After that it is part of the PCX document set
		Do Case
		Case File(LCDEST)
			Do SENDAUTH With LCDEST
		Otherwise
			LCSOURCE = Addbs(C_POSFOLDER)+A_IMAGES(1,1)
			Copy File (LCSOURCE) To (LCDEST)
			Do SENDAUTH With LCDEST
		Endcase
		Wait Clear
		Return
	Endif
*// 8/11/09 end
Endif

Select SUBPOENA
Set Order To CLTAG
If Seek( PC_CLCODE + Str( NTAG))
	Do Case
	Case SUBPOENA.Type = "P"
		Do PRINTGROUP With MV, ;
			"CAPos" + Iif( SUBPOENA.EXTRA, "PDT", "Pers")
	Case SUBPOENA.Type = "C"
		Do PRINTGROUP With MV, ;
			"CAPos" + Iif( SUBPOENA.EXTRA, "CivDT", "Civil")
	Endcase
Else
&&07/25/2017 :  #66153
	If PL_CIVBLE
		Do PRINTGROUP With MV, "PosSubp"
	Else
		Do PRINTGROUP With MV, "CAPosSubp"
	Endif

Endif
Select 0
&& add witness fee for proof of service on a default subpoena
N_FEEAMT = 0.00
If Used('Timesheet7')
**10/26/09
	Select TIMESHEET7
	Use
Endif

C_SQL="exec  [dbo].[GetEntrybyClTag]'" + FIXQUOTE(PC_CLCODE) + "','" +Alltrim(Str(NTAG) )+ "'"

OMEDSUB.SQLEXECUTE(C_SQL,'Timesheet7')

Select TIMESHEET7
Index On CL_CODE+Str(Tag)+Str(TXN_CODE) Tag AR Additive
Index On CL_CODE+"*"+Str(Tag) Tag CLTAG Additive

*--11/05/02 kdl start: change to look for 1st request, not 1st transAction
Set Order To AR

D_ISSUE = D_NULL
If Seek( PC_CLCODE + Str( NTAG) + Str( 11))
	D_ISSUE=Ctod(Left(Dtoc(TIMESHEET7.TXN_DATE),10))

Endif

Set Order To CLTAG
If Seek( PC_CLCODE + "*" + Str( NTAG))
	Scan While CL_CODE + "*" + Str( Tag) = PC_CLCODE + "*" + Str( NTAG)
		If TIMESHEET7.TXN_CODE = 7
			N_FEEAMT = TIMESHEET7.WIT_FEE
		Endif
	Endscan
ENDIF
*06/20/2018 - MD #90728 
IF TYPE("PNREQFEE")<>"N"
	PNREQFEE=0
ENDIF 	
*---------------------
Do PRINTFIELD With MV, "Loc", PC_OFFCODE
Do PRINTFIELD With MV, "ReqFee", Iif( PNREQFEE > 0, ;
	ALLTRIM( Str( PNREQFEE, 6, 2)), " ")
	*--03/01/2019 #125666 MD
*-- Do PRINTFIELD With MV, "WXX", Iif( N_FEEAMT > 0, "XX", " ")
*-- Do PRINTFIELD With MV, "RXX", Iif( PNREQFEE > 0, "XX", " ")
Do PRINTFIELD With MV, "WXX", Iif( N_FEEAMT > 0, "XXX", "____")
Do PRINTFIELD With MV, "RXX", Iif( PNREQFEE > 0, "XXX", "____")

Do PRINTFIELD With MV, "WFee", ;
	IIF( N_FEEAMT > 0, Alltrim( Str( N_FEEAMT, 6, 2)), " ")
Do PRINTFIELD With MV, "Spec", ;
	PC_LRSNO + "." + Alltrim( Str( NTAG))

Do PRINTGROUP With MV, "Plaintiff"
* 05/25/04 DMA Use long plaintiff name
Do PRINTFIELD With MV, "FirstName", PC_PLNAM
Do PRINTFIELD With MV, "MidInitial", ""
Do PRINTFIELD With MV, "LastName", ""

Do PRINTGROUP With MV, "Case"
Do PRINTFIELD With MV, "Plcap", Alltrim( PC_PLCAPTN)
Do PRINTFIELD With MV, "Defcap", Alltrim( PC_DFCAPTN)
Do PRINTFIELD With MV, "Docket", Alltrim( PC_DOCKET)

Do PRINTGROUP With MV, "Control"
Do PRINTFIELD With MV, "Date", Dtoc(D_ISSUE)
Do PDEPINFO With MID, MDEP, .T.
Release OMEDSUB

Select (DBINIT)
Wait Clear
Return
*-------------------------------------------------------------------------------

*--7/11/03 kdl start: add supplemental tag procedures
********************************************************************************
* PROCEDURE: LPGETSUP
* Abstract: Get supplemental tag
********************************************************************************
Procedure LPGETSUP

*********************************************************************************
Local NILOOP
L_SUPPLEM = .F.
If L_NEW4SCR
*--tag already exists so scheck if it is a mirror. If it is, skip
*--check for supplemental tag. Was done when tag was mirrored.
	N_CURAREA = Select()
	Select TIMESHEET

	If Not "MIRROR OF" $ Descript
		LC_MESSAGE = "Is this a supplemental request?"
		O_MESSAGE = Createobject('rts_message_yes_no',LC_MESSAGE)
		O_MESSAGE.Show
		L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
		O_MESSAGE.Release
		If L_CONFIRM

			L_SUPPLEM = .T.
		Endif
	Endif
	Select (N_CURAREA)
Else
*--tag does not exist yet, so just check for supplemental status
	LC_MESSAGE = "Is this a supplemental request?"
	O_MESSAGE = Createobject('rts_message_yes_no',LC_MESSAGE)
	O_MESSAGE.Show
	L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
	O_MESSAGE.Release
	If L_CONFIRM
		L_SUPPLEM = .T.
	Endif
Endif
If L_SUPPLEM
	N_SUPPLEM=0
	NILOOP=0
	Do While N_SUPPLEM=0 And NILOOP<4
		OSUPTAG=Createobject("generic.frmGetTag")
		If Type("oSupTag")="O"
			OSUPTAG.Show
			N_SUPPLEM=OSUPTAG.SUPTAG
			If N_SUPPLEM=0
				Exit && CANCEL
			Endif
			Release OSUPTAG
			N_SUPPLEM = LFCHKTAG( N_SUPPLEM)
			If N_SUPPLEM > 0
				Exit
			Endif
			NILOOP=NILOOP+1
		Endif
	Enddo
Endif                                           &&l_Supplem
Return

********************************************************************************
* PROCEDURE: LFCHKTAG
* Abstract: Validate entered tag number.  Set to 0 if not found and return .F.
********************************************************************************
Function LFCHKTAG

********************************************************************************
Parameter N_TMPTAG
Private N_CURAREA, N_RECNO, C_ORDER
N_CURAREA = Select()
_Screen.MousePointer=11
If Used('SupplRec')
	Select SUPPLREC
	Use
Endif
If Type("oMed")<>"O"
	OMED= Createobject("generic.medgeneric")
Endif
C_STR="Exec DBO.GetSingleMasterRequest '" + FIXQUOTE(Master.CL_CODE) + "','" ;
	+ Str(N_TMPTAG) + "'"


L_RETVAL= OMED.SQLEXECUTE(C_STR,"SupplRec")
_Screen.MousePointer=0
Select SUPPLREC
If Eof()
	LC_MESSAGE = "Entered tag does not exist. Try again."
	O_MESSAGE = Createobject('rts_message',LC_MESSAGE)
	O_MESSAGE.Show

	N_TMPTAG = 0
Endif

Select ( N_CURAREA)
Return N_TMPTAG
*--7/11/03 kdl end:

********************************************************************************
* PROCEDURE: LP1STLK
* Abstract: Get the user confirmation of tag level first-look and update record table
********************************************************************************
Procedure LP1STLK

*********************************************************************************

Private  N_CURAREA,	c_quest
N_CURAREA = Select()

PL_TFLOOK = .F.
PC_TFLATTY = ""
If PL_CFLOOK
	c_quest="This case is marked for first-look review!"
Else
	c_quest="This tag meets first-look review criteria!"
Endif

LC_MESSAGE = c_quest + " Apply first-look processing to this request?"
O_MESSAGE = Createobject('rts_message_yes_no',LC_MESSAGE)
O_MESSAGE.Show
L_CONFIRM=Iif(O_MESSAGE.EXIT_MODE="YES",.T.,.F.)
O_MESSAGE.Release
If L_CONFIRM
	PL_TFLOOK = .T.
	PC_TFLATTY = PC_FLATTY
Endif


Select (N_CURAREA)
Return



****************************************************************
* 07/20/04 DMA 0ne-line procedure, used only once -- moved into main code
*PROCEDURE TxHIPAAPage
*DO PrintGroup WITH mv, "TXHIPAA"
*RETURN

*******************************************************************************************************
Procedure PRNTXDOC

*******************************************************************************************************
** Moved here from Subp_Lib, since only used from within Subp_PA
** Assumes gfGetCas has already been called
Private BUSED, C_DBF, X, C_ATTY

* Use or Select TABills

C_DBF = Alias()
If Used( "TABills")
	BUSED = .T.
Else
	BUSED = .F.
	L_TABILL=GETTABILL(PC_CLCODE)
	If Not L_TABILL
		GFMESSAGE("Cannot get TAbills file")
		Return
	Endif
Endif
Select TABILLS
Set Order To CLAC

Seek Master.CL_CODE

C_ATTY = TABILLS.AT_CODE

Select  TIMESHEET

* Print notice of intent to depose using written questions

Do PWRQUEST With NTAG, Alltrim( Descript), Alltrim( mailid_no)


Set Procedure To TA_LIB Additive
Do SPINOPEN With "Printing questions"


* Print copies of all the deposition questions
Select  TIMESHEET
Do PRTTXQST With MDEP, MID, RQ_QUEST, Tag
Do SPINCLOSE
If Not PL_AUTOFAX
	Do PRTENQA With MV, MCLASS, Iif( Empty( MGROUP), "0", MGROUP), ""
Endif
If Not Empty(C_DBF)
	Select (C_DBF)
Endif

Return

*******************************************************************************************************
Procedure TXCOURTVAL

*******************************************************************************************************
Local C_ALIAS As String
C_ALIAS =Alias()
HASIT=.F.
If Used("txcourt")
	COURTUSE = .T.
	Select TXCOURT
	HASIT=.T.

Else
	O = Createobj("generic.medgeneric")
	O.SQLEXECUTE("exec dbo.GetAllTxCourt", "TxCourt")
	PC_TXCTTYP = Subs( PC_COURT1, 1, 3)
	Select TXCOURT
	CursorSetProp("KeyFieldList", "COURT,CRT_ID,County", "TXCourt")
	Index On COURT Tag COURT
	Index On CRT_ID Tag CRT_ID

	HASIT = .T.
Endif


If Not Empty(C_ALIAS)
	Select (C_ALIAS)
Endif
If HASIT
	Return .T.
Else
	Return .F.
Endif

****************************************************************************************************
*!*	FUNCTION CHECKMISSINGCAPS
*!*	LOCAL L_RETVAL
*!*	L_RETVAL =.T.
*!*	DO CASE
*!*	CASE EMPTY( PC_RQATCOD)

*!*		LC_MESSAGE = "Requesting Attorney is missing from case! Go to 1 screen."
*!*		O_MESSAGE = CREATEOBJECT('rts_message',LC_MESSAGE)
*!*		O_MESSAGE.SHOW
*!*		DO UPDTOPREISSUE WITH "4"
*!*	&&07/22/2011 DO NOT ALLOW WITH AN ISSUE TILL CAPS ARE FILLED
*!*	CASE EMPTY( PC_PLCAPTN) OR EMPTY( PC_DFCAPTN)

*!*		LC_MESSAGE = IIF(EMPTY( PC_PLCAPTN),"Plaintiff Caption is missing. Please edit the case.", "Defense Caption is missing. Please edit the case.")
*!*		O_MESSAGE = CREATEOBJECT('rts_message',LC_MESSAGE)
*!*		O_MESSAGE.SHOW


*!*	ENDCASE

*!*	RETURN  L_RETVAL

********************update request with an origibal pre-issue status/data.******************************************
Procedure UPDTOPREISSUE

*******************************************************************************************************
Parameters CSTEP

Local L_RETVAL As BOOLEAN, N_OLDTAG As Integer, C_ALIAS As String, OMEDR As Object
C_ALIAS =Alias()
If Type ('OMEDR')<>'O'
	OMEDR = Createobj("generic.medgeneric")
Endif
If (Used ("REQUEST") Or Used ("Record") ) And Used("IfCancel")

	Select ifcancel
	Go Top



	If ifcancel.action="U" And tblname ="Record"
		L_RETVAL= .T.
		C_STR="Update tblRequest set req_date = NULL, SEND_DATE =NULL, " ;
			+ "status='T',  QUAL='"+ '' + "', INPROGRESS=0, descript ='" + FIXQUOTE(Alltrim(Record.Descript)) + "'" ;
			+ " Where cl_code = '" + FIXQUOTE(PC_CLCODE) + "' AND " + ;
			+ "  Tag = '" + Str(Record.Tag) +"' and deleted is null"
	Else

		C_STR="update tblRequest  set active=0, status='T', deleted='"+CT_TODAY+"', "+;
			"deletedby='"+CSTEP+" CANCELED BY "+Alltrim(GOAPP.CURRENTUSER.NTLOGIN)+"'"+ ;
			" where cl_code='"+FIXQUOTE(PC_CLCODE)+"' and tag ='"+Str(Request.Tag)+"'"

	Endif
	L_RETVAL= OMEDR.SQLEXECUTE(C_STR,"")




	If L_RETVAL
		If ifcancel.action="D" And Inlist(tblname,"Record", "Request")
			N_OLDTAG =Request.Tag-1
			C_STR= "Update tblMaster set subcnt='" +  Str(N_OLDTAG) + "' Where cl_code = '" + FIXQUOTE(PC_CLCODE) + "'"
			L_TAGCNTUPD=OMEDR.SQLEXECUTE(C_STR , "")
			If Not L_TAGCNTUPD

				GFMESSAGE("Cannot retrieve an old Tag's Number for the case. Contact IT. ")
				Return
			Endif
		Endif
	Endif
Endif
If Not Empty(C_ALIAS)
	Select (C_ALIAS)
Endif
Release OMEDR
Return L_RETVAL

**************************************************************************************
* Procedure: LFUPTiff
**as 04/02/13 use scanexe.prg instead
* Date: 5/23/06
* Abstract: Updates user's copy of tiffauto.exe, if necessary
**************************************************************************************


*!*	PROCEDURE lfuptiff
*!*	PRIVATE n_txttiff, d_txttiff
*!*	LOCAL lcoffice
*!*	n_txttiff = ADIR(a_txttiff, "\\SANSTOR\IMAGE\TXTTIFF\TIFFAUTO.EXE")



*!*	IF pl_caver  &&pl_ofcOak
*!*		IF n_txttiff > 0 AND FILE("c:\TIFFAUTO.EXE")
*!*			d_txttiff = a_txttiff[1, 3]
*!*			n_txttiff = ADIR(a_txttiff, "C:\TIFFAUTO.EXE")
*!*			IF n_txttiff > 0
*!*				IF d_txttiff > a_txttiff[1, 3]
*!*					COPY FILE \\sanstor\IMAGE\txttiff\tiffauto.EXE TO c:\tiffauto.EXE
*!*				ENDIF
*!*			ENDIF
*!*		ENDIF
*!*	ELSE
*!*		IF n_txttiff > 0 AND FILE("c:\vfp\TIFFAUTO.EXE")
*!*			d_txttiff = a_txttiff[1, 3]
*!*			n_txttiff = ADIR(a_txttiff, "C:\VFP\TIFFAUTO.EXE")
*!*			IF n_txttiff > 0
*!*				IF d_txttiff > a_txttiff[1, 3]
*!*					COPY FILE \\sanstor\IMAGE\txttiff\tiffauto.EXE TO c:\vfp\tiffauto.EXE
*!*				ENDIF
*!*			ENDIF
*!*		ENDIF
*!*	ENDIF
*******************************************************************************
Procedure NOTARYINS             && Motley-Lead-IL instruction
**EF 08/03/06
********************************************************************************
C_SAVE = Select()

Wait Window "Printing an Instruction Page" Nowait
Do PRINTGROUP With MV, "NotaryIns"
Select (C_SAVE)
Wait Clear
Return
********************************************************************************
Procedure  TOBACCOPAGES          && Tobacco Trust  Inst + Court Order pages
**EF 06/09/2008
********************************************************************************
Private  C_SAVE As String
C_SAVE = Select()

Wait Window "Printing  Instruction Pages" Nowait
Do PRINTGROUP With MV, "TobacInst"
Select (C_SAVE)
Wait Clear
Return
**************************************************************************
Function WHATMONTHISIT()

**************************************************************************
Parameters NID
Private C_MONTH As String
C_MONTH =''
C_MONTH= LAMONTH[nId ]
Return C_MONTH

*******************************************************************************
Procedure  AVAMCEWEN   && AVA/McEwen Court Order
**EF 11/09/2012
********************************************************************************
Private  C_SAVE As String
C_SAVE = Select()

Wait Window "Printing Avandia Court Order Pages" Nowait
Do PRINTGROUP With MV, "AVAEwen"
Select (C_SAVE)
Wait Clear
Return


********************************************************************************
Procedure  MRCLETTER       && MRCCourt Order
**EF 02/12/2014
********************************************************************************
Private  C_SAVE As String
C_SAVE = Select()

Wait Window "Printing MRC Court Order Pages" Nowait
Do PRINTGROUP With MV, "MRCLetter"
Select (C_SAVE)
Wait Clear
Return

********************************************************************************
Procedure  AVACOURTORD       && AVA Court Order
**EF 06/14/2011
********************************************************************************
Private  C_SAVE As String
C_SAVE = Select()

Wait Window "Printing Avandia Court Order Pages" Nowait
Do PRINTGROUP With MV, "AVACourt"
Select (C_SAVE)
Wait Clear
Return

********************************************************************************
Procedure  BALSRQRUSH      && bailey/srq rush letter
**EF 08/22/2011
********************************************************************************
Private  C_SAVE As String
C_SAVE = Select()
Do PRINTGROUP With MV, "BalRush"
Select (C_SAVE)
Wait Clear
Return
********************************************************************************
Procedure  STARKLORPAGE   && 04/24/13

********************************************************************************
Private  C_SAVE As String
C_SAVE = Select()

Wait Window "Printing Avandia Court Order Pages" Nowait
Do PRINTGROUP With MV, "LorStark"
Select (C_SAVE)
Wait Clear
Return
********************************************************************************
Procedure  VLLor
**09/08/2017 : added LOR to all cases in the Vehslage & Lahr's : F000020347
********************************************************************************
Private  C_SAVE As String
C_SAVE = Select()
Do PRINTGROUP With MV, "VLahrLor"
Select (C_SAVE)
Wait Clear
Return
**************************************************************************************
Procedure  CorsiLor
**12/12/2017 : added LOR to all cases in the  Firm Code F000004192. #75224
********************************************************************************
Private  C_SAVE As String
C_SAVE = Select()
Do PRINTGROUP With MV, "GRCosriLor"
Select (C_SAVE)
Wait Clear
Return


**************************************************************************************
Procedure  HMBLor
**11/13/2017 : added LOR to all cases in the  Firm Code F000020550 (Hamilton, Miller & Birthisel)
********************************************************************************
Private  C_SAVE As String
C_SAVE = Select()
Do PRINTGROUP With MV, "HMBLor"
Select (C_SAVE)
Wait Clear
Return
**************************************************************************************
Procedure WCABPAGE

***************************************************************************************
Private LC_SAVE
LC_SAVE = Select()

L_TABILL=GETTABILL(PC_CLCODE)
If Not L_TABILL
	GFMESSAGE("Cannot get TAbills file")
	Return
Endif
Select TABILLS

Do While TABILLS.CL_CODE = PC_CLCODE And Not Eof()
	If TABILLS.Code = "P" And Inlist( RESPONSE, "T", "F", "S")

		Do WCABRQST With TABILLS.AT_CODE
	Endif
	Skip
Enddo
Select TABILLS

Select (LC_SAVE)
Wait Clear



Return

*******************************************************************************
********************************************************************************
Procedure  VigorLor
**09/25/2017 : added LOR to all -firm code F000020274 #69833
********************************************************************************
Private  C_SAVE As String
C_SAVE = Select()
Do PRINTGROUP With MV, "VigorLor"
Select (C_SAVE)
Wait Clear
Return
**************************************************************************************



**04/02/2013 USE SCANEXE.PRG INSTEAD
*!*	PROCEDURE checkburnbase
*!*	LOCAL clocviewer,cnetviewer,d_txttiff,n_txttiff,t_txttiff,cstring,cfile
*!*	clocviewer=ALLTRIM(ADDBS(mlpripro("R", "RTS.INI", "Data","clocprint", "\"))) +"burn_baseimage.exe"
*!*	cnetviewer=ALLTRIM(ADDBS(mlpripro("R", "RTS.INI", "Data","cnetburnbase", "\"))) +"burn_baseimage.exe"

*!*	cfile = clocviewer

*!*	IF NOT DIRECTORY("c:\program files\rts")
*!*		MD "c:\program files\rts"
*!*	ENDIF
*!*	n_txttiff = ADIR(a_txttiff,cnetviewer)
*!*	IF n_txttiff > 0 AND FILE(clocviewer)

*!*		d_txttiff = a_txttiff[1, 3]
*!*		t_txttiff = a_txttiff[1, 4]
*!*		n_txttiff = ADIR(a_txttiff,clocviewer)
*!*		IF n_txttiff > 0
*!*			IF (d_txttiff > a_txttiff[1, 3]) OR (d_txttiff = a_txttiff[1, 3] AND t_txttiff > a_txttiff[1, 4])
*!*				COPY FILE (cnetviewer) TO (clocviewer)
*!*			ENDIF
*!*		ENDIF

*!*	ELSE
*!*		IF n_txttiff > 0
*!*			cnetpath=ALLTRIM(ADDBS(mlpripro("R", "RTS.INI", "Data","cnetburnbase", "\")))
*!*			cstring=ADDBS(cnetpath) + "setup.exe"
*!*			IF FILE(cstring)
*!*				gfmessage("One-time installation process for " + cstring + " required")
*!*				RUN &cstring
*!*			ELSE
*!*				gfmessage("Installation program " + cstring	+ " not found. Please notify Helpdesk.")
*!*			ENDIF
*!*		ENDIF

*!*	ENDIF
