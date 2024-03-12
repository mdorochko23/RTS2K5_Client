PROCEDURE gfdepinf
**EF 01/18/10 - define RPSBATCH by a dept's category
**EF 11/29/07 - added batch printing var
**EF 02/28/07 - added a parameter to get a hospital's dept data
**EF 12/27/05 - switched to sql
******************************************************************************
* PROCEDURE gfMail
*
*   Collects critical information about a deponent from the appropriate rolodex
*   (MailA.dbf, MailD.dbf, MailE.dbf, and MailH.dbf files)
*   and stores it in global variables (defined
*   in Public.prg) for common usage.
*
* ***************************************************************************
*   Called by Subp_pa, afaxrmd, BillCovr, gfGetAtt, Printcan
* ****************************************************************************
*  03/02/05  IZ  check if file can be opened (it can't if mailid_no is empty)
*  11/30/04  EF  Use for the 'Autofax of Cancellation Letters' project
*  06/24/03  DMA Ensure that rolodex is opened before use.
*  06/20/03  DMA Rename to gfDepInf to avoid conflict with gfMail in Global.prg
*  05/16/03  EF  Add Mail Attn data
*  11/04/02  EF  original codding
*
******************************************************************************
PARAMETERS c_hospdept
LOCAL n_dec

IF pl_mail
	RETURN
ENDIF
o = CREATEOBJ("generic.medgeneric")
STORE "" TO pc_madd1, pc_madd2, pc_mailcity, pc_mailst, ;
	pc_mailzip, pc_faxsub, pc_faxauth, pc_govtloc, pc_mailfname, ;
	pc_maillname, pc_raddpt, pc_pathdpt, pc_echodpt, pc_efaxsub, ;
	pc_efaxauth, pc_pfaxsub, pc_pfaxauth, pc_rfaxsub, pc_rfaxauth, ;
	pc_bfaxsub, pc_bfaxauth, pc_mattn, pc_batchrq
STORE 0 TO pn_mailphn, pn_mailfax, pn_radfax, pn_pathfax, ;
	pn_echfax, pn_billfax
STORE .F. TO pl_mailfax, pl_faxorig, pl_efax, pl_efaxorg, ;
	pl_pfax, pl_pfaxorg, pl_rfax, pl_rfaxorg, pl_bfaxorg, ;
	pl_callonly, pl_mcall, pl_bcall, pl_pcall, pl_rcall, ;
	pl_ecall, pl_specrpssrv, pl_handdlvr,  pl_mailorig, pl__fee37



pn_mailrec = RECNO()


IF NOT EMPTY( pc_mailid)
**2/21/08 close the file always before creating a new one (just in case)
	IF FILE("pc_DepoFile")
		SELECT pc_depofile
		USE
	ENDIF
**2/21/08
** 03/02/05 IZ check if file can be opened (it can't if mailid_no is empty)
	o.sqlexecute("exec dbo.GetDepInf '"+pc_mailid+"'", "pc_DepoFile")

	SELECT pc_depofile

	IF TYPE('c_hospdept')='C'
		IF  !EMPTY(c_hospdept) AND UPPER( LEFT( pc_mailid, 1))="H"
			LOCAL lnxxx, lcfield
			lcfield=""
			=AFIELDS(ladeptflds)
			FOR lnxxx=1 TO ALEN(ladeptflds,1)
				IF ALLTRIM(UPPER(ladeptflds[lnXXX,1]))=="DEPT_CODE"
					lcfield="DEPT_CODE"
				ENDIF
				IF ALLTRIM(UPPER(ladeptflds[lnXXX,1]))=="DEPTCODE"
					lcfield="DEPTCODE"
				ENDIF
				IF ALLTRIM(UPPER(ladeptflds[lnXXX,1]))=="CODE"
					lcfield="CODE"
				ENDIF
			NEXT
			IF !EMPTY(ALLTRIM(lcfield))
				LOCATE FOR &lcfield= ALLTRIM(c_hospdept)
				IF NOT FOUND()
**EF 3/20/07- make sure it finds master record.
					LOCATE FOR &lcfield= 'Z'
				ENDIF

			ENDIF
			
		ENDIF
	ENDIF
	pc_maildesc = NAME
	pc_madd1    = add1
	pc_madd2    = add2
	pc_mailcity = city
	pc_mailst   = state
	pc_mailzip  = zip
	n_dec=SET('DECIMALS')
	SET DECIMALS TO 0
	pn_mailphn  = IIF(TYPE('Phone')='N',phone,VAL(phone))
	SET DECIMALS TO n_dec
***11/29/07 - DO NOT FAX WHEN A BATCH REQUEST'S MAIL ID IS USED
**01/18/10-  define RPS by a  dept's category-start
*l_oK=o.sqlexecute("SELECT  dbo.GetRpsQueueName('" + pc_MailID + "')", "RPSQ")
	IF TYPE('c_hospdept')="U" OR TYPE('c_hospdept')="L"
		c_hospdept='Z'
	ENDIF

	l_ok=o.sqlexecute("SELECT dbo.GetRpsQueueNamebyDept ('" + pc_mailid + "','" + c_hospdept + "','" + pc_offcode +"')", "RpsQ")
	IF l_ok
*pc_BatchRq =ALLTRIM(NVL(RpsQ.exp,""))
		pl_specrpssrv=NVL(rpsq.EXP,.F.)
		pc_batchrq=IIF(pl_specrpssrv,"RpsBatch"	,"")

		SELECT pc_depofile
	ENDIF

**01/18/10-  define RPS by a  dept's category -end
	pl_faxorig  = IIF(EMPTY(pc_batchrq),faxorig,.F.)
	pc_faxsub   = IIF(EMPTY(pc_batchrq),fax_sub,"")
	pc_faxauth  = IIF(EMPTY(pc_batchrq),fax_auth,"")
	pn_mailfax  = IIF(EMPTY(pc_batchrq),fax_no,0)
	pl_mailfax  = IIF(EMPTY(pc_batchrq),fax,.F.)

	pc_govtloc  = govt
	pl_callonly = callonly

	pc_mailfname = NAME
	pc_maillname = ""
	pc_mattn     = ALLTRIM( attn)


	pc_raddpt   = ""
	pc_pathdpt  = ""
	pc_echodpt  = ""
	pn_radfax   = IIF(EMPTY(pc_batchrq),fax_no,0)
	pn_pathfax  = IIF(EMPTY(pc_batchrq),fax_no,0)
	pn_echfax   = IIF(EMPTY(pc_batchrq),fax_no,0)
	pl_efax     = IIF(EMPTY(pc_batchrq),fax,.F.)
	pl_efaxorg  = IIF(EMPTY(pc_batchrq),faxorig,.F.)
	pl_pfax     = IIF(EMPTY(pc_batchrq),fax,.F.)
	pl_pfaxorg  = IIF(EMPTY(pc_batchrq),faxorig,.F.)
	pl_rfax     = IIF(EMPTY(pc_batchrq),fax,.F.)
	pl_rfaxorg  = IIF(EMPTY(pc_batchrq),faxorig,.F.)
	pc_efaxsub  = IIF(EMPTY(pc_batchrq),fax_sub,"")
	pc_efaxauth = IIF(EMPTY(pc_batchrq),fax_auth,"")
	pc_pfaxsub  = IIF(EMPTY(pc_batchrq),fax_sub,"")
	pc_pfaxauth = IIF(EMPTY(pc_batchrq),fax_auth,"")
	pc_rfaxsub  = IIF(EMPTY(pc_batchrq),fax_sub,"")
	pc_rfaxauth = IIF(EMPTY(pc_batchrq),fax_auth,"")
	pn_billfax  = IIF(EMPTY(pc_batchrq),fax_no,0)
	pl_bfaxorg  = IIF(EMPTY(pc_batchrq),faxorig,.F.)
	pc_bfaxsub  = IIF(EMPTY(pc_batchrq),fax_sub,"")
	pc_bfaxauth = IIF(EMPTY(pc_batchrq),fax_auth,"")
	pl_mcall    = callonly
	pl_bcall    = callonly
	pl_pcall    = callonly
	pl_rcall    = callonly
	pl_ecall    = callonly
	pl_handdlvr= NVL(askhanddelivery, .F.)



	pl_mailorig= NVL(askorigsubp,.F.) AND ( "PA" $ pc_court1 OR ALLTRIM(pc_court1) ="PCCP"  or ALLTRIM(pc_Court1) ="WCAB") AND NOT pl_reissue&& 06/21/12 - only use for KOP PA courts , AND NOT A REISSUED TAGS (per Alec)
	 	  &&03/03/14 - remove txn 37 for KOP subp with forms (per Liz)
		**03/13/2013- add txn37 for Orig and kopGeneric sub issues: "HoldPrint" Project.
		DO CASE
		*CASE pl_MailOrig
			*pl_Fee37= .t.
		CASE  pc_RpsForm="KOPGeneric"
			pl_Fee37= .t.
		OTHERWISE
			pl_Fee37= .f.
		ENDCASE
		**03/13/2013- add txn37 for Orig and kopGeneric sub issues
		ENDIF &&& test cycle


pl_mail = .T.

RETURN


