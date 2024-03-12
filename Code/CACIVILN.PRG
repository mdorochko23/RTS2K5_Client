PROCEDURE CACivilN
*****************************************************************************
* CACivilN.prg - Procedures for printing special California notices for
*  civil/deposition subs. Subpoena.dbf contains details of the special notice
*  required for a specific tag. Data is stored in Subpoena.dbf by
*  Subp_pa when the notice request is initially entered into RTS. Additional
*  details for those documents requiring declaration pages will be in
*  DECL.dbf
*
* Called by CANotice at the start of the end-of-day notice production run.
*
* Prior to calling this program, CANotice has stored in file CANType.DBF
*    the PSNotice information on unprinted special notices
*    for date = ldRunDate
* "Special notices" are those with information stored in Subpoena.dbf
* (civil notices, depositions, etc.) and/or Decl.dbf (declaration details)
*
* Calls: gfGetCas, gfClrCas
*
* Uses the following internal procedures within TA_Lib Procedure file:
*      PrintGroup, PrintField, PrintEnq
*
* Uses the following routines internal to Subp_CA
*      CAPosNot -- CA Proof of Service of Notice
*      CADecAff    -- CA Declaration-Affidavit (Civil Duces Tecum)
*      CAConNtc  -- CA Notice to Consumer
*      CAConPOS -- CA Proof of Service of Notice to Consumer
*      CAUSSubp  -- CA US District Court Subpoena for CA court
*      CADepSub    -- CA Deponent Subpoena

* Internal procedures:
*      NotcLoop     -- Primary loop to print notice sets for plaintiff plus
*                          all defendants
*      ReplPrtn     -- Update Printed flag for notices that were printed
*      DefPrep      -- Collect defense attorney information before printing
*      DefLoop      -- Loops through defense attorneys to print their sets
*      DefPrint     -- Print notices for a single defense attorney
*      CANotCov     -- Print Notice cover sheet for deposition/appearance sets
*      ConsPrnt     -- Prints Consumer Notice and Proof of Service
*                             via CAConNtc and CAConPOS
*      PrintSub     -- Print Subpoena via CADepSub or CAUSCDSubp routines in Subp_CA
*      CACivOrd     -- Print Civil Order Verification page set


* RPS DOCUMENTS USED
*      CANotCov Routine: CANotCov, CANotPSCov
*      CACivOrd Routine: CACivOrd, CAPSOrd
*
* History :
* Date     Name  Comment
* ---------------------------------------------------------------------------
** EF 03/30/06 - added to the project.
*****************************************************************************
* EF 03/26/2012   Use new USDC form
* EF 08/21/2009   added with n_type for defprep
* EF  05/26/2005  Fixed a bug in the defprint
* EF  09/23/2004  Fixed a bug : added c_platty
* DMA 07/20/2004  Use case-level globals for all TAMaster data
* DMA 07/15/2004  Eliminate use of cafGetInfo routine in CANotice
* DMA 05/25/2004  Switch to long plaintiff names on all documents
* kdl 05/07/2004  reopen CANType non-excl after tag build
* DMA 05/06/2004  Add calls to gfGetCas, gfClrCas
* DMA 04/30/2004  CANType is now a permanent file, opened and closed here.
*                 Use of psCases temp file is also eliminated in this module.
* DMA 06/03/2003  Use CADepSub, CADecAff instead of CADepSubp, CA_Declaration_Aff
* IZ  06/02/2003  Assigns values in public variables for Cl_Code and Tag
*                 for use by RPS routine PrintJCre
* DMA 04/24/2003  Tuneup of DefPrep routine
* EF  08/20/2002  Added declaration for lRca_no and assigned it to ""
* EF  09/12/2001  3-char. litigation code
* EF  08/29/2000  The deposition pers. subs were replaced and an order
*                 verification set was added.
* EF  08/11/2000  The civil subpoenas were replaced by new ones and an order
*                 verification set was added.
* EF  06/14/2000  The first release.
* ---------------------------------------------------------------------------
*
*  Files open on entry to this routine:
*  dbCANotice -> PSNotice, ordered by a non-unique date + client code index
*                (This will be hidden by the PRIVATE dbCANotice statement below)
*  dbSubp     -> Subpoena, ordered by client code + str(Tag)
*  CANType    -> CANType, unordered
*
*PUBLIC mv, mclass, mgroup, mTag

*mclass = "Notice"
*mgroup = "1"
PARAMETERS l_HSOnly, rtReprint
*--- 11/13/2020 MD added second parameter #186387
IF PCOUNT()<2
   rtReprint=0
ENDIF 
rtReprint =NVL(rtReprint,0)
IF TYPE("rtReprint")<>"N"
	rtReprint=convertToNum(rtReprint)
ENDIF 
*--- 11/13/2020 MD added second parameter #186387

PRIVATE dbCANotice, dbTAMaster, dbTAAtty, szInit
PRIVATE llReady, lnMax1, lnCur1, l_Defense, l_ExtraDoc, l_SubXtra, ;
   c_SubpType, c_alias as String
c_alias = SELECT()
l_Defense = .F.                                 && .T. when processing defense atty notices
lCAAsb = .F.                                    && .T. when working on CA Asbestos case
l_ExtraDoc = .T.                                && .T. when Decl.C1 is .F. for the issue
l_SubXtra = .F.                                 && .T. when Subpoena.Extra is .T. for the issue
c_SubpType = " "                                && Subpoena type code from Subpoena file



WAIT WINDOW "Checking deposition/appearance notices. Please wait." NOWAIT NOCLEAR 

* Set up this routine's primary copy of the PSNotice file, using a
* non-unique index on date + case (+ hand-serve flag, if needed).
* The index only includes unprinted notices.
* Position the file on the first unprinted notice for the print date.
pc_CntNot = IIF( L_HSOnly, "ca_hscount", "ca_count")

SELECT canotice
SET ORDER TO (pc_CntNot)
SEEK DTOC( ldRunDate)

* Set up this routine's copy of the Subpoena database, and look for an
* entry matching the case and tag of the selected notice in dbCANotice.
* If no entry is found, assume this is a default-format subpoena.
* If an entry is found, get the Extra flag to see if this is a default subpoena.
*

SELECT subpoena
llDefault = .T.
IF SEEK( Canotice.Cl_Code + STR( Canotice.Tag))
   SCATTER MEMO MEMVAR
   l_SubXtra = m.extra
ENDIF

oMed = CREATEOBJECT("generic.medgeneric")
LOCAL oMstr as medMaster OF Master 
oMstr=CREATEOBJECT("medMaster")
SET PROCEDURE to ta_lib additive


IF USED( "CANType")
   SELECT CANType
   USE
ENDIF
USE ( f_CANType) EXCL IN 0
*
* Set up indexes on CANType to provide one entry for each individual case
* that has notices to be printed.
SELECT CANType
INDEX ON Cl_Code + STR( Tag) TAG clTag
INDEX ON DTOC( txn_date) + Cl_Code UNIQUE FOR NOT Printed ;
   TAG ca_cases
INDEX ON DTOC( txn_date) + Cl_Code UNIQUE FOR NOT Printed ;
   AND hs_notice TAG ca_hscases

*--5/7/05 kdl start: reopen the table multi user
USE ( f_CANType) IN 0

* ---------------------------------------------------------------------------
* Print Plaintiff notices first
* ---------------------------------------------------------------------------

IF l_HSOnly
   SET FILTER TO hs_subpoen
ENDIF
pc_CaseNot = IIF( l_HSOnly, "ca_hscases", "ca_cases")
SET ORDER TO (pc_CaseNot)
SEEK DTOC( ldRunDate)

COUNT TO lnMax1 WHILE txn_date = ldRunDate
lnCur1 = 0
SET NEAR ON
SEEK DTOC( ldRunDate)
*
* Each pass through this loop processes a single case. There may be
* more than one notice to be printed for the case.
*
* 07/15/04 DMA CANType now only holds entries for the desired print date.
*              No more need for the WHILE clause on the SCAN.
SCAN 
   gcCl_Code = CANType.Cl_Code
   gnTag = CANType.Tag
    l_gotMasterid=oMed.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(CANType.Cl_Code) + "')", "MasterID")
      IF  NOT l_gotMasterid
      	gfmessage("Data processing error. Try again or contact IT dept.")
      	RETURN 
      ENDIF
      
      	oMstr.getitem(Masterid.exp)   
      	RELEASE oMstr    
    	SELECT MASTER      
      pl_GotCase = .F.
      DO gfGetCas WITH .T.    
     IF NOT USED('Court')
		DO GetCACourt WITH ALLTRIM(master.court)
	endif            
        

   SELECT CANType  
   mv = ""
   mclass = "Notice"
   mgroup = "1"
	mDep=""
	mid=""
	*-- 01/20/2021 MD #218721 sent reprint notices to RPS16
	IF rtReprint>0
		mclass = "reprintNotice"
	ENDIF 
	*---------------------------------------------------
    *--	11/13/2020 MD added rtReprint #186387
   DO NotcLoop WITH Cl_Code, mDep, mid,rtReprint

   IF NOT EMPTY( mv)
      DO PrintEnq IN ta_lib WITH mv, mclass, mgroup
   ENDIF
   lnCur1 = lnCur1 + 1
   DO gfClrCas
   SELECT court
   use
   SELECT CANType
ENDSCAN
SELECT CANType
USE
SELECT (c_alias )
WAIT CLEAR 
RETURN

*****************************************************************************
PROCEDURE NotcLoop
*
* Plaintiff Notice processing -- do ALL civil depo / appearance notices for the case
*
PARAMETERS c_NotcCase, mDep, mid,lRTReprint
*-- 11/13/2020 MD added RTreprint #186387
IF PCOUNT()<4
   lRTReprint=0
ENDIF 
lRTReprint =NVL(lRTReprint,0)
IF TYPE("lRTReprint")<>"N"
	lRTReprint=convertToNum(lRTReprint)
ENDIF 
*-- 11/13/2020 MD added RTreprint #186387

* PARAMETERS
*  c_NotcCase    case being noticed
*  mDep         deponent name -- empty on entry
*  mID          deponent mail ID -- empty on entry
*
* gfGetCas has already been called for the case referenced by c_NotcCase
*
PRIVATE c_alias , dbCANotice, dbTAMaster, dbTABills, dbTAAtty, c_platty

c_alias  = SELECT()
c_SubpType = " "
c_platty=""
WAIT WINDOW "Preparing Notices.." NOWAIT NOCLEAR 


nTag = CANType.Tag
SELECT subpoena
IF SEEK( c_NotcCase + STR( nTag))
   llDefault = .F.
   SCATTER MEMO MEMVAR
   l_SubXtra = m.extra
ELSE
   llDefault = .T.
   l_SubXtra = .F.
ENDIF

SELECT 0
IF USED('Timesheet')
		SELECT timesheet
		USE
ENDIF
*!*		c_sql="SELECT * FROM tbltimesheet with (NOLOCK, index(IX_tblTIMESHEET)) WHERE cl_code='" + ;
*!*			fixquote(c_NotcCase) + "' AND tag='" +  ;
*!*			ALLTRIM(STR(ntag) )+ "' AND DELETED IS NULL Order by txn_code"

	c_sql=" Exec [dbo].[GetTimeSheetbyClcodeTag] '" + fixquote(c_NotcCase) + "','" + ALLTRIM(STR(ntag) )+ "' "

	oMed.sqlexecute(c_sql,'Timesheet')

	SELECT timesheet	
	INDEX ON cl_code+"*"+STR(TAG) TAG cltag ADDITIVE	
	SET ORDER TO cltag

 	SCAN WHILE Cl_Code + "*" + STR(Tag) = c_NotcCase + "*" + STR( nTag)
      dtxn_date = CTOD(LEFT(DTOC(Txn_date),10))
     
    ENDSCAN
************************


IF NOT USED ("Tabills")
		l_Tabill=gettabill(c_NotcCase)
		IF NOT l_Tabill
			gfmessage("Cannot get TAbills file to print Notices.")
			RETURN
		ENDIF
ENDIF

SELECT tabills

*SEEK c_NotcCase

* Scan through TABills entries for this case, and make notices for all
* that meet all of the following criteria:
*   1) Attorney's role is Plaintiff AND
*   2) Attorney has ordered all or some records AND
*   3) Attorney is not the requesting attorney AND
*   4) Attorney does not have the "don't notice" flag set
SCAN FOR (code = "P") ;
      AND INLIST( response, "T", "S") ;
      AND at_code <> pc_rqatcod ;
      AND NOT NoNotice WHILE (Cl_Code == c_NotcCase)
   SELECT 0
   * Go to the full PSNotice file and scan through ALL unprinted
   * notice requests for the selected date and case
   SELECT CANotice
   SET ORDER TO (pc_CntNot)
*   pc_CntNot is one of "ca_hscount" or "ca_count"; non-unique index
*   that gives us all tags requiring noticing for a date/case pair

pc_court1=ALLTRIM(master.court)
   SEEK DTOC( ldRunDate) + c_NotcCase
   * Process notices only for non-USDC Courts; use Global vbl to check
   IF LEFT( pc_court1, 4) <> "USDC"
      SCAN FOR (txn_date = ldRunDate) ;
            AND NOT Printed ;
            AND (Cl_Code == c_NotcCase)

         SCATTER MEMO MEMVAR

        
         gcCl_Code = m.Cl_Code
         gnTag = m.Tag

         
         SELECT Subpoena
        
         SET ORDER TO ClTag
         IF SEEK ( m.Cl_Code + STR( m.Tag))
            llDefault = .F.
            l_SubXtra = subpoena.Extra
            c_SubpType = subpoena.Type
            IF l_SubXtra
              
                  SELECT 0
                  USE ( f_decl) AGAIN
              
               SET ORDER TO ClTag
               ** Decl.C1 is .T. if "The attached affidavit or declaration"
               **   was checked when the request was entered.
               ** When Decl.C1 is .F., all other fields in Decl are empty
               **   and there are no details to pick up in the Decl file.
               ** l_ExtraDoc is set .T. if the "attached affidavit" field
               **   was NOT checked when the request was entered, which
               **   means that there are additional documents that must
               **   be printed.
               IF SEEK( c_NotcCase + STR( m.Tag))
                  l_ExtraDoc = NOT Decl.C1
               ELSE
                  l_ExtraDoc = .T.
               ENDIF
               * Go back to the file of "special" notices and find the record
               * for this request.
               * Move file's contents into memvars, which will overwrite the
               * data that was SCATTERed earlier from PSNotice
               SELECT CANtype
               SET ORDER TO ClTag
               SEEK c_NotcCase + STR( m.Tag)
               SCATTER MEMO MEMVAR
            ENDIF
         ELSE
            llDefault = .T.
            l_SubXtra = .F.
            c_SubpType = " "
         ENDIF

         * All details have been acquired
         * Generate the plaintiff attorney's packet of documents, followed
         * by the defense attorneys' notice packets

         * 1) Always start off with a notice cover sheet, regardless of document type
         c_platty = pc_platcod
         IF NOT USED('MASTER')
         LOCAL oMstr as Object
        	oMstr=CREATEOBJECT("medMaster")
         	oMstr.getitem(Masterid.exp)    
         	RELEASE oMstr   
    		SELECT MASTER      
      		pl_GotCase = .F.
      		DO gfGetCas WITH .T.   
         ENDIF
         DO GetcaCourt WITH ALLTRIM(master.court)
          
         DO CANotCov WITH m.txn_date, m.hs_notice, c_platty
		
         DO CASE

            * Civil Deposition Subpoena
            CASE c_SubpType = "C" AND l_SubXtra

               * 2) If there is no attached affidavit, generate a notice to Consumer
               *    and matching proof of service
               IF l_ExtraDoc
                  DO ConsPrnt WITH m.due_date, m.hs_notice, ;
                     m.descript, m.mailid_no
               ENDIF

               * 3) Generate Subpoenas
               *DO PrintSub WITH m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date
 				DO PrntSubpwNot WITH m.Cl_Code, m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date,.f.
               

               * 4) Generate CA Declaration-Affidavit (Civil Duces Tecum)
               DO CADecAff IN Subp_CA WITH m.Tag, m.txn_date

               * 5) If there is no attached affidavit, generate Proof of
               *    Service to Consumer
               IF l_ExtraDoc
                  DO CAPosNot IN Subp_CA ;
                     WITH m.Tag, m.hs_notice, .T., .F., ldRunDate
               ENDIF

               * 6) Generate Civil Order Verification
               DO CACivOrd WITH m.due_date, "canotice"

               * 7) Generate second set of Subpoenas
               *DO PrintSub WITH m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date
 				DO PrntSubpwNot WITH m.Cl_Code, m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date,.f.
               
               * 8) Generate second copy of Declaration-Affidavit
               DO CADecAff IN Subp_CA WITH m.Tag, m.txn_date

               * 9) If there is no attached affidavit, generate additional copy
               * of notice to Consumer and Proof of Service of Notice
               IF l_ExtraDoc
                  DO ConsPrnt WITH m.due_date, m.hs_notice, ;
                     m.descript, m.mailid_no
                  DO CAPosNot IN Subp_CA ;
                     WITH m.Tag, m.hs_notice, .T., .F., ldRunDate
               ENDIF

               * 10) Send plaintiff documents to printer
               
               *-- 01/20/2021 MD #218721 sent reprint notices to RPS16
				IF lRTReprint>0
					mclass = "reprintNotice"
				ENDIF
				*------------------------------------------------ 
               IF NOT EMPTY( mv)
                  DO PrintEnq IN ta_lib WITH mv, mclass, mgroup
               ENDIF

               * 11) Generate defense-counsel notice packets
               DO DefLoop WITH lRTReprint

            CASE c_SubpType = "P" AND l_SubXtra
               ** Civil Personal Appearance subpoena w/records

               SCATTER MEMO MEMVAR
               * 2) Generate Notice to Consumer and matching proof of service
               DO ConsPrnt WITH m.due_date, m.hs_notice, ;
                  m.descript, m.mailid_no

               * 3) Generate Subpoenas
               *DO PrintSub WITH m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date
 				DO PrntSubpwNot WITH m.Cl_Code, m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date,.f.
               * 4) Generate Proof of Service of Notice
               DO CAPosNot IN Subp_CA ;
                  WITH m.Tag, m.hs_notice, .T., .F., ldRunDate

               * 5) Generate Civil Order Verification Set
               DO CACivOrd WITH m.due_date, "canotice"

               * 6-9) Second copies of Notice, Subpoenas, Proof of Service of Notice
               DO ConsPrnt WITH m.due_date, m.hs_notice, ;
                  m.descript, m.mailid_no
               *DO PrintSub WITH m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date
                DO PrntSubpwNot WITH m.Cl_Code, m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date,.f.
               DO CAPosNot IN Subp_CA ;
                  WITH m.Tag, m.hs_notice, .T., .F., ldRunDate

               * Send all plaintiff documents to printer
               mclass = "Notice"              
               mgroup = "1"
                *-- 01/20/2021 MD #218721 sent reprint notices to RPS16
               IF lRTReprint>0
					mclass = "reprintNotice"
				ENDIF 
				*---------------------------------------------------
               IF NOT EMPTY( mv)
                  DO PrintEnq IN ta_lib WITH mv, mclass, mgroup
               ENDIF

               * 10) Generate defense attorney packets
               DO DefLoop WITH lRTReprint

            OTHERWISE

               * Civil Deposition or Personal Appearance Subpoena w/o records

               SCATTER MEMO MEMVAR

               * 2) Generate subpoena
               *DO PrintSub WITH m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date
 				DO PrntSubpwNot WITH m.Cl_Code, m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date,.f.
               * 3) Generate Proof of Service of Notice
               DO CAPosNot IN Subp_CA ;
                  WITH m.Tag, m.hs_notice, .T., .F., ldRunDate

               * 4) Generate Civil Order Verification Set
               DO CACivOrd WITH m.due_date, "canotice"

               * 5) Generate second copy of Subpoena
              * DO PrintSub WITH m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date
               DO PrntSubpwNot WITH m.Cl_Code, m.Tag, m.due_date, m.descript, m.mailid_no, m.txn_date,.f.

               * 6) Generate second copy of Proof of Service of Notice
               DO CAPosNot IN Subp_CA ;
                  WITH m.Tag, m.hs_notice, .T., .F., ldRunDate

               mclass = "Notice"
               mgroup = "1"
               *-- 01/20/2021 MD #218721 sent reprint notices to RPS16
               IF lRTReprint>0
					mclass = "reprintNotice"
				ENDIF 
				*---------------------------------------------------
               * Send completed plaintiff set to print
               IF NOT EMPTY( mv)
                  DO PrintEnq IN ta_lib WITH mv, mclass, mgroup
               ENDIF

               * 7) Generate defense attorney notice packets
               DO DefLoop WITH lRTReprint

         ENDCASE
      ENDSCAN
   ENDIF

   mclass = "Notice"
   mgroup = "1"
    *-- 01/20/2021 MD #218721 sent reprint notices to RPS16
    IF lRTReprint>0
		mclass = "reprintNotice"
	ENDIF 
	*---------------------------------------------------
   * If any generated items (defense packets) are still unprinted,
   * send them to the print queues
   IF NOT EMPTY( mv)
      DO PrintEnq IN ta_lib WITH mv, mclass, mgroup
   ENDIF
   * Update the "printed" flags for the notices
   *-- 11/13/2020 MD added RTreprint #186387
   IF NVL(lRTReprint,0)=0
	   DO ReplPrtn WITH c_NotcCase
   ENDIF 
   *-- 11/13/2020 MD added RTreprint #186387
ENDSCAN


SELECT CANotice
USE
WAIT CLEAR 
      RETURN
**************************************************************************
*
* Clean up after civil plaintiff noticing
*
PROCEDURE ReplPrtn
PARAMETERS  c_NotcCase

dbInit = SELECT()
*SELECT TAMaster

IF USED( "CANAtty")
   SELECT canatty
   USE
ENDIF
IF USED( "CAAtList")
   SELECT caatlist
   USE
ENDIF

** After processing, go back and mark all printed notices with Printed=.T.
** Note that dbCaNotice is pointing to an instance of primary PSNotice,
** not the CANType local copy.



l_upd=oMed.sqlexecute("exec dbo.UpdCACivNotice '" + DTOC(txn_date) + "','" + fixquote(c_NotcCase) + "'")
IF NOT l_Upd
					
	gfmessage("Error in the update notice program.")
ENDIF				

IF mv_release
   RELEASE mv
ENDIF
WAIT CLEAR
SELECT (dbInit)

      RETURN

** -----------------------------------------------------------------------------------------------------
PROCEDURE ConsPrnt
* Uses routines in Subp_CA to generate Notice to Consumer and
* matching proof of service
PARAMETERS mdepdate, llHS, mDep, mid
PRIVATE dbInit
dbInit = SELECT()
WAIT WINDOW "Printing notice to consumer" NOWAIT NOCLEAR 
DO CAConNtc IN Subp_CA WITH ldRundate, llHS, mdepdate, mDep, mid
DO CAConPOS IN Subp_CA WITH ldRundate, llHS, mdepdate
SELECT ( dbInit)
WAIT CLEAR 
RETURN

** -----------------------------------------------------------------------------------------------------

PROCEDURE PrintSub
* Generate the subpoena, using the appropriate routine in Subp_CA
* c_NotcCase is the client code of the relevant case
PARAMETERS n_Tag, d_DepoDat, c_Deponent, c_MailID, d_Notice
* n_Tag       Tag number of item for which subpoena is to be generated
* d_DepoDat   Date on which deposition is due
* c_Deponent  Deponent name
* c_MailID    Deponent Mail ID
* d_Notice    Date on which subpoena/notice is being produced

PRIVATE dbInit, dbTAMaster, dbRecord, dbSpec_Ins
dbInit = SELECT()
WAIT WINDOW "Printing subpoena" NOWAIT NOCLEAR 
SELECT 0
	_SCREEN.MOUSEPOINTER=11

*c_code =fixquote(c_NotcCase)
*!*	oMED.sqlexecute("select * from tblspec_ins WITH (NOLOCK) where cl_code = '" + ;
*!*	                    c_code + "' and tag=' " + STR(n_tag) + "' AND ACTIVE=1", "Spec_ins")

oMED.sqlexecute(" exec [dbo].[GetSpecInsByClCodeTag] '" + fixquote(c_NotcCase) + "','" + STR(n_tag) + "'","Spec_ins")
c_code =fixquote(c_NotcCase)
*!*	oMED.sqlexecute("select * from tblRequest WITH (NOLOCK)  where cl_code = '" + ;
*!*						c_code + "' and tag=' " + STR(n_tag) + "' AND ACTIVE=1", "Record")

oMED.sqlexecute(" exec dbo.GetRequestRecordbyClcodeTag '" + fixquote(c_NotcCase)  + "','" + STR(n_tag) + "' ", "Record")
WAIT WINDOW "Getting Deponent's information" NOWAIT NOCLEAR 
		
l_mail=oMED.sqlexecute("exec dbo.GetDepInfoByMailIdDept '" + ALLTRIM(RECORD.MAILID_NO) + ;
				"','" + ALLTRIM(SPEC_INS.dept) + "' ", "pc_DepoFile")
=CURSORSETPROP("KeyFieldList", "Code, id_tbldeponents", "pc_DepoFile")
_SCREEN.MOUSEPOINTER=0					


IF LEFT( ALLTRIM(master.court), 4) = "USDC"
LOCAL l_COURT as String, l_COURT2 as String, l_AtName as String, l_nameinv as String, l_reqType as String, l_county as String, ;
l_dep as String, l_mid as String
STORE "" TO l_COURT , l_COURT2, l_AtName, l_nameinv , l_reqType , l_county,l_dep ,l_mid 
  
      	l_COURT=pc_Court1
		l_COURT2=pc_Court2
		l_AtName=pc_AtyName
		l_nameinv=pc_AtyFirm
		l_reqType= ALLTRIM(NVL(RECORD.TYPE,'A'))
		l_county=pc_c1Cnty
		l_dep=c_Deponent
		l_mid=c_MailID
		pc_tagdist=ALLTRIM(NVL(Record.District,""))
		pn_tag=n_Tag			
		IF TYPE('ldDueDate')="U"   
		ldDueDate=d_DepoDat
		ENDIF
		pd_Depsitn=ldDueDate
		DO subprint with LNTAG, l_COURT, l_COURT2,  l_AtName, l_nameinv,  l_reqType,l_county, l_dep, l_mid
      
      
      
      
ELSE
   DO CADepSub IN Subp_CA WITH Spec_Ins.spec_inst, ;
      ALLTRIM(Record.descript), ALLTRIM(Record.mailid_no), Record.Req_Date, ;
      d_DepoDat, n_Tag
ENDIF

SELECT Record
USE
SELECT Spec_Ins
USE
SELECT ( dbInit)
WAIT CLEAR 
      RETURN
*--------------------------------------------------------------------------------------
*Order verification set
*--------------------------------------------------------------------------------------
PROCEDURE CACivOrd
PARAMETERS d_RunDate, dbPsnotice
*PARAMETERS ldRunDate, c_NotcCase, dbPsnotice, dbTAm, lType, cSubpType
* 07/15/04 DMA Use global case variables
* 05/25/04 DMA Use long plaintiff name
* 05/04/04 DMA Use new-format RCA Number
PRIVATE dbInit, dbCANotice, c_Rca_no, c_Address, c_atcsz
dbInit = SELECT()
mclass = "Notice"
mgroup = "1"
c_Rca_no = ""
c_atcsz = ""
c_Address = ""
WAIT WINDOW "Print Order Verification" NOWAIT NOCLEAR 


SELECT canotice 
SET ORDER TO (pc_CntNot)

SEEK DTOC( d_RunDate) + c_NotcCase
IF NOT USED('Court')
	DO GetcaCourt WITH ALLTRIM(master.court)
endif
DO PrintGroup WITH mv, IIF( c_SubpType = "C", "CACivOrd", "CAPSOrd")
DO PrintField WITH mv, "CourtCounty", pc_c1Cnty
DO PrintField WITH mv, "DocDate", DTOC( canotice.txn_date)
DO PrintField WITH mv, "DepDate", DTOC( canotice.txn_date)
DO PrintField WITH mv, "Loc", ALLTRIM( pc_offcode)
IF l_SubXtra
   DO PrintField WITH mv, "OrdExtra", "."       && "and all parties noticed as indicated."
ELSE
   DO PrintField WITH mv, "OrdExtra", "."
ENDIF
DO PrintField WITH mv, "RT", pc_lrsno

DO PrintGroup WITH mv, "Plaintiff"
* 05/25/04 DMA Use long plaintiff name
DO PrintField WITH mv, "FirstName", ALLT( pc_plnam)
DO PrintField WITH mv, "LastName", ""
DO PrintField WITH mv, "MidInitial", ""
IF pl_BBCase
   * 05/04/04 DMA Use New-format RCA Number
   
    c_Rca_no=""
    l_Rec=oMED.sqlexecute(" exec dbo.GetRequestRecordbyClcodeTag '" + fixquote(c_NotcCase) + "' ,'" +STR(caNotice.Tag) + "'", "Record")
*!*		l_Rec=oMED.sqlexecute("select * from tblrequest WITH (NOLOCK) where cl_code= '" + fixquote(c_NotcCase) + "' and tag ='" + STR(caNotice.Tag) + "' AND ACTIVE=1 ", "Record")
   IF l_Rec
   
      c_RCA_No = pc_plbbASB + "." + record.ASB_Round
      USE
   ELSE
   gfmessage('No Record File')
   endif
   
   DO PrintField WITH mv, "Extra", c_Rca_no
   SELECT CANotice
ELSE
   DO PrintField WITH mv, "Extra", " "
ENDIF

c_Address = ""
c_Address= PrintAtyData ( pc_rqatcod)

DO PrintGroup WITH mv, "ReqAtty"
DO PrintField WITH mv, "Ata1", c_Address

DO PrintGroup WITH mv, "Case"
DO PrintField WITH mv, "Plcap", pc_plcaptn
DO PrintField WITH mv, "Defcap", pc_dfcaptn
DO PrintField WITH mv, "Case", IIF( EMPTY( pc_casenam), " ", pc_casenam)
DO PrintField WITH mv, "Docket", pc_docket
SELECT (dbInit)
WAIT CLEAR 
RETURN
***************************************************************************
***************************
PROCEDURE DefLoop
LPARAMETERS LRTReprint2
* Generate notices for all defense attorneys in a case
PRIVATE l_DefNotc, n_type
IF PCOUNT()<1
   LRTReprint2=0
ENDIF 
LRTReprint2 =NVL(LRTReprint2,0)
IF TYPE("LRTReprint2")<>"N"
	LRTReprint2=convertToNum(LRTReprint2)
ENDIF 


n_type=3
DO case
CASE pc_LitCode == "C  "
	n_type=1
	
CASE pc_LitCode<>"C  "
	n_type=2
endcase

DO DefPrep with n_type

SELECT CANAtty
lnMax1 = RECCOUNT()
lnCur1 = 0
IF lnMax1 > 0
   SET ORDER TO Atty
   GO TOP
   l_DefNotc = .T.
   DO WHILE NOT EOF()
      IF l_SubXtra AND INLIST( c_SubpType, "C", "R")
      IF NOT USED('subpoena')
         SELECT 0
         USE ( f_subpoena) AGAIN ORDER CLTag
      endif    
      SELECT subpoena
         l_DefNotc = SEEK( c_NotcCase + STR( m.Tag))
         *USE
      ENDIF
      IF l_DefNotc
         SELECT CANotice
         SEEK DTOC( ldRunDate) + CANAtty.Cl_Code
         SELECT CANAtty
         IF ( pc_LitCode == "C  ") AND (CANotice.type = "A")
            ** Civil Litigation Authorization defense notices print in CANotice
            SKIP
            LOOP
         ENDIF
         ** Print Defense notices case by case
         lnRec = RECNO()
         mv = ""
        ** DO DefPrint WITH at_code, ldRunDate, c_NotcCase, m.Tag
        **6/27/08 ef - c_NotcCase VS.CANAtty.Cl_Code
       DO DefPrint WITH at_code, ldRunDate, CANAtty.Cl_Code, CANAtty.Tag ,LRTReprint2
      ENDIF
      SELECT CANAtty
      GO lnRec
      SKIP
      lnCur1 = lnCur1 + 1
   ENDDO
   IF l_SubXtra AND INLIST( c_SubpType, "C", "P")
      SELECT CANotice
      LOCATE FOR Cl_Code = c_NotcCase AND Tag = M.Tag
   ENDIF
ENDIF
IF NOT( l_SubXtra AND INLIST( c_SubpType, "C", "P"))
   SELECT CANotice
   LOCATE FOR Cl_Code = c_NotcCase AND Tag = M.Tag
ENDIF
      RETURN
***************************************************************************
PROCEDURE DefPrep2
PRIVATE dbInit
* 04/24/03 DMA Tuneup to eliminate parameters, APPEND BLANK,
*              and inefficient &db.. notation
*
* Builds two temporary files for use in notice-set production:
*    CANAtty holds all notice-eligible non-plaintiff attorneys in the case
*        (this includes both defense and lead attorneys)
*    CAAtList holds all notice-eligible attorneys in the case
*
* Eligibility for notice receipt requires that:
*    1) Attorney's response code in TABills is "T" or "S"
*    2) Attorney is not the Plaintiff's Attorney for the case
*    3) Attorney does not have the NoNotice flag set in TABills

dbInit = SELECT()
LOCAL oMstr as Object
oMstr=CREATEOBJECT("medMaster")
WAIT WINDOW "Preparing list of defense attorneys" NOWAIT NOCLEAR 


USE ( f_CANType) AGAIN IN 0 ORDER (pc_CaseNot) ALIAS NotcData

IF USED( "CANAtty")
   SELECT canatty
   USE
ENDIF
IF USED( "CAAtList")
   SELECT caatlist
   USE
ENDIF
SELECT 0
*-- 01/21/2021 MD #218721
SET SAFETY OFF 
*-- 01/21/2021 MD #218721

CREATE TABLE C:\CANAtty (at_code C(8), Cl_Code C(10))
INDEX ON at_code + Cl_Code TAG atty
INDEX ON at_code UNIQUE TAG notice
CREATE TABLE C:\CAAtList (at_code C(8), Cl_Code C(10), role C(1))
INDEX ON Cl_Code + IIF( role = "P", "1", "2") + at_code TAG Atty

SELECT NotcData
IF SEEK( DTOC( ldRunDate))

l_gotMasterid=oMed.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(NotcData.Cl_Code) + "')", "MasterID")
      IF  NOT l_gotMasterid
      	  gfmessage("Data processing error. Try again or contact IT dept.")
      	RETURN 
      ENDIF
      
      oMstr.getitem(Masterid.exp)       
     
RELEASE oMstr
   SELECT master
  * SEEK c_NotcCase
  l_Tabill=gettabill(c_NotcCase)
		IF NOT l_Tabill
			gfmessage("Cannot get TAbills file to print Notices.")
			RETURN
		ENDIF
   SELECT tabills
  * IF SEEK( c_NotcCase)
      SCAN FOR INLIST( response, "T", "S") AND ;
            TABILLS.At_Code <> master.Rq_At_Code AND ;
            NOT nonotice WHILE tabills.Cl_Code == c_NotcCase
         IF TABILLS.Code <> "P"
            INSERT INTO CANAtty ;
               ( At_code, Cl_Code) ;
               VALUES ;
               ( TABILLS.at_code, c_NotcCase)
         ENDIF
         INSERT INTO CAAtList ;
            (at_code, Cl_Code, role) ;
            VALUES ;
            ( TABILLS.at_code, c_NotcCase, TABILLS.code)
         SELECT TABILLS
      ENDSCAN
  * ENDIF
   SELECT NotcData
ENDIF
SELECT CANAtty
SET ORDER TO Atty
SELECT CAAtList
SET ORDER TO Atty
SELECT NotcData
USE
SELECT tabills
USE
SELECT master
USE
SELECT ( dbInit)
WAIT CLEAR 
      RETURN
*/ -----------------------------------------------------------------

*-------------------------------------------------------------------------------
PROCEDURE DefPrint

** Generate documents for defense attorneys
* 05/26/05 EF  Close files in temp working areas
* 07/22/04 DMA Eliminate unused parameter llGLA, llOrdVer
* 05/04/04 DMA Receive more parameters via inheritance
PARAMETERS lcAt_Code, ldRunDate, c_NotcCase, n_Tag, lrtReprint3
IF PCOUNT()<5
   lrtReprint3=0
ENDIF 
lrtReprint3 =NVL(lrtReprint3,0)
IF TYPE("lrtReprint3")<>"N"
	lrtReprint3=convertToNum(lrtReprint3)
ENDIF 


PRIVATE dbInit, dbTAAtty, dbCANotice, dbTAMaster, lcRqAtty
l_Defense = .T.

dbInit = SELECT()
LOCAL oMstr as Object
oMstr=CREATEOBJECT("medMaster")

l_gotMasterid=oMed.sqlexecute("SELECT DBO.fn_GetID_tblmaster('" + fixquote(c_NotcCase) + "')", "MasterID")
      IF  NOT l_gotMasterid
      	 gfmessage("Data processing error. Try again or contact IT dept.")
      	RETURN 
      ENDIf
      
 oMstr.getitem(Masterid.exp) 
  RELEASE oMstr     
WAIT WINDOW "Preparing defense notice packet for attorney " + ALLT( lcAt_Code) + ;
   " in case " + ALLT( lrs_no) + "." + CHR(13) + ;
   "Notice type: " + IIF( c_SubpType = "C", "Civil Deposition", ;
   "Personal Appearance") NOWAIT NOCLEAR 
lcRqAtty = rq_at_code
llBB = ((litigation == "A  ") AND (rq_at_code=="BEBE  3C"))

*--- 01/05/2022 MD #260575 added second parameter
l_CANot=GetCANotic(ldRunDate,lrtReprint3)

IF NOT l_CANot
	gfmessage("Cannot get CA Notice file")
	RETURN
ENDIF
SELECT canotice
SET ORDER TO (pc_CntNot)
SEEK DTOC( ldRunDate) + c_NotcCase
SCAN FOR Cl_Code == c_NotcCase AND Tag = n_Tag

   ** 06/02/03 IZ assigns public variables for Cl_Code and Tag
   gcCl_Code = c_NotcCase
   gnTag = n_Tag
   ** end IZ

   SCATTER MEMO MEMVAR
   DO CASE
      CASE c_SubpType = "C"
         * Civil Deposition subpoena

         DO CANotCov WITH m.txn_date, m.hs_notice, lcAt_Code

         ** l_ExtraDoc is set .T. if the "attached affidavit" field
         **   was NOT checked when the request was entered, which
         **   means that there are additional documents that must be printed.
         IF l_ExtraDoc AND l_SubXtra
            DO ConsPrnt WITH  m.due_date,;
               m.hs_notice, m.descript, m.mailid_no
         ENDIF
         DO PrintSub WITH n_Tag, m.due_date, m.descript, m.mailid_no, m.txn_date

         *SELECT TAMaster
         *SET ORDER TO Cl_Code
         *SEEK c_NotcCase

         DO CADecAff IN Subp_CA WITH n_Tag, m.txn_date

         ** l_ExtraDoc is set .T. if the "attached affidavit" field
         **   was NOT checked when the request was entered, which
         **   means that there are additional documents that must
         **   be printed.
         IF l_ExtraDoc
            DO CAPosNot IN Subp_CA ;
               WITH n_Tag, m.hs_notice, .T., .F., ldRunDate
         ENDIF
         mclass = "Notice"
         mgroup = "1"
          *-- 01/20/2021 MD #218721 sent reprint notices to RPS16
          IF lrtReprint3>0
			 mclass = "reprintNotice"
		  ENDIF 
		 *---------------------------------------------------
         IF NOT EMPTY( mv)
            DO PrintEnq IN ta_lib WITH mv, mclass, mgroup
         ENDIF

      CASE c_SubpType = "P"
         * Civil Personal appearance subpoena

         DO CANotCov WITH m.txn_date, m.hs_notice, lcAt_Code

         IF l_SubXtra
            SCATTER MEMO MEMVAR
            DO ConsPrnt WITH  m.due_date, m.hs_notice, ;
               m.descript, m.mailid_no
         ENDIF
         DO PrintSub WITH n_Tag, m.due_date, m.descript, m.mailid_no, m.txn_date
         DO CAPosNot IN Subp_CA ;
            WITH n_Tag, m.hs_notice, .T., .F., ldRunDate
         mclass = "Notice"
         mgroup = "1"
		 *-- 01/20/2021 MD #218721 sent reprint notices to RPS16
         IF lrtReprint3>0
			mclass = "reprintNotice"
		 ENDIF 
		 *---------------------------------------------------
         IF NOT EMPTY( mv)
            DO PrintEnq IN ta_lib WITH mv, mclass, mgroup
         ENDIF
   ENDCASE
ENDSCAN
l_Defense = .F.
select master
use
*select Canotice
*use
SELECT (dbInit)
WAIT CLEAR 
RETURN

*----------------------------------------------------------------------------
*Cover page for civil deposition and personal appearance notices
*----------------------------------------------------------------------------
PROCEDURE CANotCov
* Produces the cover page for an individual attorney's notice set.
*    If this is a civil deposition subpoena, RPS document CANotCov is used.
*    If this is a personal appearance subpoena, RPS document CANotPSCov is used.
*
* 07/16/04 DMA Use case-level global variables, acquire most info by inheritance
*              Eliminate lookups in TAMaster, Court databases
* 05/25/04 DMA Use long plaintiff name

PARAMETERS d_Notice, l_HandServ, c_ThisAtty
* d_Notice:     Document date
* l_Handserv:   .T. if notice will be hand-served
* c_ThisAtty:   Attorney code of attorney receiving the notice

PRIVATE dbInit, c_Address

DO PrintGroup WITH mv, IIF( c_SubpType == "C", "CANotCov", "CANotPSCov")
DO PrintField WITH mv, "DocDate", DTOC( d_Notice)
DO PrintField WITH mv, "Loc", ALLTRIM( pc_offcode)

DO PrintField WITH mv, "Title", ;
   IIF( INLIST( c_ThisAtty, pc_platcod, pc_rqatcod) AND l_HandServ, ;
   "HAND SERVED", " ")
DO PrintField WITH mv, "RT", pc_lrsno
DO PrintField WITH mv, "ExtraCap", ;
   IIF( l_Defense, "", " TO CONSUMER'S ATTORNEY")

DO PrintGroup WITH mv, "Case"
IF EMPTY( pc_plcaptn + pc_dfcaptn)
   DO PrintField WITH mv, "Case", pc_casenam
ELSE
   DO PrintField WITH mv, "Case", ALLTRIM( pc_plcaptn) + " VS. " ;
      + ALLTRIM( pc_dfcaptn) + ;
      IIF( EMPTY( pc_casenam), "", CHR(13) + ALLTRIM( pc_casenam))
ENDIF
DO PrintField WITH mv, "Docket", pc_docket
c_Alias=ALIAS()
oMED.sqlexecute("select * from tblcourt where court= '" + master.court + "'", "Court")
pc_c1Cnty=Court.county
SELECT (c_Alias)
DO PrintField WITH mv, "CourtCounty", ALLTRIM( pc_c1Cnty)

DO PrintGroup WITH mv, "Plaintiff"
* 05/25/04 DMA Use long plaintiff name
DO PrintField WITH mv, "FirstName", pc_plnam
DO PrintField WITH mv, "LastName", ""
DO PrintField WITH mv, "MidInitial", ""

dbInit = SELECT()

c_Atty=fixquote(pc_rqatcod)
pl_GetAt = .F.
DO gfatinfo WITH c_Atty, "M"        
* Attorney who is requesting the record
*SEEK pc_rqatcod
DO PrintGroup WITH mv, "ReqAtty"
DO PrintField WITH mv, "Ata1", pc_Atyname&&(ALLTRIM( newfirst) + " " + ;
   IIF( NOT EMPTY( TAAtty.NewInit), TAAtty.NewInit + ". ", "") + ;
   ALLTRIM( newlast) + IIF( NOT EMPTY( title), ", " + title,"") )
DO PrintField WITH mv, "Name_inv", pc_atyfirm&&ALLTRIM( TAAtty.firm)

* Attorney who is receiving the notice

c_Address = ""
c_Address= PrintAtyData ( c_ThisAtty)

DO PrintGroup WITH mv, "PltAtty"
DO PrintField WITH mv, "Ata1", c_Address

SELECT (dbInit)
RETURN
