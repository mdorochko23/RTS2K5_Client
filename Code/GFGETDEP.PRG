PROCEDURE GFGETDEP
PARAMETERS C_DEPCLCODE, N_TAG

*
*   Collects critical information about a deponent from Record.dbf and
*   subsidiary databases, and stores it in global variables (defined
*   in Public.prg) for common usage.
*
*   Assumes that the Record table is open, selected, and positioned on the
*   deponent's row.
*
*   REMINDER: Changes to this routine should be made in parallel with
*             changes to gfClrDep and Public.
*
*   Assumes that gfGetCas has already been called for the case.
*
*   Called by New4Scr, Subp_pa, SortDep, CovPage, PrtCovP, Print30,
*             TheNotic, RStatus
*
*    Uses external routines RevwStat
*  03/20/09  EF   added  pc_tagdist ( tag's district for USDC tags)
*  03/28/07  EF   added pl_civsubp
*  05/09/06  EF   Chcek for the "C" datatype on tag's
*  11/11/05  MD   Added pl_investig
*  11/07/05  EF   Use cleanstring for cl-code
*  09/30/05  kdl  convert to use SQL Server tables
*  05/03/05  DMA  Remove comment reference to unused module DepDirec
*  01/24/05  kdl  added check in recspec for soft image flag
*  05/10/04  DMA  Add pc_tag, pc_trimtag for indexing, print/display usage
*  02/26/04  DMA  Add variables for deponent-research tracking
*  02/20/04  EF   Add qualifier for a PA court issues
*   Original coding: 5/1/2001 DMA
*--1/24/05 kdl start: set records soft image flag

LOCAL N_CURAREA, C_TAG

IF  TYPE('n_tag')<>"C"
	C_TAG=ALLTRIM(STR(N_TAG))
ELSE
	C_TAG=ALLTRIM(N_TAG)
ENDIF

LOCAL OMED AS MEDGENERIC OF GENERIC
OMED=CREATEOBJ("medgeneric")
C_CODE= OMED.CLEANSTRING(C_DEPCLCODE)
**10/01/18 SL #109598
*OMED.SQLEXECUTE("SELECT * from tblrequest WITH (NOLOCK,INDEX (ix_tblrequests_2)) "+
OMED.SQLEXECUTE("SELECT * from tblrequest WITH (NOLOCK) "+;
	" WHERE cl_code =" + C_CODE + " AND tag=&c_tag. AND active=1", 'record')


IF PL_GOTDEPO
	RETURN
ENDIF

PN_DEPOREC = RECNO()
PN_TAG     = RECORD.TAG
PC_TAG     = STR( PN_TAG)
PC_TRIMTAG = ALLT( PC_TAG)
PC_DEPOKEY = C_DEPCLCODE + "*" + PC_TAG
PC_ADMKEY  = C_DEPCLCODE + PC_TAG
PC_DEPORCA = RECORD.RCA_NO
PD_OPENDEP = RECORD.OPEN_DATE
PC_DESCRPT = RECORD.DESCRIPT
PD_REQDATE = RECORD.REQ_DATE
PD_REQMAIL = RECORD.SEND_DATE
PC_MAILID  = ALLTRIM(NVL(RECORD.MAILID_NO,''))
*IF !EMPTY( NVL(RECORD.TYPE,''))
	PC_ISSTYPE = NVL(RECORD.TYPE,'')
*ENDIF
PL_INVESTIG= RECORD.INVESTIG
PD_CREATED = NVL(RECORD.CREATED,RECORD.OPEN_DATE)
**4/22/2010 NOT USED ANY LONGER
IF NOT EMPTY( PC_MAILID)
	PC_DEPTYPE = UPPER( LEFT( PC_MAILID, 1))
	IF NOT INLIST( PC_DEPTYPE, "H", "E", "A", "D")
		PC_DEPTYPE = "D"
	ENDIF

ELSE
	STORE " " TO PC_DEPOFILE, PC_DEPTYPE, PC_DEPODEPT, PC_REVSTAT
ENDIF
PL_REISSUE = RECORD.REISSUE
PC_STATUS  = RECORD.STATUS
PL_INCOMPL = RECORD.INC
PC_INCCODE = IIF( PL_INCOMPL OR PL_HIPAA, RECORD.QUAL, " ")
PL_HASNRS  = RECORD.NRS
PC_NRSTYPE = IIF( PL_HASNRS, RECORD.NRS_CODE, " ")
PL_FROMREV = RECORD.FROMREV
PL_AMRESP  = RECORD.AM_RESP
PL_WAIVRCVD = RECORD.WAIVRCVD
pc_TagType=NVL(RECORD.tag_type,'')

*--5/30/19: store tag's scanned document type [87505]
pc_ScanDocType= NVL(RECORD.sScanDocType,'TIFF')

*-- 08/26/21 kdl: add flag to identify Oakland fist-look login path [247599]
pl_Oak_FL_Type=.F.
n_curarea = SELECT()

*OMED.SQLEXECUTE("exec [dbo].[getOakFlLoginType] " + ALLTRIM(STR(pn_lrsno)), 'fltype')
OMED.SQLEXECUTE("exec [dbo].[getOakFlLoginType] " + PC_LRSNO, 'fltype')		&& 6/2/2022, ZD #274239. JH.
IF USED("fltype")
	pl_Oak_FL_Type = NVL(fltype.bresult,.F.)
	USE IN "fltype"
ENDIF
SELECT (n_curarea)

DO CASE
CASE NOT PL_REVIEW
	PC_REVSTAT = "N"
CASE NOT EMPTY( RECORD.REVW_STAT)
	PC_REVSTAT = RECORD.REVW_STAT
CASE NOT INLIST( PC_STATUS, "N", "R", "I", "C")
	PC_REVSTAT = "U"
OTHERWISE
	PC_REVSTAT = " "
ENDCASE
PC_REVLINE = REVWSTAT( PC_REVSTAT)
PL_HOLDPSY  = RECORD.HOLDPSY
PL_AUTOFAX  = .F. &&5/8/08 EF : only needed if  called from the Autofax : Record.AF_AutoFax
PC_FAXATTN  = RECORD.AF_ATTN
PN_AFAXNO   = RECORD.AF_FAXNO
PN_AFCOUNT  = RECORD.AF_FAXCNT
PN_AFCHKAMT = RECORD.AF_CHKAMT
PL_EXPDTE   = RECORD.EXPEDITE
PD_EXPDATE  = NVL(RECORD.EXPDATE, {  /  /    })
PL_SCANN    = RECORD.SCANNED
PL_BBSENT   = RECORD.BB_SENT
PC_BBTYPE   = RECORD.BB_TYPE
PL_FRSTLOOK = NVL(RECORD.FIRST_LOOK,.F.)
PC_TFLATTY   = NVL(RECORD.FL_ATTY,"")
PL_REDACTED = NVL(RECORD.REDACTED,.F.)
PL_DISTRIB  = NVL(RECORD.DISTRIBUTE,.F.)
PL_FLIMGMOD = NVL(RECORD.FL_IMGMOD,.F.)
PL_PICKUP  = RECORD.PICKUP
PC_TAGDIST = NVL(RECORD.DISTRICT,'')
IF NOT PL_BBCASE
	STORE "" TO PC_BBROUND, PC_BBWEBNO, PC_BBLOCNO, PC_BBNURCA
ELSE
	PC_BBROUND = RECORD.ASB_ROUND
	PC_BBWEBNO = RECORD.WEB_ORDER
	PC_BBLOCNO = RECORD.BB_LOCATOR
	PC_BBNURCA = PC_PLBBASB + "." + PC_BBROUND
ENDIF
PN_SUPPTO = RECORD.SUPPLEM_TO                   && supplem_to field data variable
PL_RESRCH = RECORD.RESEARCH                     && .T. if research is in progress
PD_RSCHDATE = NVL(RECORD.RSRCH_DATE ,{  /  /    })                && Date research started
PD_UPLDDATE = RECORD.UPLD_DATE
PL_GOTDEPO = .T.
PL_SOFTFLG = NVL(RECORD.IS_SOFTIMG,.F.)
**Do not include USDC court's tags
LOCAL L_USDCLIKE AS BOOLEAN
L_USDCLIKE =.F.

IF  LEFT( ALLTRIM(PC_COURT1), 4) = "USDC"
	L_USDCLIKE =.T.
ENDIF

IF NOT L_USDCLIKE
	PL_CIVSUBP = IIF(ALLTRIM(PC_LITCODE)="C"  AND (ALLTRIM(PC_ISSTYPE)="S" OR EMPTY(ALLTRIM(PC_ISSTYPE)))  , .T., .F.)
ELSE

	PL_CIVSUBP=.F.
ENDIF
&& non-programmed subp #51529

DO  ChkNonProg
*!*	IF pl_KoPVer AND   TYPE('PC_ISSTYPE')="C"
*!*		IF ALLTRIM(PC_ISSTYPE)="S"
*!*			pl_noSform= IIF ( (pl_c1Form=.F. AND UPPER(pc_RpsForm)="NONPROG"  ) , .T.,.F.)
*!*		ELSE
*!*			pl_noSform=.F. && AUTHS
*!*		ENDIF
*!*	&& : non-programmed subp end
*!*	ELSE
*!*		pl_noSform=.F. && CA OFFICE
*!*	ENDIF

*--if record is on scanning hold, check if program stack includes printcov.
*--if it does set variables to show record as recieved.

IF NOT EMPTY(NVL(RECORD.HSTATUS,'')) AND NOT RECORD.STATUS=='F'
	=ASTACKINFO(A_STACK)
	FOR N_CNT = 1 TO ALEN(A_STACK,1)
		IF UPPER("DEPONENTOPTION") $ UPPER(A_STACK[n_cnt,3])
			IF NOT EMPTY(NVL(RECORD.HSTATUS,''))
				PC_STATUS  = RECORD.HSTATUS
				PL_INCOMPL = RECORD.HINC
				PC_INCCODE = IIF( PL_INCOMPL OR PL_HIPAA,RECORD.HQUAL," ")
				PL_HASNRS  = RECORD.HNRS
				PC_NRSTYPE = IIF( PL_HASNRS,RECORD.HNRS_CODE, " ")
			ENDIF
			EXIT
		ENDIF
	ENDFOR
ENDIF
**07/11/2013 - added new reelase daet for KOP Hold Requests
LOCAL ld_MAIL AS DATETIME
ld_MAIL=PD_REQMAIL
IF TYPE('pn_HoldSub') ="N"
	DO newreleasedt WITH ld_MAIL, pn_HoldSub
**07/11/2013 - added new reelase daet for KOP Hold Requests
ENDIF
RETURN

PROCEDURE ChkNonProg

IF pl_KoPVer AND   TYPE('PC_ISSTYPE')="C"
	IF ALLTRIM(PC_ISSTYPE)="S"
		pl_noSform= IIF ( (pl_c1Form=.F. AND UPPER(pc_RpsForm)="NONPROG"  ) , .T.,.F.)
	ELSE
		pl_noSform=.F. && AUTHS
	ENDIF
&& : non-programmed subp end
ELSE
	pl_noSform=.F. && CA OFFICE
ENDIF

RETURN

